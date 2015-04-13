//
//  IKWebpImageDecoder.m
//  IKAnimatedImageView
//
//  Created by Kevin on 10/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKWebpImageDecoder.h"
#import "webp/decode.h"
#import "webp/mux_types.h"
#import <webp/demux.h>

#import "IKWebPAnimatedImage.h"

@implementation IKWebpImageDecoder

static void __freeWebpFrameImageData(void *info, const void *data, size_t size)
{
    free((void*)data);
}

-(IKAnimatedImage*)decodeWithImageData:(NSData*)imageData
{
    WebPData data;
    WebPDataInit(&data);
    
    data.bytes = (const uint8_t *)[imageData bytes];
    data.size = [imageData length];
    
    WebPDemuxer* demux = WebPDemux(&data);
    
    int width = WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH);
    int height = WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT);
    uint32_t bgColor = WebPDemuxGetI(demux, WEBP_FF_BACKGROUND_COLOR);
    uint32_t flags = WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS);
    
    CGFloat totalTime = 0;
    BOOL hasBlendMode = NO;
    NSMutableArray *imageFrames = [[NSMutableArray alloc] init];
    if (flags & ANIMATION_FLAG) {
        WebPIterator iter;
        if (WebPDemuxGetFrame(demux, 1, &iter)) {
            WebPDecoderConfig config;
            WebPInitDecoderConfig(&config);
            
            config.input.height = height;
            config.input.width = width;
            config.input.has_alpha = iter.has_alpha;
            config.input.has_animation = 1;
            config.options.no_fancy_upsampling = 1;
            config.options.bypass_filtering = 1;
            config.options.use_threads = 1;
            config.output.colorspace = MODE_RGBA;
            CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
            do {
                WebPData frame = iter.fragment;
                CGFloat delayTime = iter.duration / 1000.0;
                if (delayTime < 0.01)
                    delayTime = 0.1;
                VP8StatusCode status = WebPDecode(frame.bytes, frame.size, &config);
                if (status != VP8_STATUS_OK)
                    continue;
                int imageWidth, imageHeight;
                uint8_t *data = WebPDecodeRGBA(frame.bytes, frame.size, &imageWidth, &imageHeight);
                if (data == NULL)
                    continue;
                CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, imageWidth * imageHeight * 4, __freeWebpFrameImageData);
                CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
                CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
                CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, 4 * imageWidth, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
                
                IKWebPAnimatedImageFrame *imageFrame = [[IKWebPAnimatedImageFrame alloc] init];
                imageFrame.width = imageWidth;
                imageFrame.height = imageHeight;
                imageFrame.xOffset = iter.x_offset;
                imageFrame.yOffset = iter.y_offset;
                imageFrame.delayTime = delayTime;
                imageFrame.blend_method = iter.blend_method;
                imageFrame.sourceImage = (__bridge id)(imageRef);
                [imageFrames addObject: imageFrame];
                if (iter.blend_method == 0)
                    hasBlendMode = YES;
                CGImageRelease(imageRef);
                CGDataProviderRelease(provider);
                totalTime += delayTime;
            } while (WebPDemuxNextFrame(&iter));
            
            CGColorSpaceRelease(colorSpaceRef);
            WebPDemuxReleaseIterator(&iter);
            WebPFreeDecBuffer(&config.output);            
        }
    }
    WebPDemuxDelete(demux);
    if (imageFrames.count == 0)
        return NULL;
    IKWebPAnimatedImage *animatedImage = [[IKWebPAnimatedImage alloc] initWithImageFrames: imageFrames];
    float (^toColorf)(uint32_t, int) = ^(uint32_t color, int shift){
        return (color >> shift) / 255.f;
    };
#if TARGET_OS_IPHONE
    animatedImage.backgroundColor = [IKColor colorWithRed: toColorf(bgColor, 0)
                                                    green: toColorf(bgColor, 8)
                                                     blue: toColorf(bgColor, 16)
                                                    alpha: toColorf(bgColor, 24)];
#elif TARGET_OS_MAC
    animatedImage.backgroundColor = [IKColor colorWithDeviceRed: toColorf(bgColor, 0)
                                                          green: toColorf(bgColor, 8)
                                                           blue: toColorf(bgColor, 16)
                                                          alpha: toColorf(bgColor, 24)];
#endif

    animatedImage.totalTime = totalTime;
    animatedImage.imageWidth = width;
    animatedImage.imageHeight = height;
    animatedImage.hasBlendMode = hasBlendMode;
    return animatedImage;
}

@end
