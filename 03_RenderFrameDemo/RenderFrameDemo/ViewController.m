//
//  ViewController.m
//  RenderFrameDemo
//
//  Created by sunke on 2020/9/12.
//  Copyright © 2020 KentSun. All rights reserved.
//

#import "ViewController.h"
#import "SKOpenGLView.h"
#import "VideoCapture.h"

@interface ViewController ()
@property (nonatomic, strong) VideoCapture *videoCapture;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor orangeColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    SKOpenGLView *glView = [[SKOpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glView];
    
    self.videoCapture = [[VideoCapture alloc] init];
    [self.videoCapture startCapturing:glView];
}

@end
