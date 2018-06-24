//
//  SYVideoFrame.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "SYVideoFrame.h"


@implementation SYVideoFrame

@end


#pragma mark - YUV
@implementation SYVideoFrameYUV

@end


#pragma mark -- YUV:I420
@implementation SYVideoFrameI420

- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width     = frameW;
        self.height    = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size      = frameSize * 1.5;
        if (buffLen != self.size)
        {
            NSLog(@"It's wrong with I420 data");
            return nil;
        }
        unsigned char* y = (unsigned char*)malloc(frameSize);
        unsigned char* u = (unsigned char*)malloc(frameSize * 0.25);
        unsigned char* v = (unsigned char*)malloc(frameSize * 0.25);
        if (NULL == y || NULL == u || NULL == v)
        {
            NSLog(@"Malloc buffer for I420 frame is failure!");
            return nil;
        }
        memset(y, 0, frameSize);
        memset(u, 0, frameSize * 0.25);
        memset(v, 0, frameSize * 0.25);
        
        memcpy(y, buffer, frameSize);
        memcpy(u, buffer + frameSize, frameSize * 0.25);
        memcpy(v, buffer + (int)(frameSize * 1.25), frameSize * 0.25);
        
        // yuv数据
        self.luma    = [NSData dataWithBytes:y length:frameSize];
        self.chromaB = [NSData dataWithBytes:u length:frameSize * 0.25];
        self.chromaR = [NSData dataWithBytes:v length:frameSize * 0.25];
        
        free(y);
        free(u);
        free(v);
        y = NULL;
        u = NULL;
        v = NULL;
    }
    return self;
}

@end


#pragma mark -- YUV:NV12
@implementation SYVideoFrameNV12

- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width     = frameW;
        self.height    = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size      = frameSize * 1.5;
        if (buffLen != self.size)
        {
            NSLog(@"It's wrong with NV12 data");
            return nil;
        }
        unsigned char* yuv = (unsigned char*)malloc(self.size);
        unsigned char* y   = (unsigned char*)malloc(frameSize);
        unsigned char* u   = (unsigned char*)malloc(frameSize * 0.25);
        unsigned char* v   = (unsigned char*)malloc(frameSize * 0.25);
        if (NULL == yuv || NULL == y || NULL == u || NULL == v)
        {
            NSLog(@"Malloc buffer for NV12 frame is failure!");
            return nil;
        }
        memset(yuv, 0, self.size);
        memset(y, 0, frameSize);
        memset(u, 0, frameSize * 0.25);
        memset(v, 0, frameSize * 0.25);
        
        memcpy(yuv, buffer, buffLen);
        memmove(y, yuv, frameSize);
        
        unsigned int index = 0;
        for (int i = frameSize; i < self.size; i += 2)
        {
            memmove(u + index, yuv + i, 1);
            memmove(v + index, yuv + i + 1, 1);
            index++;
        }
        
        // yuv数据
        self.luma    = [NSData dataWithBytes:y length:frameSize];
        self.chromaB = [NSData dataWithBytes:u length:frameSize * 0.25];
        self.chromaR = [NSData dataWithBytes:v length:frameSize * 0.25];
        
        free(yuv);
        free(y);
        free(u);
        free(v);
        yuv = NULL;
        y   = NULL;
        u   = NULL;
        v   = NULL;
    }
    return self;
}

@end


#pragma mark -- YUV:NV21
@implementation SYVideoFrameNV21

- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width     = frameW;
        self.height    = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size      = frameSize * 1.5;
        if (buffLen != self.size)
        {
            NSLog(@"It's wrong with NV12 data");
            return nil;
        }
        unsigned char* yuv = (unsigned char*)malloc(self.size);
        unsigned char* y   = (unsigned char*)malloc(frameSize);
        unsigned char* u   = (unsigned char*)malloc(frameSize * 0.25);
        unsigned char* v   = (unsigned char*)malloc(frameSize * 0.25);
        if (NULL == yuv || NULL == y || NULL == u || NULL == v)
        {
            NSLog(@"Malloc buffer for NV12 frame is failure!");
            return nil;
        }
        memset(yuv, 0, self.size);
        memset(y, 0, frameSize);
        memset(u, 0, frameSize * 0.25);
        memset(v, 0, frameSize * 0.25);
        
        memcpy(yuv, buffer, buffLen);
        memmove(y, yuv, frameSize);
        
        unsigned int index = 0;
        for (int i = frameSize; i < self.size; i += 2)
        {
            memmove(v + index, yuv + i, 1);
            memmove(u + index, yuv + i + 1, 1);
            index++;
        }
        
        // yuv数据
        self.luma    = [NSData dataWithBytes:y length:frameSize];
        self.chromaB = [NSData dataWithBytes:u length:frameSize * 0.25];
        self.chromaR = [NSData dataWithBytes:v length:frameSize * 0.25];
        
        free(yuv);
        free(y);
        free(u);
        free(v);
        yuv = NULL;
        y   = NULL;
        u   = NULL;
        v   = NULL;
    }
    return self;
}

@end


#pragma mark - RGB
@implementation SYVideoFrameRGB24

- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width    = frameW;
        self.height   = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size     = frameSize * 3;
        if (buffLen != self.size)
        {
            NSLog(@"It's wrong with RGB data");
            return nil;
        }
        unsigned char* rgb = (unsigned char*)malloc(self.size);
        unsigned char* r   = (unsigned char*)malloc(frameSize);
        unsigned char* g   = (unsigned char*)malloc(frameSize);
        unsigned char* b   = (unsigned char*)malloc(frameSize);
        if (NULL == rgb || NULL == r || NULL == g || NULL == b)
        {
            NSLog(@"Malloc buffer for RGB frame is failure!");
            return nil;
        }
        memset(rgb, 0, self.size);
        memset(r, 0, frameSize);
        memset(g, 0, frameSize);
        memset(b, 0, frameSize);
        memcpy(rgb, buffer, self.size);
        
        unsigned int index = 0;
        
        for (int i = 0; i < self.size; i += 3)
        {
            memmove(r + index, rgb + i + 0, 1);
            memmove(g + index, rgb + i + 1, 1);
            memmove(b + index, rgb + i + 2, 1);
            index++;
        }
        
        // rgb数据
        self.R = [NSData dataWithBytes:r length:frameSize];
        self.G = [NSData dataWithBytes:g length:frameSize];
        self.B = [NSData dataWithBytes:b length:frameSize];
        
        free(rgb);
        free(r);
        free(g);
        free(b);
        rgb = NULL;
        r   = NULL;
        g   = NULL;
        b   = NULL;
    }
    return self;
}

@end
