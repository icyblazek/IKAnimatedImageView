//
//  IKAnimatedImageDecoder.m
//  IKAnimatedImageView
//
//  Created by Kevin on 8/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKAnimatedImageDecoder.h"

@implementation IKAnimatedImageDecoder

+(IKAnimatedImageDecoder*)decoder
{
    return [[self alloc] init];
}

-(IKAnimatedImage*)decodeWithImageData:(NSData*)imageData
{
    NSAssert(NO, @"decode class must be a subclass of IKAnimatedImageDecoder");
    return NULL;
}

-(IKAnimatedImage*)decodeWithFilePath:(NSString*)filePath
{
    NSAssert(NO, @"decode class must be a subclass of IKAnimatedImageDecoder");
    NSData *imageData = [[NSData alloc] initWithContentsOfFile: filePath];
    return [self decodeWithImageData: imageData];
}

@end
