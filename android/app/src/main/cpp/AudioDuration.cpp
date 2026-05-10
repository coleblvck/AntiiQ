#include "AudioDuration.h"
#include <cstring>
#include <cstdio>
#include <cstdlib>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
}

struct MP3FrameHeader {
    int version;
    int layer;
    int bitrate;
    int sampleRate;
    int frameSize;
    int samplesPerFrame;
};

static bool parseMP3FrameHeader(const uint8_t* data, MP3FrameHeader* header) {
    if (data[0] != 0xFF || (data[1] & 0xE0) != 0xE0) {
        return false;
    }

    int version = (data[1] >> 3) & 0x03;
    if (version == 0x01) return false;

    int layer = (data[1] >> 1) & 0x03;
    if (layer == 0x00) return false;

    int bitrateIndex = (data[2] >> 4) & 0x0F;
    if (bitrateIndex == 0x0F || bitrateIndex == 0x00) return false;

    int sampleRateIndex = (data[2] >> 2) & 0x03;
    if (sampleRateIndex == 0x03) return false;

    int padding = (data[2] >> 1) & 0x01;

    static const int versions[] = {2, 0, 2, 1};
    header->version = versions[version];

    static const int layers[] = {0, 3, 2, 1};
    header->layer = layers[layer];

    static const int bitrates[2][16] = {
            {0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0},
            {0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0}
    };
    int brTable = (header->version == 1) ? 0 : 1;
    header->bitrate = bitrates[brTable][bitrateIndex] * 1000;

    static const int sampleRates[3][4] = {
            {44100, 48000, 32000, 0},
            {22050, 24000, 16000, 0},
            {11025, 12000, 8000, 0}
    };
    int srTable = (header->version == 1) ? 0 : (header->version == 2) ? 1 : 2;
    header->sampleRate = sampleRates[srTable][sampleRateIndex];

    if (header->layer == 3) {
        header->samplesPerFrame = (header->version == 1) ? 1152 : 576;
        header->frameSize = (header->samplesPerFrame / 8 * header->bitrate) /
                            header->sampleRate + padding;
    } else {
        return false;
    }

    return true;
}

static uint32_t parseXingHeader(const uint8_t* data, size_t size) {
    MP3FrameHeader frameHeader;
    if (!parseMP3FrameHeader(data, &frameHeader)) {
        return 0;
    }

    int xingOffset = (frameHeader.version == 1) ? 36 : 21;
    if (xingOffset + 8 > size) return 0;

    const uint8_t* xingData = data + xingOffset;

    if (memcmp(xingData, "Xing", 4) != 0 && memcmp(xingData, "Info", 4) != 0) {
        return 0;
    }

    uint32_t flags = (xingData[4] << 24) | (xingData[5] << 16) |
                     (xingData[6] << 8) | xingData[7];

    if (flags & 0x0001) {
        uint32_t frames = (xingData[8] << 24) | (xingData[9] << 16) |
                          (xingData[10] << 8) | xingData[11];
        return frames;
    }

    return 0;
}

static uint32_t parseVBRIHeader(const uint8_t* data, size_t size) {
    if (size < 36 + 32) return 0;

    const uint8_t* vbriData = data + 36;

    if (memcmp(vbriData, "VBRI", 4) != 0) {
        return 0;
    }

    uint32_t frames = (vbriData[14] << 24) | (vbriData[15] << 16) |
                      (vbriData[16] << 8) | vbriData[17];
    return frames;
}

static int64_t getMP3DurationFromVBRHeader(const char* filePath) {
    FILE* file = fopen(filePath, "rb");
    if (!file) {
        return 0;
    }

    uint8_t id3Header[10];
    if (fread(id3Header, 1, 10, file) != 10) {
        fclose(file);
        return 0;
    }

    size_t audioDataOffset = 0;

    if (memcmp(id3Header, "ID3", 3) == 0) {
        uint32_t id3Size = ((id3Header[6] & 0x7F) << 21) |
                           ((id3Header[7] & 0x7F) << 14) |
                           ((id3Header[8] & 0x7F) << 7) |
                           (id3Header[9] & 0x7F);

        audioDataOffset = 10 + id3Size;

        if (fseek(file, audioDataOffset, SEEK_SET) != 0) {
            fclose(file);
            return 0;
        }
    } else {
        fseek(file, 0, SEEK_SET);
    }

    uint8_t buffer[200];
    size_t bytesRead = fread(buffer, 1, sizeof(buffer), file);
    fclose(file);

    if (bytesRead < 40) {
        return 0;
    }

    MP3FrameHeader frameHeader;
    if (!parseMP3FrameHeader(buffer, &frameHeader)) {
        return 0;
    }

    uint32_t frames = parseXingHeader(buffer, bytesRead);

    if (frames == 0) {
        frames = parseVBRIHeader(buffer, bytesRead);
    }

    if (frames == 0) {
        return 0;
    }

    int64_t duration = ((int64_t)frames * frameHeader.samplesPerFrame * 1000) /
                       frameHeader.sampleRate;

    return duration;
}

int64_t getAccurateDuration(AVFormatContext* formatCtx, int audioStreamIndex,
                            const char* filePath) {
    AVStream* audioStream = formatCtx->streams[audioStreamIndex];

    int64_t ffmpegDuration = 0;
    if (formatCtx->duration != AV_NOPTS_VALUE) {
        ffmpegDuration = formatCtx->duration / 1000;
    } else if (audioStream->duration != AV_NOPTS_VALUE) {
        ffmpegDuration = av_rescale_q(audioStream->duration, audioStream->time_base,
                                      AVRational{1, 1000});
    }

    if (audioStream->codecpar->codec_id == AV_CODEC_ID_MP3) {
        int64_t vbrDuration = getMP3DurationFromVBRHeader(filePath);

        if (vbrDuration > 0) {
            int64_t diff = llabs(vbrDuration - ffmpegDuration);
            int64_t percentDiff = ffmpegDuration > 0 ? (diff * 100) / ffmpegDuration : 0;

            if (percentDiff > 5) {
                return vbrDuration;
            }
        }
    }

    return ffmpegDuration;
}