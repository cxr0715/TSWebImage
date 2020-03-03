//
//  TaskScheduler.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/25.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "TaskScheduler.h"
//#import "NSArray+ThreadSafe.h"
//#import "NSDictionary+ThreadSafe.h"
#import <stdatomic.h>

#define maxPoolCount 5;
#define maxTimerSerialQueue 10
static void* TaskSchedulerQueueSpecificKey = &TaskSchedulerQueueSpecificKey;

static atomic_uint_fast64_t TaskSchedulerTimerIncrement = 0;

/**
 用于存储优先队列中的优先任务
 */
@interface PriorityTask : NSObject
@property (nonatomic, assign) CFIndex priority;
@property (nonatomic, copy) dispatch_block_t taskBlock;
@end

@implementation PriorityTask

@end


/**
 二叉堆创建时候的retain参数，如果没有则不会retain堆中元素
 */
static const void * TSRetain(CFAllocatorRef allocator, const void *ptr) {
    return (const void *)CFRetain((CFTypeRef)ptr);
}

/**
 二叉堆创建时候的release参数，如果没有则不会release堆中元素
 */
static void TSRelease(CFAllocatorRef allocator, const void *ptr) {
    return (void)CFRelease((CFTypeRef)ptr);
}

/**
 二叉堆创建时候的compare参数，一定要有改参数，在入队的时候会执行该方法，更具改方法规则来对入队元素做操作
 */
static CFComparisonResult TaskCompare(const void *ptr1, const void *ptr2, void *context) {
    PriorityTask *priorityTask1 = (PriorityTask *)((__bridge id)(ptr1));
    PriorityTask *priorityTask2 = (PriorityTask *)((__bridge id)(ptr2));
    if (priorityTask1.priority < priorityTask2.priority) {
        return kCFCompareLessThan;
    } else if (priorityTask1.priority == priorityTask2.priority) {
        return kCFCompareEqualTo;
    } else {
        return kCFCompareGreaterThan;
    }
}

@interface TaskScheduler ()

/**
 高优先级，用于用户需要马上执行的事件
 */
@property (nonatomic, strong) NSOperationQueue *highTaskPool;

/**
 默认优先级，主线程和没有设置优先级的线程都默认为这个优先级
 */
@property (nonatomic, strong) NSOperationQueue *defaultTaskPool;

/**
 优先队列，串行
 */
@property (nonatomic, strong) NSOperationQueue *priorityTaskPool;

/**
 低优先级，用于普通任务
 */
@property (nonatomic, strong) NSOperationQueue *lowTaskPool;

@property (nonatomic, strong) NSMapTable <id ,NSMutableArray <NSMutableDictionary <NSString *, NSOperation *>*>*>*highTaskPoolMapTable;

/**
 默认队列会开启underlyingQueue（潜在队列），每个字典中只会有一组数据
 */
@property (nonatomic, strong) NSMapTable <id ,NSMutableArray <NSMutableDictionary <NSString *, NSOperation *>*>*>*defaultTaskPoolMapTable;

@property (nonatomic, strong) NSMapTable <id ,NSMutableArray <NSMutableDictionary <NSString *, NSOperation *>*>*>*lowTaskPoolMapTable;

@property (nonatomic, strong) NSMutableDictionary<NSNumber*,NSMapTable*>* serialQueues;

/**
 二叉堆（小顶堆），用于实现优先队列
 */
@property (nonatomic, assign) CFBinaryHeapRef binaryHeapRef;

/**
 优先队列是否运行
 */
@property (nonatomic, assign) BOOL priorityTaskPoolIsRun;

@end

@implementation TaskScheduler

+ (NSString*)fetchUUID {
    return [@(atomic_fetch_add(&TaskSchedulerTimerIncrement,1)) stringValue];
}

+ (TaskScheduler *)shareManager {
    static TaskScheduler *taskPool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        taskPool = [[TaskScheduler alloc] init];
    });
    return taskPool;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _serialQueues = [NSMutableDictionary dictionary];
    }
    return self;
}

//- (dispatch_queue_t)serialQueueOfPriority:(NSOperationQueuePriority)priority{
//    CHECKANDRET(priority == NSOperationQueuePriorityLow||priority == NSOperationQueuePriorityNormal|| priority == NSOperationQueuePriorityHigh, nil);
//    static atomic_uint_fast64_t idx = 0;
//    [self.serialQueues batchOperation:^{
//        CHECK( !self.serialQueues[@(priority)] );
//        self.serialQueues[@(priority)] = [NSMapTable weakToWeakObjectsMapTable];
//    }];
//    NSMapTable<dispatch_queue_t,YYTaskSchedulerContext*>* table = self.serialQueues[@(priority)];
//    @synchronized ( table ) {
//        dispatch_queue_t queue = nil;
////        NSArray* keys = NSAllMapTableKeys(table);
//        if( table.count ){
//            //因NSAllMapTableKeys 在xcode9上编译会报错，改成如下获取keys方法
//            NSMutableArray* keys = [NSMutableArray new];
//            NSEnumerator* enumerator = table.keyEnumerator;
//            dispatch_queue_t tmpq = enumerator.nextObject;
//            while ( tmpq ) {
//                [keys addObject:tmpq];
//                tmpq = enumerator.nextObject;
//            }
//
//            queue = [keys firstObject];
//            NSUInteger minpayload = [table objectForKey:queue].payload;
//            for( int i = 1; i < keys.count; ++i ){
//                NSUInteger payload = [table objectForKey:[keys objectAtIndex:i]].payload;
//                if( payload < minpayload ){
//                    minpayload = payload;
//                    queue = [keys objectAtIndex:i];
//                }
//            }
//            //如果队列平均负载很大且队列数不超过maxTimerSerialQueue，则创建新队列
//            if( minpayload >= 6 && table.count < maxTimerSerialQueue ){
//                queue = nil;
//            }
//        }
//        if( !queue ){
//            uint64_t ix = atomic_fetch_add(&idx,1);
//            YYTaskSchedulerContext* context = [YYTaskSchedulerContext new];
//            context.qIdentifier = SF(@"com.yy.taskscheduler%@",@(ix));
//            dispatch_qos_class_t qos = QOS_CLASS_DEFAULT;
//            if( priority == NSOperationQueuePriorityHigh ){
//                qos = QOS_CLASS_USER_INITIATED;
//            }else if(priority == NSOperationQueuePriorityLow ){
//                qos = QOS_CLASS_UTILITY;
//            }
//            queue = dispatch_queue_create(context.qIdentifier.UTF8String, [self queueAttrForQos:qos concurrent:NO]);
//            context.queue = queue;
//            dispatch_queue_set_specific(queue, TaskSchedulerQueueSpecificKey, (__bridge void*)context, NULL);
//            dispatch_set_context(queue, (__bridge_retained void*)context);
//            dispatch_set_finalizer_f(queue, &taskschedulerCleanContext);
//            [table setObject:context forKey:queue];
//        }
//        return queue;
//    }
//}

//- (void)changePayloadForQueue:(dispatch_queue_t)queue increment:(BOOL)isIncrement{
//    CHECK(queue);
//    __block NSMapTable* table = nil;
//    [self.serialQueues enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMapTable * _Nonnull obj, BOOL * _Nonnull stop) {
//        @synchronized (obj) {
//            if( [obj objectForKey:queue] ){
//                table = obj;
//                *stop = YES;
//            }
//        }
//    }];
//    CHECK(table);
//    @synchronized (table) {
//        YYTaskSchedulerContext* context = [table objectForKey:queue];
//        CHECK(context);
//        NSUInteger payload = context.payload;
//        if( isIncrement ){
//            context.payload += 1;
//        }
//        else if( payload > 0 ){
//            context.payload -= 1;
//        }
//    }
//}

//- (BOOL)isInQueue:(dispatch_queue_t)queue{
//    void* specific = dispatch_queue_get_specific(queue, TaskSchedulerQueueSpecificKey);
//    return ( specific && specific == dispatch_get_specific(TaskSchedulerQueueSpecificKey) );
//}

- (NSString *)addSerialTaskToPool:(dispatch_block_t)taskBlock taskPriority:(NSOperationQueuePriority)taskPriority fromObj:(id)obj {
    if (!taskBlock) {
        return nil;
    }
    
    NSString *token = [TaskScheduler fetchUUID];
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        taskBlock();
    }];
    blockOperation.queuePriority = taskPriority;
    blockOperation.qualityOfService = [self choiceOperationQualityOfServiceWithTaskPriority:taskPriority];
    
    NSMutableArray <NSMutableDictionary <NSString *, NSOperation *>*>*array = [[self choiceMapTableWithPriority:taskPriority] objectForKey:obj];
    if (!array) {
        array = [NSMutableArray array];
        [[self choiceMapTableWithPriority:taskPriority] setObject:array forKey:obj];
    }
    
    if (array.count > 0) {
        NSMutableDictionary *dictionary = [array lastObject];
        NSBlockOperation *blockOperationEnd = [[dictionary allValues] lastObject];
        [blockOperation addDependency:blockOperationEnd];
    }
    
    __block NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:blockOperation forKey:token];
    [array addObject:dictionary];
    
    [blockOperation setCompletionBlock:^{
        if ([array containsObject:dictionary]) {
            [array removeObject:dictionary];
        }
    }];
    
    [[self choiceOperationQueueWithTaskPriority:taskPriority] addOperation:blockOperation];
    
//    [self singleShotOperation:^{
//        if (blockOperation.isFinished) {
//            NSLog(@"blockOperation:%@ is cancel",token);
//        } else {
//            NSLog(@"blockOperation:%@ is not cancel",token);
//        }
//    } interval:15];
    
    return token;
}

- (void)addTaskToPool:(dispatch_block_t)taskBlock blockAfterToMainThread:(dispatch_block_t)taskAfterBlock fromObj:(id)obj {
    if (!taskBlock || !taskAfterBlock) {
        return;
    }
    
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        taskBlock();
    }];
    
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        taskAfterBlock();
    }];
    
    [op2 addDependency:op1];
    
    [self.defaultTaskPool addOperation:op1];
    [[NSOperationQueue mainQueue] addOperation:op2];
}

- (void)addConcurrentTaskToPool:(dispatch_block_t)taskBlock taskPriority:(NSOperationQueuePriority)taskPriority {
    if (!taskBlock) {
        return;
    }
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        taskBlock();
    }];
    
    [[self choiceOperationQueueWithTaskPriority:taskPriority] addOperation:op];
}

- (void)addConcurrentOperationTaskToPool:(NSOperation *)operation taskPriority:(NSOperationQueuePriority)taskPriority {
    if (!operation) {
        return;
    }
    [[self choiceOperationQueueWithTaskPriority:taskPriority] addOperation:operation];
}

- (void)cancelTaskWithID:(NSString *)taskID withObj:(id)obj {
    if (taskID.length <= 0) {
        return;
    }
    
    NSMutableArray <NSMutableDictionary <NSString *, NSOperation *>*>*array = [self.defaultTaskPoolMapTable objectForKey:obj];
    if (!array) {
        array = [self.highTaskPoolMapTable objectForKey:obj];
        if (!array) {
            array = [self.lowTaskPoolMapTable objectForKey:obj];
            if (!array) {
                return;
            }
        }
    }
    
    [array enumerateObjectsUsingBlock:^(NSMutableDictionary<NSString *,NSOperation *> * _Nonnull dictionary, NSUInteger idx, BOOL * _Nonnull stop) {
        NSOperation *operation = [dictionary objectForKey:taskID];
        if (operation) {
            if (idx + 1 < array.count && idx != 0) {
                NSOperation *nextOperation = [[array[idx + 1] allValues] firstObject];
                NSOperation *priorOperation = [[array[idx - 1] allValues] firstObject];
                [nextOperation addDependency:priorOperation];
            }
            
            [operation cancel];
            [dictionary removeObjectForKey:taskID];
            [array removeObject:dictionary];
            *stop = YES;
        }
    }];
}

- (void)addTaskArrayToPool:(NSArray *)taskBlockArray {
    if (!taskBlockArray) {
        return;
    }

    NSMutableArray <NSBlockOperation *>*operationArray = [NSMutableArray array];
    for (dispatch_block_t block in taskBlockArray) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            block();
        }];
        if (operation) {
            [operationArray addObject:operation];
        }
    }
    
    NSBlockOperation *lastOperation = [operationArray lastObject];
    [operationArray enumerateObjectsUsingBlock:^(NSBlockOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
        if (operation != lastOperation) {
            [lastOperation addDependency:operation];
        }
    }];
    
    NSMutableArray *operationArrayCopy = [operationArray copy];
    [self.defaultTaskPool addOperations:operationArrayCopy waitUntilFinished:NO];
}

- (void)addTaskToPriorityQueue:(dispatch_block_t)taskBlock withTaskPriority:(NSUInteger)priority fromRecursion:(BOOL)recursion {
    if (!taskBlock) {
        return;
    }
    
    PriorityTask *priorityTask = [[PriorityTask alloc] init];
    priorityTask.taskBlock = taskBlock;
    priorityTask.priority = priority;

    @synchronized ((__bridge id)self.binaryHeapRef) {
        if (!recursion) {
            CFBinaryHeapAddValue(self.binaryHeapRef, (__bridge const void *)priorityTask);
        }
        
        PriorityTask *priorityTaskMini = CFBinaryHeapGetMinimum(self.binaryHeapRef);
        
        if (!self.priorityTaskPoolIsRun) {
            self.priorityTaskPoolIsRun = YES;
            CFBinaryHeapRemoveMinimumValue(self.binaryHeapRef);
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                priorityTaskMini.taskBlock();
            }];
            
            [operation setCompletionBlock:^{
                self.priorityTaskPoolIsRun = NO;
                if (CFBinaryHeapGetCount(self.binaryHeapRef)) {
                    PriorityTask *priorityTaskNowMini = CFBinaryHeapGetMinimum(self.binaryHeapRef);
                    if (priorityTaskNowMini.taskBlock) {
                        [self addTaskToPriorityQueue:priorityTaskNowMini.taskBlock withTaskPriority:priorityTaskNowMini.priority fromRecursion:YES];                        
                    } else {
                        return;
                    }
                } else {
                    return;
                }
            }];
            
            [self.priorityTaskPool addOperation:operation];
        }
    }
    
}

#pragma mark - util
/**
 根据传入的优先级返回对应的mapTable（队列存储空间）
 PS:这里不会返回最高优先级的队列，所以当传入最高优先级时候，返回的是次高优先级

 @param taskPriority 传入优先级
 @return mapTable（队列存储空间）
 */
- (NSMapTable *)choiceMapTableWithPriority:(NSOperationQueuePriority)taskPriority {
    // 这里只使用三个优先级，不适用最高和最低优先级
    switch (taskPriority) {
        case NSOperationQueuePriorityLow:
            {
                return self.lowTaskPoolMapTable;
            }
            break;
        case NSOperationQueuePriorityNormal:
            {
                return self.defaultTaskPoolMapTable;
            }
            break;
        case NSOperationQueuePriorityHigh:
            {
                return self.highTaskPoolMapTable;
            }
            break;
        default:
            {
                NSAssert(NO, @"taskPriority error");
                return nil;
            }
            break;
    }
}

/**
 根据传入的优先级返回对应的NSOperationQueue
 PS:这里不会返回最高优先级的队列，所以当传入最高优先级时候，返回的是次高优先级

 @param taskPriority 传入优先级
 @return 对应的队列
 */
- (NSOperationQueue *)choiceOperationQueueWithTaskPriority:(NSOperationQueuePriority)taskPriority {
    // 这里只使用三个优先级，不适用最高和最低优先级
    switch (taskPriority) {
        case NSOperationQueuePriorityLow:
            {
                return self.lowTaskPool;
            }
            break;
        case NSOperationQueuePriorityNormal:
            {
                return self.defaultTaskPool;
            }
            break;
        case NSOperationQueuePriorityHigh:
            {
                return self.highTaskPool;
            }
            break;
        default:
            {
                NSAssert(NO, @"taskPriority error");
                return nil;
            }
            break;
    }
}

/**
 根据传入的优先级返回对应的任务的QOS(服务质量级别)
 PS:这里不会返回最高优先级的队列，所以当传入最高优先级时候，返回的是次高优先级

 @param taskPriority 任务优先级
 @return 返回的任务的QOS服务质量级别
 */
- (NSQualityOfService)choiceOperationQualityOfServiceWithTaskPriority:(NSOperationQueuePriority)taskPriority {
    // 这里只使用三个优先级，不适用最高和最低优先级
    switch (taskPriority) {
        case NSOperationQueuePriorityLow:
            {
                return NSQualityOfServiceUtility;
            }
            break;
        case NSOperationQueuePriorityNormal:
            {
                return NSQualityOfServiceDefault;
            }
            break;
        case NSOperationQueuePriorityHigh:
            {
                return NSQualityOfServiceUserInitiated;
            }
            break;
        default:
            {
                NSAssert(NO, @"taskPriority error");
                return 0;
            }
            break;
    }
}

#pragma mark get-set
- (NSOperationQueue *)highTaskPool {
    if (!_highTaskPool) {
        _highTaskPool = [[NSOperationQueue alloc] init];
        _highTaskPool.qualityOfService = NSQualityOfServiceUserInitiated;
        _highTaskPool.maxConcurrentOperationCount = maxPoolCount;
        dispatch_queue_t queueTaskScheduler = dispatch_queue_create("com.TaskSchedulerHighTaskPool", [self queueAttrForQos:QOS_CLASS_USER_INITIATED concurrent:YES]);
        _highTaskPool.underlyingQueue = queueTaskScheduler;
    }
    return _highTaskPool;
}

- (NSMapTable *)highTaskPoolMapTable {
    if (!_highTaskPoolMapTable) {
        _highTaskPoolMapTable = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _highTaskPoolMapTable;
}

- (NSOperationQueue *)defaultTaskPool {
    if (!_defaultTaskPool) {
        _defaultTaskPool = [[NSOperationQueue alloc] init];
        _defaultTaskPool.qualityOfService = NSQualityOfServiceDefault;
        _defaultTaskPool.maxConcurrentOperationCount = maxPoolCount;
        dispatch_queue_t queueTaskScheduler = dispatch_queue_create("com.TaskSchedulerDefaultTaskPool", [self queueAttrForQos:QOS_CLASS_DEFAULT concurrent:YES]);
        _defaultTaskPool.underlyingQueue = queueTaskScheduler;
    }
    return _defaultTaskPool;
}

- (NSOperationQueue *)priorityTaskPool {
    if (!_priorityTaskPool) {
        _priorityTaskPool = [[NSOperationQueue alloc] init];
        _priorityTaskPool.qualityOfService = NSQualityOfServiceDefault;
        _priorityTaskPool.maxConcurrentOperationCount = 1;
    }
    return _priorityTaskPool;
}

- (NSMapTable *)defaultTaskPoolMapTable {
    if (!_defaultTaskPoolMapTable) {
        _defaultTaskPoolMapTable = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _defaultTaskPoolMapTable;
}

- (NSOperationQueue *)lowTaskPool {
    if (!_lowTaskPool) {
        _lowTaskPool = [[NSOperationQueue alloc] init];
        _lowTaskPool.qualityOfService = NSQualityOfServiceUtility;
        _lowTaskPool.maxConcurrentOperationCount = maxPoolCount;
        dispatch_queue_t queueTaskScheduler = dispatch_queue_create("com.TaskSchedulerLowTaskPool", [self queueAttrForQos:QOS_CLASS_UTILITY concurrent:YES]);
        _lowTaskPool.underlyingQueue = queueTaskScheduler;
    }
    return _lowTaskPool;
}

- (NSMapTable *)lowTaskPoolMapTable {
    if (!_lowTaskPoolMapTable) {
        _lowTaskPoolMapTable = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _lowTaskPoolMapTable;
}

- (dispatch_queue_attr_t)queueAttrForQos:(dispatch_qos_class_t)qos concurrent:(BOOL)concur{
    if(@available(iOS 10.0,*)){
        return dispatch_queue_attr_make_with_qos_class(concur?DISPATCH_QUEUE_CONCURRENT_WITH_AUTORELEASE_POOL:DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL, qos, 0);
    }else {
        return dispatch_queue_attr_make_with_qos_class(concur?DISPATCH_QUEUE_CONCURRENT:DISPATCH_QUEUE_SERIAL, qos, 0);
    }
}

- (CFBinaryHeapRef)binaryHeapRef {
    if (!_binaryHeapRef) {
        _binaryHeapRef = CFBinaryHeapCreate(NULL, 0, &(CFBinaryHeapCallBacks){
            .version = 0,
            .retain = TSRetain,
            .release = TSRelease,
            .copyDescription = CFCopyDescription,
            .compare = TaskCompare
        }, NULL);
    }
    return _binaryHeapRef;
}
@end
