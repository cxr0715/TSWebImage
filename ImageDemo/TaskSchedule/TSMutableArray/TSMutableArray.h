//
//  TSMutableArray.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/26.
//  Copyright © 2018年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @brief 基于保护MutableArray并发读写的目的，派生出对primitive读写操作进行锁同步保护的TSMutableArray
 可以做到的是不会由于并发读写引发汇编级的对象持有释放及objc_msgSend等崩溃，但由于读取过程中数据修改而引发的OC异常需要在使用过程中逐一做出应对
 目前的版本已经将测试中发现的问题做了修正，随项目推进会逐步完善
 @warning 不要用for in 遍历数组，因为遍历会取数组元素的unsafe_unretain，若遍历过程中数组被修改，仍有可能会有多线程崩溃
          同时在传递mutable array的过程中使用对应的copy
 */
@interface TSMutableArray : NSMutableArray

- (instancetype)initWithContent:(NSMutableArray*)arr NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
