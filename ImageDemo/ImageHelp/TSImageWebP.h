//
//  TSImageWebP.h
//  ImageDemo
//
//  Created by YYInc on 2019/4/10.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"

NS_ASSUME_NONNULL_BEGIN

@interface TSImageWebP : NSObject
- (instancetype)initIncremental;
- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished;
- (UIImage *)incrementalDecodedImage;
@end

NS_ASSUME_NONNULL_END
