//
//  TSImageOperation.h
//  ImageDemo
//
//  Created by YYInc on 2019/4/8.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^SDImageLoaderCompletedBlock)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished);
typedef SDImageLoaderCompletedBlock SDWebImageDownloaderCompletedBlock;

typedef void(^TSImageFromDiskCompletedBlock)(UIImage * _Nullable image);
typedef TSImageFromDiskCompletedBlock TSImageCompletedBlock;

NS_ASSUME_NONNULL_BEGIN

@interface TSImageOperation : NSOperation <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
@property (nonatomic, copy) SDImageLoaderCompletedBlock imageBlock;
- (instancetype)initWithURL:(NSURL *)url completed:(SDImageLoaderCompletedBlock)completed;
- (void)loadImageWithURL:(NSURL *)url withImageBlock:(SDImageLoaderCompletedBlock)imageBlock;
- (void)bitmapToImage:(NSData *)soucreData imageRef:(CGImageRef)imageRef;
- (void)createImageWithData:(NSData *)data withBlock:(TSImageFromDiskCompletedBlock)completed;
@end

NS_ASSUME_NONNULL_END
