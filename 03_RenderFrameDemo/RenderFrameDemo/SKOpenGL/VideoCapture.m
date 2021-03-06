//
//  VideoCapture.m
//  RenderFrameDemo
//
//  Created by sunke on 2020/9/12.
//  Copyright © 2020 KentSun. All rights reserved.
//

#import "VideoCapture.h"
#import <AVFoundation/AVFoundation.h>
#import "SKOpenGLView.h"

@interface VideoCapture() <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *layer;
@property (nonatomic, strong) dispatch_queue_t videoQueue;

@property (nonatomic, weak) SKOpenGLView *openGLView;

@end


@implementation VideoCapture


- (instancetype)init {
    if (self = [super init]) {
        self.videoQueue = dispatch_queue_create("KentSun.RenderFrameDemo", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - 开始/停止采集
- (void)startCapturing:(SKOpenGLView *)openGLView {
    
    self.openGLView = openGLView;
    
    // 1.创建session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPreset640x480;
    self.session = session;
    
    // 2.创建输入设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    [session addInput:input];
    
    // 3.创建输出设备
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:self.videoQueue];
    // 设置输出的像素格式(YUV/RGB)
    output.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    output.alwaysDiscardsLateVideoFrames = YES;
    [session addOutput:output];
    
    AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
    
    if ([connection isVideoOrientationSupported]) {
        NSLog(@"支持修改");
    } else {
        NSLog(@"不知修改");
    }
    
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    // 5.开始采集
    [session startRunning];
}

- (void)stopCapturing {
    [self.layer removeFromSuperlayer];
    [self.session stopRunning];
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [self.openGLView displaySampleBuffer:sampleBuffer];
}


@end
