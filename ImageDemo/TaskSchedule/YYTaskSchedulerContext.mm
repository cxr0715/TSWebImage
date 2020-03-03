//
//  YYTaskSchedulerContext.m
//  ChannelProject
//
//  Created by 方阳 on 2019/1/29.
//  Copyright © 2019年 YY. All rights reserved.
//

#import "YYTaskSchedulerContext.h"
#import "TaskScheduler.h"

void taskschedulerCleanContext(void* context){
    YYTaskSchedulerContext* cont = (__bridge_transfer YYTaskSchedulerContext*)context;
    NSString* identifier = cont.qIdentifier;
    cont = nil;
}

@implementation YYTaskSchedulerContext

- (instancetype)init
{
    self = [super init];
    if (self) {
        _payload = 0;
    }
    return self;
}

- (void)dealloc
{
    
}

@end
