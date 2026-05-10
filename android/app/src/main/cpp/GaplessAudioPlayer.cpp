#include "GaplessAudioPlayer.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <thread>
#include <sys/resource.h>
#include <errno.h>

#include "AudioDuration.h"

namespace {
    static void logThreadPriority(const char* threadName) {
        int policy = 0;
        sched_param param{};
        pthread_getschedparam(pthread_self(), &policy, &param);
        const int niceValue = getpriority(PRIO_PROCESS, 0);
        LOGI("%s policy=%d priority=%d nice=%d", threadName, policy, param.sched_priority, niceValue);
    }
}

GaplessAudioPlayer::DecoderContext::DecoderContext(DecoderContext&& other) noexcept {
    *this = std::move(other);
}

GaplessAudioPlayer::DecoderContext& GaplessAudioPlayer::DecoderContext::operator=(DecoderContext&& other) noexcept {
    if (this != &other) {
        reset();
        formatContext = other.formatContext;
        codecContext = other.codecContext;
        audioStreamIndex = other.audioStreamIndex;
        durationMs = other.durationMs;
        samplesDecoded = other.samplesDecoded;
        isActive = other.isActive;
        isInitialized = other.isInitialized;
        filePath = std::move(other.filePath);
        sampleRate = other.sampleRate;
        channels = other.channels;
        sampleFormat = other.sampleFormat;

        other.formatContext = nullptr;
        other.codecContext = nullptr;
        other.audioStreamIndex = -1;
        other.durationMs = 0;
        other.samplesDecoded = 0;
        other.isActive = false;
        other.isInitialized = false;
        other.sampleRate = 0;
        other.channels = 0;
        other.sampleFormat = AV_SAMPLE_FMT_NONE;
    }
    return *this;
}

void GaplessAudioPlayer::DecoderContext::reset() {
    if (codecContext) avcodec_free_context(&codecContext);
    if (formatContext) avformat_close_input(&formatContext);
    formatContext = nullptr;
    codecContext = nullptr;
    audioStreamIndex = -1;
    durationMs = 0;
    samplesDecoded = 0;
    isActive = false;
    isInitialized = false;
    filePath.clear();
    sampleRate = 0;
    channels = 0;
    sampleFormat = AV_SAMPLE_FMT_NONE;
}

GaplessAudioPlayer::GaplessAudioPlayer() {
    cfNextPacket_ = av_packet_alloc();
    cfNextFrame_ = av_frame_alloc();
    cfNextFiltered_ = av_frame_alloc();

    outputRing_.resize(OUTPUT_RING_CAPACITY_FRAMES * OUTPUT_CHANNELS, 0.0f);
}

GaplessAudioPlayer::~GaplessAudioPlayer() {
    if (eventThread != 0) {
        eventQueue.shutdown();
        pthread_join(eventThread, nullptr);
        eventThread = 0;
    }
    cleanup();
    if (cfNextPacket_) av_packet_free(&cfNextPacket_);
    if (cfNextFrame_) av_frame_free(&cfNextFrame_);
    if (cfNextFiltered_) av_frame_free(&cfNextFiltered_);
}

void* GaplessAudioPlayer::eventThreadFunc(void* arg) {
    auto* player = static_cast<GaplessAudioPlayer*>(arg);
    player->processEvents();
    return nullptr;
}

void GaplessAudioPlayer::processEvents() {
    JNIEnv* env = attachThread();
    if (!env) return;
    while (!eventQueue.isShutdown()) {
        PlayerEvent event(PlayerEventType::TRACK_ENDED);
        if (!eventQueue.pop(event, 1000)) continue;
        switch (event.type) {
            case PlayerEventType::TRACK_ENDED:
                if (playbackCallback && onTrackEndedMethod) env->CallVoidMethod(playbackCallback, onTrackEndedMethod);
                break;
            case PlayerEventType::SEEK_COMPLETED:
                if (playbackCallback && onSeekCompletedMethod) env->CallVoidMethod(playbackCallback, onSeekCompletedMethod, event.int64Param);
                break;
            case PlayerEventType::ERROR:
                if (playbackCallback && onErrorMethod) {
                    jstring jMsg = env->NewStringUTF(event.stringParam1.c_str());
                    env->CallVoidMethod(playbackCallback, onErrorMethod, event.intParam, jMsg);
                    env->DeleteLocalRef(jMsg);
                }
                break;
            case PlayerEventType::TRACK_TRANSITION:
                if (playbackCallback && onTrackTransitionMethod) {
                    jstring from = env->NewStringUTF(event.stringParam1.c_str());
                    jstring to = env->NewStringUTF(event.stringParam2.c_str());
                    env->CallVoidMethod(playbackCallback, onTrackTransitionMethod, from, to);
                    env->DeleteLocalRef(from);
                    env->DeleteLocalRef(to);
                }
                break;
            case PlayerEventType::NEXT_TRACK_FAILED:
                if (playbackCallback && onNextTrackFailedMethod) {
                    jstring track = env->NewStringUTF(event.stringParam1.c_str());
                    jstring err = env->NewStringUTF(event.stringParam2.c_str());
                    env->CallVoidMethod(playbackCallback, onNextTrackFailedMethod, track, err);
                    env->DeleteLocalRef(track);
                    env->DeleteLocalRef(err);
                }
                break;
        }
        if (env->ExceptionCheck()) { env->ExceptionDescribe(); env->ExceptionClear(); }
    }
    javaVM->DetachCurrentThread();
}

void GaplessAudioPlayer::postEvent(PlayerEvent event) {
    eventQueue.push(std::move(event));
}

int GaplessAudioPlayer::open(const char* filePath, const char* trackId, JavaVM* vm,
                             jobject audioCallback, jobject lifecycleCallback) {
    if (!filePath || !trackId || !vm) return -1;
    if (isPrepared || isPlaying) close();

    javaVM = vm;
    currentTrackId = trackId;

    if (eventThread == 0) {
        pthread_create(&eventThread, nullptr, eventThreadFunc, this);
    }

    JNIEnv* env = nullptr;
    if (javaVM->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) return -1;

    const int result = initializeDecoder(&currentDecoder, filePath);
    if (result != 0) return result;

    const bool compatibilityOutput = audioCompatibilityMode.load(std::memory_order_acquire);
    audioPipeline.setOutputSampleRate(compatibilityOutput ? COMPATIBILITY_OUTPUT_SAMPLE_RATE : OUTPUT_SAMPLE_RATE);
    updateCachedBurstSize();

    currentDecoder.isActive = true;
    audioPipeline.attachDecoder(currentDecoder.codecContext);
    transitionPipeline.detachDecoder();

    if (audioCallback) {
        if (audioTrackCallback) env->DeleteGlobalRef(audioTrackCallback);
        audioTrackCallback = env->NewGlobalRef(audioCallback);
        jclass cls = env->GetObjectClass(audioCallback);
        writeAudioMethod = env->GetMethodID(cls, "onAudioData", "([FIII)V");
    }

    if (lifecycleCallback) {
        if (playbackCallback) env->DeleteGlobalRef(playbackCallback);
        playbackCallback = env->NewGlobalRef(lifecycleCallback);
        jclass cls = env->GetObjectClass(lifecycleCallback);
        onTrackEndedMethod = env->GetMethodID(cls, "onTrackEnded", "()V");
        onSeekCompletedMethod = env->GetMethodID(cls, "onSeekCompleted", "(J)V");
        onErrorMethod = env->GetMethodID(cls, "onError", "(ILjava/lang/String;)V");
        onTrackTransitionMethod = env->GetMethodID(cls, "onTrackTransition", "(Ljava/lang/String;Ljava/lang/String;)V");
        onPrepareNextTrackMethod = env->GetMethodID(cls, "onPrepareNextTrack", "()Ljava/lang/String;");
        onNextTrackFailedMethod = env->GetMethodID(cls, "onNextTrackFailed", "(Ljava/lang/String;Ljava/lang/String;)V");
    }

    {
        std::lock_guard<std::mutex> lock(bufferMutex);
        resetDoubleBufferStateLocked();
    }
    currentPositionMs = 0;
    isPrepared = true;
    playbackPhase = NORMAL_PLAYBACK;
    playbackCompleted_.store(false, std::memory_order_release);
    decoderValid_.store(true, std::memory_order_release);
    return 0;
}

int GaplessAudioPlayer::initializeDecoder(DecoderContext* decoder, const char* filePath) {
    decoder->reset();
    decoder->filePath = filePath;

    AVDictionary* opts = nullptr;
    av_dict_set(&opts, "analyzeduration", "1000000", 0);
    av_dict_set(&opts, "probesize", "500000", 0);
    if (avformat_open_input(&decoder->formatContext, filePath, nullptr, &opts) < 0) {
        av_dict_free(&opts);
        return -1;
    }
    av_dict_free(&opts);
    if (avformat_find_stream_info(decoder->formatContext, nullptr) < 0) return -2;

    decoder->audioStreamIndex = av_find_best_stream(decoder->formatContext, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    if (decoder->audioStreamIndex < 0) return -3;

    AVStream* audioStream = decoder->formatContext->streams[decoder->audioStreamIndex];
    const AVCodec* codec = avcodec_find_decoder(audioStream->codecpar->codec_id);
    if (!codec) return -4;

    decoder->codecContext = avcodec_alloc_context3(codec);
    if (!decoder->codecContext) return -5;
    if (avcodec_parameters_to_context(decoder->codecContext, audioStream->codecpar) < 0) return -6;
    if (avcodec_open2(decoder->codecContext, codec, nullptr) < 0) return -7;

    decoder->durationMs = getAccurateDuration(decoder->formatContext, decoder->audioStreamIndex, filePath);
    decoder->sampleRate = decoder->codecContext->sample_rate;
    decoder->channels = decoder->codecContext->ch_layout.nb_channels;
    decoder->sampleFormat = decoder->codecContext->sample_fmt;
    decoder->isInitialized = true;
    return 0;
}

void GaplessAudioPlayer::cleanupDecoder(DecoderContext* decoder) {
    decoder->reset();
}

void GaplessAudioPlayer::close() {
    decoderValid_.store(false, std::memory_order_release);
    stopRequested = true;
    isPlaying = false;
    pauseCondition.notify_all();
    bufferConsumedCondition.notify_all();

    if (decodeThread != 0) {
        pthread_join(decodeThread, nullptr);
        decodeThread = 0;
    }
    if (prepareThread != 0) {
        pthread_join(prepareThread, nullptr);
        prepareThread = 0;
    }

    {
        std::lock_guard<std::mutex> lock(bufferMutex);
        resetDoubleBufferStateLocked();
    }

    std::lock_guard<std::mutex> lock(decoderMutex);
    audioPipeline.detachDecoder();
    transitionPipeline.detachDecoder();
    audioPipeline.getNativeEffects().flush();
    cleanupDecoder(&currentDecoder);
    cleanupDecoder(&nextDecoder);
    isPrepared = false;
    seekRequested = false;
    stopRequested = false;
    currentPositionMs = 0;
    playbackCompleted_.store(false, std::memory_order_release);
    playbackPhase = IDLE;
    crossfadeSamplesRemaining = 0;
    totalCrossfadeSamples = 0;
    cfCurrentBuffer_.clear();
    cfNextBuffer_.clear();
    cfFinalizeBuffer_.clear();
    cfMixedBuffer_.clear();
    currentTrackId.clear();
    nextTrackId.clear();
}

void GaplessAudioPlayer::updateCachedBurstSize() {
    cachedFramesPerBurst.store(192, std::memory_order_release);
}

void GaplessAudioPlayer::syncTransitionPipelineLocked() {
    transitionPipeline.copySettingsFrom(audioPipeline);
    transitionPipeline.detachDecoder();
    if (nextDecoder.isInitialized && nextDecoder.codecContext) {
        transitionPipeline.attachDecoder(nextDecoder.codecContext);
    }
}

void GaplessAudioPlayer::start() {
    if (!isPrepared || isPlaying) return;

    if (decodeThread != 0 && !decodeThreadRunning_.load(std::memory_order_acquire)) {
        pthread_join(decodeThread, nullptr);
        decodeThread = 0;
    }

    if (playbackCompleted_.load(std::memory_order_acquire)) {
        resetPlaybackToStart();
    }

    isPlaying = true;
    stopRequested = false;
    pauseCondition.notify_all();

    if (decodeThread == 0) {
        pthread_create(&decodeThread, nullptr, decodeThreadFunc, this);

    }
}

void GaplessAudioPlayer::pause() {
    isPlaying = false;
}

void GaplessAudioPlayer::stop() {
    isPlaying = false;
    stopRequested = true;
    pauseCondition.notify_all();
    bufferConsumedCondition.notify_all();
}

void GaplessAudioPlayer::seekTo(int64_t positionMs) {
    seekTargetMs = positionMs;
    seekRequested = true;
    pauseCondition.notify_all();
}

void* GaplessAudioPlayer::decodeThreadFunc(void* arg) {
    auto* player = static_cast<GaplessAudioPlayer*>(arg);
    setpriority(PRIO_PROCESS, 0, -16);
    player->decodeLoop();
    return nullptr;
}

void GaplessAudioPlayer::decodeLoop() {
    decodeThreadRunning_.store(true, std::memory_order_release);
    logThreadPriority("DecodeThread");
    auto packetDeleter = [](AVPacket* p) { if (p) av_packet_free(&p); };
    auto frameDeleter = [](AVFrame* f) { if (f) av_frame_free(&f); };
    std::unique_ptr<AVPacket, decltype(packetDeleter)> packet(av_packet_alloc(), packetDeleter);
    std::unique_ptr<AVFrame, decltype(frameDeleter)> frame(av_frame_alloc(), frameDeleter);
    std::unique_ptr<AVFrame, decltype(frameDeleter)> filteredFrame(av_frame_alloc(), frameDeleter);
    if (!packet || !frame || !filteredFrame) {
        decodeThreadRunning_.store(false, std::memory_order_release);
        return;
    }

    JNIEnv* env = attachThread();
    if (!env) {
        decodeThreadRunning_.store(false, std::memory_order_release);
        return;
    }

    bool reachedEnd = false;

    while (!stopRequested.load(std::memory_order_acquire)) {
        if (seekRequested.load(std::memory_order_acquire)) {
            performSeek(env);
            reachedEnd = false;
            continue;
        }

        if (!isPlaying.load(std::memory_order_acquire)) {
            std::unique_lock<std::mutex> lock(pauseMutex);
            pauseCondition.wait(lock, [this] {
                return isPlaying.load(std::memory_order_acquire) || stopRequested.load(std::memory_order_acquire) || seekRequested.load(std::memory_order_acquire);
            });
            continue;
        }

        if ((gaplessEnabled.load(std::memory_order_acquire) || crossfadeEnabled.load(std::memory_order_acquire)) &&
            playbackPhase == NORMAL_PLAYBACK && shouldPrepareNext()) {
            playbackPhase = PREPARING_NEXT;
            if (prepareThread == 0) pthread_create(&prepareThread, nullptr, prepareThreadFunc, this);
        }

        if (playbackPhase == PREPARING_NEXT && nextDecoder.isInitialized && shouldStartTransition()) {
            playbackPhase = TRANSITIONING;
            cfCurrentBuffer_.clear();
            cfNextBuffer_.clear();
            cfFinalizeBuffer_.clear();
            cfMixedBuffer_.clear();
            if (crossfadeEnabled) {
                totalCrossfadeSamples = (audioPipeline.getOutputSampleRate() * crossfadeDurationMs.load()) / 1000;
                crossfadeSamplesRemaining = totalCrossfadeSamples;
            }
        }

        int readResult;
        {
            std::lock_guard<std::mutex> lock(decoderMutex);
            readResult = av_read_frame(currentDecoder.formatContext, packet.get());
        }

        if (readResult < 0) {
            if (readResult == AVERROR_EOF) {
                handleEndOfFile(env, packet.get(), frame.get(), filteredFrame.get(), reachedEnd);
                if (reachedEnd) break;
                continue;
            }
            break;
        }

        if (packet->stream_index == currentDecoder.audioStreamIndex) {
            if (playbackPhase == TRANSITIONING && crossfadeEnabled) {
                processCrossfadeTransition(packet.get(), frame.get(), filteredFrame.get());
            } else {
                processNormalPlayback(packet.get(), frame.get(), filteredFrame.get());
            }
        }
        av_packet_unref(packet.get());
    }

    javaVM->DetachCurrentThread();
    isPlaying = false;
    decodeThreadRunning_.store(false, std::memory_order_release);
}

void* GaplessAudioPlayer::prepareThreadFunc(void* arg) {
    static_cast<GaplessAudioPlayer*>(arg)->prepareNextTrack();
    return nullptr;
}

void GaplessAudioPlayer::prepareNextTrack() {
    JNIEnv* env = attachThread();
    if (!env) return;
    const std::string nextPath = requestNextTrack(env);
    if (nextPath.empty()) {
        playbackPhase = NORMAL_PLAYBACK;
        javaVM->DetachCurrentThread();
        prepareThread = 0;
        return;
    }

    DecoderContext preparedDecoder;
    if (initializeDecoder(&preparedDecoder, nextPath.c_str()) != 0) {
        postEvent(PlayerEvent::nextTrackFailed(nextTrackId, "Failed to initialize decoder"));
        playbackPhase = NORMAL_PLAYBACK;
    } else {
        std::lock_guard<std::mutex> lock(decoderMutex);
        if (playbackPhase == PREPARING_NEXT || playbackPhase == TRANSITIONING) {
            cleanupDecoder(&nextDecoder);
            nextDecoder = std::move(preparedDecoder);
            syncTransitionPipelineLocked();
        } else {
            preparedDecoder.reset();
        }
    }
    javaVM->DetachCurrentThread();
    prepareThread = 0;
}

void GaplessAudioPlayer::resetDoubleBufferStateLocked() {
    const uint32_t nextEpoch = bufferEpoch_.load(std::memory_order_acquire) + 1;
    outputRingReadFrame_.store(0, std::memory_order_release);
    outputRingWriteFrame_.store(0, std::memory_order_release);
    outputRingQueuedFrames_.store(0, std::memory_order_release);
    bufferEpoch_.store(nextEpoch, std::memory_order_release);
}

int GaplessAudioPlayer::getDesiredPrefillBuffers() const {
    const int burst = std::max(1, cachedFramesPerBurst.load(std::memory_order_acquire));
    const int targetFrames = std::max(8192, burst * 24);
    const int targetBuffers = (targetFrames + OUTPUT_BUFFER_CAPACITY_FRAMES - 1) / OUTPUT_BUFFER_CAPACITY_FRAMES;
    return std::clamp(targetBuffers, 4, OUTPUT_BUFFER_SLOT_COUNT);
}

void GaplessAudioPlayer::publishToOutput(const std::vector<float>& data, int numFrames) {
    if (numFrames <= 0) return;
    JNIEnv* env = attachThread();
    if (!env || !audioTrackCallback || !writeAudioMethod) return;
    std::vector<float> copy = data;
    const float volume = currentVolume.load(std::memory_order_acquire);
    if (std::abs(volume - 1.0f) > 0.001f) {
        for (auto& sample : copy) sample *= volume;
    }
    jfloatArray audioData = env->NewFloatArray(numFrames * OUTPUT_CHANNELS);
    if (!audioData) return;
    env->SetFloatArrayRegion(audioData, 0, numFrames * OUTPUT_CHANNELS, copy.data());
    env->CallVoidMethod(audioTrackCallback, writeAudioMethod, audioData, numFrames * OUTPUT_CHANNELS, audioPipeline.getOutputSampleRate(), OUTPUT_CHANNELS);
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        stopRequested.store(true, std::memory_order_release);
        isPlaying.store(false, std::memory_order_release);
    }
    env->DeleteLocalRef(audioData);
}

void GaplessAudioPlayer::processNormalPlayback(AVPacket* packet, AVFrame* frame, AVFrame* filteredFrame) {
    (void)filteredFrame;
    {
        std::lock_guard<std::mutex> lock(decoderMutex);
        if (!currentDecoder.isInitialized) return;
        if (avcodec_send_packet(currentDecoder.codecContext, packet) < 0) return;
    }

    while (!stopRequested.load(std::memory_order_acquire) && !seekRequested.load(std::memory_order_acquire)) {
        av_frame_unref(frame);
        const int rcv = avcodec_receive_frame(currentDecoder.codecContext, frame);
        if (rcv != 0) break;

        int outSamples = 0;
        if (audioPipeline.processFrame(frame, decodeBuffer_, &outSamples) == 0 && outSamples > 0) {
            publishToOutput(decodeBuffer_, outSamples);
            updatePosition(packet, &currentDecoder, outSamples);
        }
    }
}

void GaplessAudioPlayer::handleEndOfFile(JNIEnv* env, AVPacket* packet, AVFrame* frame,
                                         AVFrame* filteredFrame, bool& reachedEnd) {
    if (playbackPhase == TRANSITIONING && nextDecoder.isInitialized) {
        if (crossfadeEnabled && crossfadeSamplesRemaining > 0) {
            finishCrossfade();
        } else {
            swapDecoders();
            reachedEnd = false;
        }
        return;
    }
    if (playbackPhase == PREPARING_NEXT && nextDecoder.isInitialized) {
        swapDecoders();
        reachedEnd = false;
        return;
    }
    if (!reachedEnd) {
        reachedEnd = true;
        currentPositionMs = currentDecoder.durationMs;
        playbackCompleted_.store(true, std::memory_order_release);
        postEvent(PlayerEvent::trackEnded());
    }
}

void GaplessAudioPlayer::mixCrossfadeInto(const std::vector<float>& currentBuf, int currentSamples,
                                          const std::vector<float>& nextBuf, int nextSamples,
                                          std::vector<float>& outMixed, int* outMixedSamples) {
    const int samplesToMix = std::min(std::min(currentSamples, nextSamples), static_cast<int>(crossfadeSamplesRemaining.load()));
    *outMixedSamples = 0;
    if (samplesToMix <= 0) return;
    outMixed.resize(samplesToMix * OUTPUT_CHANNELS);
    const int progress = totalCrossfadeSamples - crossfadeSamplesRemaining.load();
    const float invTotal = totalCrossfadeSamples > 0 ? (1.0f / totalCrossfadeSamples) : 1.0f;
    for (int i = 0; i < samplesToMix; ++i) {
        const float t = (progress + i) * invTotal;
        const float fadeOut = std::sqrt(std::max(0.0f, 1.0f - t));
        const float fadeIn = t * t * t;
        for (int ch = 0; ch < OUTPUT_CHANNELS; ++ch) {
            const int idx = i * OUTPUT_CHANNELS + ch;
            outMixed[idx] = (currentBuf[idx] * fadeOut) + (nextBuf[idx] * fadeIn);
        }
    }
    crossfadeSamplesRemaining -= samplesToMix;
    *outMixedSamples = samplesToMix;
}

void GaplessAudioPlayer::finalizeCrossfade(AVPacket* packet, AVFrame* frame, AVFrame* filteredFrame) {
    (void)packet;
    (void)frame;
    (void)filteredFrame;
    finishCrossfade();
}

void GaplessAudioPlayer::applyFadeIn(std::vector<float>& buffer, int samples) {
    const int progress = totalCrossfadeSamples - crossfadeSamplesRemaining.load();
    const float invTotal = totalCrossfadeSamples > 0 ? (1.0f / totalCrossfadeSamples) : 1.0f;
    const int samplesToFade = std::min(samples, static_cast<int>(crossfadeSamplesRemaining.load()));
    for (int i = 0; i < samplesToFade; ++i) {
        const float t      = (progress + i) * invTotal;
        const float fadeIn = t * t * t;
        for (int ch = 0; ch < OUTPUT_CHANNELS; ++ch) buffer[i * OUTPUT_CHANNELS + ch] *= fadeIn;
    }
    crossfadeSamplesRemaining -= samplesToFade;
}

void GaplessAudioPlayer::processGaplessTransition() {
    swapDecoders();
}

void GaplessAudioPlayer::processCrossfadeTransition(AVPacket* packet, AVFrame* frame, AVFrame* filteredFrame) {
    int currentSamples = 0;
    {
        std::lock_guard<std::mutex> lock(decoderMutex);
        if (!currentDecoder.isInitialized) return;
        if (avcodec_send_packet(currentDecoder.codecContext, packet) < 0 || avcodec_receive_frame(currentDecoder.codecContext, frame) != 0) return;
    }
    if (decodeFrame(audioPipeline, &currentDecoder, frame, filteredFrame, cfFinalizeBuffer_, &currentSamples) == 0 && currentSamples > 0) {
        appendFrameBlock(cfCurrentBuffer_, cfFinalizeBuffer_, currentSamples);
    }

    while (!stopRequested.load(std::memory_order_acquire) &&
           crossfadeSamplesRemaining.load(std::memory_order_acquire) > 0) {
        const int currentFrames = static_cast<int>(cfCurrentBuffer_.size()) / OUTPUT_CHANNELS;
        if (currentFrames <= 0) break;

        const int nextFrames = static_cast<int>(cfNextBuffer_.size()) / OUTPUT_CHANNELS;
        if (nextFrames <= 0) {
            if (decodeNextFrameForCrossfade(cfNextBuffer_) <= 0) break;
            continue;
        }

        int mixedFrames = 0;
        mixCrossfadeInto(cfCurrentBuffer_, currentFrames, cfNextBuffer_, nextFrames, cfMixedBuffer_, &mixedFrames);
        if (mixedFrames <= 0) break;
        publishToOutput(cfMixedBuffer_, mixedFrames);
        consumeFrameBlock(cfCurrentBuffer_, mixedFrames);
        consumeFrameBlock(cfNextBuffer_, mixedFrames);
    }

    if (currentSamples > 0) {
        updatePosition(packet, &currentDecoder, currentSamples);
    }

    if (crossfadeSamplesRemaining <= 0) {
        flushPendingTransitionAudio();
        swapDecoders();
    }
}

int GaplessAudioPlayer::decodeFrame(AudioPipeline& pipeline, DecoderContext* decoder, AVFrame* frame, AVFrame* filteredFrame,
                                    std::vector<float>& outBuffer, int* outSamples) {
    (void)decoder; (void)filteredFrame;
    return pipeline.processFrame(frame, outBuffer, outSamples);
}

void GaplessAudioPlayer::swapDecoders() {
    decoderValid_.store(false, std::memory_order_release);
    postEvent(PlayerEvent::trackTransition(currentTrackId, nextTrackId));
    DecoderContext previousDecoder = std::move(currentDecoder);
    currentDecoder = std::move(nextDecoder);
    currentTrackId = std::move(nextTrackId);
    nextDecoder = DecoderContext();
    nextTrackId.clear();
    currentDecoder.samplesDecoded = 0;
    currentPositionMs = 0;
    playbackCompleted_.store(false, std::memory_order_release);
    audioPipeline.switchDecoder(currentDecoder.codecContext);
    transitionPipeline.detachDecoder();
    cleanupDecoder(&previousDecoder);
    playbackPhase = NORMAL_PLAYBACK;
    crossfadeSamplesRemaining = 0;
    totalCrossfadeSamples = 0;
    cfCurrentBuffer_.clear();
    cfNextBuffer_.clear();
    cfFinalizeBuffer_.clear();
    cfMixedBuffer_.clear();
    decoderValid_.store(true, std::memory_order_release);
}

bool GaplessAudioPlayer::shouldPrepareNext() {
    if (!currentDecoder.isInitialized || currentDecoder.durationMs == 0) return false;
    const int64_t remaining = currentDecoder.durationMs - currentPositionMs.load(std::memory_order_acquire);
    const int64_t threshold = std::min<int64_t>(static_cast<int64_t>(currentDecoder.durationMs * 0.15), 5000);
    return remaining > 0 && remaining <= threshold;
}

void GaplessAudioPlayer::setCrossfadeDuration(int durationMs) {
    crossfadeDurationMs = std::max(0, std::min(5000, durationMs));
}

bool GaplessAudioPlayer::shouldStartTransition() {
    if (!nextDecoder.isInitialized || currentDecoder.durationMs == 0) return false;
    const int64_t remaining = currentDecoder.durationMs - currentPositionMs.load(std::memory_order_acquire);
    return crossfadeEnabled ? remaining <= crossfadeDurationMs.load() : remaining <= 50;
}

void GaplessAudioPlayer::performSeek(JNIEnv* env) {
    (void)env;
    std::lock_guard<std::mutex> lock(decoderMutex);
    if (!currentDecoder.isInitialized) {
        seekRequested = false;
        return;
    }
    AVStream* audioStream = currentDecoder.formatContext->streams[currentDecoder.audioStreamIndex];
    const int64_t targetMs = seekTargetMs.load(std::memory_order_acquire);
    const int64_t seekTimestamp = av_rescale_q(targetMs, AVRational{1, 1000}, audioStream->time_base);
    if (av_seek_frame(currentDecoder.formatContext, currentDecoder.audioStreamIndex, seekTimestamp, AVSEEK_FLAG_BACKWARD) >= 0) {
        avcodec_flush_buffers(currentDecoder.codecContext);
        audioPipeline.flush();
        currentDecoder.samplesDecoded =
            (targetMs * static_cast<int64_t>(std::max(1, audioPipeline.getOutputSampleRate()))) / 1000;
        currentPositionMs = targetMs;
        playbackCompleted_.store(false, std::memory_order_release);
        {
            std::lock_guard<std::mutex> bufferLock(bufferMutex);
            resetDoubleBufferStateLocked();
        }
        transitionPipeline.detachDecoder();
        cfCurrentBuffer_.clear();
        cfNextBuffer_.clear();
        cfFinalizeBuffer_.clear();
        cfMixedBuffer_.clear();
        crossfadeSamplesRemaining = 0;
        totalCrossfadeSamples = 0;
        bufferConsumedCondition.notify_all();
        postEvent(PlayerEvent::seekCompleted(targetMs));
    } else {
        postEvent(PlayerEvent::error(-100, "Seek operation failed"));
    }
    seekRequested = false;
}

void GaplessAudioPlayer::updatePosition(AVPacket* packet, DecoderContext* decoder, int decodedFrames) {
    (void)packet;
    if (!decoder || decodedFrames <= 0) return;
    decoder->samplesDecoded += decodedFrames;
    const int outputSampleRate = std::max(1, audioPipeline.getOutputSampleRate());
    currentPositionMs = (decoder->samplesDecoded * 1000) / outputSampleRate;
}

int64_t GaplessAudioPlayer::getDuration() const { return currentDecoder.durationMs; }
int64_t GaplessAudioPlayer::getCurrentPosition() const { return currentPositionMs.load(std::memory_order_acquire); }
bool GaplessAudioPlayer::isPlayingState() const { return isPlaying.load(std::memory_order_acquire); }

void GaplessAudioPlayer::setVolume(float volume) {
    currentVolume.store(std::max(0.0f, std::min(1.0f, volume)), std::memory_order_release);
}

void GaplessAudioPlayer::applyVolume(uint8_t* buffer, int samples, float volume) {
    float* f = reinterpret_cast<float*>(buffer);
    for (int i = 0; i < samples * OUTPUT_CHANNELS; ++i) f[i] *= volume;
}

void GaplessAudioPlayer::cancelGaplessPreparation() {
    std::lock_guard<std::mutex> lock(decoderMutex);
    if (playbackPhase == PREPARING_NEXT || playbackPhase == TRANSITIONING) {
        cleanupDecoder(&nextDecoder);
        transitionPipeline.detachDecoder();
        nextTrackId.clear();
        playbackPhase = NORMAL_PLAYBACK;
        cfCurrentBuffer_.clear();
        cfNextBuffer_.clear();
        cfFinalizeBuffer_.clear();
        cfMixedBuffer_.clear();
        crossfadeSamplesRemaining = 0;
        totalCrossfadeSamples = 0;
    }
}

JNIEnv* GaplessAudioPlayer::attachThread() {
    if (!javaVM) return nullptr;
    JNIEnv* env = nullptr;
    if (javaVM->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_EDETACHED) {
        if (javaVM->AttachCurrentThread(&env, nullptr) != JNI_OK) return nullptr;
    }
    return env;
}

void GaplessAudioPlayer::notifyTrackEnded(JNIEnv* env) { (void)env; postEvent(PlayerEvent::trackEnded()); }
void GaplessAudioPlayer::notifySeekCompleted(JNIEnv* env, int64_t position) { (void)env; postEvent(PlayerEvent::seekCompleted(position)); }
void GaplessAudioPlayer::notifyError(JNIEnv* env, int errorCode, const char* message) { (void)env; postEvent(PlayerEvent::error(errorCode, message)); }
void GaplessAudioPlayer::notifyTrackTransition(JNIEnv* env, const char* fromTrackId, const char* toTrackId) { (void)env; postEvent(PlayerEvent::trackTransition(fromTrackId, toTrackId)); }

std::string GaplessAudioPlayer::requestNextTrack(JNIEnv* env) {
    if (!playbackCallback || !onPrepareNextTrackMethod) return "";
    jstring jResult = static_cast<jstring>(env->CallObjectMethod(playbackCallback, onPrepareNextTrackMethod));
    if (!jResult) return "";
    const char* cStr = env->GetStringUTFChars(jResult, nullptr);
    std::string result(cStr ? cStr : "");
    env->ReleaseStringUTFChars(jResult, cStr);
    env->DeleteLocalRef(jResult);
    const size_t sep = result.find('|');
    if (sep != std::string::npos) {
        nextTrackId = result.substr(0, sep);
        return result.substr(sep + 1);
    }
    return "";
}

void GaplessAudioPlayer::notifyNextTrackFailed(JNIEnv* env, const char* trackId, const char* error) {
    (void)env;
    postEvent(PlayerEvent::nextTrackFailed(trackId, error));
}

void GaplessAudioPlayer::cleanup() {
    close();
    if (javaVM) {
        JNIEnv* env = nullptr;
        if (javaVM->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_OK) {
            if (audioTrackCallback) { env->DeleteGlobalRef(audioTrackCallback); audioTrackCallback = nullptr; }
            if (playbackCallback) { env->DeleteGlobalRef(playbackCallback); playbackCallback = nullptr; }
        }
    }
    javaVM = nullptr;
}

void GaplessAudioPlayer::resetPlaybackToStart() {
    std::lock_guard<std::mutex> lock(decoderMutex);
    if (!currentDecoder.isInitialized) return;

    if (av_seek_frame(currentDecoder.formatContext, currentDecoder.audioStreamIndex, 0, AVSEEK_FLAG_BACKWARD) >= 0) {
        avcodec_flush_buffers(currentDecoder.codecContext);
        audioPipeline.flush();
        currentDecoder.samplesDecoded = 0;
        currentPositionMs = 0;
        playbackCompleted_.store(false, std::memory_order_release);
        {
            std::lock_guard<std::mutex> bufferLock(bufferMutex);
            resetDoubleBufferStateLocked();
        }
        transitionPipeline.detachDecoder();
        cfCurrentBuffer_.clear();
        cfNextBuffer_.clear();
        cfFinalizeBuffer_.clear();
        cfMixedBuffer_.clear();
        crossfadeSamplesRemaining = 0;
        totalCrossfadeSamples = 0;
        bufferConsumedCondition.notify_all();
    } else {
        currentPositionMs = 0;
        playbackCompleted_.store(false, std::memory_order_release);
    }
}

int GaplessAudioPlayer::getOutputBufferQueuedCount() const {
    const int queuedFrames = outputRingQueuedFrames_.load(std::memory_order_acquire);
    return (queuedFrames + OUTPUT_BUFFER_CAPACITY_FRAMES - 1) / OUTPUT_BUFFER_CAPACITY_FRAMES;
}

int GaplessAudioPlayer::decodeNextFrameForCrossfade(std::vector<float>& outBuffer) {
    while (!stopRequested.load(std::memory_order_acquire)) {
        av_packet_unref(cfNextPacket_);
        av_frame_unref(cfNextFrame_);
        av_frame_unref(cfNextFiltered_);

        bool reachedEnd = false;
        {
            std::lock_guard<std::mutex> lock(decoderMutex);
            if (!nextDecoder.isInitialized) return 0;
            const int readResult = av_read_frame(nextDecoder.formatContext, cfNextPacket_);
            if (readResult < 0) {
                reachedEnd = true;
            } else if (cfNextPacket_->stream_index != nextDecoder.audioStreamIndex) {
                continue;
            } else if (avcodec_send_packet(nextDecoder.codecContext, cfNextPacket_) < 0 ||
                       avcodec_receive_frame(nextDecoder.codecContext, cfNextFrame_) != 0) {
                continue;
            }
        }

        if (reachedEnd) {
            return 0;
        }

        int nextFrames = 0;
        if (decodeFrame(transitionPipeline, &nextDecoder, cfNextFrame_, cfNextFiltered_, cfFinalizeBuffer_, &nextFrames) == 0 && nextFrames > 0) {
            appendFrameBlock(outBuffer, cfFinalizeBuffer_, nextFrames);
            return nextFrames;
        }
    }

    return 0;
}

void GaplessAudioPlayer::appendFrameBlock(std::vector<float>& target, const std::vector<float>& source, int frames) {
    if (frames <= 0 || source.empty()) return;
    const size_t samplesToAppend = std::min(source.size(), static_cast<size_t>(frames) * OUTPUT_CHANNELS);
    target.insert(target.end(), source.begin(), source.begin() + static_cast<std::ptrdiff_t>(samplesToAppend));
}

void GaplessAudioPlayer::consumeFrameBlock(std::vector<float>& target, int frames) {
    if (frames <= 0 || target.empty()) return;
    const size_t samplesToConsume = std::min(target.size(), static_cast<size_t>(frames) * OUTPUT_CHANNELS);
    target.erase(target.begin(), target.begin() + static_cast<std::ptrdiff_t>(samplesToConsume));
}

void GaplessAudioPlayer::flushPendingTransitionAudio() {
    const int pendingFrames = static_cast<int>(cfNextBuffer_.size()) / OUTPUT_CHANNELS;
    if (pendingFrames > 0) {
        publishToOutput(cfNextBuffer_, pendingFrames);
        cfNextBuffer_.clear();
    }
}

void GaplessAudioPlayer::finishCrossfade() {
    while (!stopRequested.load(std::memory_order_acquire) &&
           crossfadeSamplesRemaining.load(std::memory_order_acquire) > 0) {
        const int currentFrames = static_cast<int>(cfCurrentBuffer_.size()) / OUTPUT_CHANNELS;
        const int nextFrames = static_cast<int>(cfNextBuffer_.size()) / OUTPUT_CHANNELS;

        if (currentFrames > 0 && nextFrames > 0) {
            int mixedFrames = 0;
            mixCrossfadeInto(cfCurrentBuffer_, currentFrames, cfNextBuffer_, nextFrames, cfMixedBuffer_, &mixedFrames);
            if (mixedFrames <= 0) break;
            publishToOutput(cfMixedBuffer_, mixedFrames);
            consumeFrameBlock(cfCurrentBuffer_, mixedFrames);
            consumeFrameBlock(cfNextBuffer_, mixedFrames);
            continue;
        }

        if (nextFrames <= 0 && decodeNextFrameForCrossfade(cfNextBuffer_) <= 0) {
            break;
        }

        const int refreshedNextFrames = static_cast<int>(cfNextBuffer_.size()) / OUTPUT_CHANNELS;
        if (currentFrames <= 0 && refreshedNextFrames > 0) {
            cfFinalizeBuffer_ = cfNextBuffer_;
            applyFadeIn(cfFinalizeBuffer_, refreshedNextFrames);
            publishToOutput(cfFinalizeBuffer_, refreshedNextFrames);
            cfNextBuffer_.clear();
        }
    }

    flushPendingTransitionAudio();
    swapDecoders();
}
