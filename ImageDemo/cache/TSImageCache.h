//
//  TSImageCache.h
//  ImageDemo
//
//  Created by YYInc on 2019/4/13.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TSList.h"

NS_ASSUME_NONNULL_BEGIN

@interface TSImageCache : NSCache
@property (nonatomic, strong) TSList *list;
+ (TSImageCache *)shareManager;
- (void)setImageToMermory:(UIImage *)image withKey:(NSString *)key;
- (UIImage *)getImageFromMermoryWithKey:(NSString *)key;
- (void)setImageDataToDisk:(NSData *)imageData withKey:(NSString *)key;
- (NSData *)getImageDataFromDisk:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
