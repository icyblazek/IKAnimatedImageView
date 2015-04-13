//
//  IKAnimatedImage.h
//  IKAnimatedImageView
//
//  Created by Kevin on 8/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
    #define IKColor UIColor
    #define IKImage UIImage
#elif TARGET_OS_MAC
    #import <AppKit/AppKit.h>
    #define IKColor NSColor
    #define IKImage NSImage
#endif

@class IKAnimatedImageDecoder;

@interface IKAnimatedImageFrame: NSObject{
}

@property (assign) CGFloat delayTime;
@property (strong) id sourceImage;

@end

@interface IKAnimatedImage : NSObject{
    NSMutableArray *imageFrames;
    CAKeyframeAnimation *keyFrameAnimation;
    IKImage *_thumbImage;
}

/** init image frames
 * @params frames of IKAnimatedImageFrame
 */
-(id)initWithImageFrames:(NSArray*)frames;

+(IKAnimatedImage*)animatedImageWithImagePath:(NSString*)filePath Decoder:(IKAnimatedImageDecoder*)decoder;
+(IKAnimatedImage*)animatedImageWithImageData:(NSData*)imageData Decoder:(IKAnimatedImageDecoder*)decoder;

-(IKAnimatedImageFrame*)objectAtIndexedSubscript:(NSUInteger)idx;

/** create CAKeyframeAnimation
 */
-(CAKeyframeAnimation*)convertToKeyFrameAnimation;
-(NSArray*)getFrameTimes;


-(void)drawInRect:(CGRect)fromRect FrameIndex:(NSInteger)frameIndex;

@property (readonly) NSInteger frameCount;
@property (assign) CGFloat totalTime;
@property (assign) CGFloat imageWidth;
@property (assign) CGFloat imageHeight;
@property (strong) IKColor *backgroundColor;
@property (readonly) IKImage *thumbImage;

@end
