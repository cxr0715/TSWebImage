//
//  TSImageWebP.m
//  ImageDemo
//
//  Created by YYInc on 2019/4/10.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import "TSImageWebP.h"

@interface TSImageWebP ()
@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSTimeInterval duration; // Frame duration in seconds
@property (nonatomic, assign) NSUInteger width; // Frame width
@property (nonatomic, assign) NSUInteger height; // Frame height
@property (nonatomic, assign) NSUInteger offsetX; // Frame origin.x in canvas (left-bottom based)
@property (nonatomic, assign) NSUInteger offsetY; // Frame origin.y in canvas (left-bottom based)
@property (nonatomic, assign) BOOL hasAlpha; // Whether frame contains alpha
@property (nonatomic, assign) BOOL isFullSize; // Whether frame size is equal to canvas size
@property (nonatomic, assign) WebPMuxAnimBlend blend; // Frame dispose method
@property (nonatomic, assign) WebPMuxAnimDispose dispose; // Frame blend operation
@property (nonatomic, assign) NSUInteger blendFromIndex; // The nearest previous frame index which blend mode is WEBP_MUX_BLEND
@end

@implementation TSImageWebP {
    WebPIDecoder *_idec;
    WebPDemuxer *_demux;
    NSData *_imageData;
    CGFloat _scale;
    NSUInteger _loopCount;
    NSUInteger _frameCount;
    NSArray *_frames;
    CGContextRef _canvas;
    CGColorSpaceRef _colorSpace;
    BOOL _hasAnimation;
    BOOL _hasAlpha;
    BOOL _finished;
    CGFloat _canvasWidth;
    CGFloat _canvasHeight;
    dispatch_semaphore_t _lock;
    NSUInteger _currentBlendIndex;
}

- (instancetype)initIncremental {
    self = [super init];
    if (self) {
        // Progressive images need transparent, so always use premultiplied BGRA
        _idec = WebPINewRGB(MODE_bgrA, NULL, 0, 0);
        CGFloat scale = 1;
//        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
//        if (scaleFactor != nil) {
//            scale = [scaleFactor doubleValue];
//            if (scale < 1) {
//                scale = 1;
//            }
//        }
        _scale = scale;
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
//    if (_finished) {
//        return;
//    }
    _imageData = data;
    _finished = finished;
    VP8StatusCode status = WebPIUpdate(_idec, data.bytes, data.length);
    if (status != VP8_STATUS_OK && status != VP8_STATUS_SUSPENDED) {
        return;
    }
    // libwebp current does not support progressive decoding for animated image, so no need to scan and update the frame information
}

- (UIImage *)incrementalDecodedImage {
    UIImage *image;
    
    int width = 0;
    int height = 0;
    int last_y = 0;
    int stride = 0;
    uint8_t *rgba = WebPIDecGetRGB(_idec, &last_y, &width, &height, &stride);
    // last_y may be 0, means no enough bitmap data to decode, ignore this
    if (width + height > 0 && last_y > 0 && height >= last_y) {
        // Construct a UIImage from the decoded RGBA value array
        size_t rgbaSize = last_y * stride;
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, rgbaSize, NULL);
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
        size_t components = 4;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        // Why to use last_y for image height is because of libwebp's bug (https://bugs.chromium.org/p/webp/issues/detail?id=362)
        // It will not keep memory barrier safe on x86 architechure (macOS & iPhone simulator) but on ARM architecture (iPhone & iPad & tv & watch) it works great
        // If different threads use WebPIDecGetRGB to grab rgba bitmap, it will contain the previous decoded bitmap data
        // So this will cause our drawed image looks strange(above is the current part but below is the previous part)
        // We only grab the last_y height and draw the last_y height instead of total height image
        // Besides fix, this can enhance performance since we do not need to create extra bitmap
        CGImageRef imageRef = CGImageCreate(width, last_y, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
        
        CGDataProviderRelease(provider);
        
        if (!imageRef) {
            return nil;
        }
        
        CGContextRef canvas = CGBitmapContextCreate(NULL, width, height, 8, 0, CGColorSpaceCreateWithName(kCGColorSpaceSRGB), bitmapInfo);
        if (!canvas) {
            CGImageRelease(imageRef);
            return nil;
        }
        
        // Only draw the last_y image height, keep remains transparent, in Core Graphics coordinate system
        CGContextDrawImage(canvas, CGRectMake(0, height - last_y, width, last_y), imageRef);
        CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
        CGImageRelease(imageRef);
        if (!newImageRef) {
            CGContextRelease(canvas);
            return nil;
        }
        CGFloat scale = _scale;
//        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
//        if (scaleFactor != nil) {
//            scale = [scaleFactor doubleValue];
//            if (scale < 1) {
//                scale = 1;
//            }
//        }
        
        image = [[UIImage alloc] initWithCGImage:newImageRef scale:scale orientation:UIImageOrientationUp];
//        image.sd_isDecoded = YES; // Already drawn on bitmap context above
//        image.sd_imageFormat = SDImageFormatWebP;
        CGImageRelease(newImageRef);
        CGContextRelease(canvas);
    }
    
    return image;
}

@end
