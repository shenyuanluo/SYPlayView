//
//  NV12ViewController.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/24.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "NV12ViewController.h"
#import "SYPlayView.h"


#define YUV_WIDTH  480          // 视频帧宽
#define YUV_HEIGHT 360          // 视频帧高
#define YUV_BUFF_SIZE  259200   // 缓冲大小（YUV_WIDTH * YUV_HEIGHT * 1.5）
#define YUV_FPS 25              // 帧率


@interface NV12ViewController ()
{
    BOOL m_isInitPlayView;
    BOOL m_isStopRead;
}

@property (nonatomic, strong) SYPlayView *playView;

@end

@implementation NV12ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title       = @"NV12";
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
            [strongSelf readYUVData];
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
    NSLog(@"-------- NV12ViewController dealloc --------");
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
                                               videoFormat:SYVideoNv12
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

#pragma mark -- 读取 YUV 文件数据
- (void)readYUVData
{
    NSString *filePath;
    if (TARGET_IPHONE_SIMULATOR)    // 模拟器
    {
        filePath = [[NSBundle mainBundle] pathForResource:@"XinWenLianBo_480x360_NV12"
                                                   ofType:@"yuv"];
    }
    else    // 真机
    {
        NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask,
                                                             YES);
        NSString *docPath = array[0];
        filePath = [NSString stringWithFormat:@"%@/%@", docPath, @"XinWenLianBo_480x360_NV12.yuv"];
    }
    unsigned char *buff = (unsigned char *)malloc(YUV_BUFF_SIZE);
    if (NULL == buff)
    {
        NSLog(@"Malloc data buffer failure!");
        return;
    }
    
    // 打开 YUV 文件
    FILE *fp = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding],"rb+");
    if (NULL == fp)
    {
        NSLog(@"Open NV12 file failure!");
        free(buff);
        buff = NULL;
        return;
    }
    while (NO == m_isStopRead && !feof(fp))
    {
        memset(buff, 0, YUV_BUFF_SIZE);
        fread(buff, 1, YUV_BUFF_SIZE, fp);  // 每次读取一帧数据
        
        [self.playView renderData:(unsigned char *)buff
                             size:YUV_BUFF_SIZE
                            width:YUV_WIDTH
                           height:YUV_HEIGHT];
        // 通过 sleep 模拟视频流来控制播放速度
        usleep((unsigned int)(((float)(1.0f / YUV_FPS)) * 1000000));
        
        if (feof(fp))     // 循环播放
        {
            fseek(fp, 0, SEEK_SET);
            NSLog(@"Replay...");
        }
    }
    NSLog(@"Stop play!");
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
