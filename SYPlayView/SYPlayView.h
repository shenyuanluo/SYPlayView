//
//  SYPlayView.h
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 视频渲染类
 */

#import <UIKit/UIKit.h>
#import "SYFullScreenView.h"
#import "SYVideoFrame.h"


@interface SYPlayView : SYFullScreenView

/**
 初始化播放视图

 @param frame 视图 frame
 @param isRatio 是否按帧比例显示
 @return 播放视图实例
 */
- (instancetype)initWithFrame:(CGRect)frame
                    ratioPlay:(BOOL)isRatio;

/**
 渲染 视频 帧画面

 @param frame 视频 帧数据
 */
- (void)render:(SYVideoFrame *)frame;

/**
 设置是否开启捏合缩放功能（default is NO）
 
 @param enable 是否开启；YES：开启，NO：关闭
 */
- (void)enableScale:(BOOL)enable;

/**
 设置捏合缩放比例大小（开启时可用）
 
 @param maxScale 最大缩放
 @param minScale 最小缩放
 */
- (void)setupMaxScale:(CGFloat)maxScale
             minScale:(CGFloat)minScale;

@end
