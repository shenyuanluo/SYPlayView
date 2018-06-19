//
//  SYVideoFrame.h
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 视频数据模型类
 */

#import <Foundation/Foundation.h>


@interface SYVideoFrame : NSObject

/** 视频帧 宽度 */
@property (nonatomic, assign, readwrite) NSUInteger width;
/** 视频帧 高度 */
@property (nonatomic, assign, readwrite) NSUInteger height;
/** 视频帧 亮度数据（Y分量) */
@property (nonatomic, strong, readwrite) NSData *luma;
/** 视频帧 色度数据（U分量) */
@property (nonatomic, strong, readwrite) NSData *chromaB;
/** 视频帧 色度数据（V分量) */
@property (nonatomic, strong, readwrite) NSData *chromaR;

@end


