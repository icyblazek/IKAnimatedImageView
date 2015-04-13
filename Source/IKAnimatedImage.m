//
//  IKAnimatedImage.m
//  IKAnimatedImageView
//
//  Created by Kevin on 8/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKAnimatedImage.h"
#import "IKAnimatedImageDecoder.h"

@implementation IKAnimatedImageFrame

-(id)init
{
    if (self = [super init]){
    }
    return self;
}

-(void)dealloc
{
    self.sourceImage = nil;
}

@end

@implementation IKAnimatedImage

-(id)initWithImageFrames:(NSArray*)frames
{
    if (self = [super init]){
        imageFrames = [[NSMutableArray alloc] init];
        [imageFrames addObjectsFromArray: frames];
    }
    return self;
}

+(IKAnimatedImage*)animatedImageWithImagePath:(NSString*)filePath Decoder:(IKAnimatedImageDecoder*)decoder
{
    if (![[decoder class] isSubclassOfClass: [IKAnimatedImageDecoder class]])
        NSAssert(NO, @"decoderClass is must be a subclass of IKAnimatedImageDecoder");
    
    NSData *imageData = [[NSData alloc] initWithContentsOfFile: filePath];
    return [decoder decodeWithImageData: imageData];
}

+(IKAnimatedImage*)animatedImageWithImageData:(NSData*)imageData Decoder:(IKAnimatedImageDecoder*)decoder
{
    if (![[decoder class] isSubclassOfClass: [IKAnimatedImageDecoder class]])
        NSAssert(NO, @"decoderClass is must be a subclass of IKAnimatedImageDecoder");
    
    return [decoder decodeWithImageData: imageData];
}

-(void)dealloc
{
    imageFrames = nil;
}

-(IKAnimatedImageFrame*)objectAtIndexedSubscript:(NSUInteger)idx
{
    return imageFrames[idx];
}

-(NSInteger)frameCount
{
    return imageFrames.count;
}

-(CAKeyframeAnimation*)convertToKeyFrameAnimation
{
    if (imageFrames.count == 0)
        return nil;
    if (!keyFrameAnimation){
        keyFrameAnimation = [CAKeyframeAnimation animationWithKeyPath: @"contents"];
        NSMutableArray *times = [NSMutableArray arrayWithCapacity: 3];
        NSMutableArray *images = [NSMutableArray arrayWithCapacity: 3];
        CGFloat currentTime = 0;
        for (int i = 0; i < imageFrames.count; ++i) {
            IKAnimatedImageFrame *imageFrame = imageFrames[i];
            [times addObject:[NSNumber numberWithFloat: (currentTime / self.totalTime)]];
            currentTime += imageFrame.delayTime;
            [images addObject: imageFrame.sourceImage];
        }
        [keyFrameAnimation setKeyTimes: times];
        
        [keyFrameAnimation setValues: images];
        [keyFrameAnimation setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear]];
        keyFrameAnimation.duration = self.totalTime;
        keyFrameAnimation.repeatCount = HUGE_VALF;
    }
    return keyFrameAnimation;
}

-(NSArray*)getFrameTimes
{
    if (imageFrames.count == 0)
        return nil;
    return [imageFrames valueForKeyPath: @"delayTime"];
}

-(IKImage*)thumbImage
{
    if (_thumbImage)
        return _thumbImage;
    IKAnimatedImageFrame *imageFrame = imageFrames[0];
#if TARGET_OS_IPHONE
    _thumbImage = [[UIImage alloc] initWithCGImage: (__bridge CGImageRef)(imageFrame.sourceImage)];
#elif TARGET_OS_MAC
    _thumbImage = [[NSImage alloc] initWithCGImage: (__bridge CGImageRef)(imageFrame.sourceImage) size: NSMakeSize(self.imageWidth, self.imageHeight)];
#endif
    return _thumbImage;
}

-(void)drawInRect:(CGRect)fromRect FrameIndex:(NSInteger)frameIndex
{
    if (frameIndex < 0 || frameIndex >= imageFrames.count)
        return;
    IKAnimatedImageFrame *imageFrame = imageFrames[frameIndex];
#if TARGET_OS_IPHONE
    CGContextRef ctx = UIGraphicsGetCurrentContext();
#elif TARGET_OS_MAC
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
#endif
    CGImageRef sourceImageRef = (__bridge CGImageRef)imageFrame.sourceImage;
    CGContextDrawImage(ctx, fromRect, sourceImageRef);
}


@end
