#ifndef MP3_DURATION_H
#define MP3_DURATION_H

#include <cstdint>

extern "C" {
#include <libavformat/avformat.h>
}

/**
 * Get accurate duration for MP3 files with VBR headers
 * Falls back to standard FFmpeg duration for non-MP3 or files without VBR headers
 */
int64_t getAccurateDuration(AVFormatContext* formatCtx, int audioStreamIndex,
                            const char* filePath);

#endif // MP3_DURATION_H