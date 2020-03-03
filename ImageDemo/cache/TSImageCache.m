//
//  TSImageCache.m
//  ImageDemo
//
//  Created by YYInc on 2019/4/13.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import "TSImageCache.h"
#import <CommonCrypto/CommonDigest.h>

#define kImageDiskCache @"ImageDiskCache"
#define SD_MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)

@interface TSImageCache ()
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSString *path;
@end

@implementation TSImageCache
+ (TSImageCache *)shareManager {
    static TSImageCache *imageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCache = [[TSImageCache alloc] init];
        imageCache.countLimit = 5;
        imageCache.totalCostLimit = 5 * 1024 * 1024;
        imageCache.fileManager = [[NSFileManager alloc] init];
        imageCache.path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        [imageCache.path stringByAppendingPathComponent:kImageDiskCache];
        [imageCache.fileManager createDirectoryAtPath:imageCache.path withIntermediateDirectories:YES attributes:nil error:nil];
        
        imageCache.list = [[TSList alloc] init];
    });
    return imageCache;
}

- (void)setImageToMermory:(UIImage *)image withKey:(NSString *)key {
    if (!image || key.length <= 0) {
        return;
    }
//    [self setObject:image forKey:key];
    
    TSListNode *node = [[TSListNode alloc] init];
    node.key = key;
    node.value = image;
    [self.list insertNode:node];
}

- (UIImage *)getImageFromMermoryWithKey:(NSString *)key {
    if (key.length <= 0) {
        return nil;
    }
    return [self.list getValueWithKey:key];
//    return [self objectForKey:key];
}

- (void)setImageDataToDisk:(NSData *)imageData withKey:(NSString *)key {
    if (!imageData && key.length <= 0) {
        return;
    }
    
    NSString *filename = SDDiskCacheFileNameForKey(key);
    filename = [self.path stringByAppendingPathComponent:filename];
    
    NSURL *urlPath = [NSURL fileURLWithPath:filename];
    
    [imageData writeToURL:urlPath options:NSDataWritingAtomic error:nil];
}

- (NSData *)getImageDataFromDisk:(NSString *)key {
    if (key.length <= 0) {
        return nil;
    }
    
    NSString *filename = SDDiskCacheFileNameForKey(key);
    filename = [self.path stringByAppendingPathComponent:filename];
    
    NSData *data = [NSData dataWithContentsOfFile:filename options:0 error:nil];
    if (data) {
        return data;
    }
    return nil;
}

static inline NSString * _Nonnull SDDiskCacheFileNameForKey(NSString * _Nullable key) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *ext = keyURL ? keyURL.pathExtension : key.pathExtension;
    // File system has file name length limit, we need to check if ext is too long, we don't add it to the filename
    if (ext.length > SD_MAX_FILE_EXTENSION_LENGTH) {
        ext = nil;
    }
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    return filename;
}

@end
