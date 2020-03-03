//
//  NSDictionary+ThreadSafe.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/25.
//  Copyright © 2018年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (ThreadSafe)

- (NSMutableDictionary*)tsMutableCopy;

@end

@interface NSMutableDictionary (ThreadSafe)

+ (instancetype)TsDictionary;

- (void)batchOperation:(dispatch_block_t)block;

@end
NS_ASSUME_NONNULL_END
