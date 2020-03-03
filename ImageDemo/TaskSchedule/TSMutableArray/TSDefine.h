//
//  TSDefine.h
//  ChannelProject
//
//  Created by 方阳 on 2018/12/26.
//  Copyright © 2018年 YY. All rights reserved.
//

#ifndef TSDefine_h
#define TSDefine_h
#import <Foundation/Foundation.h>

void ts_executeCleanupBlock(__strong dispatch_block_t *block);
//频繁操作不要用 cleanup attribute,CPU资源消耗严重
#define tsclean             __strong dispatch_block_t blk __attribute__((cleanup(ts_executeCleanupBlock), unused)) = ^
#define handlelock          [lock lock];@weakify(self); tsclean{ @strongify(self);CHECK(self);[self->lock unlock];}
#define handleunfairlock          if(@available(iOS 10.0,*)){          \
                                    os_unfair_lock_lock((os_unfair_lock_t)(&unfairlock));                                   \
                                  }else{[lock lock];}                                                   \
                                  @weakify(self);                                                       \
                                  tsclean{ @strongify(self);                                            \
                                           CHECK(self);                                                 \
                                           if(@available(iOS 10.0,*)){\
                                              os_unfair_lock_unlock((os_unfair_lock_t)(&(self->unfairlock)));                       \
                                           }else{ [self->lock unlock];}                                 \
                                  }
#define lockunfairlock      if(@available(iOS 10.0,*)){          \
                                os_unfair_lock_lock((os_unfair_lock_t)(&unfairlock));                                   \
                            }else{[lock lock];}
#define unlockunfairlock    if(@available(iOS 10.0,*)){\
                                os_unfair_lock_unlock((os_unfair_lock_t)(&unfairlock));                       \
                            }else{ [lock unlock];}
#endif /* TSDefine_h */
