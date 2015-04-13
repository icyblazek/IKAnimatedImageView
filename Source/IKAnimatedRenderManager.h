//
//  IKAnimatedRenderManager.h
//  IKAnimatedImageView
//
//  Created by Kevin on 9/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IKAnimatedImage.h"

typedef NSUInteger IKAnimatedImageRenderID;

@protocol IKAnimatedRenderProtocol <NSObject>

@optional
/**
 *
 */
-(void)onUpdateAnimatedImageFrameWithIndex:(NSInteger)frameIndex AnimatedImageRenderID:(IKAnimatedImageRenderID)animatedImageRenderID;
-(void)onUpdateAnimatedImageFrameWithIndexs:(NSArray*)frameIndexs AnimatedImageRenderIDs:(NSArray*)animatedImageRenderIDs;

@end

@interface IKAnimatedRenderManager : NSObject{

}

+(IKAnimatedRenderManager*)RenderMangaer;

/** 添加需要渲染对象至队列
 * @renderObject 该对象需要实现IKAnimatedRenderProtocol
 * @animtedImage 读取原始动态图片相关信息
 * @return Animated Image ID
 */
-(IKAnimatedImageRenderID)addRenderObject:(id<IKAnimatedRenderProtocol>)renderObject AnimatedImage:(IKAnimatedImage*)animatedImage;

/** 移除渲染对象，当图片不需要渲染，或者停止动画时调用该方法
 */
-(void)removeRenderObject:(IKAnimatedImageRenderID)animatedImageID;

@property (assign) double frameInterval;

@end
