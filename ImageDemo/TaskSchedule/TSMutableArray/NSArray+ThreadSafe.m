//
//  NSArray+ThreadSafe.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/26.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "NSArray+ThreadSafe.h"
#import "TSMutableArray.h"
#import <objc/runtime.h>

@implementation NSArray (ThreadSafe)

+ (void)load{
    [self exchangeInstanceMethod:object_getClass([NSArray class]) newSEL:@selector(arrayWithArray_ThreadSafe:) origSEL:@selector(arrayWithArray:)];
}

+ (instancetype)arrayWithArray_ThreadSafe:(NSArray *)array;{
    if( [array isKindOfClass:[TSMutableArray class]] ){
        return [self arrayWithArray_ThreadSafe:[(TSMutableArray*)array copy]];
    }
    return [self arrayWithArray_ThreadSafe:array];
}

+ (void)exchangeInstanceMethod:(Class)theClass newSEL:(SEL)newSEL origSEL:(SEL)origSEL{
    CHECK(theClass);
    Method newmethod = class_getInstanceMethod(theClass, newSEL);
    Method origmethod = class_getInstanceMethod(theClass, origSEL);
    CHECK( newmethod && origmethod );
    method_exchangeImplementations(newmethod, origmethod);
}

#pragma mark api
- (NSMutableArray *)tsMutableCopy
{
    return [TSMutableArray arrayWithArray:self];
}

@end

@implementation NSMutableArray (ThreadSafe)

+ (instancetype)TsArray
{
    return [TSMutableArray new];
}

@end

//    unsigned int ccount;
//    Class* buf = objc_copyClassList(&ccount);
//    for( int a = 0; a<ccount ; ++a )
//    {
//        Class cls = buf[a];
//        unsigned int count = 0;
//        Method* list = class_copyMethodList(cls, &count);
//        for( int i = 0; i < count; ++i )
//        {
//            Method m = list[i];
//            SEL sel = method_getName(m);
//            if( [NSStringFromSelector(sel) isEqualToString:@"initWithArray:"] ){
//                NSLog(@"check arrayWithArray:%@",cls);
//            }
//        }
//    }
