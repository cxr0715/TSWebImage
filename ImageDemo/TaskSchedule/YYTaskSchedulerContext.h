//
//  YYTaskSchedulerContext.h
//  ChannelProject
//
//  Created by 方阳 on 2019/1/29.
//  Copyright © 2019年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YYTaskSchedulerContext : NSObject

@property (nonatomic,weak)      dispatch_queue_t queue;
@property (nonatomic,strong)    NSString*   qIdentifier;
@property (nonatomic,assign)    NSUInteger  payload;

@end

void taskschedulerCleanContext(void* context);
