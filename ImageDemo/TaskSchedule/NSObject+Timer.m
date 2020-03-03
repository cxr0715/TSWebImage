//
//  NSObject+Timer.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/25.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "NSObject+Timer.h"
#import "TaskScheduler+Timer.h"
//#import "BNLeakChecker.h"
#import "YYTimerTaskObserver.h"

@implementation NSObject (Timer)

- (NSString*)addTimerOperation:(BOOL (^)(void))block interval:(NSTimeInterval)interval{
    CHECKANDRET(block, nil);
    return [self addTimerOperation:block interval:interval atMain:YES];
}

- (NSString*)singleShotOperation:(dispatch_block_t)block interval:(NSTimeInterval)interval{
    CHECKANDRET(block, nil);
    return [self singleShotOperation:block interval:interval atMain:YES];
}

- (NSString*)singleShotOperation:(dispatch_block_t)block interval:(NSTimeInterval)interval atMain:(BOOL)main;{
    CHECKANDRET(block, nil);
#ifdef DEBUG
    [self checkBlockRetain:block];
#endif
    return [TaskScheduler addTimerOperation:^BOOL{
        block();
        return YES;
    } forObj:self timeInterval:interval atMain:main singleShot:YES];
}

- (NSString*)addTimerOperation:(BOOL(^)(void))block interval:(NSTimeInterval)interval atMain:(BOOL)main;{
    CHECKANDRET(block, nil);
#ifdef DEBUG
    [self checkBlockRetain:block];
#endif
    return [TaskScheduler addTimerOperation:block forObj:self timeInterval:interval atMain:main singleShot:NO];
}

- (void)cancelTimerOperation:(NSString *)token{
    [TaskScheduler cancelTimerOperation:token forObj:self];
}

- (void)cancelTimerOperations;{
    [TaskScheduler cancelTimerOperationsFor:self];
}

- (void)fireTimerOperation:(NSString*)token{
    [self fireTimerOperation:token sync:YES];
}

- (void)fireTimerOperation:(NSString *)token sync:(BOOL)isSync{
    [TaskScheduler fireTimerOperation:token forObj:self sync:isSync];
}

- (NSArray<NSString *> *)validTimers{
    return [TaskScheduler validTimersForObj:self];
}

- (NSTimeInterval)getTimerInterval:(NSString *)token{
    return [TaskScheduler getTimerInterval:token forObj:self];
}

- (NSUInteger)getFiredTimes:(NSString *)token{
    return [TaskScheduler getFiredTimes:token forObj:self];
}

- (NSArray<NSString *> *)getTimersWithInterval:(NSTimeInterval)interval{
    return [TaskScheduler getTimersWithInterval:interval forObj:self];
}

#pragma mark Utility Methods
- (void)checkBlockRetain:(id)block;{
//    if( [[BNLeakChecker sharedChecker] isBlock:block retainObserver:self] ){
//        [[NSException exceptionWithName:@"NSObject(Timer)" reason:SF(@"block retain %@",self) userInfo:nil] raise];
//    }
}
@end
