//
//  NSObject+Timer.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/25.
//  Copyright © 2018年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Timer)
/**
 @brief 添加只运行一次的定时任务
 @param block 定时任务
 @param interval 定时任务间隔
 @param main 是否在主线程回调，默认为在主线程回调
 */
- (NSString*)singleShotOperation:(dispatch_block_t)block interval:(NSTimeInterval)interval atMain:(BOOL)main;
- (NSString*)singleShotOperation:(dispatch_block_t)block interval:(NSTimeInterval)interval;

/**
 @brief 添加定时任务
 @param block 定时任务
 @param interval 定时任务间隔
 @param main 是否在主线程回调，默认为在主线程回调
 */
- (NSString*)addTimerOperation:(BOOL(^)(void))block interval:(NSTimeInterval)interval atMain:(BOOL)main;
- (NSString*)addTimerOperation:(BOOL(^)(void))block interval:(NSTimeInterval)interval;

/**
 @brief 取消指定的定时任务
 @param token 定时任务id
 */
- (void)cancelTimerOperation:(NSString*)token;

/**
 @brief 取消所有定时任务
 */
- (void)cancelTimerOperations;

/**
 @brief 触发定时任务一次
 @param token 定时器所对应的token
 @param isSync 若为YES则同步地触发定时器操作，否则提交到定时器任务队列串行执行，默认为同步执行
 */
- (void)fireTimerOperation:(NSString*)token sync:(BOOL)isSync;
- (void)fireTimerOperation:(NSString*)token;

/**
 @brief 获取当前有效定时任务
 */
- (NSArray<NSString*>*)validTimers;

/**
 @brief 获取定时器时间间隔
 @param token 定时器id
 @warning 若定时器不存在，则返回-1
 */
- (NSTimeInterval)getTimerInterval:(NSString*)token;

/**
 @brief 获取定时任务已执行的任务
 */
- (NSUInteger)getFiredTimes:(NSString*)token;

/**
 @brief 获取指定超时时间的定时器
 @param interval 超时时间
 @warning double比大小相对准确
 */
- (NSArray<NSString*>*)getTimersWithInterval:(NSTimeInterval)interval;

@end

NS_ASSUME_NONNULL_END
