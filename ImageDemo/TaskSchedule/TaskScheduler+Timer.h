//
//  TaskScheduler+Timer.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/25.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "TaskScheduler.h"

NS_ASSUME_NONNULL_BEGIN

@interface TaskScheduler (Timer)

/**
 @brief 设定定时任务
 @param block 定时任务
 @param obj   定时器宿主对象
 @param main  是否希望在主线程执行
 */
+ (NSString*)addTimerOperation:(BOOL(^)(void))block forObj:(id)obj timeInterval:(NSTimeInterval)interval atMain:(BOOL)main singleShot:(BOOL)singleShot;

/**
 @brief 取消指定的定时任务
 @param token 定时任务id
 @param obj   定时器宿主对象
 */
+ (void)cancelTimerOperation:(NSString*)token forObj:(id)obj;

/**
 @brief 取消特定对象上所有定时任务
 @param obj 定时器宿主对象
 */
+ (void)cancelTimerOperationsFor:(id)obj;

/**
 @brief 触发定时任务一次
 @param token 定时器所对应的token
 @param obj 定时器宿主对象
 @param sync 是否同步触发
 */
+ (void)fireTimerOperation:(NSString*)token forObj:(id)obj sync:(BOOL)isSync;


/**
 @brief 获取有效定时任务
 @param obj 定时器宿主对象
 */
+ (NSArray<NSString*>*)validTimersForObj:(id)obj;

/**
 @brief 获取指定定时器的间隔
 @param token 定时器id
 @param obj 定时器宿主对象
 */
+ (NSTimeInterval)getTimerInterval:(NSString*)token forObj:(id)obj;

/**
 @brief 获取指定对象上定时任务已执行的次数
 @param token 定时器id
 @param obj 定时器宿主对象
 */
+ (NSUInteger)getFiredTimes:(NSString*)token forObj:(id)obj;

/**
 @brief 获取指定超时间隔的定时器
 @param interval 超时间隔
 @param obj 定时器宿主对象
 */
+ (NSArray<NSString*>*)getTimersWithInterval:(NSTimeInterval)interval forObj:(id)obj;

@end

NS_ASSUME_NONNULL_END
