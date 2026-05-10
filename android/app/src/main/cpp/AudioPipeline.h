#ifndef AUDIO_PIPELINE_H
#define AUDIO_PIPELINE_H

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>
}

#include <memory>
#include <atomic>
#include <mutex>
#include <vector>

#include <soundtouch/SoundTouch.h>
#include "NativeEffectsChain.h"

class AudioPipeline {
public:
    static constexpr int OUTPUT_SAMPLE_RATE = 44100;
    static constexpr int OUTPUT_CHANNELS = 2;
    static constexpr AVSampleFormat OUTPUT_FORMAT = AV_SAMPLE_FMT_FLT;

    AudioPipeline();
    ~AudioPipeline();

    void attachDecoder(AVCodecContext* codecCtx);
    void switchDecoder(AVCodecContext* codecCtx);
    void detachDecoder();
    void copySettingsFrom(const AudioPipeline& other);
    bool isDecoderAttached() const { return codecContext != nullptr; }

    int processFrame(AVFrame* inputFrame, std::vector<float>& outBuffer, int* outSamples);
    void flush();
    void keepResamplerWarm();

    NativeEffectsChain& getNativeEffects() { return effectsProcessor; }
    const NativeEffectsChain& getNativeEffects() const { return effectsProcessor; }

    void setTempo(float rate);
    void setPitch(float semitones);
    void setPitchRate(float rate);
    float getTempo() const { return tempoRate.load(std::memory_order_acquire); }
    float getPitch() const { return pitchSemitones.load(std::memory_order_acquire); }
    float getPitchRate() const { return pitchRate.load(std::memory_order_acquire); }

    void rebuildResampler(AVSampleFormat newInputFormat);
    AVSampleFormat getCurrentInputFormat() const {
        return currentInputFormat.load(std::memory_order_acquire);
    }

    void setOutputSampleRate(int rate);
    int getOutputSampleRate() const { return actualOutputSampleRate.load(std::memory_order_acquire); }

private:
    AVCodecContext* codecContext = nullptr;
    SwrContext* swrContext = nullptr;
    NativeEffectsChain effectsProcessor;

    std::unique_ptr<soundtouch::SoundTouch> soundTouch;
    std::atomic<float> tempoRate{1.0f};
    std::atomic<float> pitchSemitones{0.0f};
    std::atomic<float> pitchRate{1.0f};
    std::mutex soundTouchMutex;

    std::atomic<AVSampleFormat> currentInputFormat{AV_SAMPLE_FMT_NONE};
    std::mutex resamplerMutex;

    AVFrame* soundTouchFrame = nullptr;
    std::vector<float> floatBuffer;
    std::vector<float> soundTouchOutput;
    std::vector<uint8_t> warmupInputBytes;
    std::vector<float> warmupOutputFloats;
    std::atomic<int> actualOutputSampleRate{OUTPUT_SAMPLE_RATE};
    bool hasPendingSoundTouchOutput = false;

    int initializeResampler(AVSampleFormat inputFormat);
    void cleanupResampler();
    int resampleFrame(AVFrame* frame, std::vector<float>& outBuffer, int* outSamples);
    void warmResamplerLocked(AVSampleFormat inputFormat);
    void drainResamplerLocked();

    void initializeSoundTouch();
    void configureSoundTouchLocked();
    int processSoundTouch(AVFrame* inputFrame, AVFrame* outputFrame);
    void convertToFloat(AVFrame* frame, std::vector<float>& output);
    void convertFromFloat(const float* input, int samples, int sampleRate, AVFrame* output);
};

#endif // AUDIO_PIPELINE_H
