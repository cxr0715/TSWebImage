//
//  TaskScheduler+Timer.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/25.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "TaskScheduler+Timer.h"
#import "NSObject+Timer.h"
#import "YYTimerTaskObserver.h"
#import "NSDictionary+ThreadSafe.h"
#import <objc/runtime.h>

static void* TaskSchedulerObserverKey = &TaskSchedulerObserverKey;

@implementation TaskScheduler (Timer)

+ (NSString*)addTimerOperation:(BOOL(^)(void))block forObj:(id)obj timeInterval:(NSTimeInterval)interval atMain:(BOOL)main singleShot:(BOOL)singleShot;{
    CHECKANDRET(block && obj, nil);
    YYTimerTaskObserver* observer = objc_getAssociatedObject(obj, TaskSchedulerObserverKey);
    if( !observer ){
        observer = [YYTimerTaskObserver new];
        objc_setAssociatedObject(obj, TaskSchedulerObserverKey, observer, OBJC_ASSOCIATION_RETAIN);
        observer.timers = [NSMutableDictionary TsDictionary];
    }
    NSString* token = [self fetchUUID];
    YYTimerTask* task = [YYTimerTask new];
    task.operation = block;
    task.interval = interval;
    if( main ){
        task.queue = dispatch_get_main_queue();
        task.isMainQueue = YES;
    }
    else{
        task.queue = [[TaskScheduler shareManager] serialQueueOfPriority:NSOperationQueuePriorityNormal];
        task.isMainQueue = NO;
    }
    NSAssert(task.queue, @"invalid queue");
    task.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, task.queue);
    observer.timers[token] = task;
    dispatch_source_set_timer(task.source, dispatch_time(DISPATCH_TIME_NOW,interval*NSEC_PER_SEC), singleShot?DISPATCH_TIME_FOREVER:interval*NSEC_PER_SEC,(1ull * NSEC_PER_SEC) / 200);
    if( !task.isMainQueue ){
        [[TaskScheduler shareManager] changePayloadForQueue:task.queue increment:YES];
    }
    __weak typeof(obj) weakobj = obj;
    __weak typeof(task) weaktask = task;
//    @weakify(obj);
//    @weakify(task);
    dispatch_source_set_event_handler(task.source, ^{
        __strong typeof(weakobj) strongobj = weakobj;
        __strong typeof(weaktask) strongtask = weaktask;
//        @strongify(obj)
//        @strongify(task)
        BOOL ret = block();
        [strongtask incrementFireTimes];
        if( ret ){
            [strongobj cancelTimerOperation:token];
        }
    });
    dispatch_resume(task.source);
    return token;
}

+ (void)cancelTimerOperation:(NSString*)token forObj:(id)obj;{
    CHECK(obj&&token);
    YYTimerTaskObserver* observer = objc_getAssociatedObject(obj, TaskSchedulerObserverKey);
    CHECK(observer);
    __block dispatch_source_t source = nil;
    [observer.timers batchOperation:^{
        YYTimerTask* task = observer.timers[token];
        CHECK(task);
        if( !task.isMainQueue ){
            [[TaskScheduler shareManager] changePayloadForQueue:task.queue increment:NO];
        }
        [observer.timers removeObjectForKey:token];
        source = task.source;
    }];
    CHECK(source);
    dispatch_source_cancel(source);
}

+ (void)cancelTimerOperationsFor:(id)obj;{
    CHECK(obj);
    YYTimerTaskObserver* observer = objc_getAssociatedObject(obj, TaskSchedulerObserverKey);
    CHECK(observer);
    NSArray<NSString*>* allkeys = [observer.timers allKeys];
    for( NSString* key in allkeys ){
        [TaskScheduler cancelTimerOperation:key forObj:obj];
    }
    [observer.timers removeAllObjects];
}

+ (void)fireTimerOperation:(NSString*)token forObj:(nonnull id)obj sync:(BOOL)isSync{
    CHECK( obj && token );
    YYTimerTaskObserver* observer = objc_getAssociatedObject(obj, TaskSchedulerObserverKey);
    CHECK(observer);
    YYTimerTask* task = observer.timers[token];
    CHECK(task && task.operation && task.queue);
    if( isSync || [self inTargetQueue:task.queue] ){
        task.operation();
        [task incrementFireTimes];
    }
    else{
        dispatch_async(task.queue, ^{
            task.operation();
            [task incrementFireTimes];
        });
    }
}

+ (NSArray<NSString*>*)validTimersForObj:(id)obj;{
    CHECKANDRET(obj, nil);
    YYTimerTaskObserver* observer = objc_getAssociatedObject(obj, TaskSchedulerObserverKey);
    CHECKANDRET(observer, nil);
    return observer.timers.allKeys;
}

+ (NSTimeInterval)getTimerInterval:(NSString *)token forObj:(id)obj{
    NSTimeInterval ts = -1;
    CHECKANDRET(token&&obj, ts);
    YYTimerTaskObserver* observer = objc_getAssociatedObject(obj, TaskSchedulerObserverKey);
    YYTimerTask* task = observer.timers[token];
    CHECKANDRET(task, ts);
    return task.interval;
}

+ (NSUInteger)getFiredTimes:(NSString *)token forObj:(id)obj{
    NSUInteger times = 0;
    CHECKANDRET(token&&obj, times);
    YYTimerTaskObserver* observer = objc_getAssociatedObject(obj, TaskSchedulerObserverKey);
    YYTimerTask* task = observer.timers[token];
    CHECKANDRET(task, times);
    return task.firedTimes;
}

+ (NSArray<NSString *> *)getTimersWithInterval:(NSTimeInterval)interval forObj:(id)obj{
    CHECKANDRET(obj, nil);
    YYTimerTaskObserver* observer = objc_getAssociatedObject(obj, TaskSchedulerObserverKey);
    __block NSMutableArray* ts = [NSMutableArray new];
    [observer.timers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, YYTimerTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if( obj.interval == interval || fabs(obj.interval-interval) < DBL_EPSILON ){
            [ts addObject:key];
        }
    }];
    return [ts copy];
}

#pragma mark utility
+ (BOOL)inTargetQueue:(dispatch_queue_t)queue;{
    CHECKANDRET(queue, NO);
    if( [NSThread isMainThread] ){
        return (queue == dispatch_get_main_queue());
    }
    else {
        return [[TaskScheduler shareManager] isInQueue:queue];
    }
    
    return NO;
}
@end
