# TSImage

TSImage：轻量级的图片加载框架。参考[UIImageView+AFNetworking](https://github.com/AFNetworking/AFNetworking/blob/master/UIKit+AFNetworking/UIImageView+AFNetworking.h)，[SDWebImage](<https://github.com/SDWebImage/SDWebImage>)，[YYWebImage](<https://github.com/ibireme/YYWebImage>)，[FastImageCache](<https://github.com/path/FastImageCache>)实现。

主要实现的功能包括：

1.下载图片（包括下载方式，异步下载的队列管理）。

2.异步decode图片（调用ImageIO的API，实现data的渐进式图片解码）。

3.缓存实现。

4.FastImageCache相关的图片加载优化（还未实现，相关原理简析）。

## 1.下载图片实现

### 1.1下载方式

| AFNetWorking | SDWebImage   | YYWebImage      |
| ------------ | ------------ | --------------- |
| NSURLSession | NSURLSession | NSURLConnection |

NSURLConnection：

YYWebImage使用的NSURLConnection方法：

\_connection = [[NSURLConnection alloc] initWithRequest:\_request delegate:[\_YYWebImageWeakProxy proxyWithTarget:self]];

传入NSURLRequest已经需要回调的代理即可，传入参数较少，定制特定请求参数的能力较差。

NSURLSession：

![](<https://user-gold-cdn.xitu.io/2017/2/20/b948328ad51bf3e772c222476ff7bb56?imageslim>)

NSURLSession只是一个抽象类，它本身并不会进行真正的请求，而是通过创建NSURLSessionTask进行网络请求的，同一个NSURLSession可以创建多个task，task之间是共享cache和cookie的。

![](https://user-gold-cdn.xitu.io/2017/2/20/4d44abd141f927297a0f421d3423b33b?imageslim)

NSURLSessionTask又包括：

NSURLSessionDataTask：用来执行从服务器下载数据的请求任务，例如读取json，读取图片数据等。

NSURLSessionDownloadTask：用来执行从服务器下载文件的任务，包括回调下载进度，断点续传，直接将下载下来的文件放入沙盒而不是内存—这也是和NSURLConnection不同的一点。

NSURLSessionUploadTask：用来执行从本地上传文件到服务器的任务。

NSURLSessionTask可以看做是NSURLSessionDataTask，NSURLSessionDownloadTask，NSURLSessionUploadTask的[类簇](https://baike.baidu.com/item/类簇)。

NSURLSession使用：

![](/Users/yyinc/Library/Application Support/typora-user-images/image-20190422181410683.png)

创建NSURLSessionConfiguration，可以设定缓存策略，超时时间，网络服务类型等。通过NSURLSessionConfiguration创建NSURLSession，指定通过delegate的形式回调，可以指定回调的NSOperationQueue。再创建NSURLSessionTask，每一个创建的NSURLSessionTask都是被挂起的状态，调用resume执行该任务。

![](/Users/yyinc/Library/Application Support/typora-user-images/image-20190422182436934.png)

在当前类中实现NSURLSessionDataDelegate，在- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;中实现completionHandler(NSURLSessionResponseAllow);以允许接受后续数据。

\- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;在这个代理方法中接受数据。

### 1.2下载队列管理

| AFNetWorking                                                 | SDWebImage                                                   | YYWebImage                                                   |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| AFURLSessionManager中实现代理回调，在自定义的子线程中处理数据，在创建NSURLSession的时候指定了回调的Queue。存放AFURLSessionManagerTaskDelegate到AFURLSessionManager的字典中，然后在数据回调的时候根据key取出对应的value，回调completionHandler | 使用集成自NSOperation的SDWebImageDownloaderOperation，在SDWebImageDownloaderOperation中实现NSURLSessionDataDelegate的代理，加入Operation到指定线程中回调数据。 | 类似SD，使用集成自NSOperation的YYWebImageOperation，在其中实现NSURLConnection的代理，加入Operation到指定线程中回调数据。 |

TSImage仿照SD和YYWebImage，自定义集成自NSOperation的TSImageOperation，把每一个新的请求都封装为一个TSImageOperation，加入创建出来的TSImageOperation到TaskScheduler中。因为是继承NSOperation的自定义Operation任务，所以需要自己定义executing，finished等状态，自己去维护这些状态。通过重写- (BOOL)isConcurrent方法允许并发，通过重写- (void)start方法来启动自定义的Operation任务。在start方法中启动NSURLSession，在对应的delegate中回调数据。

![](/Users/yyinc/Library/Application Support/typora-user-images/image-20190422203957705.png)

## 2.图片缓存

| AFNetWorking                                                 | SDWebImage                                                   | YYWebImage                                       |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------ |
| 只有内存缓存，没有磁盘缓存。简单的NSMutableDictionary的内存缓存。 | 有内存缓存也有磁盘缓存。分为SDMemoryCache和SDDiskCache，其中SDMemoryCache集成自NSCache，SDDiskCache根据URL的MD5值缓存数据在磁盘。 | 使用YYCache做缓存，自己实现的双向链表，实现LRU。 |

TSImage使用TSImageCache，继承自NSCache，也有自己实现的双向链表TSList，自己实现的简单的LRU算法。

![](/Users/yyinc/Library/Application Support/typora-user-images/image-20190422211941295.png)

## 3.异步decode图片

这里三个框架都有实现异步的图片decode，实现方式都是大同小异，都是调用ImageIO的API，实现手动的异步子线程解码图片。

TSImage使用的渐进式解码，具体的实现如下：

1.首先在接收到数据后，判断当前图片的类型，可以根据返回的data的头部来判断当前图片类型，例如0xFF是JPG，0x89是PNG。

2.

```objective-c
_imageSource = CGImageSourceCreateIncremental((__bridge CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : (__bridge NSString *)imageUTType});// 创建一个渐进形的指定类型的CGImageSourceRef
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
    CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, 0, CGColorSpaceCreateDeviceRGB(), bitmapInfo);
    if (!context) return NULL;
    
    // 绘制
    CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), imageRef); // decode
    // 从上下文中获取CGImage
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    CFRelease(context);
```

3.ImageIO无法解析WebP，所以加入WebP.framework用来解析WebP

## 4.FastImageCache

iOS加载图片的时候，解码之后图片之后，CATransaction捕获到UIImageView layer树的变化，提交CATransaction，开始进行图像渲染，如果数据没有字节对齐，Core Animation会再拷贝一份数据，进行字节对齐。[链接](https://blog.cnbang.net/tech/2578/)。

![](<http://blog.cnbang.net/wp-content/uploads/2015/02/fastImageCache1.png>)

![](<http://blog.cnbang.net/wp-content/uploads/2015/02/fastImageCache2.png>)

bitmap信息在内存中有可能是不连续的，但是程序在取内存渲染的时候是一块一块的进行的，就有可能取到杂质信息，所以要进行copy。可以在CGBitmapContextCreate创建的时候bytesPerRow参数传64倍数。