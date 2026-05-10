#include "AudioPipeline.h"

#include <android/log.h>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>

extern "C" {
#include <libavutil/opt.h>
}

using namespace soundtouch;

#define LOG_TAG "AudioPipeline"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

AudioPipeline::AudioPipeline() {
    soundTouchFrame = av_frame_alloc();
    initializeSoundTouch();
}

AudioPipeline::~AudioPipeline() {
    detachDecoder();
    if (soundTouchFrame) {
        av_frame_free(&soundTouchFrame);
    }
}

void AudioPipeline::initializeSoundTouch() {
    std::lock_guard<std::mutex> lock(soundTouchMutex);
    soundTouch = std::make_unique<SoundTouch>();
    configureSoundTouchLocked();
}

void AudioPipeline::configureSoundTouchLocked() {
    if (!soundTouch) return;
    const int inputRate = codecContext ? codecContext->sample_rate : OUTPUT_SAMPLE_RATE;
    soundTouch->setSampleRate(std::max(1, inputRate));
    soundTouch->setChannels(OUTPUT_CHANNELS);
    soundTouch->setSetting(SETTING_USE_QUICKSEEK, 0);
    soundTouch->setSetting(SETTING_USE_AA_FILTER, 1);
    soundTouch->setSetting(SETTING_SEQUENCE_MS, 40);
    soundTouch->setSetting(SETTING_SEEKWINDOW_MS, 15);
    soundTouch->setSetting(SETTING_OVERLAP_MS, 8);
    soundTouch->setTempo(tempoRate.load(std::memory_order_acquire));
    soundTouch->setPitchSemiTones(pitchSemitones.load(std::memory_order_acquire));
}

void AudioPipeline::attachDecoder(AVCodecContext* codecCtx) {
    if (!codecCtx) return;
    std::lock_guard<std::mutex> lock(resamplerMutex);
    codecContext = codecCtx;
    currentInputFormat.store(codecCtx->sample_fmt, std::memory_order_release);
    cleanupResampler();
    initializeResampler(codecCtx->sample_fmt);
    effectsProcessor.configure(getOutputSampleRate(), OUTPUT_CHANNELS);
    std::lock_guard<std::mutex> soundTouchLock(soundTouchMutex);
    configureSoundTouchLocked();
}

void AudioPipeline::switchDecoder(AVCodecContext* codecCtx) {
    if (!codecCtx) return;

    bool rebuildResampler = true;
    bool clearSoundTouchState = true;
    {
        std::lock_guard<std::mutex> lock(resamplerMutex);
        if (codecContext && swrContext &&
            currentInputFormat.load(std::memory_order_acquire) == codecCtx->sample_fmt &&
            codecContext->sample_rate == codecCtx->sample_rate &&
            codecContext->ch_layout.nb_channels == codecCtx->ch_layout.nb_channels) {
            rebuildResampler = false;
            clearSoundTouchState = false;
        }

        codecContext = codecCtx;
        currentInputFormat.store(codecCtx->sample_fmt, std::memory_order_release);

        if (rebuildResampler) {
            cleanupResampler();
            initializeResampler(codecCtx->sample_fmt);
        }
    }

    if (rebuildResampler) {
        effectsProcessor.configure(getOutputSampleRate(), OUTPUT_CHANNELS);
    }

    std::lock_guard<std::mutex> soundTouchLock(soundTouchMutex);
    if (soundTouch && clearSoundTouchState) {
        soundTouch->clear();
    }
    configureSoundTouchLocked();
}

void AudioPipeline::detachDecoder() {
    flush();
    std::lock_guard<std::mutex> lock(resamplerMutex);
    cleanupResampler();
    codecContext = nullptr;
    currentInputFormat.store(AV_SAMPLE_FMT_NONE, std::memory_order_release);
}

void AudioPipeline::copySettingsFrom(const AudioPipeline& other) {
    if (this == &other) return;
    auto& otherMutable = const_cast<AudioPipeline&>(other);

    actualOutputSampleRate.store(other.actualOutputSampleRate.load(std::memory_order_acquire),
                                 std::memory_order_release);
    tempoRate.store(other.tempoRate.load(std::memory_order_acquire), std::memory_order_release);
    pitchSemitones.store(other.pitchSemitones.load(std::memory_order_acquire), std::memory_order_release);
    pitchRate.store(other.pitchRate.load(std::memory_order_acquire), std::memory_order_release);

    {
        std::scoped_lock lock(soundTouchMutex, otherMutable.soundTouchMutex);
        if (soundTouch) {
            soundTouch->clear();
            soundTouch->setTempo(tempoRate.load(std::memory_order_acquire));
            soundTouch->setPitchSemiTones(pitchSemitones.load(std::memory_order_acquire));
        }
    }

    effectsProcessor.copySettingsFrom(other.effectsProcessor);
}

int AudioPipeline::processFrame(AVFrame* inputFrame, std::vector<float>& outBuffer, int* outSamples) {
    if (!codecContext || !inputFrame || !outSamples) return -1;

    AVFrame* frameToResample = inputFrame;
    const float tempo = tempoRate.load(std::memory_order_acquire);
    const float pitchRateValue = pitchRate.load(std::memory_order_acquire);
    const bool needsSoundTouch = (std::abs(tempo - 1.0f) > 0.001f) || (std::abs(pitchRateValue - 1.0f) > 0.001f);

    if (needsSoundTouch) {
        const int st = processSoundTouch(inputFrame, soundTouchFrame);
        if (st != 0) {
            return st;
        }
        frameToResample = soundTouchFrame;
    }

    const AVSampleFormat frameFormat = static_cast<AVSampleFormat>(frameToResample->format);
    if (frameFormat != currentInputFormat.load(std::memory_order_acquire)) {
        rebuildResampler(frameFormat);
    }

    const int result = resampleFrame(frameToResample, outBuffer, outSamples);
    if (result == 0 && *outSamples > 0) {
        effectsProcessor.process(outBuffer.data(), *outSamples, getOutputSampleRate());
    }

    if (frameToResample == soundTouchFrame) {
        av_frame_unref(soundTouchFrame);
    }

    return result;
}

void AudioPipeline::setOutputSampleRate(int rate) {
    actualOutputSampleRate.store(std::max(1, rate), std::memory_order_release);
    std::lock_guard<std::mutex> lock(resamplerMutex);
    if (codecContext) {
        cleanupResampler();
        initializeResampler(currentInputFormat.load(std::memory_order_acquire));
    }
    effectsProcessor.configure(getOutputSampleRate(), OUTPUT_CHANNELS);
}

void AudioPipeline::setTempo(float rate) {
    rate = std::max(0.5f, std::min(2.0f, rate));
    tempoRate.store(rate, std::memory_order_release);
    std::lock_guard<std::mutex> lock(soundTouchMutex);
    if (soundTouch) {
        soundTouch->clear();
        soundTouch->setTempo(rate);
    }
}

void AudioPipeline::setPitch(float semitones) {
    semitones = std::max(-12.0f, std::min(12.0f, semitones));
    pitchSemitones.store(semitones, std::memory_order_release);
    pitchRate.store(std::pow(2.0f, semitones / 12.0f), std::memory_order_release);
    std::lock_guard<std::mutex> lock(soundTouchMutex);
    if (soundTouch) {
        soundTouch->clear();
        soundTouch->setPitchSemiTones(semitones);
    }
}

void AudioPipeline::setPitchRate(float rate) {
    rate = std::max(0.5f, std::min(2.0f, rate));
    pitchRate.store(rate, std::memory_order_release);
    const float semitones = 12.0f * std::log2(rate);
    pitchSemitones.store(semitones, std::memory_order_release);
    std::lock_guard<std::mutex> lock(soundTouchMutex);
    if (soundTouch) {
        soundTouch->clear();
        soundTouch->setPitchSemiTones(semitones);
    }
}

void AudioPipeline::rebuildResampler(AVSampleFormat newInputFormat) {
    std::lock_guard<std::mutex> lock(resamplerMutex);
    cleanupResampler();
    if (initializeResampler(newInputFormat) == 0) {
        currentInputFormat.store(newInputFormat, std::memory_order_release);
    }
}

void AudioPipeline::flush() {
    {
        std::lock_guard<std::mutex> lock(soundTouchMutex);
        if (soundTouch) {
            soundTouch->clear();
            hasPendingSoundTouchOutput = false;
        }
    }

    {
        std::lock_guard<std::mutex> lock(resamplerMutex);
        drainResamplerLocked();
    }

    effectsProcessor.flush();
}

int AudioPipeline::initializeResampler(AVSampleFormat inputFormat) {
    if (!codecContext) return -1;
    if (inputFormat == AV_SAMPLE_FMT_NONE) return -1;

    AVChannelLayout outLayout = AV_CHANNEL_LAYOUT_STEREO;
    swrContext = swr_alloc();
    if (!swrContext) return -1;

    av_opt_set_chlayout(swrContext, "in_chlayout", &codecContext->ch_layout, 0);
    av_opt_set_chlayout(swrContext, "out_chlayout", &outLayout, 0);
    av_opt_set_int(swrContext, "in_sample_rate", codecContext->sample_rate, 0);
    av_opt_set_int(swrContext, "out_sample_rate", getOutputSampleRate(), 0);
    av_opt_set_sample_fmt(swrContext, "in_sample_fmt", inputFormat, 0);
    av_opt_set_sample_fmt(swrContext, "out_sample_fmt", OUTPUT_FORMAT, 0);

    if (swr_init(swrContext) < 0) {
        cleanupResampler();
        return -1;
    }

    currentInputFormat.store(inputFormat, std::memory_order_release);
    warmResamplerLocked(inputFormat);
    return 0;
}

void AudioPipeline::cleanupResampler() {
    if (swrContext) {
        swr_free(&swrContext);
        swrContext = nullptr;
    }
}

void AudioPipeline::warmResamplerLocked(AVSampleFormat inputFormat) {
    if (!swrContext || !codecContext) return;
    if (inputFormat == AV_SAMPLE_FMT_NONE) return;

    const int warmIn = 1152;
    const int channels = std::max(1, codecContext->ch_layout.nb_channels);
    const int bytesPerSample = av_get_bytes_per_sample(inputFormat);
    if (bytesPerSample <= 0) return;
    const int inputBytes = std::max(1, warmIn * channels * std::max(1, bytesPerSample));
    warmupInputBytes.assign(inputBytes, 0);

    const int warmOut = av_rescale_rnd(warmIn, getOutputSampleRate(), codecContext->sample_rate, AV_ROUND_UP) + 64;
    warmupOutputFloats.assign(warmOut * OUTPUT_CHANNELS, 0.0f);

    const uint8_t* inPlanes[AV_NUM_DATA_POINTERS] = {};
    if (av_sample_fmt_is_planar(inputFormat)) {
        const int planeSize = warmIn * std::max(1, bytesPerSample);
        for (int ch = 0; ch < channels && ch < AV_NUM_DATA_POINTERS; ++ch) {
            inPlanes[ch] = warmupInputBytes.data() + (ch * planeSize);
        }
    } else {
        inPlanes[0] = warmupInputBytes.data();
    }

    uint8_t* outPlanes[1] = { reinterpret_cast<uint8_t*>(warmupOutputFloats.data()) };
    swr_convert(swrContext, outPlanes, warmOut, inPlanes, warmIn);
    drainResamplerLocked();
}

void AudioPipeline::drainResamplerLocked() {
    if (!swrContext || !codecContext) return;
    const int drainFrames = 256;
    if (warmupOutputFloats.size() < static_cast<size_t>(drainFrames * OUTPUT_CHANNELS)) {
        warmupOutputFloats.resize(drainFrames * OUTPUT_CHANNELS, 0.0f);
    }
    uint8_t* outPlanes[1] = { reinterpret_cast<uint8_t*>(warmupOutputFloats.data()) };
    while (swr_convert(swrContext, outPlanes, drainFrames, nullptr, 0) > 0) {}
}

void AudioPipeline::keepResamplerWarm() {
    std::lock_guard<std::mutex> lock(resamplerMutex);
    warmResamplerLocked(currentInputFormat.load(std::memory_order_acquire));
}

int AudioPipeline::resampleFrame(AVFrame* frame, std::vector<float>& outBuffer, int* outSamples) {
    std::lock_guard<std::mutex> lock(resamplerMutex);
    if (!swrContext) return -1;
    const int outputRate = getOutputSampleRate();

    constexpr int paddingFrames = 64;
    const int outSamplesCount = av_rescale_rnd(
            swr_get_delay(swrContext, frame->sample_rate) + frame->nb_samples,
            outputRate,
            frame->sample_rate,
            AV_ROUND_UP) + paddingFrames;

    const int floatsNeeded = outSamplesCount * OUTPUT_CHANNELS;
    if (static_cast<int>(outBuffer.size()) < floatsNeeded) {
        outBuffer.resize(floatsNeeded);
    }

    uint8_t* outPlanes[1] = { reinterpret_cast<uint8_t*>(outBuffer.data()) };
    const int converted = swr_convert(swrContext, outPlanes, outSamplesCount, const_cast<const uint8_t**>(frame->data), frame->nb_samples);
    if (converted < 0 || converted > outSamplesCount) {
        *outSamples = 0;
        return -1;
    }

    const int totalFloats = converted * OUTPUT_CHANNELS;
    for (int i = 0; i < totalFloats; ++i) {
        if (!std::isfinite(outBuffer[i])) outBuffer[i] = 0.0f;
    }
    *outSamples = converted;
    return 0;
}

int AudioPipeline::processSoundTouch(AVFrame* inputFrame, AVFrame* outputFrame) {
    std::lock_guard<std::mutex> lock(soundTouchMutex);
    if (!soundTouch) return -1;

    av_frame_unref(outputFrame);
    convertToFloat(inputFrame, floatBuffer);
    soundTouch->putSamples(floatBuffer.data(), inputFrame->nb_samples);

    const int available = soundTouch->numSamples();
    if (available <= 0) {
        return AVERROR(EAGAIN);
    }

    soundTouchOutput.resize(available * OUTPUT_CHANNELS);
    const int received = soundTouch->receiveSamples(soundTouchOutput.data(), available);
    if (received <= 0) {
        return AVERROR(EAGAIN);
    }

    convertFromFloat(soundTouchOutput.data(), received, inputFrame->sample_rate, outputFrame);
    return 0;
}

void AudioPipeline::convertToFloat(AVFrame* frame, std::vector<float>& output) {
    const int samples = frame->nb_samples;
    const int channels = std::max(1, frame->ch_layout.nb_channels);
    output.resize(samples * OUTPUT_CHANNELS);
    const AVSampleFormat fmt = static_cast<AVSampleFormat>(frame->format);

    if (fmt == AV_SAMPLE_FMT_FLTP) {
        auto* left = reinterpret_cast<float*>(frame->data[0]);
        auto* right = channels > 1 ? reinterpret_cast<float*>(frame->data[1]) : left;
        for (int i = 0; i < samples; ++i) {
            output[i * 2] = left[i];
            output[i * 2 + 1] = right[i];
        }
    } else if (fmt == AV_SAMPLE_FMT_FLT) {
        auto* data = reinterpret_cast<float*>(frame->data[0]);
        if (channels == 2) {
            std::memcpy(output.data(), data, samples * OUTPUT_CHANNELS * sizeof(float));
        } else {
            for (int i = 0; i < samples; ++i) {
                output[i * 2] = data[i];
                output[i * 2 + 1] = data[i];
            }
        }
    } else if (fmt == AV_SAMPLE_FMT_S16P) {
        auto* left = reinterpret_cast<int16_t*>(frame->data[0]);
        auto* right = channels > 1 ? reinterpret_cast<int16_t*>(frame->data[1]) : left;
        for (int i = 0; i < samples; ++i) {
            output[i * 2] = left[i] / 32768.0f;
            output[i * 2 + 1] = right[i] / 32768.0f;
        }
    } else if (fmt == AV_SAMPLE_FMT_S16) {
        auto* data = reinterpret_cast<int16_t*>(frame->data[0]);
        for (int i = 0; i < samples; ++i) {
            const float left = data[i * channels] / 32768.0f;
            const float right = data[i * channels + (channels > 1 ? 1 : 0)] / 32768.0f;
            output[i * 2] = left;
            output[i * 2 + 1] = right;
        }
    } else if (fmt == AV_SAMPLE_FMT_S32P) {
        auto* left = reinterpret_cast<int32_t*>(frame->data[0]);
        auto* right = channels > 1 ? reinterpret_cast<int32_t*>(frame->data[1]) : left;
        for (int i = 0; i < samples; ++i) {
            output[i * 2] = static_cast<float>(left[i] / 2147483648.0);
            output[i * 2 + 1] = static_cast<float>(right[i] / 2147483648.0);
        }
    } else if (fmt == AV_SAMPLE_FMT_S32) {
        auto* data = reinterpret_cast<int32_t*>(frame->data[0]);
        for (int i = 0; i < samples; ++i) {
            const float left = static_cast<float>(data[i * channels] / 2147483648.0);
            const float right = static_cast<float>(data[i * channels + (channels > 1 ? 1 : 0)] / 2147483648.0);
            output[i * 2] = left;
            output[i * 2 + 1] = right;
        }
    } else if (fmt == AV_SAMPLE_FMT_DBLP) {
        auto* left = reinterpret_cast<double*>(frame->data[0]);
        auto* right = channels > 1 ? reinterpret_cast<double*>(frame->data[1]) : left;
        for (int i = 0; i < samples; ++i) {
            output[i * 2] = static_cast<float>(left[i]);
            output[i * 2 + 1] = static_cast<float>(right[i]);
        }
    } else if (fmt == AV_SAMPLE_FMT_DBL) {
        auto* data = reinterpret_cast<double*>(frame->data[0]);
        for (int i = 0; i < samples; ++i) {
            output[i * 2] = static_cast<float>(data[i * channels]);
            output[i * 2 + 1] = static_cast<float>(data[i * channels + (channels > 1 ? 1 : 0)]);
        }
    } else {
        std::fill(output.begin(), output.end(), 0.0f);
    }
}

void AudioPipeline::convertFromFloat(const float* input, int samples, int sampleRate, AVFrame* output) {
    output->format = AV_SAMPLE_FMT_FLTP;
    output->sample_rate = sampleRate;
    output->ch_layout = AV_CHANNEL_LAYOUT_STEREO;
    output->nb_samples = samples;
    if (av_frame_get_buffer(output, 0) < 0) return;

    auto* left = reinterpret_cast<float*>(output->data[0]);
    auto* right = reinterpret_cast<float*>(output->data[1]);
    for (int i = 0; i < samples; ++i) {
        left[i] = input[i * 2];
        right[i] = input[i * 2 + 1];
    }
}
