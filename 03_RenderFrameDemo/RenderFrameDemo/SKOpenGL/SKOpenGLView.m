//
//  SKOpenGLView.m
//  RenderFrameDemo
//
//  Created by sunke on 2020/9/12.
//  Copyright © 2020 KentSun. All rights reserved.
//

/*
将view的颜色渲染成橘色
   1> 将SKOpenGLView的layer改成CAEAGLLyaer
   2> 创建EAGLContext(上下文, 状态机)
OpenGL画出图片的过程
   1> layer必须CAEAGLLyaer
   2> 创建EAGLContext, 将EAGLContext设置setCurrentContext
   3> 创建渲染缓冲区
   4> 创建帧缓冲区
   5> 创建两个着色器
       顶点着色器
           0) 创建顶点着色器程序, 并且加载, 和编译程序
           1) 接受传入的顶点数据
           2) 接受传入的纹理坐标数据
       片段着色器
           0) 创建片段着色器程序, 并且加载, 和编译程序
           1) 接受纹理数据
*/

/*
 OpenGL如何画出图片
    顶点着色器 和 片段着色器
    共同的特点
        1> 他们都运行在GPU上面的程序, openGL2.0开始被称之为可编程管线, 在OpenGL1.0的时候, 固定管线, 很多顶点着色器都是固定的, 不能任意的修改, 但是从OpenGL2.0开始, 变成可编程管线, 但是难度也突然提升了很多, 相当于我们需要在GPU上面来运行我们的程序
        2> 都是用来为GPU提供绘制图像的内容的
 
    顶点着色器: 接受传入的三角形顶点/纹理的顶点数据
        1> 在openGL的世界里, 所有的图像都是以三角形的方式存在的. 为什么是三角形? 比如两个点只能组成一条线, 但是四个点就组成了无线多的面, 不能将4个顶点固定在一个平面上. 但是三角形的三个点确定下来之后, 是一定在同一个平面的. 如果想在其他平面继续画东西, 就给出其他平面的三角形即可
        2> 外界提供给我们即将画出的图像的所有顶点, 比如说现在要画一个长方形, 一个长方形是由两个三角形组成的, 那么就需要提供能形成两个三角形的顶点. 而顶点着色器就是接受三角形顶点的. 之后会经过各种变化, 形成新的顶点(因为就3D图像来说, 很多内容是会被上层的内容遮盖的, 那么有些顶点是没有存在的必要)
        3> 接受纹理数据, 并且对纹理数据进行转化
    片段着色器
        1> 接受变化后的顶点, 之后再根据传入的纹理数据, 生成片段, 之后根据片段给屏幕渲染对应的颜色
    如何创建着色器
        1> 需要书写glsl程序, 该程序就是运行了GPU上的程序
        2> 加载源码, 并且编译的程序
*/

#import "SKOpenGLView.h"
#import <OpenGLES/ES2/gl.h>

// HDTV --> 高清视频
static const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
          0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

// SDTV --> 标清视频
const GLfloat kColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};


@interface SKOpenGLView()
{
    
    GLint vertexIndex;  //顶点index
    GLint textureIndex; //纹理index
    
    GLint samplerYIndex;    //y的index
    GLint samplerUVIndex;   //UV的index
    GLint matrixIndex;      //矩阵index
    
    
    const GLfloat *_preferredConversion;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    EAGLContext *_glContext;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
}

@end

@implementation SKOpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupOpenGL];
    }
    return self;
}

- (void)setupOpenGL {
    _preferredConversion = kColorConversion709;
    
    // 1.创建EAGLContext
    EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _glContext = glContext;
    [EAGLContext setCurrentContext:glContext];
    CAEAGLLayer *glLayer = (CAEAGLLayer *)self.layer;
    
    // 2.创建渲染缓冲区
    GLuint renderBuffers;
    glGenRenderbuffers(1, &renderBuffers);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffers);
    [glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:glLayer];
    
    // 3.创建帧缓冲区
    GLuint frameBuffers;
    glGenFramebuffers(1, &frameBuffers);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffers);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffers);
    
    
    
    // 4.加载和编译着色器程序
    GLuint vertexShader = [self compileShader:@"VertexSource" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"FragmentSource" withType:GL_FRAGMENT_SHADER];
    
    // 5.将两个程序结合起来
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
    }
    glUseProgram(programHandle);
    
    
    // 6.获取顶点着色器的属性index
    vertexIndex = glGetAttribLocation(programHandle, "Position");
    glEnableVertexAttribArray(vertexIndex);
    textureIndex = glGetAttribLocation(programHandle, "TexCoordIn");
    glEnableVertexAttribArray(textureIndex);
    
    // 7.获取片段着色器的属性index
    samplerYIndex = glGetUniformLocation(programHandle, "SamplerY");
    samplerUVIndex = glGetUniformLocation(programHandle, "SamplerUV");
    matrixIndex = glGetUniformLocation(programHandle, "colorConversionMatrix");
    
    // 8.设置纹理数据
    glUniform1i(samplerYIndex, 0);
    glUniform1i(samplerUVIndex, 1);
    
    // 9.给矩阵变化传入值
    glUniformMatrix3fv(matrixIndex, 1, GL_FALSE, _preferredConversion);
    
    // 10.创建纹理缓存
    CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, glContext, NULL, &_videoTextureCache);
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    // 1.获取shader文件的路径
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        return 0;
    }
    
    // 2.根据类型, 创建对应的着色器对象
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3.加载着色器源码
    const char* shaderStringUTF8 = [shaderString UTF8String];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, NULL);
    
    // 4.编译着色器
    glCompileShader(shaderHandle);
    
    // 5.查看是否编译成功, 如果没有成功, 则打印对应的错误信息
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
    }
    
    return shaderHandle;
}

- (void)displaySampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // 1.获取CVPixelBuffer
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 2.获取图片的宽度和高度
    int frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    // 3.设置当前的上下文是之前创建的上下文
    if ([EAGLContext currentContext] != _glContext) {
        [EAGLContext setCurrentContext:_glContext]; // 非常重要的一行代码
    }
    
    // 4.清楚之前的纹理数据, 获取新的纹理数据
    [self cleanUpTextures];
    
    // 5.判断纹理的类型
    CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
        _preferredConversion = kColorConversion601FullRange;
    } else {
        _preferredConversion = kColorConversion709;
    }
    
    // 6.获取Y的纹理数据
    glActiveTexture(GL_TEXTURE0);
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 _videoTextureCache,
                                                 pixelBuffer,
                                                 NULL,
                                                 GL_TEXTURE_2D,
                                                 GL_LUMINANCE,
                                                 frameWidth,
                                                 frameHeight,
                                                 GL_LUMINANCE,
                                                 GL_UNSIGNED_BYTE,
                                                 0,
                                                 &_lumaTexture);
    
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 7.获取UV纹理
    glActiveTexture(GL_TEXTURE1);
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 _videoTextureCache,
                                                 pixelBuffer,
                                                 NULL,
                                                 GL_TEXTURE_2D,
                                                 GL_LUMINANCE_ALPHA,
                                                 frameWidth / 2,
                                                 frameHeight / 2,
                                                 GL_LUMINANCE_ALPHA,
                                                 GL_UNSIGNED_BYTE,
                                                 1,
                                                 &_chromaTexture);
    
    glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 8.传入顶点坐标
    // 8.1.获取顶点坐标
    GLfloat quadVertexData [] = {
        -1, -1,
        1, -1,
        -1, 1,
        1, 1,
    };
    glVertexAttribPointer(vertexIndex, 2, GL_FLOAT, 0, 0, quadVertexData);
    
    // 8.2.纹理坐标
    GLfloat quadTextureData[] =  { // 正常坐标
        0, 1,
        1, 1,
        0, 0,
        1, 0
    };
    glVertexAttribPointer(textureIndex, 2, GL_FLOAT, 0, 0, quadTextureData);
    
    // 9.展示数据
    glViewport(0, 0, frameWidth, frameHeight);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    if ([EAGLContext currentContext] == _glContext) {
        [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

- (void)cleanUpTextures
{
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}


@end
