//
//  SYWavHeader.h
//  SYOpenALPlayer
//
//  Created by shenyuanluo on 2017/12/30.
//  Copyright © 2017年 http://blog.shenyuanluo.com/ All rights reserved.
//

#ifndef SYWavParser_h
#define SYWavParser_h

typedef unsigned int uInt32;
typedef unsigned short uInt16;

// 除说明外，其他都是 小端模式
typedef struct __riff {
    char riffChunkID[4];        // 固定标识 'RIFF' （大端模式）
    uInt32 fileSize;            // 文件大小（除掉标志'RIFF' + 这个整数本身）
    char format[4];             // 固定标识 'WAVE' （大端模式）
}RIFF;


typedef struct __fmt {
    char fmtChunkID[4];         // 固定标识 'fmt ' （大端模式）
    uInt32 fmtChunkSize;        // fmt 区块大小（除掉标志'fmt ' + 这个整数本身）
    uInt16 audioFormat;         // 格式类型(pcm = 1)
    uInt16 numChannels;         // 声道数（Mono = 1, Stereo = 2）
    uInt32 sampleRate;          // 采样率（48000, 44100）
    uInt32 byteRate;            // 每秒播放字节数（码率/8） = sampleRate * numChannels * bitsPerSample/8
    uInt16 blockAlign;          // DATA数据块单位（单位采样）长度 = numChannels * bitsPerSample/8
    uInt16 bitsPerSample;       // PCM位深 - 用来存储采样点y值所使用的二进制位个数（8 bits, 16 bits, 24 bits）
}FMTChunk;


typedef struct __data {
    char dataChunkID[4];        // 固定标识'data'（大端模式）
    uInt32 dataChunkSize;       // 数据部分总长度 区块大小（除掉标志'data' + 这个整数本身）
}DATAChunk;


typedef struct __wav {
    RIFF riff;                  // riff 块
    FMTChunk fmt;               // fmt  块
    DATAChunk data;             // data 块
}WAVHead;

#endif /* SYWavParser_h */
