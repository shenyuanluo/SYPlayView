//
//  ViewController.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "ViewController.h"
#import "SYPlayView.h"




#define SRC_WIDTH  352      // 视频帧宽
#define SRC_HEIGHT 288      // 视频帧高
#define BUFF_SIZE  152064   // 缓冲大小（SRC_WIDTH * SRC_HEIGHT * 1.5）
#define FPS 30              // 帧率

@interface ViewController ()

@property (nonatomic, strong) SYPlayView *playView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupPlayView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"-------- ViewController dealloc --------");
}

#pragma mark -- 设置播放视图
- (void)setupPlayView
{
    CGFloat playViewW = [[UIScreen mainScreen] bounds].size.width;
    CGFloat radio = (CGFloat)(4.0f / 3.0f);
    CGFloat playViewH = playViewW / radio;

    CGRect playViewRect = CGRectMake(0, 64, playViewW, playViewH);
    self.playView = [[SYPlayView alloc] initWithFrame:playViewRect
                                            ratioPlay:YES];
    self.playView.backgroundColor = [UIColor lightGrayColor];
    [self.playView enableScale:YES];
    [self.playView setupMaxScale:4 minScale:1];
    [self.view addSubview:self.playView];
}

#pragma mark -- 读取 YUV 数据
- (void)readYUVData
{
    NSString *filePath;
    if (TARGET_IPHONE_SIMULATOR)    // 模拟器
    {
       filePath = [[NSBundle mainBundle] pathForResource:@"akiyo_cif"
                                                  ofType:@"yuv"];
    }
    else    // 真机
    {
        NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                           NSUserDomainMask,
                                                           YES);
        NSString *docPath = array[0];
        filePath = [NSString stringWithFormat:@"%@/%@", docPath, @"akiyo_cif.yuv"];
    }
    char *buff = (char *)malloc(BUFF_SIZE);
    
    // 打开 YUV 文件
    FILE *fp = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding],"rb+");
    if (NULL == fp)
    {
        NSLog(@"Open YUV file failure!");
        return;
    }
    long offset = 0;
    while (!feof(fp))
    {
        memset(buff, 0, BUFF_SIZE);
        fread(buff, 1, SRC_WIDTH * SRC_HEIGHT * 1.5f, fp);  // 每次读取一帧 YUV 数据
        
        [self decodeBuffer:(unsigned char *)buff
                    length:BUFF_SIZE
                     width:SRC_WIDTH
                    height:SRC_HEIGHT];
        // 通过 sleep 模拟视频流来控制播放速度
        usleep((unsigned int)(((float)(1.0f / FPS)) * 1000000));
        
        offset = ftell(fp);
        fflush(stdout);
        printf("offset = %ld\n", offset);
        if (feof(fp))
        {
            fseek(fp, 0, SEEK_SET);
            NSLog(@"重新播放！");
        }
    }
    NSLog(@"文件读取完毕！");
}

#pragma mark -- 解析 YUV 数据
- (void)decodeBuffer:(unsigned char*)buffer
              length:(long)dLen
               width:(long)lWidth
              height:(long)lHeight
{
    fflush(stdout);
    printf("decodeDataLen = %ld, width = %ld, height = %ld\n", dLen, lWidth, lHeight);
    @autoreleasepool
    {
        SYVideoFrame *yuvFrame = [[SYVideoFrame alloc] init];
        yuvFrame.width  = lWidth;
        yuvFrame.height = lHeight;
        long imageSize = lWidth * lHeight;
        
        // 亮度数据
        yuvFrame.luma = [NSData dataWithBytes:buffer
                                       length: imageSize];
        // 色度（颜色色调）数据
        yuvFrame.chromaB = [NSData dataWithBytes:buffer + (int)imageSize
                                          length:imageSize * 0.25];
        // 色度（颜色饱和度）数据
        yuvFrame.chromaR = [NSData dataWithBytes:buffer + (int)(imageSize * 1.25)
                                          length:imageSize * 0.25];
        
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            [strongSelf.playView render:yuvFrame];  // 渲染            
        });
    }
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
