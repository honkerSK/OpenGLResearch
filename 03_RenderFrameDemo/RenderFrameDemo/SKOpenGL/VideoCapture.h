//
//  VideoCapture.h
//  RenderFrameDemo
//
//  Created by sunke on 2020/9/12.
//  Copyright © 2020 KentSun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SKOpenGLView;

@interface VideoCapture : NSObject

- (void)startCapturing:(SKOpenGLView *)openGLView ;
- (void)stopCapturing;

@end

NS_ASSUME_NONNULL_END
