//
//  RGB24ViewController.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/24.
//  Copyright © 2018年 shenyuanluo. All rights reserved.
//

#import "RGB24ViewController.h"
#import "SYPlayView.h"


#define RGB24_WIDTH  480          // 视频帧宽
#define RGB24_HEIGHT 360          // 视频帧高
#define RGB24_BUFF_SIZE  518400   // 缓冲大小（RGB_WIDTH * RGB_HEIGHT * 3）
#define RGB24_FPS 25              // 帧率


@interface RGB24ViewController ()
{
    BOOL m_isInitPlayView;
    BOOL m_isStopRead;
}

@property (nonatomic, strong) SYPlayView *playView;

@end

@implementation RGB24ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title       = @"RGB24";
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
    NSLog(@"-------- RGB24ViewController dealloc --------");
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
                                               videoFormat:SYVideoRgb24
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
        filePath = [[NSBundle mainBundle] pathForResource:@"XinWenLianBo"
                                                   ofType:@"rgb"];
    }
    else    // 真机
    {
        NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask,
                                                             YES);
        NSString *docPath = array[0];
        filePath = [NSString stringWithFormat:@"%@/%@", docPath, @"XinWenLianBo.rgb"];
    }
    unsigned char *buff = (unsigned char *)malloc(RGB24_BUFF_SIZE);
    if (NULL == buff)
    {
        NSLog(@"Malloc data buffer failure!");
        return;
    }
    
    // 打开 YUV 文件
    FILE *fp = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding],"rb+");
    if (NULL == fp)
    {
        NSLog(@"Open RGB24 file failure!");
        free(buff);
        buff = NULL;
        return;
    }
    while (NO == m_isStopRead && !feof(fp))
    {
        memset(buff, 0, RGB24_BUFF_SIZE);
        fread(buff, 1, RGB24_BUFF_SIZE, fp);  // 每次读取一帧数据
        
        [self.playView renderData:buff
                             size:RGB24_BUFF_SIZE
                            width:RGB24_WIDTH
                           height:RGB24_HEIGHT];
        // 通过 sleep 模拟视频流来控制播放速度
        usleep((unsigned int)(((float)(1.0f / RGB24_FPS)) * 1000000));
        
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
