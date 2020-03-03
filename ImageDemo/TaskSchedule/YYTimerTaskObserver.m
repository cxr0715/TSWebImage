//
//  YYTimerTaskObserver.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/29.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "YYTimerTaskObserver.h"
#import "TaskScheduler+Timer.h"

@interface YYTimerTask()

@property (nonatomic,readwrite,assign) NSUInteger         firedTimes;

@end

@implementation YYTimerTask

- (instancetype)init
{
    self = [super init];
    if (self) {
        _firedTimes = 0;
    }
    return self;
}

- (void)incrementFireTimes{
    @synchronized (self) {
        _firedTimes++;
    }
}

- (NSUInteger)firedTimes{
    @synchronized (self) {
        return _firedTimes;
    }
}

@end

@implementation YYTimerTaskObserver

- (void)dealloc
{
//    [self.timers batchOperation:^{
//        for( YYTimerTask* task in self.timers.allValues ){
//            if( !task.isMainQueue ){
//                [[TaskScheduler shareManager] changePayloadForQueue:task.queue increment:NO];
//            }
//            if( task.source ){
//                dispatch_source_cancel(task.source);
//            }
//        }
//    }];
    self.timers = nil;
}

@end
