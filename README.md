# IKAnimatedImageView
动态图片显示组件,支持GIF、Webp格式,支持iOS和OSX
第一个Objective-C实现的Webp Animation的组件，找了一大圈，未找到（如有请告知）

##特点：  
1、支持多种文件格式，支持GIF，WebP(支持混合模式渲染)及自定义动态图片显示(APNG计划中...)  
2、可选择指定的渲染方式，使用CAKeyframeAnimation或者使用Core Graphics来进行渲染(后者节省约%50的内存)   
3、支持自定义渲染至任意视图中，不用重新创建任何容器组件(如NSView、UIView、CALayer)  
4、统一时间帧管理，支持在同一视图中，同时渲染多个相同或者不同的图片(如实现多个动态表情在同一个视图中显示)  
5、支持调整帧率，默认60FPS  

![](https://github.com/icyblazek/IKAnimatedImageView/blob/master/demo_capture.png)

##基础使用示例：
```objc
#import "IKAnimatedImageView.h"
//Gif解码器
#import "IKGifImageDecoder.h"
//Webp解码器，需要依赖libwebp库
#import "IKWebpImageDecoder.h"

NSString *filePath = [[NSBundle mainBundle] pathForResource: @"test" ofType: @"gif"];
IKAnimatedImage *gifImage = [IKAnimatedImage animatedImageWithImagePath: filePath Decoder: [IKGifImageDecoder decoder]];
IKAnimatedImageView *gifImageView = [[IKAnimatedImageView alloc] initWithFrame: NSMakeRect(0, 0, 320, 240)];
gifImageView.image = gifImage;
[gifImageView startAnimation];

filePath = [[NSBundle mainBundle] pathForResource: @"test" ofType: @"webp"];
IKAnimatedImage *webpImage = [IKAnimatedImage animatedImageWithImagePath: filePath Decoder: [IKWebpImageDecoder decoder]];
IKAnimatedImageView *webpImageView = [[IKAnimatedImageView alloc] initWithFrame: NSMakeRect(400, 0, 320, 240)];
webpImageView.image = tmpImage;
[webpImageView startAnimation];
```

##使用CAKeyframeAnimation渲染（内存会比自己渲染高50%左右）：
```objc
webpImageView.keyframeAnimation = [tmpImage convertToKeyFrameAnimation];
[webpImageView startAnimation];
```

##自定义渲染至其它视图中：
```objc
//yourTarget 是你需要接受需要重新渲染的通知的对象（一般可能都是NSView，UIView，或者CALayer）
//yourTarget 需要实现IKAnimatedRenderProtocol协议
NSInteger yourImageRenderID = [[IKAnimatedRenderManager RenderMangaer] addRenderObject: yourTarget AnimatedImage: yourImage];

//IKAnimatedRenderProtocol委托方法，动画帧更新时，会调用此方法
-(void)onUpdateAnimatedImageFrameWithIndex:(NSInteger)frameIndex AnimatedImageRenderID:(IKAnimatedImageRenderID)animatedImageRenderID
{
     if (yourImageRenderID != animatedImageRenderID) //判断当前渲染的对象是否为你当前需要渲染的对象，有可能是其它视图的
          return;
     currentFrameIndex = frameIndex; //更新当前帧索引
     //通知刷新视图
     [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)dirtyRect
{
     [yourImage drawInRect: self.bounds FrameIndex: currentFrameIndex];
}
```

##渲染多个图片至一个视图中：
```objc
NSInteger render1 = [[IKAnimatedRenderManager RenderMangaer] addRenderObject: yourTarget AnimatedImage: yourImage1];
NSInteger render2 = [[IKAnimatedRenderManager RenderMangaer] addRenderObject: yourTarget AnimatedImage: yourImage2];

//IKAnimatedRenderProtocol委托方法，动画帧更新时，会调用此方法
-(void)onUpdateAnimatedImageFrameWithIndexs:(NSArray*)frameIndexs AnimatedImageRenderIDs:(NSArray*)animatedImageRenderIDs
{
     //判断及更新相应的图片对象及索引
     //animatedImageRenderIDs对应的帧索引在frameIndexs里面
     //通知刷新视图
     [self setNeedsDisplay];
}
```

##支持调整动画帧率（默认60fps）：
```objc
[IKAnimatedRenderManager RenderMangaer].frameInterval = 1 / 30.0f; // 30fps
```

##示例代码说明
webp解码器需要依赖libwebp，请先安装
```bash
cd IKAnimatedImageView
pod install
```

##后续计划
1、优化内存使用，提高渲染性能  
2、直接扩展NSImageView,NSImage,UIImageView,UIImage,，简化的API  
3、添加APNG格式（可能不会添加，貌似意义不大，虽然最近iOS Safari支持APNG了）  

###联系
如有建议或者疑问，欢迎Email: icyblazek@gmail.com
