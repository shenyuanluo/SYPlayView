//
//  SYOpenALPlayer.cpp
//  SYOpenALPlayer
//
//  Created by shenyuanluo on 2017/12/30.
//  Copyright © 2017年 http://blog.shenyuanluo.com/ All rights reserved.
//

#include "SYOpenALPlayer.h"


#pragma mark - Private
#pragma mark -- 更新 OpenAL 缓存
void SYOpenALPlayer::RefreshQueueBuffer()
{
    ALint processedNum = NumOfBuffProcessed();
    while (processedNum--)
    {
        ALuint buffID;
        alSourceUnqueueBuffers(m_sourceID, 1, &buffID);
        alDeleteBuffers(1, &buffID);
    }
}


#pragma mark -- 检出 OpenAL 状态
ALenum SYOpenALPlayer::CheckALError()
{
    ALenum errState = AL_NO_ERROR;
    errState = alGetError();
    switch (errState)
    {
        case AL_NO_ERROR:
            std::cout << "AL_NO_ERROR" << std::endl;
            break;
            
        case AL_INVALID_NAME:
            std::cout << "AL_INVALID_NAME : Invalid Name paramater passed to AL call" << std::endl;
            break;
            
        case AL_INVALID_ENUM:
            std::cout << "AL_INVALID_ENUM : Invalid parameter passed to AL call" << std::endl;
            break;
            
        case AL_INVALID_VALUE:
            std::cout << "AL_INVALID_VALUE : Invalid enum parameter value" << std::endl;
            break;
            
        case AL_INVALID_OPERATION:
            std::cout << "AL_INVALID_OPERATION : Illegal call" << std::endl;
            break;
            
        case AL_OUT_OF_MEMORY:
            std::cout << "AL_OUT_OF_MEMORY : No mojo" << std::endl;
            break;
            
        default:
            std::cout << "Unknown error code" << std::endl;
            break;
    }
    return errState;
}


#pragma mark - Public
#pragma mark -- 构造函数
SYOpenALPlayer::SYOpenALPlayer()
{
    m_fillBufLen  = 0;
    m_totalBufLen = BUFF_NUM * BUFF_SIZE;
    m_initBuf     = (ALubyte*)malloc(m_totalBufLen);
    
    InitOpenAL();
}


#pragma mark -- 析构函数
SYOpenALPlayer::~SYOpenALPlayer()
{
    ClearOpenAL();
}


#pragma mark -- 初始化 OpenAL
bool SYOpenALPlayer::InitOpenAL()
{
    m_device  = alcOpenDevice(NULL);     // 参数为 NULL, 让 ALC 使用默认设备
    m_context = alcCreateContext(m_device, NULL);
    alcMakeContextCurrent(m_context);   // 设置当前上下文
    
    alGenSources(1, &m_sourceID);       // 初始化音源 ID
    
    return true;
}


#pragma mark -- 配置 OpenAL
bool SYOpenALPlayer::ConfigOpenAL(ALuint channels, ALuint bits, ALuint frequency)
{
    ALenum format;
    if (8 == bits)
    {
        if (1 == channels)
        {
            format = AL_FORMAT_MONO8;   // 单声道 8 bit
        }
        else if (2 == channels)
        {
            format = AL_FORMAT_STEREO8; // 立体声（双声道） 8 bit
        }
        else
        {
            format = 0;
        }
    }
    else if (16 == bits)
    {
        if (1 == channels)
        {
            format = AL_FORMAT_MONO16;  // 单声道 16 bit
        }
        else if (2 == channels)
        {
            format = AL_FORMAT_STEREO16;    // 立体声（双声道） 16 bit
        }
        else
        {
            format = 0;
        }
    }
    else
    {
        format = 0;
    }
    if (0 == format)
    {
        std::cout << "Incompatible format : channels = " << channels << "bits = " << bits << std::endl;
        return false;
    }
    m_format    = format;
    m_frequency = frequency;
    return true;
}


#pragma mark -- 设置是否循环播放
void SYOpenALPlayer::SetLoop(ALint isLoop)
{
    alSourcei(m_sourceID, AL_LOOPING, isLoop);
}


#pragma mark -- 设置音量大小
void SYOpenALPlayer::SetVolume(ALfloat volume)
{
    alSourcef(m_sourceID, AL_GAIN, volume);
}


#pragma mark -- 设置播放速度
void SYOpenALPlayer::SetSpeed(ALfloat speed)
{
    alSpeedOfSound(speed);
}


#pragma mark -- 获取 OpenAL 已经处理（播放）完毕的缓冲个数
ALint SYOpenALPlayer::NumOfBuffProcessed()
{
    ALint bufNum;
    alGetSourcei(m_sourceID, AL_BUFFERS_PROCESSED, &bufNum);
    return bufNum;
}


#pragma mark -- 获取音源状态
ALSourceState SYOpenALPlayer::SourceState()
{
    ALint val;
    ALSourceState state;
    alGetSourcei(m_sourceID, AL_SOURCE_STATE, &val);
    switch (val)
    {
        case AL_INITIAL:
            state = alSource_initial;
            break;
            
        case AL_PLAYING:
            state = alSource_playing;
            break;
            
        case AL_PAUSED:
            state = alSource_paused;
            break;
            
        case AL_STOPPED:
            state = alSource_stopped;
            break;
            
        default:
            state = alSource_initial;
            break;
    }
    return state;
}


#pragma mark -- 打开音频缓存进行播放
void SYOpenALPlayer::OpenAudio(ALubyte* buffer, ALuint length)
{
    if (NULL == buffer || 0 == length)
    {
        std::cout << "Can not open audio !" << std::endl;
        return;
    }
    if (0 == m_fillBufLen
        || m_totalBufLen > m_fillBufLen)   // 先初始化完所有预备（开头部分）缓冲区
    {
        ALint needLen   = m_totalBufLen - m_fillBufLen;     // 需要初始化缓冲长度
        ALint cpyLen    = length > needLen ? needLen : length;  // 复制数据长度
        ALint remainLen = length - cpyLen;  // 剩余数据长度
        
        memcpy(m_initBuf, buffer, cpyLen);
        m_fillBufLen += cpyLen;
        
        if (m_totalBufLen == m_fillBufLen)  // 缓冲已满，可以开始播放
        {
            alGenBuffers(BUFF_NUM, m_buffers);  // 初始化缓冲
            for (ALint i = 0; i < BUFF_NUM; i++)    // 开头数据初始化
            {
                std::cout << "初始化数据到第 " << i << " 个缓冲区" << std::endl;
                alBufferData(m_buffers[i], m_format, m_initBuf + i * BUFF_SIZE, BUFF_SIZE, m_frequency);
            }
            std::cout << "所有缓冲区数据初始化完毕，开始进入 AL 音源队列 !" << std::endl;
            alSourceQueueBuffers(m_sourceID, BUFF_NUM, m_buffers);  // 将数据缓冲送人音源队列
            alDeleteSources(BUFF_NUM, m_buffers);   // 送入队列后的数据缓冲可以清理
            free(m_initBuf);
            m_initBuf = NULL;
            
            PlaySound();
        }
        if (0 < remainLen)  // 缓冲已满，数据还有剩余
        {
            ALuint bufId;
            alGenBuffers(1, &bufId);
            alBufferData(bufId, m_format, buffer +  cpyLen, remainLen, m_frequency);
            alSourceQueueBuffers(m_sourceID, 1, &bufId);    // 将数据缓冲送人音源队列
            alDeleteBuffers(1, &bufId); // 送入队列后的数据缓冲可以清理
        }
    }
    else
    {
        RefreshQueueBuffer();   // 更新缓存
        
        // 循环播放
        ALuint loopBufID;
        alGenBuffers(1, &loopBufID);
        alBufferData(loopBufID, m_format, buffer, (ALsizei)length, m_frequency);
        // 新替换缓冲区重新如队列等待 OpenAL 处理
        alSourceQueueBuffers(m_sourceID, 1, &loopBufID);
        alDeleteBuffers(1, &loopBufID); // 送入队列后的数据缓冲可以清理
        
        PlaySound();
    }
}


#pragma mark -- 开启播放
void SYOpenALPlayer::PlaySound()
{
    if (alSource_playing != SourceState())
    {
        alSourcePlay(m_sourceID);
    }
}


#pragma mark -- 暂停播放
void SYOpenALPlayer::PauseSound()
{
    if (alSource_paused != SourceState())
    {
        alSourcePause(m_sourceID);
    }
}


#pragma mark -- 停止播放
void SYOpenALPlayer::StopSound()
{
    if (alSource_stopped != SourceState())
    {
        alSourceStop(m_sourceID);
    }
}


#pragma mark -- 清理 OpenAL
void SYOpenALPlayer::ClearOpenAL()
{
    alDeleteSources(1, &m_sourceID);
    alcDestroyContext(m_context);
    alcCloseDevice(m_device);
}
