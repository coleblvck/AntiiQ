//
// Created by blvck on 16/11/2025.
//

#include "AntiiQEQ.h"
#include <android/log.h>

#define LOG_TAG "AntiiQEQ"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

AntiiQEQ::AntiiQEQ()
        : sampleRate(44100), numChannels(2), isEnabled(false), needsRecalc(false) {
    LOGD("AntiiQ EQ created");
}

void AntiiQEQ::configure(int sr, int channels) {
    if (sr <= 0 || channels <= 0) {
        LOGD("ERROR: Invalid sample rate (%d) or channels (%d)", sr, channels);
        return;
    }

    bool sampleRateChanged = (sr != sampleRate);
    sampleRate = sr;
    numChannels = channels;
    needsRecalc = sampleRateChanged;

    // Recalculate coefficients if sample rate changed
    if (sampleRateChanged && !bands.empty()) {
        LOGD("Sample rate changed, recalculating coefficients...");
        for (size_t i = 0; i < bands.size(); i++) {
            if (bands[i].enabled) {
                calculateCoefficients(bands[i], biquads[i]);
            }
        }
    }

    LOGD("Configured: %d Hz, %d channels", sr, channels);
}

void AntiiQEQ::setBands(const std::vector<Band>& newBands) {
    if (sampleRate <= 0) {
        LOGD("ERROR: Configure sample rate before setting bands!");
        return;
    }

    bands = newBands;
    biquads.resize(bands.size());

    // Recalculate all coefficients
    for (size_t i = 0; i < bands.size(); i++) {
        if (bands[i].enabled) {
            calculateCoefficients(bands[i], biquads[i]);
        }
    }

    LOGD("Bands updated: %zu active", bands.size());
}

void AntiiQEQ::calculateCoefficients(const Band& band, BiquadState& state) {
    // Clamp parameters to safe ranges
    float freq = std::clamp(band.frequency, MIN_FREQUENCY,
                            std::min(MAX_FREQUENCY, sampleRate * 0.49f));
    float Q = std::clamp(band.Q, MIN_Q, MAX_Q);
    float gainDb = std::clamp(band.gainDb, MIN_GAIN_DB, MAX_GAIN_DB);

    // Precompute common values
    float w0 = 2.0f * PI * freq / sampleRate;
    float cosW0 = std::cos(w0);
    float sinW0 = std::sin(w0);
    float alpha = sinW0 / (2.0f * Q);
    float A = std::pow(10.0f, gainDb / 40.0f);  // sqrt of linear gain

    float a0, a1, a2, b0, b1, b2;

    switch (band.type) {
        case PEAK: {
            // Parametric peak/notch
            b0 = 1.0f + alpha * A;
            b1 = -2.0f * cosW0;
            b2 = 1.0f - alpha * A;
            a0 = 1.0f + alpha / A;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha / A;
            break;
        }

        case LOW_SHELF: {
            float sqrtA = std::sqrt(A);
            float beta = sqrtA / Q;

            b0 = A * ((A + 1.0f) - (A - 1.0f) * cosW0 + beta * sinW0);
            b1 = 2.0f * A * ((A - 1.0f) - (A + 1.0f) * cosW0);
            b2 = A * ((A + 1.0f) - (A - 1.0f) * cosW0 - beta * sinW0);
            a0 = (A + 1.0f) + (A - 1.0f) * cosW0 + beta * sinW0;
            a1 = -2.0f * ((A - 1.0f) + (A + 1.0f) * cosW0);
            a2 = (A + 1.0f) + (A - 1.0f) * cosW0 - beta * sinW0;
            break;
        }

        case HIGH_SHELF: {
            float sqrtA = std::sqrt(A);
            float beta = sqrtA / Q;

            b0 = A * ((A + 1.0f) + (A - 1.0f) * cosW0 + beta * sinW0);
            b1 = -2.0f * A * ((A - 1.0f) + (A + 1.0f) * cosW0);
            b2 = A * ((A + 1.0f) + (A - 1.0f) * cosW0 - beta * sinW0);
            a0 = (A + 1.0f) - (A - 1.0f) * cosW0 + beta * sinW0;
            a1 = 2.0f * ((A - 1.0f) - (A + 1.0f) * cosW0);
            a2 = (A + 1.0f) - (A - 1.0f) * cosW0 - beta * sinW0;
            break;
        }

        case LOW_PASS: {
            b0 = (1.0f - cosW0) / 2.0f;
            b1 = 1.0f - cosW0;
            b2 = (1.0f - cosW0) / 2.0f;
            a0 = 1.0f + alpha;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha;
            break;
        }

        case HIGH_PASS: {
            b0 = (1.0f + cosW0) / 2.0f;
            b1 = -(1.0f + cosW0);
            b2 = (1.0f + cosW0) / 2.0f;
            a0 = 1.0f + alpha;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha;
            break;
        }

        case BAND_PASS: {
            // Standard bandpass (no gain control)
            b0 = alpha;
            b1 = 0.0f;
            b2 = -alpha;
            a0 = 1.0f + alpha;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha;
            break;
        }

        case NOTCH: {
            b0 = 1.0f;
            b1 = -2.0f * cosW0;
            b2 = 1.0f;
            a0 = 1.0f + alpha;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha;
            break;
        }

        case ALL_PASS: {
            b0 = 1.0f - alpha;
            b1 = -2.0f * cosW0;
            b2 = 1.0f + alpha;
            a0 = 1.0f + alpha;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha;
            break;
        }

        default:
            // Bypass (unity gain)
            b0 = 1.0f; b1 = 0.0f; b2 = 0.0f;
            a0 = 1.0f; a1 = 0.0f; a2 = 0.0f;
    }

    // Safety check for numerical stability
    if (std::abs(a0) < 1e-10f) {
        LOGD("ERROR: Invalid filter coefficients (a0≈0), using bypass");
        state.b0 = 1.0f;
        state.b1 = 0.0f;
        state.b2 = 0.0f;
        state.a1 = 0.0f;
        state.a2 = 0.0f;
        return;
    }

    // Normalize by a0
    float invA0 = 1.0f / a0;
    state.b0 = b0 * invA0;
    state.b1 = b1 * invA0;
    state.b2 = b2 * invA0;
    state.a1 = a1 * invA0;
    state.a2 = a2 * invA0;
}

void AntiiQEQ::process(float* leftChannel, float* rightChannel, int numSamples) {
    if (!isEnabled || bands.empty()) {
        return;  // Bypass
    }

    // Process each enabled band sequentially (cascade)
    for (size_t bandIdx = 0; bandIdx < bands.size(); bandIdx++) {
        if (!bands[bandIdx].enabled) continue;

        BiquadState& bq = biquads[bandIdx];

        // Process all samples through this band
        for (int i = 0; i < numSamples; i++) {
            leftChannel[i] = bq.processSample(leftChannel[i], bq.z1_L, bq.z2_L);
            rightChannel[i] = bq.processSample(rightChannel[i], bq.z1_R, bq.z2_R);
        }
    }
}

void AntiiQEQ::processMono(float* channel, int numSamples) {
    if (!isEnabled || bands.empty()) {
        return;
    }

    for (size_t bandIdx = 0; bandIdx < bands.size(); bandIdx++) {
        if (!bands[bandIdx].enabled) continue;

        BiquadState& bq = biquads[bandIdx];

        for (int i = 0; i < numSamples; i++) {
            channel[i] = bq.processSample(channel[i], bq.z1_L, bq.z2_L);
        }
    }
}

void AntiiQEQ::processInterleaved(float* buffer, int numSamples, int channels) {
    if (!isEnabled || bands.empty() || channels < 1) {
        return;
    }

    // Process interleaved samples (L R L R...)
    for (size_t bandIdx = 0; bandIdx < bands.size(); bandIdx++) {
        if (!bands[bandIdx].enabled) continue;

        BiquadState& bq = biquads[bandIdx];

        if (channels == 2) {
            // Stereo interleaved
            for (int i = 0; i < numSamples * 2; i += 2) {
                buffer[i] = bq.processSample(buffer[i], bq.z1_L, bq.z2_L);       // Left
                buffer[i + 1] = bq.processSample(buffer[i + 1], bq.z1_R, bq.z2_R); // Right
            }
        } else {
            // Mono or multi-channel (treat as mono)
            for (int i = 0; i < numSamples * channels; i++) {
                buffer[i] = bq.processSample(buffer[i], bq.z1_L, bq.z2_L);
            }
        }
    }
}

void AntiiQEQ::reset() {
    for (auto& bq : biquads) {
        bq.clear();
    }
    LOGD("Filter state cleared");
}