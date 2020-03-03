//
//  TSImageOperation.m
//  ImageDemo
//
//  Created by YYInc on 2019/4/8.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import "TSImageOperation.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "TSImageWebP.h"
#import "NSObject+YYTaskPool.h"

@interface TSImageOperation () {
    BOOL executing;
    BOOL finished;
}
@property (nonatomic, strong) NSMutableData *imageData;
@property (nonatomic, assign) NSUInteger expectedSize;
@property (nonatomic, assign) NSUInteger receivedSize;
@property (nonatomic, strong) NSURL *url;
@end

@implementation TSImageOperation {
    CGImageSourceRef _imageSource;
    size_t _width, _height;
    CGImagePropertyOrientation _orientation;
    CGImageRef _imageSourceRef;
}
- (instancetype)init {
    if (self = [super init]) {
        _expectedSize = 0;
        _receivedSize = 0;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url completed:(SDImageLoaderCompletedBlock)completed {
    if (self = [super init]) {
        _url = url;
        _imageBlock = completed;
        executing = NO;
        finished = NO;
        _expectedSize = 0;
        _receivedSize = 0;
    }
    return self;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (void)start {
    if (self.isCancelled) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 15;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    
    NSURLRequestCachePolicy cachePolicy = NSURLRequestUseProtocolCachePolicy;// 默认的缓存策略
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.url cachePolicy:cachePolicy timeoutInterval:15];
    NSURLSessionTask *sessionTask = [session dataTaskWithRequest:request];
    [sessionTask resume];
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)loadImageWithURL:(NSURL *)url withImageBlock:(SDImageLoaderCompletedBlock)imageBlock {
    self.imageBlock = imageBlock;
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 15;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    
    NSURLRequestCachePolicy cachePolicy = NSURLRequestUseProtocolCachePolicy;// 默认的缓存策略
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:cachePolicy timeoutInterval:15];
    NSURLSessionTask *sessionTask = [session dataTaskWithRequest:request];
    [sessionTask resume];
    
}

#pragma mark NSURLSessionDataDelegate
// 收到数据包头部的时候会回调这个代理
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSInteger expected = (NSInteger)response.expectedContentLength;
    expected = expected > 0 ? expected : 0;
    self.expectedSize = expected;
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

// 收到数据就会回调这个代理
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (!self.imageData) {
        self.imageData = [[NSMutableData alloc] initWithCapacity:self.expectedSize];
    }
    [self.imageData appendData:data];
    
    self.receivedSize = self.imageData.length;
    if (self.expectedSize == 0) {
        NSString *desc = @"from TSImageOperation NSURLSessionDataDelegate imageData.length = 0";
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        NSError *error = [NSError errorWithDomain:@"com.cxr" code:-1 userInfo:userInfo];
        self.imageBlock(nil, nil, error, YES);
        return;
    }
    
    BOOL finished = (self.receivedSize >= self.expectedSize);
    NSData *imageData = [self.imageData copy];
    
    [self dataCreateImageSoueceWithImageType:imageData finish:finished];

}

#pragma mark NSURLSessionTaskDelegate
// 收到所有数据后会回调这个代理
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
//    [self bitmapToImage:self.imageData imageRef:_imageSourceRef];
}

#pragma mark util
- (void)dataCreateImageSoueceWithImageType:(NSData *)data finish:(BOOL)finish {
    if (!data) {
        return;
    }
    
    uint8_t c;
    [data getBytes:&c length:1];
    CFStringRef imageUTType;
    
    switch (c) {
        case 0xFF:
        {
            imageUTType = kUTTypeJPEG;
            break;
        }
        case 0x89:
        {
            imageUTType = kUTTypePNG;
            break;
        }
        case 0x47:
        {
            imageUTType = kUTTypeGIF;
            break;
        }
        case 0x52: {
//            if (data.length >= 12) {
//                //RIFF....WEBP
//                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
//                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    imageUTType = ((__bridge CFStringRef)@"public.webp");
//                }
//            }
            break;
        }
        default:
        {
            imageUTType = kUTTypePNG;
            break;
        }
    }
    
    _imageSource = CGImageSourceCreateIncremental((__bridge CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : (__bridge NSString *)imageUTType});// 创建一个渐进形的指定类型的CGImageSourceRef
    switch (c) {
//        case 0xFF:
//        {
//            [self updateIncrementalData:data finished:finish];
//            break;
//        }
//        case 0x89:
//        {
//            [self updateIncrementalData:data finished:finish];
//            break;
//        }
//        case 0x47:
//        {
//            [self updateIncrementalData:data finished:finish];
//            break;
//        }
        case 0x52:
        {
            if (data.length >= 12) {
                //RIFF....WEBP
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    TSImageWebP *webp = [[TSImageWebP alloc] initIncremental];
                    [webp updateIncrementalData:data finished:finish];
                    UIImage *image = [webp incrementalDecodedImage];
                    __weak typeof(self) weakSelf = self;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        [strongSelf willChangeValueForKey:@"isFinished"];
                        [strongSelf willChangeValueForKey:@"isExecuting"];
                        
                        strongSelf->executing = NO;
                        strongSelf->finished = YES;
                        
                        [strongSelf didChangeValueForKey:@"isExecuting"];
                        [strongSelf didChangeValueForKey:@"isFinished"];
                        strongSelf.imageBlock(image, strongSelf.imageData, nil, finish);
                    });
                }
            }
            break;
        }
        default:
        {
            [self updateIncrementalData:data finished:finish];
            break;
        }
    }
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
//    if (finished) {
//        return;
//    }
    
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)data, finished);// 向imageSource中渐进形的添加内容
    
    if (_width + _height == 0) {
        // 获取imageSource的属性
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            NSInteger orientationValue = 1;
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) {
                CFNumberGetValue(val, kCFNumberLongType, &_height);
            }
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) {
                CFNumberGetValue(val, kCFNumberLongType, &_width);
            }
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) {
                CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
            }
            CFRelease(properties);
            
            // When we draw to Core Graphics, we lose orientation information,
            // which means the image below born of initWithCGIImage will be
            // oriented incorrectly sometimes. (Unlike the image born of initWithData
            // in didCompleteWithError.) So save it here and pass it on later.
            _orientation = (CGImagePropertyOrientation)orientationValue;
        }
    }
    
    // 创建一个CGImage对象
    CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
    partialImageRef = [self imageDecode:partialImageRef];
    _imageSourceRef = partialImageRef;
    UIImage *image = [UIImage imageWithCGImage:partialImageRef scale:1 orientation:UIImageOrientationUp];
    
//    CGImageRelease(partialImageRef);
    
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf willChangeValueForKey:@"isFinished"];
        [strongSelf willChangeValueForKey:@"isExecuting"];
        
        strongSelf->executing = NO;
        strongSelf->finished = YES;
        
        [strongSelf didChangeValueForKey:@"isExecuting"];
        [strongSelf didChangeValueForKey:@"isFinished"];
        strongSelf.imageBlock(image, strongSelf.imageData, nil, finished);
    });
}

- (CGImageRef)imageDecode:(CGImageRef)imageRef {
    // 获取Alpha信息
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    
    // BGRA8888 (premultiplied) or BGRX8888
    // same as UIGraphicsBeginImageContext() and -[UIView drawRect:]
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    
    // 创建图片信息上下文，data:需要渲染的内存块大小，理论上来说应该是bytesPerRow * _height
    // width:宽度
    // height:高度
    // bitsPerComponent:每个分位像素的位数，例如32位色的RGBA图片的R，G，B，A位数就是8位
    // bytesPerRow:每行位图使用的内存字节数，传入0自动计算，例如32位色图，就是32
    // colorSpace:颜色空间信息
    // bitmapInfo:是否包含Alpha通道，已经Alpha的位置，例如是RGBA还是ARGB等。
//    CFDataRef data = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&imageRef, CGImageGetBytesPerRow(imageRef));
    
    CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, 0, CGColorSpaceCreateDeviceRGB(), bitmapInfo);
    if (!context) return NULL;
    
    // 绘制
    CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), imageRef); // decode
    
    // 从上下文中获取CGImage
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    
    CFRelease(context);
    
//    NSInteger bitsPerComponent = 8;
//    NSInteger bitsPerPixel = 4 * 8;
//    size_t alignment = _width * bitsPerPixel;
//    NSInteger row = ((_width + (alignment - 1)) / alignment) * alignment;
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, [self.imageData bytes], [self.imageData length], NULL);
//    bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
//    CGImageRef newImage1 = CGImageCreate(_width, _height, bitsPerComponent, bitsPerPixel, row, colorSpace, bitmapInfo, dataProvider, NULL, false, (CGColorRenderingIntent)0);
    
    return newImage;
}

- (void)createImageWithData:(NSData *)data withBlock:(TSImageFromDiskCompletedBlock)completed {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!imageSource) {
        return;
    }
    
    __block size_t width, height;
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    if (properties) {
        NSInteger orientationValue = 1;
        CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
        if (val) {
            CFNumberGetValue(val, kCFNumberLongType, &height);
        }
        val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
        if (val) {
            CFNumberGetValue(val, kCFNumberLongType, &width);
        }
        val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
        if (val) {
            CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
        }
        CFRelease(properties);
        
        // When we draw to Core Graphics, we lose orientation information,
        // which means the image below born of initWithCGIImage will be
        // oriented incorrectly sometimes. (Unlike the image born of initWithData
        // in didCompleteWithError.) So save it here and pass it on later.
        _orientation = (CGImagePropertyOrientation)orientationValue;
    }

    __block CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    if (!imageRef) {
        return;
    }
    [self addTask:^{
        imageRef = [self imageDecodeFromDisk:imageRef withWidth:width withHeight:height];
        
    } blockAfterToMain:^{
        UIImage *image = [UIImage imageWithCGImage:imageRef scale:1 orientation:UIImageOrientationUp];
        if (completed) {
            completed(image);
        }
    }];    
}

- (CGImageRef)imageDecodeFromDisk:(CGImageRef)imageRef withWidth:(size_t)width withHeight:(size_t)height {
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    
    // BGRA8888 (premultiplied) or BGRX8888
    // same as UIGraphicsBeginImageContext() and -[UIView drawRect:]
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
//    CFDataRef data = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&imageRef, CGImageGetBytesPerRow(imageRef));
//    
//    CGContextRef context = CGBitmapContextCreate((void *)data, _width, _height, 8, 0, CGColorSpaceCreateDeviceRGB(), bitmapInfo);
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, CGColorSpaceCreateDeviceRGB(), bitmapInfo);
    if (!context) return NULL;
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); // decode
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    CFRelease(context);
    
    return newImage;
}

- (void)bitmapToImage:(NSData *)soucreData imageRef:(CGImageRef)imageRef {
    CGImageRef imgref = imageRef;
    size_t width = CGImageGetWidth(imgref);
    size_t height = CGImageGetHeight(imgref);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imgref);//图片每个颜色的bits
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imgref);//每一个像素占用的bits，15 位24位 32位等等
    size_t bytesPerRow = CGImageGetBytesPerRow(imgref);//每一行占用多少bytes(字节) 注意是bytes不是bits(比特)  1byte ＝ 8bit
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imgref);//颜色空间，比如rgb
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imgref);
    
    bool shouldInterpolate = CGImageGetShouldInterpolate(imgref);
    
    CFDataRef data = CFBridgingRetain(soucreData);
    UInt8 *buffer = (UInt8*)CFDataGetBytePtr(data);//Returns a read-only pointer to the bytes of a CFData object.// 首地址
    NSUInteger  x, y;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            //        for (y = height; y > height / 2; y--) {
            //            for (x = width; x > 0; x--) {
            
            UInt8 *tmp;
            tmp = buffer + y * bytesPerRow + x * 4;
            
            //                *tmp = 0;
            UInt8 red,green,blue,alpha;
            red = *(tmp + 0);
            green = *(tmp + 1);
            blue = *(tmp + 2);
            alpha = *(tmp + 3);
            
            UInt8 brightness = (77 * red + 28 * green + 151 * blue) / 256;
            *(tmp + 0) = brightness;
            *(tmp + 1) = brightness;
            *(tmp + 2) = brightness;
            *(tmp + 3) = alpha;
            
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
    CGContextRef effectedCgImage1 = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, bitmapInfo);
    
    CGImageRef effectedCgImage = CGBitmapContextCreateImage(effectedCgImage1);
    
    UIImage *effectedImage = [[UIImage alloc] initWithCGImage:effectedCgImage];
    
    CGImageRelease(effectedCgImage);
    
    CFRelease(effectedDataProvider);
    
    CFRelease(effectedData);
    
    CFRelease(data);
    
}

@end
