//
//  NSDictionary+ThreadSafe.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/25.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "NSDictionary+ThreadSafe.h"
#import "TSMutableDictionary.h"
#import <objc/runtime.h>

/*
 实现了 isEqualToDictionary:
 iOS9.2(iPhone5s Simulator):    NSDictionary,NSAttributeDictionary,NSKnownKeysDictionary1,CTFeatureSetting
 iOS10.3.1(iPhone6 Simulator):  NSDictionary,NSAttributeDictionary,NSKnownKeysDictionary1,__NSSingleEntryDictionaryI,CTFeatureSetting
 iOS11.4(Simulator):            NSDictionary,NSAttributeDictionary,NSKnownKeysDictionary1,__NSSingleEntryDictionaryI,CTFeatureSetting
 iOS12(iPhone6s Device):        NSDictionary,NSAttributeDictionary,NSKnownKeysDictionary1,__NSSingleEntryDictionaryI,CTFeatureSetting
 */

@implementation NSDictionary (ThreadSafe)

#pragma mark NSCopying,NSMutableCoping
- (NSMutableDictionary*)tsMutableCopy;{
    return [TSMutableDictionary dictionaryWithDictionary:self];
}

@end

@implementation NSMutableDictionary (ThreadSafe)

+ (instancetype)TsDictionary
{
    return [TSMutableDictionary new];
}

- (void)batchOperation:(dispatch_block_t)block;{
//    CHECK(block);
    if( [self isKindOfClass:[TSMutableDictionary class]] ){
        [((TSMutableDictionary*)self) performBlock:block];
    }
    else{
        block();
    }
}
@end
/*
 #check isEqualToDictionary:
 
 unsigned int ccount;
 Class* buf = objc_copyClassList(&ccount);
 for( int a = 0; a<ccount ; ++a )
 {
 Class cls = buf[a];
 unsigned int count = 0;
 Method* list = class_copyMethodList(cls, &count);
 for( int i = 0; i < count; ++i )
 {
 Method m = list[i];
 SEL sel = method_getName(m);
 if( [NSStringFromSelector(sel) isEqualToString:@"isEqualToDictionary:"] ){
 NSLog(@"check equaltodictionary:%@",cls);
 }
 }
 }
 */
