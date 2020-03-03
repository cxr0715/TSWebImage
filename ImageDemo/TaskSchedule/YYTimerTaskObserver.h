//
//  YYTimerTaskObserver.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/29.
//  Copyright © 2018年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL(^timerOperation)(void);
@interface YYTimerTask : NSObject

@property (nonatomic,strong) dispatch_source_t  source;
@property (nonatomic,strong) dispatch_queue_t   queue;
@property (nonatomic,strong) timerOperation     operation;
@property (nonatomic,assign) BOOL               isMainQueue;
@property (nonatomic,assign) NSTimeInterval     interval;
@property (nonatomic,readonly) NSUInteger         firedTimes;

- (void)incrementFireTimes;

@end

@interface YYTimerTaskObserver : NSObject

@property (nonatomic,strong) NSMutableDictionary<NSString*,YYTimerTask*>* timers;

@end
