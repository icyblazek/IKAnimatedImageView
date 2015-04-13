//
//  IKWebPAnimatedImage.m
//  IKAnimatedImageView
//
//  Created by Kevin on 10/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKWebPAnimatedImage.h"
#import <QuartzCore/QuartzCore.h>

@implementation IKWebPAnimatedImageFrame


@end

#define BEST_BYTE_ALIGNMENT 16
#define COMPUTE_BEST_BYTES_PER_ROW(bpr)		( ( (bpr) + (BEST_BYTE_ALIGNMENT-1) ) & ~(BEST_BYTE_ALIGNMENT-1) )

@implementation IKWebPAnimatedImage

-(id)initWithImageFrames:(NSArray*)frames BackgroundImageFrames:(NSArray*)bgFrames
{
    if (self = [super initWithImageFrames: frames]){
        _hasBlendMode = NO;
    }
    return self;
}

-(void)dealloc
{
    if (lastBackgrondFrameImageRef)
        CGImageRelease(lastBackgrondFrameImageRef);
}

-(CGContextRef)createBitmapContextRef:(CGSize)size
{
    CGContextRef bitmapContext = NULL;
    bitmapContext = CGBitmapContextCreate(NULL, size.width, size.height, 8, 4 * size.width, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextClearRect(bitmapContext, CGRectMake(0, 0, size.width, size.height));
    CGContextScaleCTM(bitmapContext, 1, 1 );
    return bitmapContext;
}


-(CAKeyframeAnimation*)convertToKeyFrameAnimation
{
    if (keyFrameAnimation)
        return keyFrameAnimation;
    if (!_hasBlendMode)
        return [super convertToKeyFrameAnimation];
    
    //合成模式，需要渲染合成
    NSMutableArray *times = [NSMutableArray array];
    NSMutableArray *images = [NSMutableArray array];
    CGFloat currentTime = 0;
    CGImageRef tmpLastBGImageRef = nil;
    for (NSInteger frameIndex = 0; frameIndex < imageFrames.count; frameIndex++){
        IKWebPAnimatedImageFrame *curr = imageFrames[frameIndex];
        CGImageRef currentFrameImageRef = (__bridge CGImageRef)(curr.sourceImage);
        CGFloat tmpX = curr.xOffset;
        CGFloat tmpY = self.imageHeight - curr.height - curr.yOffset;
        CGRect imageRect = CGRectMake(tmpX, tmpY, curr.width, curr.height);
        
        CGContextRef blendBGContextRef = [self createBitmapContextRef: CGSizeMake(self.imageWidth, self.imageHeight)];
        if (curr.blend_method == 1){ //创建待合成的背景
            if (self.backgroundColor){
                CGContextSetFillColorWithColor(blendBGContextRef, self.backgroundColor.CGColor);
                CGContextFillRect(blendBGContextRef, CGRectMake(0, 0, self.imageWidth, self.imageHeight));
            }
            CGContextDrawImage(blendBGContextRef, imageRect, currentFrameImageRef);
        }else if (tmpLastBGImageRef){
            CGContextDrawImage(blendBGContextRef, CGRectMake(0, 0, self.imageWidth, self.imageHeight), tmpLastBGImageRef);
            CGContextDrawImage(blendBGContextRef, imageRect, currentFrameImageRef);
        }
        
        CGImageRef newImageRef = CGBitmapContextCreateImage(blendBGContextRef);
        CGContextRelease(blendBGContextRef);
        if (tmpLastBGImageRef)
            CGImageRelease(tmpLastBGImageRef);
        tmpLastBGImageRef = newImageRef;
        
        [images addObject: (__bridge id)(newImageRef)];
        [times addObject: [NSNumber numberWithFloat: currentTime / self.totalTime]];
        currentTime += curr.delayTime;
    }
    if (tmpLastBGImageRef)
        CGImageRelease(tmpLastBGImageRef);
    
    keyFrameAnimation = [CAKeyframeAnimation animationWithKeyPath: @"contents"];    
    [keyFrameAnimation setKeyTimes: times];
    [keyFrameAnimation setValues: images];
    [keyFrameAnimation setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear]];
    keyFrameAnimation.duration = self.totalTime;
    keyFrameAnimation.repeatCount = HUGE_VALF;
    return keyFrameAnimation;
}

-(void)drawInRect:(CGRect)fromRect FrameIndex:(NSInteger)frameIndex
{
    if (frameIndex < 0 || frameIndex >= imageFrames.count)
        return;
    
#if TARGET_OS_IPHONE
    CGContextRef ctx = UIGraphicsGetCurrentContext();
#elif TARGET_OS_MAC
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
#endif
    
    IKWebPAnimatedImageFrame *curr = imageFrames[frameIndex];
    CGImageRef currentFrameImageRef = (__bridge CGImageRef)(curr.sourceImage);
    CGFloat tmpX = curr.xOffset;
    CGFloat tmpY = self.imageHeight - curr.height - curr.yOffset;
    CGRect imageRect = CGRectMake(tmpX, tmpY, curr.width, curr.height);
    //不需要合成渲染模式，直接绘制每一帧
    if (!_hasBlendMode){
        if (self.backgroundColor){
            CGContextSetFillColorWithColor(ctx, self.backgroundColor.CGColor);
            CGContextFillRect(ctx, CGRectMake(0, 0, self.imageWidth, self.imageHeight));
        }
        CGContextDrawImage(ctx, imageRect, currentFrameImageRef);
        return;
    }
    
    //合成渲染模式
    /*
     blend_method{
        WEBP_MUX_BLEND,
        WEBP_MUX_NO_BLEND
     }
     detail: look mux_types.h line: 44
     */
    CGContextRef blendBGContextRef = [self createBitmapContextRef: CGSizeMake(self.imageWidth, self.imageHeight)];
    if (curr.blend_method == 1){ //创建待合成的背景
        if (self.backgroundColor){
            CGContextSetFillColorWithColor(blendBGContextRef, self.backgroundColor.CGColor);
            CGContextFillRect(blendBGContextRef, CGRectMake(0, 0, self.imageWidth, self.imageHeight));
        }
        CGContextDrawImage(blendBGContextRef, imageRect, currentFrameImageRef);
    }else if (lastBackgrondFrameImageRef){
        CGContextDrawImage(blendBGContextRef, CGRectMake(0, 0, self.imageWidth, self.imageHeight), lastBackgrondFrameImageRef);
        CGContextDrawImage(blendBGContextRef, imageRect, currentFrameImageRef);
    }

    CGImageRef newImageRef = CGBitmapContextCreateImage(blendBGContextRef);
    CGContextRelease(blendBGContextRef);
    if (lastBackgrondFrameImageRef)
        CGImageRelease(lastBackgrondFrameImageRef);
    lastBackgrondFrameImageRef = newImageRef;
    CGContextDrawImage(ctx, fromRect, newImageRef);
}

@end
