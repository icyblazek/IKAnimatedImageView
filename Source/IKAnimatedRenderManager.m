//
//  IKAnimatedRenderManager.m
//  IKAnimatedImageView
//
//  Created by Kevin on 9/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "IKAnimatedRenderManager.h"

@interface IKAnimatedRenderInfo : NSObject{
    
}

-(id)initWithAnimatedImage:(IKAnimatedImage*)animatedImage;
-(NSInteger)frameIndexWithTimestamp:(NSTimeInterval)timestamp;

@property (weak) id<IKAnimatedRenderProtocol> renderObject;
@property (assign) IKAnimatedImageRenderID renderID;
@property (assign) NSInteger lastFrameIndex;
@property (assign) CGFloat lastTime;
@property (assign) CGFloat totalTime;
@property (strong) NSArray *frameTimes;

@end

#pragma mark ============= IKAnimatedRenderInfo =============

@implementation IKAnimatedRenderInfo

-(id)initWithAnimatedImage:(IKAnimatedImage*)animatedImage
{
    if (self = [super init]){
        _lastFrameIndex = 0;
        self.frameTimes = [animatedImage getFrameTimes];
        _lastTime = 0;
        _totalTime = animatedImage.totalTime;
    }
    return self;
}

-(NSInteger)frameIndexWithTimestamp:(NSTimeInterval)timestamp
{
    if (timestamp > _totalTime)
        return _frameTimes.count - 1;
    if (timestamp <= 0)
        return 0;
    NSInteger foundIndex = 0;
    CGFloat tmpTotalTime = 0;
    for (NSInteger index = 0; index < _frameTimes.count; index++){
        CGFloat currentFrameTime = [_frameTimes[index] floatValue];
        CGFloat maxFrameTime = tmpTotalTime + currentFrameTime;
        if (timestamp >= tmpTotalTime && timestamp <= maxFrameTime){
            foundIndex = index;
            break;
        }
        tmpTotalTime += currentFrameTime;
    }
    return foundIndex;
}

@end

#pragma mark ============= IKAnimatedRenderManager =============

@interface IKAnimatedRenderManager (){
    NSUInteger _animatedImageCount;
    NSLock *_resourceLock;
    NSMutableDictionary *_renderObjects;
    
#if TARGET_OS_IPHONE
    CADisplayLink *_displayLinkRef;
#elif TARGET_OS_MAC
    CVDisplayLinkRef _displayLinkRef;
    double __lastFrameDuration;
#endif
    bool _displayLinkRunning;
    double _frameInterval;
}

@end

@implementation IKAnimatedRenderManager

static IKAnimatedRenderManager *__animatedRenderManager;
static dispatch_once_t __animatedRenderManager_once_t;

@synthesize frameInterval = _frameInterval;


+(IKAnimatedRenderManager*)RenderMangaer
{
    dispatch_once(&__animatedRenderManager_once_t, ^{
        __animatedRenderManager = [[IKAnimatedRenderManager alloc] init];
    });
    return __animatedRenderManager;
}

-(id)init
{
    if (self = [super init]){
        _resourceLock = [[NSLock alloc] init];
        _renderObjects = [[NSMutableDictionary alloc] init];
        //默认 60fps
        _frameInterval = 1 / 60.0;
        _displayLinkRunning = NO;
    }
    return self;
}

-(void)setFrameInterval:(double)frameInterval
{
    if (_frameInterval != frameInterval){
        [self displayLinkStop];
        _frameInterval = frameInterval;
        
        [_resourceLock lock];
        [_renderObjects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            IKAnimatedRenderInfo *renderInfo = obj;
            renderInfo.lastFrameIndex = 0;
            renderInfo.lastTime = 0;
        }];
        [_resourceLock unlock];
        [self displayLinkStart];
    }
}

-(double)frameInterval
{
    return _frameInterval;
}

-(void)displayLinkStart
{
    if (!_displayLinkRunning){
        
#if TARGET_OS_IPHONE
        _displayLinkRef = [CADisplayLink displayLinkWithTarget: self selector: @selector(onDisplayLinkCallback:)];
        [_displayLinkRef setFrameInterval: _frameInterval * 60];
        [_displayLinkRef addToRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
#elif TARGET_OS_MAC
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLinkRef);
        CVDisplayLinkSetOutputCallback(_displayLinkRef, __displayLinkOutputCallback, (__bridge void *)self);
        CVDisplayLinkStart(_displayLinkRef);
#endif
        _displayLinkRunning = YES;
    }
}

-(void)displayLinkStop
{
    #if TARGET_OS_IPHONE
        [_displayLinkRef invalidate];
        _displayLinkRef = nil;
    #elif TARGET_OS_MAC
        CVDisplayLinkStop(_displayLinkRef);
        CVDisplayLinkRelease(_displayLinkRef);
        _displayLinkRef = NULL;
    #endif
        _displayLinkRunning = NO;
}


-(IKAnimatedImageRenderID)addRenderObject:(id<IKAnimatedRenderProtocol>)renderObject AnimatedImage:(IKAnimatedImage*)animatedImage
{
    _animatedImageCount++;
    IKAnimatedRenderInfo *renderInfo = [[IKAnimatedRenderInfo alloc] initWithAnimatedImage: animatedImage];
    renderInfo.renderID = _animatedImageCount;
    renderInfo.renderObject = renderObject;
    
    [_resourceLock lock];
    [_renderObjects setObject: renderInfo forKey: [NSNumber numberWithUnsignedInteger: renderInfo.renderID]];
    [_resourceLock unlock];
    
    [self displayLinkStart];
    
    return _animatedImageCount;
}

-(void)removeRenderObject:(IKAnimatedImageRenderID)animatedImageID
{
    [_resourceLock lock];
    __block NSNumber *foundKey = nil;
    [_renderObjects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        IKAnimatedImageRenderID tmpRenderID = [(NSNumber*)key unsignedIntegerValue];
        if (animatedImageID == tmpRenderID){
            foundKey = (NSNumber*)key;
            *stop = YES;
        }
    }];
    if (foundKey){
        IKAnimatedRenderInfo *renderInfo = [_renderObjects objectForKey: foundKey];
        [_renderObjects removeObjectForKey: foundKey];
        renderInfo.renderObject = nil;
    }
    
    BOOL needStopDisplayLink = _renderObjects.count == 0;
    [_resourceLock unlock];
    if (!needStopDisplayLink)
        return;
    [self displayLinkStop];
}

-(void)onRefreshAllRenderObjectsWithDuration:(CFTimeInterval)duration
{
#if !TARGET_OS_IPHONE
    __lastFrameDuration += duration;
    if (__lastFrameDuration < _frameInterval)
        return;
    __lastFrameDuration = 0;
#endif
    @autoreleasepool {
        NSMutableDictionary *needUpdateRenderObjects = [[NSMutableDictionary alloc] init];
        [_resourceLock lock];
        [_renderObjects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            IKAnimatedRenderInfo *renderInfo = obj;
            renderInfo.lastTime += duration;
            NSInteger newIndex = [renderInfo frameIndexWithTimestamp: renderInfo.lastTime];
            if (newIndex != renderInfo.lastFrameIndex){
                renderInfo.lastFrameIndex = newIndex;
                if (newIndex >= renderInfo.frameTimes.count - 1)
                    renderInfo.lastTime = 0;
                
                //合并同一个渲染对象，优化处理，当同一个渲染对象有多个图片对象需要更新时，只通知该渲染对象一次，并传入需要更新多个图片对象的ID
                NSString *tmpNeedRenderKey = [NSString stringWithFormat: @"%p", renderInfo.renderObject];
                NSMutableArray *renderIDs = [needUpdateRenderObjects objectForKey: tmpNeedRenderKey];
                if (!renderIDs){
                    renderIDs = [[NSMutableArray alloc] init];
                    [needUpdateRenderObjects setObject: renderIDs forKey: tmpNeedRenderKey];
                }
                [renderIDs addObject: obj];
            }
        }];
        [_resourceLock unlock];
        if (needUpdateRenderObjects.count > 0){
            dispatch_async(dispatch_get_main_queue(), ^{
                //通知更新需要重新渲染的对象
                [needUpdateRenderObjects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSArray *renderInfos = (NSArray*)obj;
                    if (renderInfos.count > 1){ //同一个渲染对象，多个图片对象
                        IKAnimatedRenderInfo *renderInfo = [renderInfos firstObject];
                        if ([renderInfo.renderObject respondsToSelector: @selector(onUpdateAnimatedImageFrameWithIndexs:AnimatedImageRenderIDs:)]){
                            NSArray *indexs = [renderInfos valueForKeyPath: @"lastFrameIndex"];
                            NSArray *renderIDS = [renderInfos valueForKeyPath: @"renderID"];
                            [renderInfo.renderObject onUpdateAnimatedImageFrameWithIndexs: indexs AnimatedImageRenderIDs: renderIDS];
                        }
                    }else {
                        IKAnimatedRenderInfo *renderInfo = [renderInfos firstObject];
                        if ([renderInfo.renderObject respondsToSelector: @selector(onUpdateAnimatedImageFrameWithIndex:AnimatedImageRenderID:)])
                            [renderInfo.renderObject onUpdateAnimatedImageFrameWithIndex: renderInfo.lastFrameIndex AnimatedImageRenderID: renderInfo.renderID];
                    }
                }];
            });
        }
    }
}


/** CVDisplayLinkRef 委托回调函数
 *
 */
#if TARGET_OS_IPHONE
-(void)onDisplayLinkCallback:(CADisplayLink*)displayerLink
{
    [self onRefreshAllRenderObjectsWithDuration: displayerLink.duration];
}
#elif TARGET_OS_MAC
CVReturn __displayLinkOutputCallback(CVDisplayLinkRef displayLink,
                                     const CVTimeStamp *inNow,
                                     const CVTimeStamp *inOutputTime,
                                     CVOptionFlags flagsIn,
                                     CVOptionFlags *flagsOut,
                                     void *displayLinkContext)
{
    double fps = inOutputTime->rateScalar * (double)inOutputTime->videoTimeScale / (double)inOutputTime->videoRefreshPeriod;
    NSTimeInterval duration = 1.0 / fps;
    [(__bridge IKAnimatedRenderManager*)displayLinkContext onRefreshAllRenderObjectsWithDuration: duration];
    return kCVReturnSuccess;
}
#endif

@end
