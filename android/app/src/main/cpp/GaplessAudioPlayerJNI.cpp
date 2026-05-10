#include "GaplessAudioPlayerJNI.h"
#include "GaplessAudioPlayer.h"

extern "C" {

// ==================== LIFECYCLE ====================

JNIEXPORT jlong JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeCreate(
        JNIEnv* env, jobject thiz) {
    GaplessAudioPlayer* player = new GaplessAudioPlayer();
    return reinterpret_cast<jlong>(player);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeRelease(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return;
    GaplessAudioPlayer* player = reinterpret_cast<GaplessAudioPlayer*>(handle);
    delete player;
}

// ==================== PLAYBACK CONTROL ====================

JNIEXPORT jint JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeOpen(
        JNIEnv* env, jobject thiz, jlong handle, jstring filePath, jstring trackId,
        jobject audioCallback, jobject lifecycleCallback) {

    if (handle == 0) return -1;

    GaplessAudioPlayer* player = reinterpret_cast<GaplessAudioPlayer*>(handle);
    const char* path = env->GetStringUTFChars(filePath, nullptr);
    const char* id = env->GetStringUTFChars(trackId, nullptr);

    JavaVM* vm;
    env->GetJavaVM(&vm);

    int result = player->open(path, id, vm, audioCallback, lifecycleCallback);

    env->ReleaseStringUTFChars(filePath, path);
    env->ReleaseStringUTFChars(trackId, id);
    return result;
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeClose(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->close();
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeStart(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->start();
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativePause(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->pause();
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeStop(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->stop();
}

// ==================== SEEKING & STATE ====================

JNIEXPORT jboolean JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeIsDecoderInitialized(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return false;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->isDecoderInitialized();
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSeek(
        JNIEnv* env, jobject thiz, jlong handle, jlong positionMs) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->seekTo(positionMs);
}

JNIEXPORT jlong JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetDuration(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 0;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getDuration();
}

JNIEXPORT jlong JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetPosition(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 0;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getCurrentPosition();
}

JNIEXPORT jboolean JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeIsPlaying(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return false;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->isPlayingState();
}

JNIEXPORT jint JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetSampleRate(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 0;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getSampleRate();
}

JNIEXPORT jint JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetChannels(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 0;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getChannels();
}

// ==================== GAPLESS & CROSSFADE ====================

JNIEXPORT jboolean JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeIsGaplessEnabled(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return false;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->isGaplessEnabled();
}

JNIEXPORT jboolean JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeIsCrossfadeEnabled(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return false;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->isCrossfadeEnabled();
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetGaplessEnabled(
        JNIEnv* env, jobject thiz, jlong handle, jboolean enabled) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setGaplessEnabled(enabled);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeCancelGaplessPreparation(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->cancelGaplessPreparation();
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetCrossfadeEnabled(
        JNIEnv* env, jobject thiz, jlong handle, jboolean enabled) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setCrossfadeEnabled(enabled);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetCrossfadeDuration(
        JNIEnv* env, jobject thiz, jlong handle, jint durationMs) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setCrossfadeDuration(durationMs);
}

JNIEXPORT jint JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetCrossfadeDuration(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 0;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getCrossfadeDuration();
}

// ==================== AUDIO EFFECTS ====================

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetEffectsEnabled(
        JNIEnv* env, jobject thiz, jlong handle, jboolean enabled) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setEffectsEnabled(enabled);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetEqualizerBand(
        JNIEnv* env, jobject thiz, jlong handle, jint band, jfloat gainDb) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setEqualizerBand(band, gainDb);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetEqualizerBandWidth(
        JNIEnv* env, jobject thiz, jlong handle, jint band, jfloat widthHz) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setEqualizerBandWidth(band, widthHz);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetEqualizerBandEnabled(
        JNIEnv* env, jobject thiz, jlong handle, jint band, jboolean enabled) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setEqualizerBandEnabled(band, enabled);
}

JNIEXPORT jint JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetEqualizerBandCount(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 0;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getEqualizerBandCount();
}

// ==================== TEMPO & PITCH ====================

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetTempo(
        JNIEnv* env, jobject thiz, jlong handle, jfloat rate) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setTempo(rate);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetPitchSemitones(
        JNIEnv* env, jobject thiz, jlong handle, jfloat semitones) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setPitchSemitones(semitones);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetPitchRate(
        JNIEnv* env, jobject thiz, jlong handle, jfloat rate) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setPitchRate(rate);
}

JNIEXPORT jfloat JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetTempo(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 1.0f;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getTempo();
}

JNIEXPORT jfloat JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetPitchSemitones(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 0.0f;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getPitchSemitones();
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetVolume(
        JNIEnv* env, jobject thiz, jlong handle, jfloat volume) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setVolume(volume);
}

JNIEXPORT jfloat JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetVolume(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 1.0f;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getVolume();
}

JNIEXPORT jboolean JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeIsPreparingGapless(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return false;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->isTransitioningOrPreparing();
}

// AntiiQ EQ Control
JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetAntiiQEQEnabled(
        JNIEnv* env, jobject thiz, jlong handle, jboolean enabled) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setAntiiQEQEnabled(enabled);
}

JNIEXPORT jboolean JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeIsAntiiQEQEnabled(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return false;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->isAntiiQEQEnabled();
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetAntiiQEQBands(
        JNIEnv* env, jobject thiz, jlong handle, jobjectArray bandArray) {

    if (handle == 0 || bandArray == nullptr) return;

    GaplessAudioPlayer* player = reinterpret_cast<GaplessAudioPlayer*>(handle);

    jsize bandCount = env->GetArrayLength(bandArray);

    // Cache class and field IDs (do this once for performance)
    static jclass bandClass = nullptr;
    static jfieldID freqField = nullptr;
    static jfieldID gainField = nullptr;
    static jfieldID qField = nullptr;
    static jfieldID typeField = nullptr;
    static jfieldID enabledField = nullptr;

    if (bandClass == nullptr) {
        // Get AntiiQBand class
        jclass localClass = env->FindClass("com/coleblvck/antiiq/playback/AntiiQBand");
        if (!localClass) {
            LOGE("Failed to find AntiiQBand class");
            return;
        }
        bandClass = (jclass)env->NewGlobalRef(localClass);
        env->DeleteLocalRef(localClass);

        // Cache field IDs
        freqField = env->GetFieldID(bandClass, "frequency", "F");
        gainField = env->GetFieldID(bandClass, "gainDb", "F");
        qField = env->GetFieldID(bandClass, "Q", "F");
        typeField = env->GetFieldID(bandClass, "type", "I");
        enabledField = env->GetFieldID(bandClass, "enabled", "Z");

        if (!freqField || !gainField || !qField || !typeField || !enabledField) {
            LOGE("Failed to get AntiiQBand field IDs");
            return;
        }
    }

    // Build band vector from jobjectArray
    std::vector<AntiiQEQ::Band> bands;
    bands.reserve(bandCount);

    for (int i = 0; i < bandCount; i++) {
        jobject bandObj = env->GetObjectArrayElement(bandArray, i);
        if (!bandObj) continue;

        AntiiQEQ::Band band;
        band.frequency = env->GetFloatField(bandObj, freqField);
        band.gainDb = env->GetFloatField(bandObj, gainField);
        band.Q = env->GetFloatField(bandObj, qField);
        band.type = static_cast<AntiiQEQ::FilterType>(env->GetIntField(bandObj, typeField));
        band.enabled = env->GetBooleanField(bandObj, enabledField);

        bands.push_back(band);
        env->DeleteLocalRef(bandObj);
    }

    player->setAntiiQEQBands(bands);
}

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeResetAntiiQEQ(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->resetAntiiQEQ();
}

JNIEXPORT jint JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeGetAntiiQEQBandCount(
        JNIEnv* env, jobject thiz, jlong handle) {
    if (handle == 0) return 0;
    return reinterpret_cast<GaplessAudioPlayer*>(handle)->getAntiiQEQBandCount();
}

// ==================== AUDIO OUTPUT CONTROL ====================

JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeSetAudioCompatibilityMode(
        JNIEnv* env, jobject thiz, jlong handle, jboolean enabled) {
    if (handle == 0) return;
    reinterpret_cast<GaplessAudioPlayer*>(handle)->setAudioCompatibilityMode(enabled);
}

} // extern "C"
