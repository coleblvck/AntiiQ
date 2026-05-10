package com.coleblvck.antiiq

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import com.coleblvck.antiiq.playback.AntiiQBand
import com.coleblvck.antiiq.playback.AntiiQFilterType
import com.coleblvck.antiiq.playback.GaplessAudioPlayer
import com.coleblvck.antiiq.playback.SimpleAudioFocusController
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeAudioPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var events: EventChannel.EventSink? = null
    private var player: GaplessAudioPlayer? = null
    private lateinit var audioFocus: SimpleAudioFocusController
    private val mainHandler = Handler(Looper.getMainLooper())
    private val queueLock = Any()
    private val upcomingTracks = ArrayDeque<String>()
    private var playbackWakeLock: PowerManager.WakeLock? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.coleblvck.antiiq/native_audio")
        eventChannel = EventChannel(binding.binaryMessenger, "com.coleblvck.antiiq/native_audio_events")
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        audioFocus = SimpleAudioFocusController(
            context = context,
            onPause = {
                player?.pause()
                releasePlaybackWakeLock()
                emitEvent(mapOf("event" to "pausedByFocus"))
            },
            onResume = {
                acquirePlaybackWakeLock()
                player?.start()
                emitEvent(mapOf("event" to "resumedByFocus"))
            },
            onDuck = { shouldDuck ->
                player?.setVolume(if (shouldDuck) 0.3f else 1.0f)
                emitEvent(mapOf("event" to if (shouldDuck) "duckedByFocus" else "unduckedByFocus"))
            },
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (::audioFocus.isInitialized) {
            audioFocus.abandonAudioFocus()
        }
        releasePlaybackWakeLock()
        player?.release()
        player = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        events = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.events = events
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val audioPlayer = ensurePlayer()
        try {
            when (call.method) {
                "open" -> {
                    val path = call.argument<String>("path")
                    val id = call.argument<String>("id") ?: path
                    if (path == null) {
                        result.error("INVALID_ARGUMENT", "path is required", null)
                    } else {
                        result.success(audioPlayer.open(path, id ?: path))
                    }
                }
                "play" -> {
                    if (::audioFocus.isInitialized && !audioFocus.requestAudioFocus()) {
                        result.error("AUDIO_FOCUS_DENIED", "Audio focus was not granted", null)
                        return
                    }
                    audioPlayer.start()
                    acquirePlaybackWakeLock()
                    if (::audioFocus.isInitialized) {
                        audioFocus.setPlaybackActive(true)
                    }
                    result.success(null)
                }
                "pause" -> {
                    audioPlayer.pause()
                    releasePlaybackWakeLock()
                    if (::audioFocus.isInitialized) {
                        audioFocus.setPlaybackActive(false)
                    }
                    result.success(null)
                }
                "stop" -> {
                    audioPlayer.stop()
                    releasePlaybackWakeLock()
                    if (::audioFocus.isInitialized) {
                        audioFocus.setPlaybackActive(false)
                        audioFocus.abandonAudioFocus()
                    }
                    result.success(null)
                }
                "seek" -> {
                    audioPlayer.seekTo(call.argument<Number>("positionMs")?.toLong() ?: 0L)
                    result.success(null)
                }
                "position" -> result.success(audioPlayer.getCurrentPosition())
                "duration" -> result.success(audioPlayer.getDuration())
                "isPlaying" -> result.success(audioPlayer.isPlaying())
                "setGaplessEnabled" -> {
                    audioPlayer.setGaplessEnabled(call.argument<Boolean>("enabled") ?: true)
                    result.success(null)
                }
                "setCrossfadeEnabled" -> {
                    audioPlayer.setCrossfadeEnabled(call.argument<Boolean>("enabled") ?: false)
                    result.success(null)
                }
                "setCrossfadeDuration" -> {
                    audioPlayer.setCrossfadeDuration(call.argument<Int>("durationMs") ?: 0)
                    result.success(null)
                }
                "setUpcomingQueue" -> {
                    val tracks = call.argument<List<Map<String, String>>>("tracks") ?: emptyList()
                    synchronized(queueLock) {
                        upcomingTracks.clear()
                        tracks.forEach { track ->
                            val id = track["id"]
                            val path = track["path"]
                            if (!id.isNullOrBlank() && !path.isNullOrBlank()) {
                                upcomingTracks.add("$id|$path")
                            }
                        }
                    }
                    result.success(null)
                }
                "setEffectsEnabled" -> {
                    audioPlayer.setEffectsEnabled(call.argument<Boolean>("enabled") ?: false)
                    result.success(null)
                }
                "setParametricEqEnabled" -> {
                    audioPlayer.setAntiiQEQEnabled(call.argument<Boolean>("enabled") ?: false)
                    result.success(null)
                }
                "setParametricEqBands" -> {
                    audioPlayer.setAntiiQEQBands(readBands(call.argument<List<Map<String, Any?>>>("bands") ?: emptyList()))
                    result.success(null)
                }
                "setSpeed" -> {
                    audioPlayer.setTempo(call.argument<Number>("speed")?.toFloat() ?: 1.0f)
                    result.success(null)
                }
                "setPitch" -> {
                    audioPlayer.setPitchRate(call.argument<Number>("pitch")?.toFloat() ?: 1.0f)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("NATIVE_AUDIO_ERROR", e.message, null)
        }
    }

    private fun ensurePlayer(): GaplessAudioPlayer {
        val existing = player
        if (existing != null) return existing

        val created = GaplessAudioPlayer(context)
        created.setLifecycleCallback(object : GaplessAudioPlayer.PlaybackLifecycleCallback {
            override fun onTrackEnded() {
                emitEvent(mapOf("event" to "completed"))
            }

            override fun onSeekCompleted(position: Long) {
                emitEvent(mapOf("event" to "seekCompleted", "positionMs" to position))
            }

            override fun onError(errorCode: Int, message: String) {
                emitEvent(mapOf("event" to "error", "code" to errorCode, "message" to message))
            }

            override fun onTrackTransition(fromTrackId: String, toTrackId: String) {
                emitEvent(mapOf("event" to "transition", "from" to fromTrackId, "to" to toTrackId))
            }

            override fun onPrepareNextTrack(): String? {
                val next = synchronized(queueLock) { upcomingTracks.removeFirstOrNull() }
                emitEvent(mapOf("event" to "prepareNext"))
                return next
            }

            override fun onNextTrackFailed(trackId: String, error: String) {
                emitEvent(mapOf("event" to "nextFailed", "trackId" to trackId, "message" to error))
            }
        })
        player = created
        return created
    }

    private fun acquirePlaybackWakeLock() {
        val existing = playbackWakeLock
        if (existing?.isHeld == true) return

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        playbackWakeLock = (existing ?: powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "AntiiQ:Playback"
        ).apply {
            setReferenceCounted(false)
        }).also { wakeLock ->
            if (!wakeLock.isHeld) {
                wakeLock.acquire()
            }
        }
    }

    private fun releasePlaybackWakeLock() {
        playbackWakeLock?.let { wakeLock ->
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
    }

    private fun emitEvent(event: Map<String, Any>) {
        mainHandler.post {
            events?.success(event)
        }
    }

    private fun readBands(values: List<Map<String, Any?>>): List<AntiiQBand> {
        return values.take(15).map {
            AntiiQBand(
                frequency = (it["frequency"] as? Number)?.toFloat() ?: 1000f,
                gainDb = (it["gainDb"] as? Number)?.toFloat() ?: 0f,
                Q = (it["q"] as? Number)?.toFloat() ?: 1f,
                type = (it["type"] as? Number)?.toInt() ?: AntiiQFilterType.PEAK,
                enabled = it["enabled"] as? Boolean ?: true
            )
        }
    }
}
