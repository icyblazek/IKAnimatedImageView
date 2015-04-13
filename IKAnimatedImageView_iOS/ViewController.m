//
//  ViewController.m
//  IKAnimatedImageView_iOS
//
//  Created by Kevin on 12/4/15.
//  Copyright (c) 2015 Icyblaze. All rights reserved.
//

#import "ViewController.h"
#import "IKAnimatedImageView.h"
//Gif解码器
#import "IKGifImageDecoder.h"

//Webp解码器，需要依赖libwebp库
#import "IKWebpImageDecoder.h"

@interface ViewController (){
    IKAnimatedImageView *gifImageView;
    IKAnimatedImageView *webpImageView;
    
    BOOL bUseCAKeyFrameAnimation;
    NSInteger pictureIndex;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    bUseCAKeyFrameAnimation = NO;
    pictureIndex = 1;
    [self reloadImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)btnUseCAKeyFrameAnimationClick:(id)sender
{
    bUseCAKeyFrameAnimation = [(UISegmentedControl*)sender selectedSegmentIndex] == 0;
    [self reloadImage];
}

-(IBAction)btnSwitchPictureClick:(id)sender
{
    pictureIndex = [(UISegmentedControl*)sender selectedSegmentIndex] + 1;
    [self reloadImage];
}

-(void)reloadImage
{
    if (gifImageView){
        [gifImageView removeFromSuperview];
        gifImageView = nil;
    }
    gifImageView = [[IKAnimatedImageView alloc] initWithFrame: CGRectMake(20, 100, 320, 240)];
    [self.view addSubview: gifImageView];
    
    NSString *pictureName = [NSString stringWithFormat: @"%ld", pictureIndex];
    NSString *filePath = [[NSBundle mainBundle] pathForResource: pictureName ofType: @"gif"];
    
    IKAnimatedImage *tmpImage = [IKAnimatedImage animatedImageWithImagePath: filePath Decoder: [IKGifImageDecoder decoder]];
    if (bUseCAKeyFrameAnimation)
        gifImageView.keyframeAnimation = [tmpImage convertToKeyFrameAnimation];
    else
        gifImageView.image = tmpImage;
    [gifImageView startAnimation];
    
    
    if (webpImageView){
        [webpImageView removeFromSuperview];
        webpImageView = nil;
    }
    webpImageView = [[IKAnimatedImageView alloc] initWithFrame: CGRectMake(20, 360, 320, 240)];
    [self.view addSubview: webpImageView];
    filePath = [[NSBundle mainBundle] pathForResource: pictureName ofType: @"webp"];
    tmpImage = [IKAnimatedImage animatedImageWithImagePath: filePath Decoder: [IKWebpImageDecoder decoder]];
    if (bUseCAKeyFrameAnimation)
        webpImageView.keyframeAnimation = [tmpImage convertToKeyFrameAnimation];
    else
        webpImageView.image = tmpImage;
    [webpImageView startAnimation];
}

@end
