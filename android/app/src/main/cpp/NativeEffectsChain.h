#ifndef NATIVE_EFFECTS_CHAIN_H
#define NATIVE_EFFECTS_CHAIN_H

#include <mutex>
#include <vector>

#include "AntiiQEQ.h"

class NativeEffectsChain {
public:
    NativeEffectsChain();

    void copySettingsFrom(const NativeEffectsChain& other);
    void configure(int sampleRate, int channels);
    void process(float* buffer, int frames, int sampleRate);
    void flush();

    void setEnabled(bool enabled);
    bool isEnabled() const;

    void setEqualizerBand(int band, float gainDb);
    void setEqualizerBandWidth(int band, float widthHz);
    void setEqualizerBandEnabled(int band, bool enabled);
    int getEqualizerBandCount() const;

    void setAntiiQEQEnabled(bool enabled);
    bool isAntiiQEQEnabled() const;
    void setAntiiQEQBands(const std::vector<AntiiQEQ::Band>& bands);
    void resetAntiiQEQ();
    int getAntiiQEQBandCount() const;

private:
    struct EqBandConfig {
        float frequency = 1000.0f;
        float gainDb = 0.0f;
        float widthHz = 300.0f;
        bool enabled = true;
    };

    void initializeDefaultEq();
    void rebuildEqBandsLocked();

    static float clampf(float value, float lo, float hi);
    static float widthHzToQ(float frequency, float widthHz);

    mutable std::mutex effectsMutex_;
    int sampleRate_ = 44100;
    int channels_ = 2;
    bool enabled_ = false;
    bool usingCustomBands_ = false;
    std::vector<EqBandConfig> eqBands_;
    AntiiQEQ eq_;
};

#endif
