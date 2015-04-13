//
//  IKWebPAnimatedImage.h
//  IKAnimatedImageView
//
//  Created by Kevin on 10/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKAnimatedImage.h"

@interface IKWebPAnimatedImageFrame : IKAnimatedImageFrame{
    
}

@property (assign) CGFloat xOffset;
@property (assign) CGFloat yOffset;
@property (assign) CGFloat width;
@property (assign) CGFloat height;
@property (assign) int blend_method;

@end

@interface IKWebPAnimatedImage : IKAnimatedImage{
    CGImageRef lastBackgrondFrameImageRef;
}

@property (assign) BOOL hasBlendMode;

@end
