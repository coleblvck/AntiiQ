cmake_minimum_required(VERSION 3.22.1)
project("antiiq-lite")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(${CMAKE_SOURCE_DIR}/include)

add_library(antiiq-lite SHARED
        AntiiqLiteMetadata.cpp)

if (${ANDROID_ABI} STREQUAL "arm64-v8a" OR ${ANDROID_ABI} STREQUAL "armeabi-v7a")
    add_library(audio-duration STATIC
            AudioDuration.cpp)

    add_library(audio-effects STATIC
            AntiiQEQ.cpp
            AudioPipeline.cpp
            NativeEffectsChain.cpp)

    add_library(native-audio-player SHARED
            GaplessAudioPlayer.cpp
            GaplessAudioPlayerJNI.cpp)

    add_library(avutil SHARED IMPORTED)
    set_target_properties(avutil PROPERTIES IMPORTED_LOCATION
            ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libavutil.so)

    add_library(swresample SHARED IMPORTED)
    set_target_properties(swresample PROPERTIES IMPORTED_LOCATION
            ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libswresample.so)

    add_library(avcodec SHARED IMPORTED)
    set_target_properties(avcodec PROPERTIES IMPORTED_LOCATION
            ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libavcodec.so)

    add_library(avformat SHARED IMPORTED)
    set_target_properties(avformat PROPERTIES IMPORTED_LOCATION
            ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libavformat.so)

    add_library(SoundTouch SHARED IMPORTED)
    set_target_properties(SoundTouch PROPERTIES IMPORTED_LOCATION
            ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libSoundTouch.so)

    target_link_libraries(antiiq-lite
            audio-duration
            android
            log
            avformat
            avcodec
            avutil
            swresample
            SoundTouch)

    target_link_libraries(audio-duration
            avformat
            avcodec
            avutil)

    target_link_libraries(audio-effects
            avformat
            avcodec
            avutil
            swresample
            SoundTouch
            log)

    target_link_libraries(native-audio-player
            audio-duration
            audio-effects
            android
            log
            avformat
            avcodec
            avutil
            swresample
            SoundTouch)
else()
    add_library(native-audio-player SHARED
            NativeAudioPlayerStub.cpp)

    target_compile_definitions(antiiq-lite PRIVATE ANTIIQ_LITE_NO_FFMPEG=1)
    target_link_libraries(antiiq-lite
            android
            log)
    target_link_libraries(native-audio-player
            android
            log)
endif()

target_link_options(antiiq-lite PRIVATE
        "-Wl,-z,max-page-size=16384")

target_link_options(native-audio-player PRIVATE
        "-Wl,-z,max-page-size=16384")
