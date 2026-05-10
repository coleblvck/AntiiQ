#ifndef GAPLESS_AUDIO_PLAYER_H
#define GAPLESS_AUDIO_PLAYER_H

#include <jni.h>
#include <android/log.h>
#include <pthread.h>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <string>
#include <vector>
#include <memory>

#include "AudioPipeline.h"
#include "AntiiQEQ.h"
#include "PlayerEvents.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/opt.h>
}

#undef LOG_TAG
#define LOG_TAG "GaplessAudioPlayer"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

class GaplessAudioPlayer {
private:
    static constexpr int OUTPUT_BUFFER_SLOT_COUNT = 12;
    static constexpr int OUTPUT_BUFFER_CAPACITY_FRAMES = 4096;
    static constexpr int OUTPUT_RING_CAPACITY_FRAMES =
            OUTPUT_BUFFER_SLOT_COUNT * OUTPUT_BUFFER_CAPACITY_FRAMES;

    mutable std::mutex bufferMutex;
    std::condition_variable bufferConsumedCondition;
    std::vector<float> outputRing_;
    std::atomic<int> outputRingReadFrame_{0};
    std::atomic<int> outputRingWriteFrame_{0};
    std::atomic<int> outputRingQueuedFrames_{0};

    void publishToOutput(const std::vector<float>& data, int numFrames);
    void resetDoubleBufferStateLocked();
    int getDesiredPrefillBuffers() const;
    void syncTransitionPipelineLocked();

    std::atomic<int> cachedFramesPerBurst{192};
    std::atomic<uint32_t> bufferEpoch_{1};
    std::atomic<int> callbackUnderrunCount_{0};
    std::vector<float> decodeBuffer_;
    std::vector<float> cfCurrentBuffer_;
    std::vector<float> cfNextBuffer_;
    std::vector<float> cfFinalizeBuffer_;
    std::vector<float> cfMixedBuffer_;
    AVPacket* cfNextPacket_ = nullptr;
    AVFrame* cfNextFrame_ = nullptr;
    AVFrame* cfNextFiltered_ = nullptr;
    std::atomic<bool> decoderValid_{false};

private:
    struct DecoderContext {
        AVFormatContext* formatContext = nullptr;
        AVCodecContext* codecContext = nullptr;
        int audioStreamIndex = -1;
        int64_t durationMs = 0;
        int64_t samplesDecoded = 0;
        bool isActive = false;
        bool isInitialized = false;
        std::string filePath;
        int sampleRate = 0;
        int channels = 0;
        AVSampleFormat sampleFormat = AV_SAMPLE_FMT_NONE;

        DecoderContext() = default;
        ~DecoderContext() = default;
        DecoderContext(const DecoderContext&) = delete;
        DecoderContext& operator=(const DecoderContext&) = delete;
        DecoderContext(DecoderContext&& other) noexcept;
        DecoderContext& operator=(DecoderContext&& other) noexcept;
        void reset();
    };

    enum PlaybackPhase {
        IDLE,
        NORMAL_PLAYBACK,
        PREPARING_NEXT,
        TRANSITIONING
    };

    PlayerEventQueue eventQueue;
    pthread_t eventThread = 0;

    static void* eventThreadFunc(void* arg);
    void processEvents();
    void postEvent(PlayerEvent event);

    static constexpr int OUTPUT_SAMPLE_RATE = 44100;
    static constexpr int COMPATIBILITY_OUTPUT_SAMPLE_RATE = 48000;
    static constexpr int OUTPUT_CHANNELS = 2;
    static constexpr AVSampleFormat OUTPUT_FORMAT = AV_SAMPLE_FMT_FLT;

    DecoderContext currentDecoder;
    DecoderContext nextDecoder;
    AudioPipeline audioPipeline;
    AudioPipeline transitionPipeline;

    std::atomic<PlaybackPhase> playbackPhase{IDLE};
    std::atomic<bool> isPlaying{false};
    std::atomic<bool> isPrepared{false};
    std::atomic<bool> stopRequested{false};
    std::atomic<bool> seekRequested{false};
    std::atomic<int64_t> seekTargetMs{0};
    std::atomic<int64_t> currentPositionMs{0};
    std::atomic<bool> playbackCompleted_{false};
    std::atomic<bool> decodeThreadRunning_{false};

    std::atomic<bool> gaplessEnabled{true};
    std::atomic<bool> crossfadeEnabled{false};
    std::atomic<bool> audioCompatibilityMode{false};
    std::atomic<int> crossfadeDurationMs{100};

    std::atomic<int> crossfadeSamplesRemaining{0};
    int totalCrossfadeSamples = 0;

    std::atomic<float> currentVolume{1.0f};

    pthread_t decodeThread = 0;
    pthread_t prepareThread = 0;

    JavaVM* javaVM = nullptr;
    jobject audioTrackCallback = nullptr;
    jobject playbackCallback = nullptr;
    jmethodID writeAudioMethod = nullptr;
    jmethodID onTrackEndedMethod = nullptr;
    jmethodID onSeekCompletedMethod = nullptr;
    jmethodID onErrorMethod = nullptr;
    jmethodID onTrackTransitionMethod = nullptr;
    jmethodID onPrepareNextTrackMethod = nullptr;
    jmethodID onNextTrackFailedMethod = nullptr;

    std::mutex decoderMutex;
    std::mutex pauseMutex;
    std::condition_variable pauseCondition;
    std::mutex prepareMutex;
    std::condition_variable prepareCondition;

    std::string currentTrackId;
    std::string nextTrackId;

public:
    GaplessAudioPlayer();
    ~GaplessAudioPlayer();

    bool isDecoderInitialized() const { return currentDecoder.isInitialized; }

    int open(const char* filePath, const char* trackId, JavaVM* vm,
             jobject audioCallback, jobject lifecycleCallback);
    void close();
    void start();
    void pause();
    void stop();
    void seekTo(int64_t positionMs);

    int64_t getDuration() const;
    int64_t getCurrentPosition() const;
    bool isPlayingState() const;
    int getSampleRate() const { return audioPipeline.getOutputSampleRate(); }
    int getChannels() const { return OUTPUT_CHANNELS; }
    std::string getCurrentTrackId() const { return currentTrackId; }

    void setGaplessEnabled(bool enabled) { gaplessEnabled = enabled; }
    bool isGaplessEnabled() const { return gaplessEnabled.load(); }
    void cancelGaplessPreparation();

    void setCrossfadeEnabled(bool enabled) { crossfadeEnabled = enabled; }
    bool isCrossfadeEnabled() const { return crossfadeEnabled.load(); }
    void setCrossfadeDuration(int durationMs);
    int getCrossfadeDuration() const { return crossfadeDurationMs.load(); }
    void setAudioCompatibilityMode(bool enabled) { audioCompatibilityMode.store(enabled, std::memory_order_release); }
    bool isAudioCompatibilityMode() const { return audioCompatibilityMode.load(std::memory_order_acquire); }

    void setEffectsEnabled(bool enabled) { audioPipeline.getNativeEffects().setEnabled(enabled); }
    void setEqualizerBand(int band, float gainDb) { audioPipeline.getNativeEffects().setEqualizerBand(band, gainDb); }
    void setEqualizerBandWidth(int band, float widthHz) { audioPipeline.getNativeEffects().setEqualizerBandWidth(band, widthHz); }
    void setEqualizerBandEnabled(int band, bool enabled) { audioPipeline.getNativeEffects().setEqualizerBandEnabled(band, enabled); }
    int getEqualizerBandCount() const { return audioPipeline.getNativeEffects().getEqualizerBandCount(); }

    void setTempo(float rate) { audioPipeline.setTempo(rate); }
    void setPitchSemitones(float semitones) { audioPipeline.setPitch(semitones); }
    void setPitchRate(float rate) { audioPipeline.setPitchRate(rate); }
    float getTempo() const { return audioPipeline.getTempo(); }
    float getPitchSemitones() const { return audioPipeline.getPitch(); }
    float getPitchRate() const { return audioPipeline.getPitchRate(); }

    void setVolume(float volume);
    float getVolume() const { return currentVolume.load(); }

    bool isTransitioningOrPreparing() const {
        const auto phase = playbackPhase.load();
        return phase == PREPARING_NEXT || phase == TRANSITIONING;
    }

    int getOutputBufferCapacityFrames() const { return OUTPUT_BUFFER_CAPACITY_FRAMES; }
    int getOutputBufferQueuedCount() const;
    int getOutputUnderrunCount() const { return callbackUnderrunCount_.load(std::memory_order_acquire); }
    int getFramesPerBurst() const { return cachedFramesPerBurst.load(std::memory_order_acquire); }
    int getConfiguredOutputSampleRate() const { return audioPipeline.getOutputSampleRate(); }

    void setAntiiQEQEnabled(bool enabled) { audioPipeline.getNativeEffects().setAntiiQEQEnabled(enabled); }
    bool isAntiiQEQEnabled() const { return audioPipeline.getNativeEffects().isAntiiQEQEnabled(); }
    void setAntiiQEQBands(const std::vector<AntiiQEQ::Band>& bands) { audioPipeline.getNativeEffects().setAntiiQEQBands(bands); }
    void resetAntiiQEQ() { audioPipeline.getNativeEffects().resetAntiiQEQ(); }
    int getAntiiQEQBandCount() const { return audioPipeline.getNativeEffects().getAntiiQEQBandCount(); }

private:
    int initializeDecoder(DecoderContext* decoder, const char* filePath);
    void cleanupDecoder(DecoderContext* decoder);

    static void* decodeThreadFunc(void* arg);
    static void* prepareThreadFunc(void* arg);
    void decodeLoop();
    void prepareNextTrack();

    void processNormalPlayback(AVPacket* packet, AVFrame* frame, AVFrame* filteredFrame);
    void processGaplessTransition();
    void processCrossfadeTransition(AVPacket* packet, AVFrame* frame, AVFrame* filteredFrame);
    int decodeFrame(AudioPipeline& pipeline, DecoderContext* decoder, AVFrame* frame, AVFrame* filteredFrame,
                    std::vector<float>& outBuffer, int* outSamples);
    int decodeNextFrameForCrossfade(std::vector<float>& outBuffer);
    void appendFrameBlock(std::vector<float>& target, const std::vector<float>& source, int frames);
    void consumeFrameBlock(std::vector<float>& target, int frames);
    void flushPendingTransitionAudio();
    void finishCrossfade();
    bool drainDecoderToOutput(DecoderContext* decoder, AVFrame* frame, AVFrame* filteredFrame,
                              std::vector<float>& outBuffer);
    void primePostTransitionOutput(AVPacket* packet, AVFrame* frame, AVFrame* filteredFrame);
    void mixCrossfadeInto(const std::vector<float>& currentBuf, int currentSamples,
                          const std::vector<float>& nextBuf, int nextSamples,
                          std::vector<float>& outMixed, int* outMixedSamples);

    void handleEndOfFile(JNIEnv* env, AVPacket* packet, AVFrame* frame,
                         AVFrame* filteredFrame, bool& reachedEnd);
    void finalizeCrossfade(AVPacket* packet, AVFrame* frame, AVFrame* filteredFrame);
    void applyFadeIn(std::vector<float>& buffer, int samples);

    void performSeek(JNIEnv* env);
    void updatePosition(AVPacket* packet, DecoderContext* decoder, int decodedFrames);
    void applyVolume(uint8_t* buffer, int samples, float volume);

    bool shouldPrepareNext();
    bool shouldStartTransition();
    void swapDecoders();

    void notifyTrackEnded(JNIEnv* env);
    void notifySeekCompleted(JNIEnv* env, int64_t position);
    void notifyError(JNIEnv* env, int errorCode, const char* message);
    void notifyTrackTransition(JNIEnv* env, const char* fromTrackId, const char* toTrackId);
    std::string requestNextTrack(JNIEnv* env);
    void notifyNextTrackFailed(JNIEnv* env, const char* trackId, const char* error);

    void cleanup();
    JNIEnv* attachThread();
    void updateCachedBurstSize();
    void resetPlaybackToStart();
};

#endif // GAPLESS_AUDIO_PLAYER_H
