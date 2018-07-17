//
//  RGB565ViewController.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/7/10.
//  Copyright © 2018年 shenyuanluo. All rights reserved.
//

#import "RGB565ViewController.h"
#import "SYPlayView.h"
#import "SYWavHeader.h"
#import "SYOpenALPlayer.h"


#define RGB565_WIDTH  480          // 视频帧宽
#define RGB565_HEIGHT 360          // 视频帧高
#define RGB565_BUFF_SIZE  345600   // 缓冲大小（RGB_WIDTH * RGB_HEIGHT * 2）
#define RGB565_FPS 25              // 帧率

#define IS_LOOP 0


@interface RGB565ViewController ()
{
    BOOL m_isInitPlayView;
    BOOL m_isStopRead;
    dispatch_queue_t m_videoQueue;
    dispatch_queue_t m_audioQueue;
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
    m_videoQueue     = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    m_audioQueue     = dispatch_queue_create("AudioQueue", DISPATCH_QUEUE_SERIAL);
    m_isInitPlayView = [self setupPlayView];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (YES == m_isInitPlayView)
    {
        __weak typeof(self)weakSelf = self;
        dispatch_async(m_videoQueue, ^{
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            [strongSelf readRGBData];
        });
        dispatch_async(m_audioQueue, ^{
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            [strongSelf playWav];
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
        
        if (IS_LOOP && feof(fp))     // 循环播放
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

#pragma mark -- 播放 WAV
- (void)playWav
{
    NSString *filePath;
    if (TARGET_IPHONE_SIMULATOR)    // 模拟器
    {
        filePath = [[NSBundle mainBundle] pathForResource:@"XinWenLianBo"
                                                   ofType:@"wav"];
    }
    else    // 真机
    {
        NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask,
                                                             YES);
        NSString *docPath = array[0];
        filePath = [NSString stringWithFormat:@"%@/%@", docPath, @"XinWenLianBo.wav"];
    }
    FILE *pfile;
    pfile = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
    if (NULL == pfile)
    {
        std::cout << "Open audio file failed !" << std::endl;
        return;
    }
    
    SYOpenALPlayer alPlayer;
    
    WAVHead* wavHead;
    wavHead = (WAVHead*)malloc(sizeof(WAVHead));
    fread(wavHead, 1, sizeof(WAVHead), pfile);
    
    bool isSuccess = alPlayer.ConfigOpenAL(wavHead->fmt.numChannels,
                                           wavHead->fmt.bitsPerSample,
                                           wavHead->fmt.sampleRate);
    if (false == isSuccess)
    {
        std::cout << "Config Open AL failed !" << std::endl;
        return;
    }
    
    if ('f' != wavHead->fmt.fmtChunkID[0]
        || 'm' != wavHead->fmt.fmtChunkID[1]
        || 't' != wavHead->fmt.fmtChunkID[2]
        || ' ' != wavHead->fmt.fmtChunkID[3])
    {
        std::cout << "Open audio file is not 'fmt ' !" << std::endl;
        free(wavHead);
        fclose(pfile);
        return;
    }
    if (1 != wavHead->fmt.audioFormat)
    {
        std::cout << "Not PCM !" << std::endl;
        free(wavHead);
        fclose(pfile);
        return;
    }
    
    // 循环读取 Audio 文件数据
    unsigned char* buff = (unsigned char*)malloc(BUFF_SIZE * BUFF_NUM);;
    size_t ret;
    ret = fread(buff, 1, BUFF_SIZE * BUFF_NUM, pfile);
    
    alPlayer.OpenAudio(buff, (int)ret);
    
    alPlayer.PlaySound();
    
    while (NO == m_isStopRead && !feof(pfile))
    {
        int val = alPlayer.NumOfBuffProcessed();
        if (0 >= val) // 一个 buf 都还没处理完，持续等待播放
        {
            continue;
        }
        while (val--)
        {
            // 读取下一缓存区数据
            ret = fread(buff, 1, BUFF_SIZE, pfile);
            
            alPlayer.OpenAudio(buff, (int)ret);
        }
    }
    std::cout << "文件读取完毕" << std::endl;
    // 文件读取完毕
    fclose(pfile);
    free(buff);
    free(wavHead);
    
    ALSourceState state;
    do      // 等待 OpenAL 播放完毕
    {
        state = alPlayer.SourceState();
    } while (alSource_playing == state);
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
