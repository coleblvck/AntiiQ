#include <jni.h>

extern "C" JNIEXPORT jlong JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeCreate(JNIEnv*, jobject) { return 0; }

extern "C" JNIEXPORT void JNICALL
Java_com_coleblvck_antiiq_playback_GaplessAudioPlayer_nativeRelease(JNIEnv*, jobject, jlong) {}
