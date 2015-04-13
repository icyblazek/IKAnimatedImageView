//
//  IKAnimatedImageView.m
//  IKAnimatedImageView
//
//  Created by Kevin on 8/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKAnimatedImageView.h"
#import <TargetConditionals.h>

@implementation IKAnimatedImageLayer

-(id)initWithFrame:(CGRect)frameRect
{
    if (self = [super init]){
        self.frame = frameRect;
        currentImageFrameIndex = 0;
    }
    return self;
}

-(id)initWithAnimatedImage:(IKAnimatedImage*)aImage
{
    if (self = [self initWithFrame: CGRectZero]){
        self.image = aImage;
        self.frame = CGRectMake(0, 0, aImage.imageWidth, aImage.imageHeight);
        [self display];
    }
    return self;
}

-(id)initWithRect:(CGRect)frame AnimatedImage:(IKAnimatedImage*)aImage
{
    if (self = [self initWithFrame: frame]){
        self.image = aImage;
        [self display];
    }
    return self;
}

-(void)dealloc
{
    [[IKAnimatedRenderManager RenderMangaer] removeRenderObject: _imageRenderID];    
    self.image = nil;
    self.keyframeAnimation = nil;
}

-(void)setImage:(IKAnimatedImage *)aImage
{
    if (_image == aImage)
        return;
    if (bAnimating)
        [self stopAnimation];
    _keyframeAnimation = nil;
    _image = aImage;
}

-(IKAnimatedImage*)image
{
    return _image;
}

-(void)setKeyframeAnimation:(CAKeyframeAnimation *)keyframeAnimation
{
    if (_keyframeAnimation == keyframeAnimation)
        return;
    if (bAnimating)
        [self stopAnimation];
    _image = nil;
    _keyframeAnimation = keyframeAnimation;
}

-(CAKeyframeAnimation*)keyframeAnimation
{
    return _keyframeAnimation;
}

-(void)startAnimation
{
    if (bAnimating)
        return;
    if (_keyframeAnimation){
        [self addAnimation: _keyframeAnimation forKey: @"IKAnimatedImageView"];
        bAnimating = YES;
        return;
    }
    if (self.image && self.image.frameCount == 1)
        return;
    _imageRenderID = [[IKAnimatedRenderManager RenderMangaer] addRenderObject: self AnimatedImage: self.image];
    bAnimating = YES;
}

-(void)stopAnimation
{
    if (!bAnimating)
        return;
    if (_keyframeAnimation){
        [self removeAllAnimations];
        bAnimating = NO;
        return;
    }
    [[IKAnimatedRenderManager RenderMangaer] removeRenderObject: _imageRenderID];
    currentImageFrameIndex = 0;
    bAnimating = NO;
}

-(void)drawInContext:(CGContextRef)ctx
{
    if (!_image)
        return;
#if TARGET_OS_IPHONE
    UIGraphicsPushContext(ctx);
#elif TARGET_OS_MAC
    NSGraphicsContext *previousContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext: [NSGraphicsContext graphicsContextWithGraphicsPort: ctx flipped: NO]];
#endif
    
    if (!bAnimating || _image.frameCount == 1)
        [_image drawInRect: self.bounds FrameIndex: 0];
    else
        [_image drawInRect: self.bounds FrameIndex: currentImageFrameIndex];
    
#if TARGET_OS_IPHONE
    UIGraphicsPopContext();
#elif TARGET_OS_MAC
    [NSGraphicsContext setCurrentContext: previousContext];
#endif
}

-(void)onUpdateAnimatedImageFrameWithIndex:(NSInteger)frameIndex AnimatedImageRenderID:(IKAnimatedImageRenderID)animatedImageRenderID
{
    if (animatedImageRenderID != _imageRenderID)
        return;
    currentImageFrameIndex = frameIndex;
    [self setNeedsDisplay];
}

@end

#pragma mark ================= IKAnimatedImageView ===============

@implementation IKAnimatedImageView

@synthesize image = _image, keyframeAnimation = _keyframeAnimation;

-(id)initWithFrame:(CGRect)frameRect
{
    if (self = [super initWithFrame: frameRect]){
        currentImageFrameIndex = 0;
    }
    return self;
}

-(id)initWithAnimatedImage:(IKAnimatedImage*)aImage
{
    if (self = [self initWithFrame: CGRectZero]){
        self.image = aImage;
        self.frame = CGRectMake(0, 0, aImage.imageWidth, aImage.imageHeight);
    }
    return self;
}

-(id)initWithRect:(CGRect)frame AnimatedImage:(IKAnimatedImage*)aImage
{
    if (self = [self initWithFrame: frame]){
        self.image = aImage;
    }
    return self;
}

-(void)dealloc
{
    [[IKAnimatedRenderManager RenderMangaer] removeRenderObject: _imageRenderID];
    self.image = nil;
    self.keyframeAnimation = nil;
}

-(void)setImage:(IKAnimatedImage *)aImage
{
    if (_image == aImage)
        return;
    if (bAnimating)
        [self stopAnimation];
    _keyframeAnimation = nil;
    _image = aImage;
}

-(IKAnimatedImage*)image
{
    return _image;
}

-(void)setKeyframeAnimation:(CAKeyframeAnimation *)keyframeAnimation
{
    if (_keyframeAnimation == keyframeAnimation)
        return;
    if (bAnimating)
        [self stopAnimation];
    _image = nil;
    _keyframeAnimation = keyframeAnimation;
}

-(CAKeyframeAnimation*)keyframeAnimation
{
    return _keyframeAnimation;
}

-(void)startAnimation
{
    if (bAnimating)
        return;
    if (_keyframeAnimation){
#if !TARGET_OS_IPHONE
        [self setWantsLayer: YES];
#endif
        [self.layer addAnimation: _keyframeAnimation forKey: @"IKAnimatedImageView"];
        bAnimating = YES;
        return;
    }
    if (self.image && self.image.frameCount == 1)
        return;
    _imageRenderID = [[IKAnimatedRenderManager RenderMangaer] addRenderObject: self AnimatedImage: self.image];
    bAnimating = YES;
}

-(void)stopAnimation
{
    if (!bAnimating)
        return;
    if (_keyframeAnimation){
        [self.layer removeAllAnimations];
        bAnimating = NO;
        return;
    }
    [[IKAnimatedRenderManager RenderMangaer] removeRenderObject: _imageRenderID];
    currentImageFrameIndex = 0;
    bAnimating = NO;
}

- (void)drawRect:(CGRect)dirtyRect
{
    if (!_image)
        return;
    
    BOOL isFlipped = YES;
#if TARGET_OS_IPHONE
    CGContextRef ctx = UIGraphicsGetCurrentContext();
#elif TARGET_OS_MAC
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    isFlipped = [[NSGraphicsContext currentContext] isFlipped];
#endif

    if (isFlipped){
        CGContextSaveGState(ctx);
        CGContextScaleCTM(ctx, 1.0, -1);
        CGContextTranslateCTM(ctx, 0, -self.bounds.size.height);
    }
    
    if (!bAnimating || _image.frameCount == 1)
        [_image drawInRect: self.bounds FrameIndex: 0];
    else
        [_image drawInRect: self.bounds FrameIndex: currentImageFrameIndex];
    if (isFlipped)
        CGContextRestoreGState(ctx);
}

-(void)onUpdateAnimatedImageFrameWithIndex:(NSInteger)frameIndex AnimatedImageRenderID:(IKAnimatedImageRenderID)animatedImageRenderID
{
    if (animatedImageRenderID != _imageRenderID)
        return;
    if (!bAnimating)
        return;
    currentImageFrameIndex = frameIndex;
#if TARGET_OS_IPHONE
    [self setNeedsDisplay];
#elif TARGET_OS_MAC
    [self setNeedsDisplay: YES];
#endif
}

@end
