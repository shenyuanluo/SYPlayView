//
//  SYPlayView.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "SYPlayView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "SYShader.h"
#import "SYTexture.h"
#import "SYTransform.h"
#import "SYScalingView.h"


#define SCREEN_W [UIScreen mainScreen].bounds.size.width
#define SCREEN_H [UIScreen mainScreen].bounds.size.height


#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#pragma mark -- Shader
NSString *const vsCode = SHADER_STRING
(
 attribute vec4 aPos;       // 输入，顶点坐标
 attribute vec2 aTexCoor;   // 输入，纹理坐标
 uniform mat4 modelMat;     // 模型 矩阵
 uniform mat4 projectMat;   // 投影 矩阵
 varying vec2 texCoord;     // 输出，纹理坐标(传递给片段着色器)
 
 void main()
 {
     gl_Position = projectMat * modelMat * aPos;
     texCoord    = aTexCoor;
 }
 );

NSString *const fsCode = SHADER_STRING
(
 varying highp vec2 texCoord;   // 输入，纹理坐标(顶点着色器传入)
 uniform sampler2D textureY;    // 纹理采样器，Y 纹理
 uniform sampler2D textureU;    // 纹理采样器，U 纹理
 uniform sampler2D textureV;    // 纹理采样器，V 纹理
 
 void main()
 {
     highp float y = texture2D(textureY, texCoord).r;
     highp float u = texture2D(textureU, texCoord).r - 0.5;
     highp float v = texture2D(textureV, texCoord).r - 0.5;
     
     highp float r = y + 1.402 * v;             // 颜色 R 分量
     highp float g = y - 0.344 * u - 0.714 * v; // 颜色 G 分量
     highp float b = y + 1.772 * u;             // 颜色 B 分量
     
     gl_FragColor = vec4(r, g, b, 1.0);
 }
 );


@interface SYPlayView() <
                            UIGestureRecognizerDelegate
                        >
{
    GLuint          m_VAO;                  // 视频帧 VAO
    GLuint          m_frameBuffer;          // 帧缓冲
    GLuint          m_renderBuffer;         // 渲染缓冲
    GLint           m_renderBufferWidth;    // 渲染缓冲·宽度
    GLint           m_renderBufferHeight;   // 渲染缓冲·高度
    
    GLsizei         m_decodeFrameW;         // 帧宽度
    GLsizei         m_decodeFrameH;         // 帧高度
    BOOL            m_isRatioPlay;          // 是否按帧比例显示
    BOOL            m_isEnableScale;        // 是否开启捏合缩放功能
    BOOL            m_isScaling;            // 是否正在缩放
    
    CGFloat         m_glViewScale;          // 缩放大小
    CGFloat         m_maxGlViewScale;       // 最大缩放倍数
    CGFloat         m_minGlViewScale;       // 最小缩放倍数
    GLfloat         m_transSpaceX;          // 水平移动距离（放大模式下）
    GLfloat         m_transSpaceY;          // 垂直移动距离（放大模式下）
    CGPoint         m_transStartPoint;      // 移动起始点（放大模式下）
    CGPoint         m_transEndPoint;        // 移动终点（放大模式下）
    
    UIPinchGestureRecognizer *_pinchRecognizer; // 捏合手势
}
@property (nonatomic, readwrite, strong) EAGLContext *glContext;
@property (nonatomic, readwrite, strong) SYShader *shader;
@property (nonatomic, readwrite, strong) SYTexture *yTexture;
@property (nonatomic, readwrite, strong) SYTexture *uTexture;
@property (nonatomic, readwrite, strong) SYTexture *vTexture;
@property (nonatomic, readwrite, strong) SYTransform *projectMat;
@property (nonatomic, readwrite, strong) SYTransform *modelMat;
@end


@implementation SYPlayView

#pragma mark -- 初始化播放视图
- (instancetype)initWithFrame:(CGRect)frame
                    ratioPlay:(BOOL)isRatio
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        m_isRatioPlay        = isRatio;

        [self initAttrib];

        if (NO == [self initContext])
        {
            return nil;
        }
        if (NO == [self initFrameBuffer])
        {
            return nil;
        }
        if (NO == [self initShader])
        {
            return nil;
        }
        [self initVAO];
        [self initProjectMat];
        [self initYUVTexture];

        [self addPinchRestures];
    }
    return self;
}

- (void)dealloc
{
    if (m_VAO)
    {
        glDeleteVertexArrays(1, &m_VAO);
        m_VAO = 0;
    }
    if (m_frameBuffer)
    {
        glDeleteFramebuffers(1, &m_frameBuffer);
        m_frameBuffer = 0;
    }
    if (m_renderBuffer)
    {
        glDeleteRenderbuffers(1, &m_renderBuffer);
        m_renderBuffer = 0;
    }
    if (self.glContext)
    {
        [EAGLContext setCurrentContext:nil];
        self.glContext = nil;
    }
    if (self.shader)
    {
        [self.shader freeShader];
        self.shader = nil;
    }
    if (self.yTexture)
    {
        [self.yTexture freeTexture];
    }
    if (self.uTexture)
    {
        [self.uTexture freeTexture];
    }
    if (self.vTexture)
    {
        [self.vTexture freeTexture];
    }
    
    NSLog(@"---------- SYPlayerView dealloc ----------");
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    glBindRenderbuffer(GL_RENDERBUFFER, m_renderBuffer);
    /*
     分配存储空间
     注意：当核心动画层的边界或属性更改时，需要重新分配 renderbuffer 的存储。
     如果不重新分配 renderbuffers，renderbuffer 大小将不匹配图层的大小;
     在这种情况下，Core Animation可以缩放图像的内容以适应图层。）
     */
    [self.glContext renderbufferStorage:GL_RENDERBUFFER
                           fromDrawable:(CAEAGLLayer*)self.layer];
    // 检索 renderbuffer 的高度和宽度
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &m_renderBufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &m_renderBufferHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"failed to make complete framebuffer object %x", status);
        return;
    }
    [self updateViewWidth:m_renderBufferWidth
                   height:m_renderBufferHeight];
}

#pragma mark -- 初始化参数
- (void)initAttrib
{
    m_isEnableScale  = NO;
    m_isScaling      = NO;
    m_glViewScale    = 1.0f;
    m_maxGlViewScale = 1.0f;
    m_minGlViewScale = 1.0f;
    m_transSpaceX    = 0;
    m_transSpaceY    = 0;
    m_decodeFrameW   = 0;
    m_decodeFrameH   = 0;
}

#pragma mark -- 初始化 OpenGLES 上下文
- (BOOL)initContext
{
    NSDictionary *property = @{kEAGLDrawablePropertyRetainedBacking : @(NO),
                               kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8 };
    CAEAGLLayer *eaglLayer       = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque             = YES; // 设置不透明，提高性能
    eaglLayer.drawableProperties = property;
    eaglLayer.contentsScale      = [UIScreen mainScreen].scale;
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.glContext)
    {
        NSLog(@"Init OpenGL context failure !");
        return NO;
    }
    if (![EAGLContext setCurrentContext:self.glContext])
    {
        NSLog(@"Set OpenGL context failure !");
        return NO;
    }
    return YES;
}

#pragma mark -- 初始化帧缓冲
- (BOOL)initFrameBuffer
{
    glGenFramebuffers(1, &m_frameBuffer);   // 生成帧缓冲对象
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBuffer);   // 绑定帧缓冲对象
    glGenRenderbuffers(1, &m_renderBuffer); // 生成渲染缓冲对象
    glBindRenderbuffer(GL_RENDERBUFFER, m_renderBuffer);    // 绑定渲染缓冲对象
    /*
     初始分配存储空间
     Apple 不允许 OpenGL 直接渲染在屏幕上，需要将其放进输出的颜色缓冲，
     然后询问 EAGL 去把缓冲对象展现到屏幕上。
     因为颜色渲染缓冲是强制需要的，为了设置这些属性，
     需要通过 EAGLContext 调用 renderbufferStorage:fromDrawable:
     将colorRenderbuffer 和 Core Animation 图层关联起来。
     （注意：‘glRenderbufferStorage’ 在 iOS 平台不适用）
     */
    [self.glContext renderbufferStorage:GL_RENDERBUFFER
                           fromDrawable:(CAEAGLLayer*)self.layer];
    // 检索 renderbuffer 的高度和宽度
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &m_renderBufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &m_renderBufferHeight);
    // 将渲染缓冲附件添加到帧缓冲上，‘GL_COLOR_ATTACHMENT0’ 作为颜色缓冲
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_renderBuffer);
    
    /*
     解绑渲染缓冲对象
     注意：已经分配足够内存的渲染缓冲对象附件，可以将其解绑
     */
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
    if (GL_FRAMEBUFFER_COMPLETE != glCheckFramebufferStatus(GL_FRAMEBUFFER))
    {
        
        NSLog(@"Create frame buffer failure !");
        m_frameBuffer = 0;
//        return NO;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);   // 还原成默认缓冲，以免渲染错误
    
    [self updateViewWidth:m_renderBufferWidth
                   height:m_renderBufferHeight];
    return YES;
}

#pragma mark -- 初始化着色器
- (BOOL)initShader
{
    self.shader = [[SYShader alloc] initWithVShaderCode:vsCode.UTF8String
                                            fShaderCode:fsCode.UTF8String];
    if (!self.shader)
    {
        NSLog(@"Create shader failure !");
        return NO;
    }
    // 设置相关属性下标
    [self.shader setAttrib:"aPos" onIndex:0];
    [self.shader setAttrib:"aTexCoor" onIndex:1];
    // 设置着色器相关纹理单元
    [self.shader setUniformInt:"textureY"
                            forValue:0];
    [self.shader setUniformInt:"textureU"
                            forValue:1];
    [self.shader setUniformInt:"textureV"
                            forValue:2];
    return YES;
}

#pragma mark -- 初始化 VAO
- (void)initVAO
{
    // 顶点数据
    GLfloat vertices[] =
    {
        // 顶点坐标     // 纹理坐标
        -1.0f, -1.0f,  0.0f, 1.0f,
         1.0f, -1.0f,  1.0f, 1.0f,
        -1.0f,  1.0f,  0.0f, 0.0f,
         1.0f,  1.0f,  1.0f, 0.0f,
    };
    GLuint VBO;
    glGenVertexArrays(1, &m_VAO); // 创建一个顶点数组对象（可包含：VBO，EBO，VertexAttribPointer ）
    glGenBuffers(1, &VBO);    // 创建顶点缓存对象
    glBindVertexArray(m_VAO); // 绑定顶点数组对象在先，然后再绑定和设置顶点缓存对象，并且配置顶点属性
    glBindBuffer(GL_ARRAY_BUFFER, VBO);   // 绑定缓存对象类型为：顶点数组缓存
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), &vertices, GL_STATIC_DRAW); // 拷贝顶点数据到顶点缓存对象ID引用的缓存中
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (void*)0); // 设置顶点属性 （告诉 OpenGL 如何解释使用顶点数据）
    glEnableVertexAttribArray(0);   // 启用顶点属性
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat))); // 设置纹理属性 （告诉 OpenGL 如何解释使用纹理数据）
    glEnableVertexAttribArray(1);   // 启用纹理属性
    glBindVertexArray(0);
    glDeleteBuffers(1, &VBO); // 设置好相关属性的 顶点缓存对象可以删除
}

#pragma mark -- 初始化 Project Matrix
- (void)initProjectMat
{
    self.projectMat = [[SYTransform alloc] init];
    [self.projectMat orthoWithLeft:-1.0f
                             right:1.0f
                               top:1.0f
                            bottom:-1.0f
                         nearPlane:-1.0f
                          farPlane:1.0f];
    self.modelMat = [[SYTransform alloc] init];
}

#pragma mark -- 初始化 YUV 纹理
- (void)initYUVTexture
{
    self.yTexture = [[SYTexture alloc] init];
    self.uTexture = [[SYTexture alloc] init];
    self.vTexture = [[SYTexture alloc] init];
}

#pragma mark -- 渲染帧数据
- (void)render:(SYVideoFrame *)frame
{
    if (!frame)
    {
        return;
    }
    [self createTextureWithFrame:frame];
    
    [EAGLContext setCurrentContext:self.glContext];
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBuffer);   // 绑定帧缓冲，开始绘制
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);   // 设置清除缓存时窗体背景颜色
    glClear(GL_COLOR_BUFFER_BIT);   // 开始清除（颜色缓冲）
    
    
    // 变换矩阵
    [self.modelMat reset];
    [self.modelMat scaleX:m_glViewScale
                        Y:m_glViewScale
                        Z:0.0f];
    [self.modelMat translateX:m_transSpaceX
                            Y:m_transSpaceY
                            Z:0.0f];
    
    /* ========== 视频渲染 ========== */
    [self.shader use];
    [self.shader setUniformMat4:"modelMat"
                       forValue:self.modelMat.use.m];
    [self.shader setUniformMat4:"projectMat"
                       forValue:self.projectMat.use.m];
    // 激活并绑定纹理
    [self.yTexture useInUnit:GL_TEXTURE0];
    [self.uTexture useInUnit:GL_TEXTURE1];
    [self.vTexture useInUnit:GL_TEXTURE2];
    glBindVertexArray(m_VAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindVertexArray(0);

    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];   // 显示 renderbuffer 内容
}

#pragma mark -- 设置是否开启捏合缩放功能
- (void)enableScale:(BOOL)enable
{
    m_isEnableScale = enable;
}

#pragma mark -- 设置捏合缩放比例大小
- (void)setupMaxScale:(CGFloat)maxScale
             minScale:(CGFloat)minScale
{
    if (NO == m_isEnableScale)
    {
        return;
    }
    m_maxGlViewScale = sqrtf(maxScale);
    m_minGlViewScale = sqrtf(minScale);
}

#pragma mark -- 创建帧 Y、U、V 纹理
- (void)createTextureWithFrame:(SYVideoFrame *)vFrame
{
    if (!vFrame)
    {
        return;
    }
    SYVideoFrame *yuvFrame = (SYVideoFrame*)vFrame;
    if (!yuvFrame.luma || !yuvFrame.chromaB || !yuvFrame.chromaR)
    {
        return;
    }
    NSUInteger lumaLen    = yuvFrame.width * yuvFrame.height;
    NSUInteger chromaBLen = lumaLen * 0.25;
    NSUInteger chromaRLen = lumaLen * 0.25;
    if (lumaLen != yuvFrame.luma.length
        || chromaBLen != yuvFrame.chromaB.length
        || chromaRLen != yuvFrame.chromaR.length)
    {
        return;
    }
    if (vFrame.width != m_decodeFrameW
        || vFrame.height != m_decodeFrameH)
    {
        m_decodeFrameW = (GLsizei)vFrame.width;
        m_decodeFrameH = (GLsizei)vFrame.height;
        [self updateViewWidth:m_renderBufferWidth
                       height:m_renderBufferHeight];
    }
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    const GLubyte *pixels[3] =
    {
        yuvFrame.luma.bytes,
        yuvFrame.chromaB.bytes,
        yuvFrame.chromaR.bytes
    };
    NSUInteger widths[3] =
    {
        vFrame.width,
        vFrame.width * 0.5,
        vFrame.width * 0.5
    };
    NSUInteger heights[3] =
    {
        vFrame.height,
        vFrame.height * 0.5,
        vFrame.height * 0.5
    };
    // 创建 Y 纹理
    [self.yTexture crateTextureWithData:pixels[0]
                                  width:(GLsizei)widths[0]
                                 height:(GLsizei)heights[0]
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
    
    // 创建 U 纹理
    [self.uTexture crateTextureWithData:pixels[1]
                                  width:(GLsizei)widths[1]
                                 height:(GLsizei)heights[1]
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
    
    // 创建 V 纹理
    [self.vTexture crateTextureWithData:pixels[2]
                                  width:(GLsizei)widths[2]
                                 height:(GLsizei)heights[2]
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
}

#pragma mark -- 大小变化更新
- (void)updateViewWidth:(GLint)width
                 height:(GLint)height
{
    CGRect viewportRect = CGRectZero;
    if (NO == m_isRatioPlay)
    {
        viewportRect = CGRectMake(0, 0, width, height);
    }
    else
    {
        viewportRect = [SYScalingView scaleWithSubSize:CGSizeMake(m_decodeFrameW, m_decodeFrameH)
                                          inParentSize:CGSizeMake(width, height)];
    }
    glViewport(viewportRect.origin.x,
               viewportRect.origin.y,
               viewportRect.size.width,
               viewportRect.size.height);
}

#pragma mark - 捏合处理
#pragma mark -- 捏合手势添加
-(void)addPinchRestures
{
    if (!_pinchRecognizer)
    {
        self.multipleTouchEnabled = YES;
        _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(pinchAction:)];
        _pinchRecognizer.delegate = self;
        [self addGestureRecognizer:_pinchRecognizer];
    }
}

#pragma mark -- 捏合放大
- (void)pinchAction:(UIPinchGestureRecognizer *)sender
{
    m_glViewScale *= sender.scale;
    
    if (m_maxGlViewScale <= m_glViewScale)
    {
        m_glViewScale = m_maxGlViewScale;
    }
    
    if (m_minGlViewScale >= m_glViewScale)
    {
        m_glViewScale = m_minGlViewScale;
    }
    
    m_transSpaceY = 0;
    m_transSpaceX = 0;
    m_isScaling   = (1 < m_glViewScale) ? YES : NO;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    return m_isEnableScale;
}

#pragma mark - 移动手势处理
- (void)touchesBegan:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event
{
    if(1 != [touches count])
    {
        return;
    }
    UITouch *touch   = [touches anyObject];
    m_transStartPoint = [touch locationInView:self]; // 移动起点（手指开始点击）
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event
{
    if(1 != [touches count] || NO == m_isScaling)
    {
        return;
    }
    UITouch *touch = [touches anyObject];
    m_transEndPoint = [touch locationInView:self];   // 移动终点（手指移动-ing）
    
    CGFloat moveHoriSpace = m_transEndPoint.x - m_transStartPoint.x;  // 水平移动距离
    CGFloat moveVertSpace = m_transEndPoint.y - m_transStartPoint.y;  // 垂直移动距离
    
    m_transStartPoint = m_transEndPoint;
    
    CGFloat moveHoriRatio = fabs(moveHoriSpace) / SCREEN_W;     // 水平移动比例
    CGFloat moveVertRatio = fabs(moveVertSpace) / SCREEN_H;     // 垂直移动比例
    CGFloat maxMoveSpace  = (m_glViewScale - 1) * (1/m_glViewScale);
    
    if (0 < moveHoriSpace)  // 向右移
    {
        m_transSpaceX += moveHoriRatio;
        if (maxMoveSpace <= m_transSpaceX)
        {
            m_transSpaceX = maxMoveSpace;
        }
    }
    else    // 向左移
    {
        m_transSpaceX -= moveHoriRatio;
        if (-maxMoveSpace >= m_transSpaceX)
        {
            m_transSpaceX = -maxMoveSpace;
        }
    }
    if (0 >= moveVertSpace) // 向上移
    {
        m_transSpaceY += moveVertRatio;
        if (maxMoveSpace <= m_transSpaceY)
        {
            m_transSpaceY = maxMoveSpace;
        }
    }
    else    // 向下移
    {
        m_transSpaceY -= moveVertRatio;
        if (-maxMoveSpace >= m_transSpaceY)
        {
            m_transSpaceY = -maxMoveSpace;
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event
{
    
}

#pragma mark -- 检查 OpenGL 状态机是否出错
- (BOOL)isErrorGL
{
    GLenum glStatus = glGetError();
    BOOL ret = NO;
    switch (glStatus)
    {
        case GL_NO_ERROR:
            ret = NO;
            break;
            
        case GL_INVALID_ENUM:
            ret = YES;
            NSLog(@"GL-ERROR: GL_INVALID_ENUM");
            break;
            
        case GL_INVALID_VALUE:
            ret = YES;
            NSLog(@"GL-ERROR: GL_INVALID_VALUE");
            break;
            
        case GL_INVALID_OPERATION:
            ret = YES;
            NSLog(@"GL-ERROR: GL_INVALID_OPERATION");
            break;
            
        case GL_OUT_OF_MEMORY:
            ret = YES;
            NSLog(@"GL-ERROR: GL_OUT_OF_MEMORY");
            break;
            
        default:
            break;
    }
    return ret;
}


@end
