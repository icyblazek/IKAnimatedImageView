//
//  AppDelegate.m
//  IKAnimatedImageView
//
//  Created by Kevin on 12/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "AppDelegate.h"
#import "IKAnimatedImageView.h"

//Gif解码器
#import "IKGifImageDecoder.h"

//Webp解码器，需要依赖libwebp库
#import "IKWebpImageDecoder.h"

@interface AppDelegate (){
    IKAnimatedImageView *gifImageView;
    IKAnimatedImageView *webpImageView;
    
    BOOL bUseCAKeyFrameAnimation;
    NSInteger pictureIndex;
}

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    bUseCAKeyFrameAnimation = NO;
    pictureIndex = 1;
    [self reloadImage];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

-(IBAction)btnUseCAKeyFrameAnimationClick:(id)sender
{
    bUseCAKeyFrameAnimation = [(NSButton*)sender state] == NSOnState;
    [self reloadImage];
}

-(IBAction)btnSwitchPictureClick:(id)sender
{
    pictureIndex = [(NSSegmentedControl*)sender selectedSegment] + 1;
    [self reloadImage];
}

-(void)reloadImage
{
    if (!gifImageView)
        gifImageView = [[IKAnimatedImageView alloc] initWithFrame: NSMakeRect(20, 50, 320, 240)];
    [self.window.contentView addSubview: gifImageView];
    
    NSString *pictureName = [NSString stringWithFormat: @"%ld", pictureIndex];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource: pictureName ofType: @"gif"];
    
    IKAnimatedImage *tmpImage = [IKAnimatedImage animatedImageWithImagePath: filePath Decoder: [IKGifImageDecoder decoder]];
    if (bUseCAKeyFrameAnimation)
        gifImageView.keyframeAnimation = [tmpImage convertToKeyFrameAnimation];
    else
        gifImageView.image = tmpImage;
    [gifImageView startAnimation];
    
    if (!webpImageView)
        webpImageView = [[IKAnimatedImageView alloc] initWithFrame: NSMakeRect(400, 50, 320, 240)];
    [self.window.contentView addSubview: webpImageView];
    filePath = [[NSBundle mainBundle] pathForResource: pictureName ofType: @"webp"];
    tmpImage = [IKAnimatedImage animatedImageWithImagePath: filePath Decoder: [IKWebpImageDecoder decoder]];
    if (bUseCAKeyFrameAnimation)
        webpImageView.keyframeAnimation = [tmpImage convertToKeyFrameAnimation];
    else
        webpImageView.image = tmpImage;
    [webpImageView startAnimation];
}

@end
