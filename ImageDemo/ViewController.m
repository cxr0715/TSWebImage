//
//  ViewController.m
//  ImageDemo
//
//  Created by YYInc on 2019/4/2.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+TSImage.h"

@interface ViewController ()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate> {
    CGImageSourceRef _source;
}
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UISlider *slider;
@property(nonatomic, strong) NSMutableData *data;
@property(nonatomic, assign) long long datalength;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.imageView = [[UIImageView alloc] init];
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self   .imageView.frame.origin.y, 300, 300);
    self.imageView.center = CGPointMake(self.view.frame.size.width / 2, self.view.center.y - 50);
    NSString *path = [[NSBundle mainBundle] pathForResource:@"mew_baseline.jpg" ofType:@""];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
//    [self HandleImage:image complite:^(UIImage *img) {
//        self.imageView.image = img;
//    }];
    [self.view addSubview:self.imageView];
    
    self.slider = [[UISlider alloc] init];
    [self.slider sizeToFit];
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 1.0;
    self.slider.value = 0;
    self.slider.center = CGPointMake(self.view.frame.size.width / 2, self.imageView.center.y);
    self.slider.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y + self.imageView.frame.size.height + 10, 300, 30);
    [self.slider addTarget:self action:@selector(change) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.slider];
    
    self.data = [NSMutableData data];
    
//    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
//
//    NSURLSessionDataTask *task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://i.pximg.net/img-original/img/2019/03/31/00/46/57/73960040_p0.png"]]];
//    
//    [task resume];
    
//    [self.imageView setImageViewWithURL:@"https://gss3.bdstatic.com/-Po3dSag_xI4khGkpoWK1HF6hhy/baike/w%3D268/sign=3fe6693cf91f3a295ac8d2c8a124bce3/314e251f95cad1c8143434c5763e6709c83d5141.jpg"];
//    [self.imageView setImageViewWithURL:@"https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png"];
    [self.imageView setImageViewWithURL:@"https://s2.ax1x.com/2019/04/22/EFL3fP.jpg"];
//    [self.imageView setImageViewWithURL:@"https://www.gstatic.com/webp/gallery/1.webp"];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.imageView setImageViewWithURL:@"https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png"];
//    });
}

- (void)change {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"mew_baseline.jpg" ofType:@""];
    if (!path) {
        NSLog(@"path nil");
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        NSLog(@"data nil");
    }
    float sliderProgress = self.slider.value;
    if (sliderProgress > 1) {
        sliderProgress = 1;
    }
    
    __block CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_source, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
    __weak typeof(self) weakSelf = self;
    dispatch_block_t taskBlock = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSData *subData = [data subdataWithRange:NSMakeRange(0, data.length * sliderProgress)];
        
        strongSelf->_source = CGImageSourceCreateIncremental(NULL);
        if (strongSelf->_source) {
            CGImageSourceUpdateData(strongSelf->_source, (__bridge CFDataRef)subData, false);
        }
        
        if (imageRef) {
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
            CFRelease(context);
        }
    });
    dispatch_async(dispatch_get_global_queue(0, 0), taskBlock);
    dispatch_block_notify(taskBlock, dispatch_get_main_queue(), ^{
        UIImage *image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        weakSelf.imageView.image = image;
//        CFRelease(imageRef);
    });
    
}

#pragma mark NSURLSessionDataDelegate
//处理服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {

    //这里可以通过NSURLResponse处理状态码之类，还可以获取http响应头信息，比如数据size
    NSLog(@"数据总size = %@", @(response.expectedContentLength));
    self.datalength = response.expectedContentLength;

    if (completionHandler) {
        // 允许处理服务器的响应，才会继续接收服务器返回的数据
        completionHandler(NSURLSessionResponseAllow);
    }
}

//处理接收到的数据 （数据量大的时候，会被调用多次）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.data appendData:data];
    NSLog(@"当前进度：百分之 %@", @(self.data.length * 1.f / self.datalength * 100));

    for (int i = 0; i < 5; i++) {
        [self change1];
    }
}

- (void)change1 {
    __block CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_source, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
    __weak typeof(self) weakSelf = self;
    dispatch_block_t taskBlock = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
//        NSData *subData = [data subdataWithRange:NSMakeRange(0, data.length * sliderProgress)];
        NSData *subData = self.data;

        strongSelf->_source = CGImageSourceCreateIncremental(NULL);
        if (strongSelf->_source) {
            CGImageSourceUpdateData(strongSelf->_source, (__bridge CFDataRef)subData, false);
        }

        if (imageRef) {
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
            CFRelease(context);
        }
    });
    dispatch_async(dispatch_get_global_queue(0, 0), taskBlock);
    dispatch_block_notify(taskBlock, dispatch_get_main_queue(), ^{
        UIImage *image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        weakSelf.imageView.image = image;
//        CFRelease(imageRef);
    });

}

#pragma mark NSURLSessionTaskDelegate
//任务结束
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        //主线程，可以在此更新UI
        NSLog(@"当前线程为： %@",[NSThread currentThread]);
//        self.imageView.image = [UIImage imageWithData:self.data];
    });
}

- (void)HandleImage:(UIImage *)img complite:(void(^)(UIImage *img))complite {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CGImageRef imgref = img.CGImage;
        size_t width = CGImageGetWidth(imgref);
        size_t height = CGImageGetHeight(imgref);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(imgref);//图片每个颜色的bits
        size_t bitsPerPixel = CGImageGetBitsPerPixel(imgref);//每一个像素占用的bits
        size_t bytesPerRow = CGImageGetBytesPerRow(imgref);//每一行占用多少bytes 注意是bytes不是bits  1byte ＝ 8bit
        
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(imgref);
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imgref);
        
        bool shouldInterpolate = CGImageGetShouldInterpolate(imgref);
        
        CGColorRenderingIntent intent = CGImageGetRenderingIntent(imgref);
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(imgref);
        
        CFDataRef data = CGDataProviderCopyData(dataProvider);
        
        UInt8 *buffer = (UInt8*)CFDataGetBytePtr(data);//Returns a read-only pointer to the bytes of a CFData object.// 首地址
        NSUInteger  x, y;
        // 像素矩阵遍历，改变成自己需要的值
        for (y = 0; y < height ; y++) {
            for (x = 0; x < width; x++) {
                //        for (y = height; y > height / 2; y--) {
                //            for (x = width; x > 0; x--) {
                
                UInt8 *tmp;
                tmp = buffer + y * bytesPerRow + x * 4;
                
                //                *tmp = 0;
                *(tmp + 1) = *tmp;
                *(tmp + 2) = *tmp;
                //                *(tmp + 3) = 0;
                //                UInt8 alpha;
                //                alpha = *(tmp + 3);
                //                UInt8 temp = *tmp;// 取red值
                //                if (alpha) {// 透明不处理 其他变成红色
                //                    *tmp = temp;//red
                //                    *(tmp + 1) = temp;//green
                //                    *(tmp + 2) = temp;// Blue
                //                }
            }
        }
        
        CFDataRef effectedData = CFDataCreate(NULL, buffer, CFDataGetLength(data));
        
        CGDataProviderRef effectedDataProvider = CGDataProviderCreateWithCFData(effectedData);
        // 生成一张新的位图
        CGImageRef effectedCgImage = CGImageCreate(
                                                   width, height,
                                                   bitsPerComponent, bitsPerPixel, bytesPerRow,
                                                   colorSpace, bitmapInfo, effectedDataProvider,
                                                   NULL, shouldInterpolate, intent);
        //        CGContextRef effectedCgImage1 = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, bitmapInfo);
        //        CGImageRef effectedCgImage = CGBitmapContextCreateImage(effectedCgImage1);
        
        UIImage *effectedImage = [[UIImage alloc] initWithCGImage:effectedCgImage];
        
        CGImageRelease(effectedCgImage);
        
        CFRelease(effectedDataProvider);
        
        CFRelease(effectedData);
        
        CFRelease(data);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complite) {
                complite(effectedImage);
            }
        });
    });
}

@end
