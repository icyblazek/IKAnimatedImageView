//
//  IKAnimatedImageDecoder.h
//  IKAnimatedImageView
//
//  Created by Kevin on 8/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IKAnimatedImage.h"

@interface IKAnimatedImageDecoder : NSObject{

}

/** new decoder
 */
+(IKAnimatedImageDecoder*)decoder;

/** image date decode to IKAnimtedImage
 */
-(IKAnimatedImage*)decodeWithImageData:(NSData*)imageData;

/** image file decode to IKAnimtedImage
 */
-(IKAnimatedImage*)decodeWithFilePath:(NSString*)filePath;

@end
