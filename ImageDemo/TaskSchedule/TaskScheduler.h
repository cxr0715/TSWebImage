//
//  TaskScheduler.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/25.
//  Copyright © 2018年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TaskScheduler : NSObject

+ (TaskScheduler *)shareManager;

/**
 @brief 获取uuid
 */
+ (NSString*)fetchUUID;

/**
 @brief 添加串行任务
 @param taskBlock 任务
 @param taskPriority 任务优先级
 @param obj 任务发起的对象
 */
- (NSString *)addSerialTaskToPool:(dispatch_block_t)taskBlock taskPriority:(NSOperationQueuePriority)taskPriority fromObj:(id)obj;

/**
 @brief 添加依赖任务
 @param taskBlock 前任务
 @param taskAfterBlock 后任务
 */
- (void)addTaskToPool:(dispatch_block_t)taskBlock blockAfterToMainThread:(dispatch_block_t)taskAfterBlock fromObj:(id)obj;

/**
 @brief 获取指定优先级的串行队列
 @param priority 优先级
 */
- (dispatch_queue_t)serialQueueOfPriority:(NSOperationQueuePriority)priority;

/**
 @brief 添加并行任务
 */
- (void)addConcurrentTaskToPool:(dispatch_block_t)taskBlock taskPriority:(NSOperationQueuePriority)taskPriority;

/**
 添加并行任务，以NSOperation的形式添加

 @param operation 需要添加的NSOperation
 @param taskPriority 优先级
 */
- (void)addConcurrentOperationTaskToPool:(NSOperation *)operation taskPriority:(NSOperationQueuePriority)taskPriority;

/**
 @brief 取消任务
 */
- (void)cancelTaskWithID:(NSString *)taskID withObj:(id)obj;

/**
 @brief 添加批量任务
 */
- (void)addTaskArrayToPool:(NSArray *)taskBlockArray;


/**
 添加任务到优先队列中，小顶堆实现

 @param taskBlock 需要执行的任务
 @param priority 任务优先级，越小越先执行，最小为0
 */
- (void)addTaskToPriorityQueue:(dispatch_block_t)taskBlock withTaskPriority:(NSUInteger)priority fromRecursion:(BOOL)recursion;

/**
 @brief 修改队列负载量
 @param queue 队列
 */
- (void)changePayloadForQueue:(dispatch_queue_t)queue increment:(BOOL)isIncrement;

/**
 @brief 检测当前是否是指定队列
 @param queue 对比的队列
 */
- (BOOL)isInQueue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
