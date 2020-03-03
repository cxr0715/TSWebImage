//
//  NSObject+YYTaskPool.m
//  ChannelProject
//
//  Created by caoxuerui on 2018/12/26.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "NSObject+YYTaskPool.h"
#import "TaskScheduler.h"

@implementation NSObject (YYTaskPool)

- (NSString *)serialHigh:(dispatch_block_t)taskBlock {
    return [[TaskScheduler shareManager] addSerialTaskToPool:taskBlock taskPriority:NSOperationQueuePriorityHigh fromObj:self];
}

- (NSString *)serialDefault:(dispatch_block_t)taskBlock {
    return [[TaskScheduler shareManager] addSerialTaskToPool:taskBlock taskPriority:NSOperationQueuePriorityNormal fromObj:self];
}

- (NSString *)serialLow:(dispatch_block_t)taskBlock {
    return [[TaskScheduler shareManager] addSerialTaskToPool:taskBlock taskPriority:NSOperationQueuePriorityLow fromObj:self];
}

- (void)addTask:(dispatch_block_t)taskBlock blockAfterToMain:(dispatch_block_t)taskAfterBlock {
    [[TaskScheduler shareManager] addTaskToPool:taskBlock blockAfterToMainThread:taskAfterBlock fromObj:self];
}

- (void)asyncMain:(dispatch_block_t)taskBlock {
    CHECK(taskBlock);
    if( [NSThread isMainThread] ){
        taskBlock();
    }else{
        dispatch_async(dispatch_get_main_queue(), taskBlock);
    }
}

- (NSString *)asyncHigh:(dispatch_block_t)block {
    [[TaskScheduler shareManager] addConcurrentTaskToPool:block taskPriority:NSOperationQueuePriorityHigh];
    return nil;
}

- (NSString *)asyncDefault:(dispatch_block_t)block {
    [[TaskScheduler shareManager] addConcurrentTaskToPool:block taskPriority:NSOperationQueuePriorityNormal];
    return nil;
}

- (NSString *)asyncLow:(dispatch_block_t)block {
    [[TaskScheduler shareManager] addConcurrentTaskToPool:block taskPriority:NSOperationQueuePriorityLow];
    return nil;
}

- (void)cancelTaskWithID:(NSString *)taskID {
    [[TaskScheduler shareManager] cancelTaskWithID:taskID withObj:self];
}

- (void)addTaskArray:(dispatch_block_t)firstBlock, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray* arrays = [NSMutableArray array];
    va_list argList;
    if (firstBlock) {
        [arrays addObject:firstBlock];
        // VA_START宏，获取可变参数列表的第一个参数的地址,在这里是获取firstObj的内存地址,这时argList的指针 指向firstObj
        va_start(argList, firstBlock);
        // 临时指针变量
        id temp;
        // VA_ARG宏，获取可变参数的当前参数，返回指定类型并将指针指向下一参数
        // 首先 argList的内存地址指向的fristObj将对应储存的值取出,如果不为nil则判断为真,将取出的值房在数组中,
        // 并且将指针指向下一个参数,这样每次循环argList所代表的指针偏移量就不断下移直到取出nil
        while ((temp = va_arg(argList, id))) {
            [arrays addObject:temp];
        }
        
    }
    // 清空列表
    va_end(argList);
    
    [[TaskScheduler shareManager] addTaskArrayToPool:arrays];
}

- (void)addPriorityTask:(dispatch_block_t)taskBlock priority:(NSUInteger)priority {
    [[TaskScheduler shareManager] addTaskToPriorityQueue:taskBlock withTaskPriority:priority fromRecursion:NO];
}

@end
