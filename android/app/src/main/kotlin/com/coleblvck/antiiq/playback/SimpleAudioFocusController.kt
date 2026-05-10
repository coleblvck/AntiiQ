package com.coleblvck.antiiq.playback

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log

class SimpleAudioFocusController(
    context: Context,
    private val onPause: () -> Unit,
    private val onResume: () -> Unit,
    private val onDuck: (Boolean) -> Unit,
) {
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val handler = Handler(Looper.getMainLooper())
    private var focusRequest: AudioFocusRequest? = null
    private var hasFocus = false
    private var playbackActive = false
    private var wasPlayingBeforeFocusLoss = false
    private var wasPausedByFocusLoss = false
    private var isDucked = false
    private var lastFocusLossAt = 0L

    fun requestAudioFocus(): Boolean {
        if (hasFocus) return true

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()

            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attributes)
                .setAcceptsDelayedFocusGain(true)
                .setWillPauseWhenDucked(false)
                .setOnAudioFocusChangeListener(listener, handler)
                .build()

            focusRequest = request
            when (audioManager.requestAudioFocus(request)) {
                AudioManager.AUDIOFOCUS_REQUEST_GRANTED -> {
                    hasFocus = true
                    true
                }
                AudioManager.AUDIOFOCUS_REQUEST_DELAYED -> true
                else -> false
            }
        } else {
            @Suppress("DEPRECATION")
            val result = audioManager.requestAudioFocus(
                listener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
            hasFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            hasFocus
        }
    }

    fun abandonAudioFocus() {
        if (!hasFocus) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(listener)
        }

        focusRequest = null
        hasFocus = false
        wasPlayingBeforeFocusLoss = false
        wasPausedByFocusLoss = false
        if (isDucked) {
            onDuck(false)
            isDucked = false
        }
    }

    fun setPlaybackActive(active: Boolean) {
        playbackActive = active
    }

    private val listener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        Log.d(TAG, "Audio focus changed: $focusChange")
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                hasFocus = true
                if (isDucked) {
                    onDuck(false)
                    isDucked = false
                }
                if (wasPausedByFocusLoss && wasPlayingBeforeFocusLoss && !playbackActive) {
                    onResume()
                    playbackActive = true
                }
                wasPlayingBeforeFocusLoss = false
                wasPausedByFocusLoss = false
            }

            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                hasFocus = false
                val now = System.currentTimeMillis()
                if (now - lastFocusLossAt < FOCUS_LOSS_DEBOUNCE_MS) return@OnAudioFocusChangeListener
                lastFocusLossAt = now

                if (isDucked) {
                    onDuck(false)
                    isDucked = false
                }

                wasPlayingBeforeFocusLoss = playbackActive
                if (playbackActive) {
                    onPause()
                    playbackActive = false
                    wasPausedByFocusLoss = true
                }
            }

            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                if (!isDucked) {
                    onDuck(true)
                    isDucked = true
                }
            }
        }
    }

    companion object {
        private const val TAG = "SimpleAudioFocus"
        private const val FOCUS_LOSS_DEBOUNCE_MS = 250L
    }
}
