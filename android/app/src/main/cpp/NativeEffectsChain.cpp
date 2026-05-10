#include "NativeEffectsChain.h"

#include <algorithm>
#include <cmath>

NativeEffectsChain::NativeEffectsChain() {
    initializeDefaultEq();
    eq_.configure(sampleRate_, channels_);
    rebuildEqBandsLocked();
}

void NativeEffectsChain::copySettingsFrom(const NativeEffectsChain& other) {
    if (this == &other) return;
    std::scoped_lock lock(effectsMutex_, other.effectsMutex_);
    sampleRate_ = other.sampleRate_;
    channels_ = other.channels_;
    enabled_ = other.enabled_;
    usingCustomBands_ = other.usingCustomBands_;
    eqBands_ = other.eqBands_;
    eq_.configure(sampleRate_, channels_);
    eq_.setEnabled(other.eq_.getEnabled());
    eq_.setBands(other.eq_.getBands());
}

void NativeEffectsChain::initializeDefaultEq() {
    const float freqs[15] = {
            31.0f, 45.0f, 63.0f, 90.0f, 125.0f,
            180.0f, 250.0f, 355.0f, 500.0f, 710.0f,
            1000.0f, 1400.0f, 2000.0f, 4000.0f, 8000.0f
    };
    eqBands_.resize(15);
    for (int i = 0; i < 15; ++i) {
        eqBands_[i].frequency = freqs[i];
        eqBands_[i].gainDb = 0.0f;
        eqBands_[i].widthHz = std::max(80.0f, freqs[i] * 0.75f);
        eqBands_[i].enabled = true;
    }
}

float NativeEffectsChain::clampf(float value, float lo, float hi) {
    return std::max(lo, std::min(value, hi));
}

float NativeEffectsChain::widthHzToQ(float frequency, float widthHz) {
    return clampf(frequency / std::max(20.0f, widthHz), 0.1f, 18.0f);
}

void NativeEffectsChain::rebuildEqBandsLocked() {
    std::vector<AntiiQEQ::Band> bands;
    bands.reserve(eqBands_.size());
    for (const auto& config : eqBands_) {
        AntiiQEQ::Band band;
        band.frequency = config.frequency;
        band.gainDb = config.gainDb;
        band.Q = widthHzToQ(config.frequency, config.widthHz);
        band.type = AntiiQEQ::PEAK;
        band.enabled = config.enabled;
        bands.push_back(band);
    }
    eq_.setBands(bands);
}

void NativeEffectsChain::configure(int sampleRate, int channels) {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    sampleRate_ = std::max(1, sampleRate);
    channels_ = std::max(1, channels);
    eq_.configure(sampleRate_, channels_);
    if (!usingCustomBands_) rebuildEqBandsLocked();
}

void NativeEffectsChain::process(float* buffer, int frames, int sampleRate) {
    if (!buffer || frames <= 0) return;

    std::lock_guard<std::mutex> lock(effectsMutex_);
    if (!enabled_ || !eq_.getEnabled()) return;
    if (sampleRate > 0 && sampleRate != sampleRate_) {
        sampleRate_ = sampleRate;
        eq_.configure(sampleRate_, channels_);
        if (!usingCustomBands_) rebuildEqBandsLocked();
    }
    eq_.processInterleaved(buffer, frames, channels_);
}

void NativeEffectsChain::flush() {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    eq_.reset();
}

void NativeEffectsChain::setEnabled(bool enabled) {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    enabled_ = enabled;
    eq_.setEnabled(enabled);
}

bool NativeEffectsChain::isEnabled() const {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    return enabled_;
}

void NativeEffectsChain::setEqualizerBand(int band, float gainDb) {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    if (band < 0 || band >= static_cast<int>(eqBands_.size())) return;
    usingCustomBands_ = false;
    eqBands_[band].gainDb = clampf(gainDb, -12.0f, 12.0f);
    rebuildEqBandsLocked();
}

void NativeEffectsChain::setEqualizerBandWidth(int band, float widthHz) {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    if (band < 0 || band >= static_cast<int>(eqBands_.size())) return;
    usingCustomBands_ = false;
    eqBands_[band].widthHz = clampf(widthHz, 20.0f, 5000.0f);
    rebuildEqBandsLocked();
}

void NativeEffectsChain::setEqualizerBandEnabled(int band, bool enabled) {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    if (band < 0 || band >= static_cast<int>(eqBands_.size())) return;
    usingCustomBands_ = false;
    eqBands_[band].enabled = enabled;
    rebuildEqBandsLocked();
}

int NativeEffectsChain::getEqualizerBandCount() const {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    return static_cast<int>(eqBands_.size());
}

void NativeEffectsChain::setAntiiQEQEnabled(bool enabled) {
    setEnabled(enabled);
}

bool NativeEffectsChain::isAntiiQEQEnabled() const {
    return isEnabled();
}

void NativeEffectsChain::setAntiiQEQBands(const std::vector<AntiiQEQ::Band>& bands) {
    std::lock_guard<std::mutex> lock(effectsMutex_);
    usingCustomBands_ = true;
    eq_.setBands(bands);
}

void NativeEffectsChain::resetAntiiQEQ() {
    flush();
}

int NativeEffectsChain::getAntiiQEQBandCount() const {
    return eq_.getBandCount();
}
