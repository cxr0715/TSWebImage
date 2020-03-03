//
//  TSMutableDictionary.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/20.
//  Copyright © 2018年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @brief 基于保护MutableDictionary并发读写的目的，派生出对primitive读写操作进行锁同步保护的TSMutableDictionary
 可以做到的是不会由于并发读写引发汇编级的对象持有释放及objc_msgSend等崩溃，但由于读取过程中数据修改而引发的OC异常需要在使用过程中逐一做出应对
 目前的版本已经将测试中发现的问题做了修正，随项目推进会逐步完善
 */
@interface TSMutableDictionary : NSMutableDictionary

- (instancetype)initWithContent:(NSMutableDictionary*)content NS_DESIGNATED_INITIALIZER;

- (void)performBlock:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
