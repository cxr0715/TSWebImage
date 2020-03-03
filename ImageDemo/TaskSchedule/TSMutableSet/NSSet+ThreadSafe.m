//
//  NSSet+ThreadSafe.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/28.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "NSSet+ThreadSafe.h"
#import "TSMutableSet.h"

@implementation NSSet (ThreadSafe)

- (instancetype)tsMutableCopy;{
    return [TSMutableSet setWithSet:self];
}

@end

@implementation NSMutableSet (ThreadSafe)

+ (instancetype)TsSet;{
    return [TSMutableSet new];
}

- (void)batchOperation:(dispatch_block_t)block;{
    CHECK(block);
    if( [self isKindOfClass:[TSMutableSet class]] )
    {
        [((TSMutableSet*)self) performBlock:block];
    }
    else {
        block();
    }
}

@end
