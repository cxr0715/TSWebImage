//
//  TaskSchedulerTests.m
//  ChannelProject
//
//  Created by 方阳 on 2019/1/2.
//  Copyright © 2019年 YY. All rights reserved.
//
#ifdef DEBUG
#import "TaskSchedulerTests.h"
#import "NSDictionary+ThreadSafe.h"
#import "TSMutableDictionary.h"
#import "NSArray+ThreadSafe.h"
#import "NSSet+ThreadSafe.h"
#import <malloc/malloc.h>
#import "TaskScheduler.h"

@implementation TaskSchedulerTests

+ (void)load{
//    [self testTsSet];
//    [self testTsArray];
//    [self testTsDictionary];
//    [self testEffeciency];
//    [self testNSPredicate];
//    [self testTimer];
}

+ (void)testNSPredicate;{
    NSString* str = @"I";
    NSMutableArray* arr = [NSMutableArray new];
    for( int i = 0; i< 100000 ;++i ){
        [arr addObject:str];
    }
    NSArray* str1 = [NSArray new];
    [arr addObject:str1];
    
    CFAbsoluteTime ts = CFAbsoluteTimeGetCurrent();
    for( NSString* sttr in arr ){
        if( [sttr isKindOfClass:[NSArray class]] ){
            break;
        }
    }
    NSLog(@"fetch mutablestring without filter:%@",@(CFAbsoluteTimeGetCurrent()-ts));
    ts = CFAbsoluteTimeGetCurrent();
    [arr filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length = 0"]];
    NSLog(@"fetch mutablestring with filter:%@",@(CFAbsoluteTimeGetCurrent()-ts));
}

+ (void)testEffeciency;{
    NSMutableDictionary* origdic = [NSMutableDictionary new];
    NSMutableDictionary* tsdic = [NSMutableDictionary TsDictionary];
    
    NSMutableArray* origarr = [NSMutableArray new];
    NSMutableArray* tsarr = [NSMutableArray TsArray];
    
    NSMutableSet* origset = [NSMutableSet new];
    NSMutableSet* tsset = [NSMutableSet TsSet];
    
    static int testcount = 1000000;
    CFAbsoluteTime ts = CFAbsoluteTimeGetCurrent();
    for( int i = 0; i < testcount; ++i ){
        [origdic setObject:@(i) forKey:@(i)];
    }
    NSLog(@"%@ times of operation for orig dic:%@",@(testcount),@(CFAbsoluteTimeGetCurrent()-ts));
    
    ts = CFAbsoluteTimeGetCurrent();
    for( int i = 0; i < testcount; ++i ){
        [tsdic setObject:@(i) forKey:@(i)];
    }
    NSLog(@"%@ times of operation for ts dic:%@",@(testcount),@(CFAbsoluteTimeGetCurrent()-ts));
    
    ts = CFAbsoluteTimeGetCurrent();
    for( int i = 0; i < testcount; ++i ){
        [origarr addObject:@(i)];
//        [origarr removeObject:@(i)];
    }
    NSLog(@"%@ times of operation for orig arr:%@",@(testcount),@(CFAbsoluteTimeGetCurrent()-ts));
    
    ts = CFAbsoluteTimeGetCurrent();
    for( int i = 0; i < testcount; ++i ){
        [tsarr addObject:@(i)];
//        [tsarr removeObject:@(i)];
    }
    NSLog(@"%@ times of operation for ts arr:%@",@(testcount),@(CFAbsoluteTimeGetCurrent()-ts));
    
    ts = CFAbsoluteTimeGetCurrent();
    for( int i = 0; i < testcount; ++i ){
        [origset addObject:@(i)];
    }
    NSLog(@"%@ times of operation for orig set:%@",@(testcount),@(CFAbsoluteTimeGetCurrent()-ts));
    
    ts = CFAbsoluteTimeGetCurrent();
    for( int i = 0; i < testcount; ++i ){
        [tsset addObject:@(i)];
    }
    NSLog(@"%@ times of operation for ts set:%@",@(testcount),@(CFAbsoluteTimeGetCurrent()-ts));
    
    ts = CFAbsoluteTimeGetCurrent();
    NSArray* arr = [origarr copy];
    NSLog(@"1 times of operation for copy orig arr:%@",@(CFAbsoluteTimeGetCurrent()-ts));
    
    ts = CFAbsoluteTimeGetCurrent();
    arr = [tsarr copy];
    NSLog(@"1 times of operation for copy ts arr:%@",@(CFAbsoluteTimeGetCurrent()-ts));
}

+ (void)testNormalArray{
    NSMutableArray* arr = [NSMutableArray new];
//    NSString* abc = nil;
//    [arr addObject:abc];
//    [arr removeLastObject];
//    [arr objectAtIndex:0];
//    [arr insertObject:@"iewo" atIndex:1];
//    [arr removeObjectAtIndex:0];
    [arr addObject:@"i"];
//    [arr replaceObjectAtIndex:0 withObject:abc];
//    [arr replaceObjectAtIndex:1 withObject:@"iew"];
}

+ (void)testTsArray;{
    NSMutableArray* arr = [NSMutableArray TsArray];
    NSString* abc = nil;
    [arr addObject:@"iew"];
    [arr addObject:@"i"];
    BOOL equal = [arr isEqualToArray:@[@"iew",@"i"]];
    NSAssert(equal, @"not correct");
    equal = [arr isEqualToArray:@[@3]];
    NSAssert( !equal , @"not correct");
    arr = [NSMutableArray TsArray];
    [arr addObject:abc];
    [arr objectAtIndex:0];
    [arr indexOfObject:abc];
    [arr insertObject:abc atIndex:0];
    [arr insertObject:@"iewo" atIndex:1];
    [arr removeObjectAtIndex:0];
    [arr addObject:@"i"];
    [arr replaceObjectAtIndex:0 withObject:abc];
    [arr replaceObjectAtIndex:1 withObject:@"iew"];
    
    [arr addObject:@"iewo"];
    [arr addObject:@"33"];
    [arr addObject:@"3323"];
    for( id i in arr ){
        NSLog(@"%@",i);
    }
    //数组线程安全测试用例
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        int a = 0;
        while ( YES ) {
            [arr addObject:@(a++)];
            if( a > 1000 ){
                [arr removeObjectAtIndex:0];
                [arr removeAllObjects];
            }
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        __block int b = 0;
        while ( YES ) {
            [arr addObject:@(b++)];
            [arr addObject:@(b++)];
            [arr removeLastObject];
        }
    });
    
}

+ (void)testTsDictionary;{
    NSObject* obj = [NSObject new];
    NSDictionary* dic = @{@"ie":@"3",@8:@"8329",@8329:@"8329",@832:obj};
    NSMutableDictionary* exdic = [NSMutableDictionary TsDictionary];
    
    NSString* abc = nil;
    [exdic objectForKey:abc];
    [exdic allKeysForObject:abc];
    [exdic objectForKeyedSubscript:abc];
    [exdic setObject:@"ieow" forKey:abc];
    [exdic removeObjectForKey:abc];
    
    exdic = [TSMutableDictionary dictionaryWithCapacity:3];
    [exdic setObject:@"3" forKey:@"ie"];
    [exdic setObject:@"8329" forKey:@8];
    [exdic setObject:@"8329" forKey:@8329];
    [exdic setObject:obj forKey:@832];
    NSAssert(exdic.count == 4, @"count wrong");
    NSAssert([[exdic objectForKey:@"ie"] isEqualToString:@"3"], @"wrong objectforkey");
    for( id a in exdic.allKeys )
    {
        NSLog(@"exdic test enumerate exdic:%@",a);
    }
    NSArray* arr = [exdic allKeysForObject:@"8329"];
    NSAssert(arr.count == 2, @"wrong allkeysforobject");
    NSAssert([exdic keyEnumerator].allObjects.count==4, @"wrong keyenmerator");
    NSAssert([exdic allValues].count==4, @"wrong keyenmerator");
    NSLog(@"exdic test %@",exdic.description);
    NSAssert([exdic isEqualToDictionary:dic], @"wrong equaltodictionary1");
    NSAssert([dic isEqualToDictionary:[exdic tsMutableCopy]], @"wrong equaltodictionary2");
    [exdic removeObjectForKey:@8];
    NSAssert([exdic isEqualToDictionary:[exdic tsMutableCopy]], @"wrong equaltodictionary3");
    exdic[@"iewo"] = @"ieiewoeiwo";
//字典线程安全测试用例
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        int a = 0;
        while ( YES ) {
            [exdic setObject:@(a++) forKey:@(a++)];
        }
    });
    int b = 0;
    while ( YES ) {
        [exdic setObject:@(b++) forKey:@(b++)];
    }
}

+ (void)testTsSet;{
    NSString* abc = nil;
    NSMutableSet* set = [NSMutableSet TsSet];
    [set addObject:abc];
    [set removeObject:abc];
    [set member:abc];
    [set addObjectsFromArray:@[@2,@3]];
    [set removeAllObjects];
    [set addObjectsFromArray:@[@2,@3]];
    NSMutableSet* ss = [NSMutableSet setWithObject:@2];
    [set intersectSet:ss];
    [set addObject:@5];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"charValue > 2"];
    [set filterUsingPredicate:predicate];
    [set filterUsingPredicate:predicate];
}

+ (void)testTimer;{
    NSMutableArray* arr = [NSMutableArray new];
    arr[0] = [NSObject new];
    arr[1] = [NSObject new];
    arr[2] = [NSObject new];
    arr[3] = [NSObject new];
    arr[4] = [NSObject new];
    arr[5] = [NSObject new];
    arr[6] = [NSObject new];
    arr[7] = [NSObject new];
    arr[8] = [NSObject new];
    arr[9] = [NSObject new];
    arr[10] = [NSObject new];
    arr[11] = [NSObject new];
    arr[12] = [NSObject new];
    arr[13] = [NSObject new];
    arr[14] = [NSObject new];
    arr[15] = [NSObject new];
    arr[16] = [NSObject new];
    arr[17] = [NSObject new];
    arr[18] = [NSObject new];
    arr[19] = [NSObject new];
    arr[20] = [NSObject new];
    arr[21] = [NSObject new];
    arr[22] = [NSObject new];
    arr[23] = [NSObject new];
    arr[24] = [NSObject new];
    arr[25] = [NSObject new];
    arr[26] = [NSObject new];
    arr[27] = [NSObject new];
    arr[28] = [NSObject new];
//    [arr[0] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 1, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[1] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 2, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[2] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 3, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[3] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 4, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[4] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 5, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[5] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 6, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[6] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 7, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[7] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 8, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[8] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 9, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[9] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 10, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[10] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 11, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[11] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 12, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[12] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 13, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[13] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 14, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[14] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 15, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[15] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 16, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[16] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 17, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[17] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 18, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[18] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 19, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[19] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 20, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[20] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 21, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[21] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 22, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[22] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 23, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[23] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 24, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[24] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 25, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[25] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 26, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[26] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 27, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    [arr[27] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 28, %@",[NSThread currentThread]);
//        return NO;
//    } interval:3 atMain:NO];
//    NSString* token = [arr[28] addTimerOperation:^BOOL{
//        NSLog(@"the very timer 29, %@",[NSThread currentThread]);
//        return NO;
//    } interval:2.9*2.9 atMain:NO];
//    NSAssert( [arr[28] getTimerInterval:token] == 2.9*2.9 , @"timer interval wrong");
//    [arr[28] fireTimerOperation:token sync:YES];
//    NSAssert([arr[28] getFiredTimes:token] == 1, @"fired times1");
//    dispatch_queue_t q = [[TaskScheduler shareManager] serialQueueOfPriority:NSOperationQueuePriorityNormal];
//    dispatch_async(q, ^{
//        [arr[28] fireTimerOperation:token sync:NO];
//        NSAssert([arr[28] getFiredTimes:token] == 2, @"fired times2");
//    });
//    NSArray<NSString*>* a = [arr[28] getTimersWithInterval:8.41];
//    NSAssert( [[a firstObject] isEqualToString:token], @"token not equal");
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSAssert([arr[28] getFiredTimes:token] == 3, @"fired times 3");
//        NSLog(@"the very timer log:%@",arr);
//    });
}
@end
#endif
