package com.coleblvck.antiiq.playback

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioRouting
import android.media.AudioTrack
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi

// Audio device data classes
enum class AudioDeviceType {
    USB,
    BLUETOOTH,
    WIRED,
    INBUILT_SPEAKER,
    UNKNOWN
}

data class AudioDeviceData(
    val name: String,
    val type: AudioDeviceType,
    val id: Int = -1
)

data class OutputDiagnostics(
    val compatibilityMode: Boolean,
    val usePcm16Output: Boolean,
    val outputPath: String,
    val processingFormat: String,
    val outputEncoding: String,
    val sessionId: Int,
    val currentDeviceId: Int,
    val outputSampleRate: Int,
    val outputChannels: Int,
    val audioTrackBufferBytes: Int,
    val audioTrackState: String,
    val framesPerBurst: Int,
    val bufferCapacityFrames: Int,
    val queuedBufferSlots: Int,
    val underrunCount: Int,
    val xRunCount: Int,
)

// EQ classes (unchanged)
object AntiiQFilterType {
    const val PEAK = 0
    const val LOW_SHELF = 1
    const val HIGH_SHELF = 2
    const val LOW_PASS = 3
    const val HIGH_PASS = 4
    const val BAND_PASS = 5
    const val NOTCH = 6
    const val ALL_PASS = 7
}

data class AntiiQBand(
    val frequency: Float,
    val gainDb: Float,
    val Q: Float,
    val type: Int,
    val enabled: Boolean = true
)

class GaplessAudioPlayer(private val context: Context) {

    private var nativeHandle: Long = 0
    private val audioTrackLock = Any()
    private var audioTrack: AudioTrack? = null
    @Volatile
    private var audioTrackAcceptingWrites: Boolean = false
    private var audioTrackEncoding: Int = AudioFormat.ENCODING_PCM_FLOAT
    private var audioTrackShortBuffer = ShortArray(0)
    private var audioTrackBufferSizeBytes: Int = 0
    private var audioTrackSampleRate: Int = 0
    private var audioTrackChannelCount: Int = 0
    private var audioSessionId: Int = 0
    private var isOpened: Boolean = false
    private var currentTrackId: String? = null
    private var effectsEnabledState: Boolean = false
    private var gaplessEnabledState: Boolean = true
    private var crossfadeEnabledState: Boolean = false
    private var crossfadeDurationState: Int = 100
    private var audioCompatibilityModeState: Boolean = false
    private var usePcm16OutputState: Boolean = false
    private var tempoState: Float = 1.0f
    private var pitchSemitonesState: Float = 0.0f
    private var pitchRateState: Float = 1.0f
    private var restorePitchWithRate: Boolean = false
    private var volumeState: Float = 1.0f
    private var antiiQEqEnabledState: Boolean = false
    private var antiiQEqBandsState: List<AntiiQBand> = emptyList()
    private var equalizerBandGainsState: MutableList<Float> = MutableList(10) { 0f }
    private var equalizerBandWidthsState: MutableList<Float> = mutableListOf(
        80f, 100f, 150f, 200f, 300f, 800f, 1500f, 2500f, 2500f, 3000f
    )
    private var equalizerBandEnabledState: MutableList<Boolean> = MutableList(10) { true }

    private var onRoutingChanged: ((AudioDeviceData, AudioDeviceData?) -> Unit)? = null
    private var previousDevice: AudioDeviceData? = null

    private val routingListener = object : AudioRouting.OnRoutingChangedListener {
        override fun onRoutingChanged(router: AudioRouting?) {
            updateAudioRouting()
        }
    }

    interface PlaybackLifecycleCallback {
        fun onTrackEnded()
        fun onSeekCompleted(position: Long)
        fun onError(errorCode: Int, message: String)
        fun onTrackTransition(fromTrackId: String, toTrackId: String)
        fun onPrepareNextTrack(): String?
        fun onNextTrackFailed(trackId: String, error: String)

    }

    private var lifecycleCallback: PlaybackLifecycleCallback? = null

    companion object {
        private const val TAG = "GaplessAudioPlayer"

        init {
            System.loadLibrary("avutil")
            System.loadLibrary("swresample")
            System.loadLibrary("avcodec")
            System.loadLibrary("avformat")
            System.loadLibrary("SoundTouch")
            System.loadLibrary("native-audio-player")
        }
    }

    init {
        nativeHandle = nativeCreate()
    }

    fun setLifecycleCallback(callback: PlaybackLifecycleCallback?) {
        this.lifecycleCallback = callback
    }

    // Set callback for AudioTrack routing changes.
    fun setRoutingCallback(callback: (currentDevice: AudioDeviceData, previousDevice: AudioDeviceData?) -> Unit) {
        this.onRoutingChanged = callback
        if (isOpened) {
            updateAudioRouting()
        }
    }

    fun open(filePath: String, trackId: String): Int {
        Log.d(TAG, "Opening: $filePath (ID: $trackId)")

        if (isOpened) {
            Log.d(TAG, "Closing previous file before opening new one")
            close()
        }

        nativeSetAudioCompatibilityMode(nativeHandle, audioCompatibilityModeState)

        val result = nativeOpen(
            nativeHandle, filePath, trackId, audioTrackCallback, lifecycleCallbackProxy
        )

        if (result == 0) {
            val sampleRate = nativeGetSampleRate(nativeHandle)
            val channels = nativeGetChannels(nativeHandle)

            initializeAudioTrack(sampleRate, channels)

            currentTrackId = trackId
            isOpened = true
            restoreRetainedPlaybackState()
            updateAudioRouting()
            Log.d(TAG, "Opened successfully: $sampleRate Hz, $channels channels (AudioTrack)")
        } else {
            Log.e(TAG, "Failed to open file: $result")
        }

        return result
    }

    private fun close() {
        if (!isOpened) return

        Log.d(TAG, "Closing current file")
        audioTrackAcceptingWrites = false
        nativeStop(nativeHandle)
        nativeClose(nativeHandle)

        synchronized(audioTrackLock) {
            audioTrack?.removeOnRoutingChangedListener(routingListener)
            try {
                audioTrack?.stop()
            } catch (e: IllegalStateException) {
                Log.w(TAG, "AudioTrack was already stopped during close", e)
            }
            audioTrack?.release()
            audioTrack = null
        }

        audioSessionId = 0
        isOpened = false
        currentTrackId = null
        Log.d(TAG, "File closed")
    }

    fun start() {
        if (!isOpened) {
            Log.w(TAG, "Cannot start: no file opened")
            return
        }

        synchronized(audioTrackLock) {
            try {
                audioTrack?.play()
                audioTrackAcceptingWrites = true
            } catch (e: IllegalStateException) {
                audioTrackAcceptingWrites = false
                Log.w(TAG, "AudioTrack could not start", e)
                return
            }
        }

        nativeStart(nativeHandle)
        Log.d(TAG, "Playback started")
    }

    fun pause() {
        if (!isOpened) return
        nativePause(nativeHandle)

        synchronized(audioTrackLock) {
            audioTrackAcceptingWrites = false
            try {
                audioTrack?.pause()
            } catch (e: IllegalStateException) {
                Log.w(TAG, "AudioTrack was not pausable", e)
            }
        }

        Log.d(TAG, "Playback paused")
    }

    fun stop() {
        if (!isOpened) return
        nativeStop(nativeHandle)

        synchronized(audioTrackLock) {
            audioTrackAcceptingWrites = false
            try {
                audioTrack?.stop()
            } catch (e: IllegalStateException) {
                Log.w(TAG, "AudioTrack was not stoppable", e)
            }
        }

        Log.d(TAG, "Playback stopped")
    }

    // ==================== AUDIO DEVICE CONTROL ====================
    
    // Query current AudioTrack routing.
    private fun updateAudioRouting() {
        val device = getDeviceInfoFromAudioTrack()

        Log.d(TAG, "Audio routing updated: $previousDevice -> ${device.name} (${device.type})")
        onRoutingChanged?.invoke(device, previousDevice)
        previousDevice = device
    }

    /**
     * Get device info from AudioTrack routing
     */
    private fun getDeviceInfoFromAudioTrack(): AudioDeviceData {
        val routedDevice = audioTrack?.routedDevice

        return if (routedDevice != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            mapAudioDeviceInfo(routedDevice, routedDevice.id)
        } else {
            AudioDeviceData(
                name = "Speaker",
                type = AudioDeviceType.INBUILT_SPEAKER,
                id = -1
            )
        }
    }

    /**
     * Map AudioDeviceInfo to our AudioDeviceData format.
     */
    @RequiresApi(Build.VERSION_CODES.M)
    private fun mapAudioDeviceInfo(deviceInfo: AudioDeviceInfo, deviceId: Int): AudioDeviceData {
        return when (deviceInfo.type) {
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_USB_HEADSET,
            AudioDeviceInfo.TYPE_USB_ACCESSORY -> AudioDeviceData(
                name = deviceInfo.productName?.toString() ?: "USB DAC",
                type = AudioDeviceType.USB,
                id = deviceId
            )

            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> AudioDeviceData(
                name = deviceInfo.productName?.toString() ?: "Bluetooth",
                type = AudioDeviceType.BLUETOOTH,
                id = deviceId
            )

            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> AudioDeviceData(
                name = deviceInfo.productName?.toString() ?: "Wired Headphones",
                type = AudioDeviceType.WIRED,
                id = deviceId
            )

            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> AudioDeviceData(
                name = "Speaker",
                type = AudioDeviceType.INBUILT_SPEAKER,
                id = deviceId
            )

            AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> AudioDeviceData(
                name = "Earpiece",
                type = AudioDeviceType.INBUILT_SPEAKER,
                id = deviceId
            )

            else -> AudioDeviceData(
                name = deviceInfo.productName?.toString() ?: "Unknown Device",
                type = AudioDeviceType.UNKNOWN,
                id = deviceId
            )
        }
    }

    // ==================== STANDARD PLAYBACK API (unchanged) ====================

    fun isDecoderInitialized(): Boolean = nativeIsDecoderInitialized(nativeHandle)
    fun seekTo(positionMs: Long) = nativeSeek(nativeHandle, positionMs)
    fun getDuration(): Long = nativeGetDuration(nativeHandle)
    fun getCurrentPosition(): Long = nativeGetPosition(nativeHandle)
    fun isPlaying(): Boolean = nativeIsPlaying(nativeHandle)
    fun getAudioSessionId(): Int = audioSessionId
    fun getCurrentTrackId(): String? = currentTrackId
    fun getOutputDiagnostics(): OutputDiagnostics = OutputDiagnostics(
        compatibilityMode = audioCompatibilityModeState,
        usePcm16Output = usePcm16OutputState,
        outputPath = if (audioCompatibilityModeState) "AudioTrack compatibility" else "AudioTrack",
        processingFormat = "32-bit float native",
        outputEncoding = when (audioTrackEncoding) {
            AudioFormat.ENCODING_PCM_16BIT -> "PCM 16-bit"
            AudioFormat.ENCODING_PCM_FLOAT -> "PCM float"
            else -> "Encoding $audioTrackEncoding"
        },
        sessionId = audioSessionId,
        currentDeviceId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) audioTrack?.routedDevice?.id ?: -1 else -1,
        outputSampleRate = audioTrackSampleRate,
        outputChannels = audioTrackChannelCount,
        audioTrackBufferBytes = audioTrackBufferSizeBytes,
        audioTrackState = audioTrackStateLabel(audioTrack),
        framesPerBurst = 0,
        bufferCapacityFrames = 0,
        queuedBufferSlots = 0,
        underrunCount = 0,
        xRunCount = 0,
    )

    fun setGaplessEnabled(enabled: Boolean) {
        gaplessEnabledState = enabled
        if (nativeHandle != 0L) {
            nativeSetGaplessEnabled(nativeHandle, enabled)
        }
    }
    fun cancelGaplessPreparation() = nativeCancelGaplessPreparation(nativeHandle)
    fun isGaplessEnabled(): Boolean = nativeIsGaplessEnabled(nativeHandle)

    // Crossfade control
    fun setCrossfadeEnabled(enabled: Boolean) {
        crossfadeEnabledState = enabled
        if (nativeHandle != 0L) {
            nativeSetCrossfadeEnabled(nativeHandle, enabled)
        }
    }
    fun setCrossfadeDuration(durationMs: Int) {
        crossfadeDurationState = durationMs.coerceIn(0, 5000)
        if (nativeHandle != 0L) {
            nativeSetCrossfadeDuration(nativeHandle, crossfadeDurationState)
        }
    }
    fun getCrossfadeDuration(): Int = nativeGetCrossfadeDuration(nativeHandle)
    fun isCrossfadeEnabled(): Boolean = nativeIsCrossfadeEnabled(nativeHandle)

    fun setAudioCompatibilityMode(enabled: Boolean) {
        audioCompatibilityModeState = enabled
        if (nativeHandle != 0L) {
            nativeSetAudioCompatibilityMode(nativeHandle, enabled)
        }
    }

    fun setUsePcm16Output(enabled: Boolean) {
        usePcm16OutputState = enabled
    }
    fun isPreparingGapless(): Boolean = if (nativeHandle != 0L) nativeIsPreparingGapless(nativeHandle) else false

    // Native EQ controls
    fun setEffectsEnabled(enabled: Boolean) {
        effectsEnabledState = enabled
        if (nativeHandle != 0L) {
            nativeSetEffectsEnabled(nativeHandle, enabled)
        }
    }
    fun setEqualizerBand(band: Int, gainDb: Float) {
        if (band !in equalizerBandGainsState.indices) return
        equalizerBandGainsState[band] = gainDb
        if (nativeHandle != 0L) {
            nativeSetEqualizerBand(nativeHandle, band, gainDb)
        }
    }
    // Tempo/Pitch
    fun setTempo(rate: Float) {
        tempoState = rate
        if (nativeHandle != 0L) {
            nativeSetTempo(nativeHandle, rate)
        }
    }
    fun setPitchSemitones(semitones: Float) {
        pitchSemitonesState = semitones
        restorePitchWithRate = false
        if (nativeHandle != 0L) {
            nativeSetPitchSemitones(nativeHandle, semitones)
        }
    }
    fun setPitchRate(rate: Float) {
        pitchRateState = rate
        restorePitchWithRate = true
        if (nativeHandle != 0L) {
            nativeSetPitchRate(nativeHandle, rate)
        }
    }
    fun getTempo(): Float = if (nativeHandle != 0L) nativeGetTempo(nativeHandle) else 1.0f
    fun getPitchSemitones(): Float = if (nativeHandle != 0L) nativeGetPitchSemitones(nativeHandle) else 0f

    // Volume
    fun setVolume(volume: Float) {
        volumeState = volume
        if (nativeHandle != 0L) {
            nativeSetVolume(nativeHandle, volume)
        }
    }
    fun getVolume(): Float = nativeGetVolume(nativeHandle)

    // Advanced EQ controls
    fun setEqualizerBandWidth(band: Int, widthHz: Float) {
        if (band !in equalizerBandWidthsState.indices) return
        equalizerBandWidthsState[band] = widthHz
        if (nativeHandle != 0L) {
            nativeSetEqualizerBandWidth(nativeHandle, band, widthHz)
        }
    }

    fun setEqualizerBandEnabled(band: Int, enabled: Boolean) {
        if (band !in equalizerBandEnabledState.indices) return
        equalizerBandEnabledState[band] = enabled
        if (nativeHandle != 0L) {
            nativeSetEqualizerBandEnabled(nativeHandle, band, enabled)
        }
    }

    fun getEqualizerBandCount(): Int = if (nativeHandle != 0L) nativeGetEqualizerBandCount(nativeHandle) else 0

    // AntiiQ EQ
    fun setAntiiQEQEnabled(enabled: Boolean) {
        antiiQEqEnabledState = enabled
        if (nativeHandle != 0L) {
            nativeSetAntiiQEQEnabled(nativeHandle, enabled)
        }
    }
    fun isAntiiQEQEnabled(): Boolean = nativeIsAntiiQEQEnabled(nativeHandle)
    fun setAntiiQEQBands(bands: List<AntiiQBand>) {
        antiiQEqBandsState = bands.toList()
        if (nativeHandle != 0L) {
            nativeSetAntiiQEQBands(nativeHandle, antiiQEqBandsState.toTypedArray())
        }
    }
    fun resetAntiiQEQ() {
        antiiQEqBandsState = emptyList()
        if (nativeHandle != 0L) {
            nativeResetAntiiQEQ(nativeHandle)
        }
    }

    // EQ Presets
    fun applyEqualizerPreset(preset: EqualizerPreset) {
        preset.gains.forEachIndexed { index, gain ->
            setEqualizerBand(index, gain)
        }

        preset.widths?.forEachIndexed { index, width ->
            setEqualizerBandWidth(index, width)
        }
    }

    enum class EqualizerPreset(
        val gains: List<Float>,
        val widths: List<Float>? = null
    ) {
        FLAT(gains = List(10) { 0f }),
        ROCK(gains = listOf(5f, 3f, -1f, -2f, 1f, 2f, 4f, 5f, 6f, 6f)),
        POP(gains = listOf(-1f, 2f, 4f, 5f, 3f, 0f, -1f, -1f, 2f, 3f)),
        JAZZ(gains = listOf(3f, 2f, 1f, 2f, -1f, -1f, 0f, 2f, 3f, 4f)),
        CLASSICAL(gains = listOf(4f, 3f, 2f, 0f, -1f, -1f, 0f, 2f, 3f, 4f)),
        CLEAN_BASS(gains = listOf(3f, 2f, 1f, 2f, -1f, -2f, 0f, 0f, 0f, -1f)),
        FULL_BASS(gains = listOf(8f, 6f, 4f, 2f, 0f, 0f, 0f, 0f, 0f, 0f)),
        TREBLE_BOOST(gains = listOf(0f, 0f, 0f, 0f, 0f, 2f, 4f, 6f, 8f, 8f)),
        VOCAL(gains = listOf(-2f, -3f, -1f, 2f, 4f, 4f, 3f, 1f, 0f, -1f)),
        ELECTRONIC(gains = listOf(4f, 3f, 1f, 0f, -2f, 2f, 1f, 2f, 4f, 5f)),
        ACOUSTIC(gains = listOf(3f, 2f, 1f, 1f, 2f, 2f, 3f, 3f, 3f, 2f)),
        CUSTOM(gains = List(10) { 0f })
    }

    // Reset all effects
    fun resetEffects() {
        resetAntiiQEQ()
        setAntiiQEQEnabled(false)
        setTempo(1.0f)
        setPitchSemitones(0f)
        setVolume(1.0f)
    }

    fun release() {
        close()
        nativeRelease(nativeHandle)
        nativeHandle = 0
        lifecycleCallback = null
        Log.d(TAG, "Released")
    }

    // ==================== PRIVATE METHODS ====================

    private fun initializeAudioTrack(sampleRate: Int, channels: Int) {
        synchronized(audioTrackLock) {
            audioTrackAcceptingWrites = false
            audioTrack?.release()
            audioTrack = null
        }

        audioTrackEncoding =
            if (usePcm16OutputState) AudioFormat.ENCODING_PCM_16BIT
            else AudioFormat.ENCODING_PCM_FLOAT
        val channelConfig = if (channels == 2) AudioFormat.CHANNEL_OUT_STEREO else AudioFormat.CHANNEL_OUT_MONO
        val minBufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioTrackEncoding)

        if (minBufferSize == AudioTrack.ERROR_BAD_VALUE || minBufferSize == AudioTrack.ERROR) {
            Log.e(TAG, "Failed to get buffer size for encoding=$audioTrackEncoding")
            return
        }

        val bufferSize = minBufferSize * if (audioCompatibilityModeState) 4 else 2
        audioTrackBufferSizeBytes = bufferSize
        audioTrackSampleRate = sampleRate
        audioTrackChannelCount = channels

        val newAudioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setChannelMask(channelConfig)
                    .setEncoding(audioTrackEncoding)
                    .build()
            )
            .setBufferSizeInBytes(bufferSize)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()

        synchronized(audioTrackLock) {
            audioTrack = newAudioTrack
        }

        audioSessionId = newAudioTrack.audioSessionId

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            newAudioTrack.addOnRoutingChangedListener(
                routingListener,
                android.os.Handler(android.os.Looper.getMainLooper())
            )
        }

        Log.d(TAG, "AudioTrack initialized: buffer=$bufferSize bytes, session=$audioSessionId, encoding=$audioTrackEncoding")
    }

    private fun audioTrackStateLabel(track: AudioTrack?): String {
        if (track == null) return "Not initialized"
        val playState = when (track.playState) {
            AudioTrack.PLAYSTATE_PLAYING -> "playing"
            AudioTrack.PLAYSTATE_PAUSED -> "paused"
            AudioTrack.PLAYSTATE_STOPPED -> "stopped"
            else -> "unknown"
        }
        val initState = when (track.state) {
            AudioTrack.STATE_INITIALIZED -> "initialized"
            AudioTrack.STATE_UNINITIALIZED -> "uninitialized"
            AudioTrack.STATE_NO_STATIC_DATA -> "no static data"
            else -> "state ${track.state}"
        }
        return "$initState / $playState"
    }

    private val audioTrackCallback = object : Any() {
        @Suppress("unused")
        fun onAudioData(data: FloatArray, size: Int, sampleRate: Int, channels: Int) {
            synchronized(audioTrackLock) {
                val track = audioTrack ?: return
                if (!audioTrackAcceptingWrites || track.state != AudioTrack.STATE_INITIALIZED) return

                try {
                    if (audioTrackEncoding == AudioFormat.ENCODING_PCM_16BIT) {
                        if (audioTrackShortBuffer.size < size) audioTrackShortBuffer = ShortArray(size)
                        for (i in 0 until size) {
                            val sample = data[i].coerceIn(-1.0f, 1.0f)
                            audioTrackShortBuffer[i] = (sample * 32767.0f).toInt().toShort()
                        }
                        val written = track.write(audioTrackShortBuffer, 0, size, AudioTrack.WRITE_BLOCKING)
                        if (written < 0) Log.w(TAG, "AudioTrack short write failed: $written")
                    } else {
                        val written = track.write(data, 0, size, AudioTrack.WRITE_BLOCKING)
                        if (written < 0) Log.w(TAG, "AudioTrack float write failed: $written")
                    }
                } catch (e: IllegalStateException) {
                    audioTrackAcceptingWrites = false
                    Log.w(TAG, "AudioTrack rejected write; stopping compatibility output for this stream", e)
                }
            }
        }
    }

    private fun restoreRetainedPlaybackState() {
        if (nativeHandle == 0L) return

        nativeSetEffectsEnabled(nativeHandle, effectsEnabledState)
        nativeSetGaplessEnabled(nativeHandle, gaplessEnabledState)
        nativeSetCrossfadeEnabled(nativeHandle, crossfadeEnabledState)
        nativeSetCrossfadeDuration(nativeHandle, crossfadeDurationState)
        nativeSetAudioCompatibilityMode(nativeHandle, audioCompatibilityModeState)
        equalizerBandGainsState.forEachIndexed { index, gain ->
            nativeSetEqualizerBand(nativeHandle, index, gain)
        }
        equalizerBandWidthsState.forEachIndexed { index, width ->
            nativeSetEqualizerBandWidth(nativeHandle, index, width)
        }
        equalizerBandEnabledState.forEachIndexed { index, enabled ->
            nativeSetEqualizerBandEnabled(nativeHandle, index, enabled)
        }
        nativeSetAntiiQEQEnabled(nativeHandle, antiiQEqEnabledState)
        if (antiiQEqBandsState.isNotEmpty()) {
            nativeSetAntiiQEQBands(nativeHandle, antiiQEqBandsState.toTypedArray())
        }
        nativeSetTempo(nativeHandle, tempoState)
        if (restorePitchWithRate) {
            nativeSetPitchRate(nativeHandle, pitchRateState)
        } else {
            nativeSetPitchSemitones(nativeHandle, pitchSemitonesState)
        }
    }

    private val lifecycleCallbackProxy = object : Any() {
        @Suppress("unused")
        fun onTrackEnded() {
            Log.d(TAG, "Native callback: Track ended")
            lifecycleCallback?.onTrackEnded()
        }

        @Suppress("unused")
        fun onSeekCompleted(position: Long) {
            Log.d(TAG, "Native callback: Seek completed at $position ms")
            lifecycleCallback?.onSeekCompleted(position)
        }

        @Suppress("unused")
        fun onError(errorCode: Int, message: String) {
            Log.e(TAG, "Native callback: Error $errorCode - $message")
            lifecycleCallback?.onError(errorCode, message)
        }

        @Suppress("unused")
        fun onTrackTransition(fromTrackId: String, toTrackId: String) {
            Log.d(TAG, "Native callback: Track transition $fromTrackId -> $toTrackId")
            currentTrackId = toTrackId
            lifecycleCallback?.onTrackTransition(fromTrackId, toTrackId)
        }

        @Suppress("unused")
        fun onPrepareNextTrack(): String? {
            Log.d(TAG, "Native callback: Requesting next track")
            return lifecycleCallback?.onPrepareNextTrack()
        }

        @Suppress("unused")
        fun onNextTrackFailed(trackId: String, error: String) {
            Log.e(TAG, "Native callback: Next track failed - $trackId: $error")
            lifecycleCallback?.onNextTrackFailed(trackId, error)
        }

    }

    // ==================== NATIVE METHODS ====================

    // Basic playback
    private external fun nativeCreate(): Long
    private external fun nativeOpen(handle: Long, filePath: String, trackId: String,
                                    audioCallback: Any, lifecycleCallback: Any?): Int
    private external fun nativeClose(handle: Long)
    private external fun nativeStart(handle: Long)
    private external fun nativePause(handle: Long)
    private external fun nativeStop(handle: Long)
    private external fun nativeIsDecoderInitialized(handle: Long): Boolean
    private external fun nativeSeek(handle: Long, positionMs: Long)
    private external fun nativeGetDuration(handle: Long): Long
    private external fun nativeGetPosition(handle: Long): Long
    private external fun nativeIsPlaying(handle: Long): Boolean
    private external fun nativeGetSampleRate(handle: Long): Int
    private external fun nativeGetChannels(handle: Long): Int
    private external fun nativeRelease(handle: Long)

    // Audio output control
    private external fun nativeSetAudioCompatibilityMode(handle: Long, enabled: Boolean)

    // Gapless & crossfade
    private external fun nativeIsGaplessEnabled(handle: Long): Boolean
    private external fun nativeIsCrossfadeEnabled(handle: Long): Boolean
    private external fun nativeSetGaplessEnabled(handle: Long, enabled: Boolean)
    private external fun nativeCancelGaplessPreparation(handle: Long)
    private external fun nativeSetCrossfadeEnabled(handle: Long, enabled: Boolean)
    private external fun nativeSetCrossfadeDuration(handle: Long, durationMs: Int)
    private external fun nativeGetCrossfadeDuration(handle: Long): Int

    // Audio effects
    private external fun nativeSetEffectsEnabled(handle: Long, enabled: Boolean)
    private external fun nativeSetEqualizerBand(handle: Long, band: Int, gainDb: Float)
    private external fun nativeSetEqualizerBandWidth(handle: Long, band: Int, widthHz: Float)
    private external fun nativeSetEqualizerBandEnabled(handle: Long, band: Int, enabled: Boolean)
    private external fun nativeGetEqualizerBandCount(handle: Long): Int

    // Tempo & Pitch
    private external fun nativeSetTempo(handle: Long, rate: Float)
    private external fun nativeSetPitchSemitones(handle: Long, semitones: Float)
    private external fun nativeSetPitchRate(handle: Long, rate: Float)
    private external fun nativeGetTempo(handle: Long): Float
    private external fun nativeGetPitchSemitones(handle: Long): Float

    // Volume
    private external fun nativeSetVolume(handle: Long, volume: Float)
    private external fun nativeGetVolume(handle: Long): Float

    // AntiiQ EQ
    private external fun nativeSetAntiiQEQEnabled(handle: Long, enabled: Boolean)
    private external fun nativeIsAntiiQEQEnabled(handle: Long): Boolean
    private external fun nativeSetAntiiQEQBands(handle: Long, bands: Array<AntiiQBand>)
    private external fun nativeResetAntiiQEQ(handle: Long)

    private external fun nativeIsPreparingGapless(handle: Long): Boolean
}
