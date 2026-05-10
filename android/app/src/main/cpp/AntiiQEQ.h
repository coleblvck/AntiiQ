//
// Created by blvck on 16/11/2025.
//

#ifndef ANTIIQ_CORE_ANTIIQEQ_H
#define ANTIIQ_CORE_ANTIIQEQ_H

#include <vector>
#include <cmath>
#include <algorithm>

/**
 * High-performance parametric EQ using biquad filters (RBJ Audio EQ Cookbook)
 * Direct Form II implementation for minimal latency and CPU usage
 *
 * Performance: ~5 multiplies + 5 adds per sample per band
 * Quality: Professional-grade, no "roughness" from anequalizer
 */
class AntiiQEQ {
public:
    // Filter types matching industry standards
    enum FilterType {
        PEAK = 0,        // Parametric peak/notch (most common for EQ)
        LOW_SHELF = 1,   // Bass shelf
        HIGH_SHELF = 2,  // Treble shelf
        LOW_PASS = 3,    // Low-pass filter
        HIGH_PASS = 4,   // High-pass filter
        BAND_PASS = 5,   // Band-pass filter
        NOTCH = 6,       // Notch filter
        ALL_PASS = 7     // All-pass filter (phase shift)
    };

    // Band configuration (sent from Kotlin in batch)
    struct Band {
        float frequency;    // Center frequency in Hz
        float gainDb;       // Gain in dB (for peak/shelf types)
        float Q;            // Q factor (bandwidth control)
        FilterType type;    // Filter type
        bool enabled;       // Individual band bypass

        Band() : frequency(1000.0f), gainDb(0.0f), Q(1.0f),
                 type(PEAK), enabled(true) {}
    };

    AntiiQEQ();
    ~AntiiQEQ() = default;

    // Configuration (call once when bands change)
    void configure(int sampleRate, int channels);
    void setBands(const std::vector<Band>& bands);
    void setEnabled(bool enabled) { isEnabled = enabled; }
    bool getEnabled() const { return isEnabled; }

    // Processing (call per audio frame)
    void process(float* leftChannel, float* rightChannel, int numSamples);
    void processMono(float* channel, int numSamples);
    void processInterleaved(float* buffer, int numSamples, int channels);

    // Utilities
    void reset();  // Clear filter state (use after seek/format change)
    int getBandCount() const { return bands.size(); }
    const std::vector<Band>& getBands() const { return bands; }

    // Access to constants (for UI/validation)
    static constexpr float getMinFrequency() { return MIN_FREQUENCY; }
    static constexpr float getMaxFrequency() { return MAX_FREQUENCY; }
    static constexpr float getMinQ() { return MIN_Q; }
    static constexpr float getMaxQ() { return MAX_Q; }
    static constexpr float getMinGainDb() { return MIN_GAIN_DB; }
    static constexpr float getMaxGainDb() { return MAX_GAIN_DB; }

private:
    // Biquad filter state (Direct Form II)
    struct BiquadState {
        // Coefficients (calculated once per band change)
        float b0, b1, b2;  // Numerator
        float a1, a2;      // Denominator (a0 normalized to 1.0)

        // State variables (per channel)
        float z1_L, z2_L;  // Left channel delay line
        float z1_R, z2_R;  // Right channel delay line

        BiquadState() : b0(1), b1(0), b2(0), a1(0), a2(0),
                        z1_L(0), z2_L(0), z1_R(0), z2_R(0) {}

        // Process single sample (Direct Form II - most efficient)
        inline float processSample(float input, float& z1, float& z2) {
            float output = b0 * input + z1;
            z1 = b1 * input - a1 * output + z2;
            z2 = b2 * input - a2 * output;

            // Denormal protection (critical for mobile)
            constexpr float DENORMAL_THRESHOLD = 1e-15f;
            if (std::abs(z1) < DENORMAL_THRESHOLD) z1 = 0.0f;
            if (std::abs(z2) < DENORMAL_THRESHOLD) z2 = 0.0f;

            return output;
        }

        void clear() {
            z1_L = z2_L = z1_R = z2_R = 0.0f;
        }
    };

    // RBJ Audio EQ Cookbook coefficient calculation
    void calculateCoefficients(const Band& band, BiquadState& state);

    // Member variables
    std::vector<Band> bands;
    std::vector<BiquadState> biquads;
    int sampleRate;
    int numChannels;
    bool isEnabled;
    bool needsRecalc;

    // Constants (extracted for easy access)
    static constexpr float PI = 3.14159265358979323846f;
    static constexpr float MIN_FREQUENCY = 20.0f;
    static constexpr float MAX_FREQUENCY = 20000.0f;
    static constexpr float MIN_Q = 0.1f;
    static constexpr float MAX_Q = 18.0f;
    static constexpr float MIN_GAIN_DB = -24.0f;
    static constexpr float MAX_GAIN_DB = 24.0f;
};

#endif //ANTIIQ_CORE_ANTIIQEQ_H
