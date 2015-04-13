//
//  IKGifImageDecoder.m
//  IKAnimatedImageView
//
//  Created by Kevin on 8/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKGifImageDecoder.h"
#import <ImageIO/ImageIO.h>

@implementation IKGifImageDecoder

-(IKAnimatedImage*)decodeWithImageData:(NSData*)imageData;
{
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    if (!imageSourceRef)
        return NULL;
    size_t frameCount = CGImageSourceGetCount(imageSourceRef);
    if (frameCount == 0){
        CFRelease(imageSourceRef);
        return NULL;
    }
    NSMutableArray *imageFrames = [[NSMutableArray alloc] initWithCapacity: frameCount];
    CGFloat gifWidth = 0;
    CGFloat gifHeight = 0;
    CGFloat totalTime = 0;
    for (size_t i = 0; i < frameCount; ++i) {
        CGImageRef frameImage = CGImageSourceCreateImageAtIndex(imageSourceRef, i, NULL);
        if (!frameImage)
            continue;
        
        CFDictionaryRef imageInfo = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, i, NULL);
        if (gifWidth == 0 && gifHeight == 0) {
            gifWidth =  [(NSNumber*)CFDictionaryGetValue(imageInfo, kCGImagePropertyPixelWidth) floatValue];
            gifHeight = [(NSNumber*)CFDictionaryGetValue(imageInfo, kCGImagePropertyPixelHeight) floatValue];
        }
        
        CFDictionaryRef gifInfo = CFDictionaryGetValue(imageInfo, kCGImagePropertyGIFDictionary);
        if (!gifInfo){
            CFRelease(frameImage);
            CFRelease(imageInfo);
            continue;
        }
        
        CGFloat unclampedDelayTime = [(NSNumber*)CFDictionaryGetValue(gifInfo, kCGImagePropertyGIFUnclampedDelayTime) floatValue];
        if (unclampedDelayTime < 0.01)
            unclampedDelayTime = 0.1;
        
        totalTime += unclampedDelayTime;
        
        IKAnimatedImageFrame *imageFrame = [[IKAnimatedImageFrame alloc] init];
        imageFrame.delayTime = unclampedDelayTime;
        imageFrame.sourceImage = (__bridge id)(frameImage);
        
        [imageFrames addObject: imageFrame];
        CFRelease(imageInfo);
        CGImageRelease(frameImage);
    }
    CFRelease(imageSourceRef);
    if (imageFrames.count == 0)
        return NULL;
    IKAnimatedImage *animatedImage = [[IKAnimatedImage alloc] initWithImageFrames: imageFrames];
    animatedImage.totalTime = totalTime;
    animatedImage.imageWidth = gifWidth;
    animatedImage.imageHeight = gifHeight;
    return animatedImage;
}


@end
