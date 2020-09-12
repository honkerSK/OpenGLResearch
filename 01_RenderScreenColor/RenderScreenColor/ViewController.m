//
//  ViewController.m
//  RenderScreenColor
//
//  Created by sunke on 2020/9/12.
//  Copyright © 2020 KentSun. All rights reserved.
//

#import "ViewController.h"
#import "SKOpenGLView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SKOpenGLView *glView = [[SKOpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glView];
}


@end
