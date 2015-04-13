//
//  IKAnimatedImageView.h
//  IKAnimatedImageView
//
//  Created by Kevin on 8/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKAnimatedImage.h"
#import "IKAnimatedRenderManager.h"

#if TARGET_OS_IPHONE
    #define CocoaView UIView
#elif TARGET_OS_MAC
    #define CocoaView NSView
#endif

@interface IKAnimatedImageLayer : CALayer <IKAnimatedRenderProtocol>{
    IKAnimatedImage *_image;
    CAKeyframeAnimation *_keyframeAnimation;    
    BOOL bAnimating;
    NSInteger currentImageFrameIndex;
    IKAnimatedImageRenderID _imageRenderID;
}

-(id)initWithAnimatedImage:(IKAnimatedImage*)aImage;
-(id)initWithRect:(CGRect)frame AnimatedImage:(IKAnimatedImage*)aImage;

-(void)startAnimation;
-(void)stopAnimation;

@property (strong) IKAnimatedImage *image;
@property (strong) CAKeyframeAnimation *keyframeAnimation;

@end


@interface IKAnimatedImageView : CocoaView <IKAnimatedRenderProtocol>{
    IKAnimatedImage *_image;
    CAKeyframeAnimation *_keyframeAnimation;
    BOOL bAnimating;
    NSInteger currentImageFrameIndex;
    IKAnimatedImageRenderID _imageRenderID;
}

/** 创建IKAnimatedImageView
 */
-(id)initWithAnimatedImage:(IKAnimatedImage*)aImage;
-(id)initWithRect:(CGRect)frame AnimatedImage:(IKAnimatedImage*)aImage;

-(void)startAnimation;
-(void)stopAnimation;

@property (strong) IKAnimatedImage *image;
@property (strong) CAKeyframeAnimation *keyframeAnimation;


@end
