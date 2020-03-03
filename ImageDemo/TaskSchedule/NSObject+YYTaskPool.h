//
//  NSObject+YYTaskPool.h
//  ChannelProject
//
//  Created by caoxuerui on 2018/12/26.
//  Copyright © 2018年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (YYTaskPool)
/**
 按照添加顺序来执行，添加到高优先级的队列，串行，先后顺序执行

 @param taskBlock 执行的任务block
 */
- (NSString *)serialHigh:(dispatch_block_t)taskBlock;

/**
 按照添加顺序来执行，添加到默认优先级的队列，串行，先后顺序执行
 
 @param taskBlock 执行的任务block
 */
- (NSString *)serialDefault:(dispatch_block_t)taskBlock;

/**
 按照添加顺序来执行，添加到低优先级的队列，串行，先后顺序执行
 
 @param taskBlock 执行的任务block
 */
- (NSString *)serialLow:(dispatch_block_t)taskBlock;

/**
 在默认队列添加两个任务block，先执行完taskBlock在执行taskAfterBlock，taskBlock在子线程，taskAfterBlock在主线程

 @param taskBlock 先执行的block
 @param taskAfterBlock taskBlock执行完之后在主线程执行的block
 */
- (void)addTask:(dispatch_block_t)taskBlock blockAfterToMain:(dispatch_block_t)taskAfterBlock;

/**
 添加到主队列，并行执行

 @param block 执行的任务block
 */
- (void)asyncMain:(dispatch_block_t)taskBlock;

/**
 添加到高优先级的队列，并行执行

 @param taskBlock 执行的任务block
 */
- (NSString *)asyncHigh:(dispatch_block_t)taskBlock;

/**
 添加到默认优先级的队列，并行执行
 
 @param taskBlock 执行的任务block
 */
- (NSString *)asyncDefault:(dispatch_block_t)taskBlock;

/**
 添加到低优先级的队列，并行执行
 
 @param taskBlock 执行的任务block
 */
- (NSString *)asyncLow:(dispatch_block_t)taskBlock;

/**
 结束一个串行的任务，前提是改任务还没有被执行

 @param taskID 任务ID
 */
- (void)cancelTaskWithID:(NSString *)taskID;

/**
 最后一个block依赖前边所有block执行完毕

 @param firstBlock block数组
 */
- (void)addTaskArray:(dispatch_block_t)firstBlock, ... NS_REQUIRES_NIL_TERMINATION;


/**
 添加任务到优先队列中，需要传入任务的优先级，越小越优先

 @param taskBlock 执行任务的block
 @param priority 该任务的优先级
 */
- (void)addPriorityTask:(dispatch_block_t)taskBlock priority:(NSUInteger)priority;

@end
