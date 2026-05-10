#include <jni.h>
#include <android/log.h>
#include "AudioDuration.h"

#ifdef ANTIIQ_LITE_NO_FFMPEG

extern "C" JNIEXPORT jobject JNICALL
Java_com_coleblvck_antiiq_AudioMetadataPlugin_extractNativeMetadata(
        JNIEnv *,
        jobject,
        jstring) {
    return nullptr;
}

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_coleblvck_antiiq_AudioMetadataPlugin_extractNativeArtwork(
        JNIEnv *,
        jobject,
        jstring) {
    return nullptr;
}

#else

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libavutil/dict.h>
#include <libavutil/mathematics.h>
}

namespace {
constexpr const char *kLogTag = "AntiiqLite";

std::string clean(const char *value) {
    if (!value) return "";
    std::string text(value);
    auto first = std::find_if_not(text.begin(), text.end(), [](unsigned char c) {
        return std::isspace(c) != 0;
    });
    auto last = std::find_if_not(text.rbegin(), text.rend(), [](unsigned char c) {
        return std::isspace(c) != 0;
    }).base();
    if (first >= last) return "";
    return std::string(first, last);
}

std::string tag(AVDictionary *metadata, const std::vector<const char *> &keys) {
    for (const auto *key : keys) {
        AVDictionaryEntry *entry = av_dict_get(metadata, key, nullptr, AV_DICT_MATCH_CASE);
        if (!entry) entry = av_dict_get(metadata, key, nullptr, 0);
        std::string value = clean(entry ? entry->value : nullptr);
        if (!value.empty()) return value;
    }
    return "";
}

std::string read_tag(AVFormatContext *format, int stream_index, const std::vector<const char *> &keys) {
    if (stream_index >= 0 && format->streams[stream_index]) {
        std::string value = tag(format->streams[stream_index]->metadata, keys);
        if (!value.empty()) return value;
    }
    return tag(format->metadata, keys);
}

int parse_number(const std::string &value) {
    if (value.empty()) return 0;
    const auto slash = value.find('/');
    const std::string head = value.substr(0, slash);
    char *end = nullptr;
    long parsed = std::strtol(head.c_str(), &end, 10);
    if (end == head.c_str()) return 0;
    return static_cast<int>(parsed);
}

int parse_year(const std::string &value) {
    if (value.empty()) return 0;
    for (size_t i = 0; i + 3 < value.size(); ++i) {
        if (std::isdigit(static_cast<unsigned char>(value[i])) &&
            std::isdigit(static_cast<unsigned char>(value[i + 1])) &&
            std::isdigit(static_cast<unsigned char>(value[i + 2])) &&
            std::isdigit(static_cast<unsigned char>(value[i + 3]))) {
            return std::atoi(value.substr(i, 4).c_str());
        }
    }
    return 0;
}

int64_t duration_ms(AVFormatContext *format, int stream_index, const char *file_path) {
    if (!format || stream_index < 0) return 0;
    return getAccurateDuration(format, stream_index, file_path);
}

std::string codec_mime(AVCodecID codec_id) {
    switch (codec_id) {
        case AV_CODEC_ID_MP3: return "audio/mpeg";
        case AV_CODEC_ID_AAC: return "audio/aac";
        case AV_CODEC_ID_FLAC: return "audio/flac";
        case AV_CODEC_ID_OPUS: return "audio/opus";
        case AV_CODEC_ID_VORBIS: return "audio/ogg";
        case AV_CODEC_ID_WAVPACK: return "audio/x-wavpack";
        case AV_CODEC_ID_APE: return "audio/x-ape";
        case AV_CODEC_ID_WMAV1:
        case AV_CODEC_ID_WMAV2:
        case AV_CODEC_ID_WMAPRO:
        case AV_CODEC_ID_WMALOSSLESS:
            return "audio/x-ms-wma";
        case AV_CODEC_ID_PCM_S16LE:
        case AV_CODEC_ID_PCM_S24LE:
        case AV_CODEC_ID_PCM_F32LE:
            return "audio/wav";
        default:
            return "";
    }
}

void put_string(JNIEnv *env, jobject map, jmethodID put, const char *key, const std::string &value) {
    if (value.empty()) return;
    jstring j_key = env->NewStringUTF(key);
    jstring j_value = env->NewStringUTF(value.c_str());
    env->CallObjectMethod(map, put, j_key, j_value);
    env->DeleteLocalRef(j_key);
    env->DeleteLocalRef(j_value);
}

void put_long(JNIEnv *env, jobject map, jmethodID put, const char *key, int64_t value) {
    jclass long_class = env->FindClass("java/lang/Long");
    jmethodID long_ctor = env->GetMethodID(long_class, "<init>", "(J)V");
    jobject boxed = env->NewObject(long_class, long_ctor, static_cast<jlong>(value));
    jstring j_key = env->NewStringUTF(key);
    env->CallObjectMethod(map, put, j_key, boxed);
    env->DeleteLocalRef(j_key);
    env->DeleteLocalRef(boxed);
    env->DeleteLocalRef(long_class);
}

void put_int(JNIEnv *env, jobject map, jmethodID put, const char *key, int value) {
    if (value == 0) return;
    jclass int_class = env->FindClass("java/lang/Integer");
    jmethodID int_ctor = env->GetMethodID(int_class, "<init>", "(I)V");
    jobject boxed = env->NewObject(int_class, int_ctor, static_cast<jint>(value));
    jstring j_key = env->NewStringUTF(key);
    env->CallObjectMethod(map, put, j_key, boxed);
    env->DeleteLocalRef(j_key);
    env->DeleteLocalRef(boxed);
    env->DeleteLocalRef(int_class);
}

jobject new_hash_map(JNIEnv *env) {
    jclass map_class = env->FindClass("java/util/HashMap");
    jmethodID ctor = env->GetMethodID(map_class, "<init>", "()V");
    jobject map = env->NewObject(map_class, ctor);
    env->DeleteLocalRef(map_class);
    return map;
}

jmethodID hash_map_put(JNIEnv *env, jobject map) {
    jclass map_class = env->GetObjectClass(map);
    jmethodID put = env->GetMethodID(map_class, "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
    env->DeleteLocalRef(map_class);
    return put;
}
}

extern "C" JNIEXPORT jobject JNICALL
Java_com_coleblvck_antiiq_AudioMetadataPlugin_extractNativeMetadata(
        JNIEnv *env,
        jobject,
        jstring path_) {
    const char *path_chars = env->GetStringUTFChars(path_, nullptr);
    if (!path_chars) return nullptr;
    std::string path(path_chars);
    env->ReleaseStringUTFChars(path_, path_chars);

    AVFormatContext *format = nullptr;
    if (avformat_open_input(&format, path.c_str(), nullptr, nullptr) < 0) {
        return nullptr;
    }
    if (avformat_find_stream_info(format, nullptr) < 0) {
        avformat_close_input(&format);
        return nullptr;
    }

    int audio_stream = av_find_best_stream(format, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    if (audio_stream < 0) {
        avformat_close_input(&format);
        return nullptr;
    }

    jobject map = new_hash_map(env);
    jmethodID put = hash_map_put(env, map);

    AVCodecParameters *codec = format->streams[audio_stream]->codecpar;
    put_string(env, map, put, "title", read_tag(format, audio_stream, {"title", "TITLE"}));
    put_string(env, map, put, "artist", read_tag(format, audio_stream, {"artist", "ARTIST", "album_artist"}));
    put_string(env, map, put, "album", read_tag(format, audio_stream, {"album", "ALBUM"}));
    put_string(env, map, put, "albumArtist", read_tag(format, audio_stream, {"album_artist", "ALBUMARTIST", "albumartist"}));
    put_string(env, map, put, "genre", read_tag(format, audio_stream, {"genre", "GENRE"}));
    put_int(env, map, put, "year", parse_year(read_tag(format, audio_stream, {"date", "DATE", "year", "YEAR"})));
    put_int(env, map, put, "trackNumber", parse_number(read_tag(format, audio_stream, {"track", "TRACK", "tracknumber", "TRACKNUMBER"})));
    put_string(env, map, put, "composer", read_tag(format, audio_stream, {"composer", "COMPOSER"}));
    put_string(env, map, put, "writer", read_tag(format, audio_stream, {"writer", "WRITER", "lyricist", "LYRICIST"}));
    put_long(env, map, put, "duration", duration_ms(format, audio_stream, path.c_str()));
    if (codec && codec->bit_rate > 0) {
        put_int(env, map, put, "bitrate", static_cast<int>(codec->bit_rate));
    } else if (format->bit_rate > 0) {
        put_int(env, map, put, "bitrate", static_cast<int>(format->bit_rate));
    }
    if (codec) {
        put_string(env, map, put, "mimeType", codec_mime(codec->codec_id));
    }

    avformat_close_input(&format);
    return map;
}

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_coleblvck_antiiq_AudioMetadataPlugin_extractNativeArtwork(
        JNIEnv *env,
        jobject,
        jstring path_) {
    const char *path_chars = env->GetStringUTFChars(path_, nullptr);
    if (!path_chars) return nullptr;
    std::string path(path_chars);
    env->ReleaseStringUTFChars(path_, path_chars);

    AVFormatContext *format = nullptr;
    if (avformat_open_input(&format, path.c_str(), nullptr, nullptr) < 0) {
        return nullptr;
    }
    if (avformat_find_stream_info(format, nullptr) < 0) {
        avformat_close_input(&format);
        return nullptr;
    }

    for (unsigned int i = 0; i < format->nb_streams; ++i) {
        AVStream *stream = format->streams[i];
        if (!stream || !stream->codecpar) continue;
        if (stream->codecpar->codec_type != AVMEDIA_TYPE_VIDEO) continue;
        if (!(stream->disposition & AV_DISPOSITION_ATTACHED_PIC)) continue;

        AVPacket *packet = &stream->attached_pic;
        if (!packet || !packet->data || packet->size <= 0) continue;

        jbyteArray bytes = env->NewByteArray(packet->size);
        env->SetByteArrayRegion(bytes, 0, packet->size, reinterpret_cast<jbyte *>(packet->data));
        avformat_close_input(&format);
        return bytes;
    }

    avformat_close_input(&format);
    return nullptr;
}

#endif
