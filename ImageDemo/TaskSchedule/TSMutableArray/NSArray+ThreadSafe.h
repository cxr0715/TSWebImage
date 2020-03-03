//
//  NSArray+ThreadSafe.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/26.
//  Copyright © 2018年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (ThreadSafe)

- (NSMutableArray*)tsMutableCopy;

@end

@interface NSMutableArray (ThreadSafe)

+ (instancetype)TsArray;

@end

NS_ASSUME_NONNULL_END
