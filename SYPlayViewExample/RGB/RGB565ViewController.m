//
//  RGB565ViewController.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/7/10.
//  Copyright © 2018年 shenyuanluo. All rights reserved.
//

#import "RGB565ViewController.h"
#import "SYPlayView.h"


#define RGB565_WIDTH  480          // 视频帧宽
#define RGB565_HEIGHT 360          // 视频帧高
#define RGB565_BUFF_SIZE  345600   // 缓冲大小（RGB_WIDTH * RGB_HEIGHT * 2）
#define RGB565_FPS 25              // 帧率


@interface RGB565ViewController ()
{
    BOOL m_isInitPlayView;
    BOOL m_isStopRead;
}

@property (nonatomic, strong) SYPlayView *playView;

@end


@interface RGB565ViewController ()

@end

@implementation RGB565ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title       = @"RGB565";
    m_isInitPlayView = NO;
    m_isStopRead     = NO;
    m_isInitPlayView = [self setupPlayView];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (YES == m_isInitPlayView)
    {
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            [strongSelf readRGBData];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    m_isStopRead = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"-------- RGB565ViewController dealloc --------");
}

#pragma mark -- 设置播放视图
- (BOOL)setupPlayView
{
    CGFloat scrHeight   = [[UIScreen mainScreen] bounds].size.height;
    CGFloat playViewW   = [[UIScreen mainScreen] bounds].size.width;
    CGFloat radio       = (CGFloat)(4.0f / 3.0f);
    CGFloat playViewH   = playViewW / radio;
    CGFloat orignY      = 812 == scrHeight ? 84 : 64;
    CGRect playViewRect = CGRectMake(0, orignY, playViewW, playViewH);
    self.playView       = [[SYPlayView alloc] initWithRect:playViewRect
                                               videoFormat:SYVideoRgb565
                                               isRatioShow:YES];
    if (!self.playView)
    {
        NSLog(@"Init playview failure!");
        return NO;
    }
    self.playView.backgroundColor = [UIColor lightGrayColor];
    [self.playView enableScale:YES];
    [self.playView setupMaxScale:4 minScale:1];
    [self.view addSubview:self.playView];
    return YES;
}

#pragma mark -- 读取 RGB 文件数据
- (void)readRGBData
{
    NSString *filePath;
    if (TARGET_IPHONE_SIMULATOR)    // 模拟器
    {
        filePath = [[NSBundle mainBundle] pathForResource:@"XinWenLianBo_480x360_RGB565"
                                                   ofType:@"rgb"];
    }
    else    // 真机
    {
        NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask,
                                                             YES);
        NSString *docPath = array[0];
        filePath = [NSString stringWithFormat:@"%@/%@", docPath, @"XinWenLianBo_480x360_RGB565.rgb"];
    }
    unsigned char *buff = (unsigned char *)malloc(RGB565_BUFF_SIZE);
    if (NULL == buff)
    {
        NSLog(@"Malloc data buffer failure!");
        return;
    }
    
    // 打开 YUV 文件
    FILE *fp = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding],"rb+");
    if (NULL == fp)
    {
        NSLog(@"Open RGB565 file failure!");
        free(buff);
        buff = NULL;
        return;
    }
    while (NO == m_isStopRead && !feof(fp))
    {
        memset(buff, 0, RGB565_BUFF_SIZE);
        fread(buff, 1, RGB565_BUFF_SIZE, fp);  // 每次读取一帧数据
        
        [self.playView renderData:buff
                             size:RGB565_BUFF_SIZE
                            width:RGB565_WIDTH
                           height:RGB565_HEIGHT];
        // 通过 sleep 模拟视频流来控制播放速度
        usleep((unsigned int)(((float)(1.0f / RGB565_FPS)) * 1000000));
        
        if (feof(fp))     // 循环播放
        {
            fseek(fp, 0, SEEK_SET);
            NSLog(@"Replay...");
        }
    }
    NSLog(@"Stop play！");
    fclose(fp);
    free(buff);
    buff = NULL;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


@end
