//
//  UIImageView+TSImage.m
//  ImageDemo
//
//  Created by YYInc on 2019/4/8.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import "UIImageView+TSImage.h"
#import "TSImageOperation.h"
#import "TaskScheduler.h"
#import "TSImageCache.h"

@implementation UIImageView (TSImage)

- (void)setImageViewWithURL:(NSString *)url {
    if (!url || url.length == 0) {
        return;
    }
    
    TSImageCache *cache = [TSImageCache shareManager];
    if ([cache getImageFromMermoryWithKey:url]) {
        self.image = [cache getImageFromMermoryWithKey:url];
        return;
    } else if ([cache getImageDataFromDisk:url]) {
        __weak typeof(self) weakSelf = self;
        TSImageOperation *tmpOperation = [[TSImageOperation alloc] init];
        [tmpOperation createImageWithData:[cache getImageDataFromDisk:url] withBlock:^(UIImage * _Nullable image) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.image = image;
        }];
        return;
    }
    
    NSURL *imageURL = [NSURL URLWithString:url];

    __weak typeof(self) weakSelf = self;
    TSImageOperation *imageOperation = [[TSImageOperation alloc] initWithURL:imageURL completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (image) {
            strongSelf.image = image;
        }
        if (finished) {
            [cache setImageToMermory:image withKey:url];
            [cache setImageDataToDisk:data withKey:url];
        }
    }];
    
    TaskScheduler *scheduler = [TaskScheduler shareManager];
    [scheduler addConcurrentOperationTaskToPool:imageOperation taskPriority:NSOperationQueuePriorityNormal];
    
//    __weak typeof(self) weakSelf = self;
//    [imageOperation loadImageWithURL:imageURL withImageBlock:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        if (image) {
//            strongSelf.image = image;
//        }
//    }];
}

@end
