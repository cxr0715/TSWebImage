//
//  TSMutableArray.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/26.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "TSMutableArray.h"
#import "TSDefine.h"
#include <os/lock.h>

typedef struct substitute_the_very_lock_s {
    uint32_t _substitute_the_very_lock_opaque;
} substitute_the_very_lock;

@interface TSMutableArray()
{
    NSRecursiveLock*        lock;
    substitute_the_very_lock          unfairlock; //iOS10上用性能最好的锁保护
    NSMutableArray*         _storage; //设计上不存在为nil的情况
}

@end

@implementation TSMutableArray

+ (instancetype)arrayWithCapacity:(NSUInteger)numItems
{
    return [[TSMutableArray alloc] initWithVolume:0];
}

+ (instancetype)arrayWithArray:(NSArray *)array
{
    return [[TSMutableArray alloc] initWithStorage:array];
}

#pragma mark NSCopying,NSMutableCoping
- (id)copy
{
    handleunfairlock;
    return [_storage copy];
}

- (id)mutableCopy;
{
    return [[TSMutableArray alloc] initWithStorage:self];
}

#pragma mark NSArray
- (id)objectAtIndex:(NSUInteger)index{
    lockunfairlock;             //不要用 cleanup attribute,CPU资源消耗严重
    if( index >= _storage.count ){
        unlockunfairlock;
        return nil;
    }
    id obj = [_storage objectAtIndex:index];
    unlockunfairlock;
    return obj;
}

- (NSUInteger)count{
    lockunfairlock
    NSUInteger count = [_storage count];
    unlockunfairlock;
    return count;
}

#pragma mark NSExtendedArray
- (NSArray *)arrayByAddingObject:(id)anObject{
    lockunfairlock;
    NSArray* arr = [_storage arrayByAddingObject:anObject];
    unlockunfairlock;
    return arr;
}

- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)otherArray{
    lockunfairlock;
    NSArray* arr = [_storage arrayByAddingObjectsFromArray:[otherArray copy]];
    unlockunfairlock;
    return arr;
}

- (NSString *)componentsJoinedByString:(NSString *)separator{
    lockunfairlock;
    NSString* str = [_storage componentsJoinedByString:separator];
    unlockunfairlock;
    return str;
}

- (BOOL)containsObject:(id)anObject{
    CHECKANDRET(anObject,NO);
    lockunfairlock;
    BOOL contains = [_storage containsObject:anObject];
    unlockunfairlock;
    return contains;
}

- (NSUInteger)indexOfObject:(id)anObject{
    lockunfairlock;
    NSUInteger idx = [_storage indexOfObject:anObject];
    unlockunfairlock;
    return idx;
}

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range{
    lockunfairlock;
    NSUInteger idx = [_storage indexOfObject:anObject inRange:range];
    unlockunfairlock;
    return idx;
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject;{
    lockunfairlock;
    NSUInteger idx = [_storage indexOfObjectIdenticalTo:anObject];
    unlockunfairlock;
    return idx;
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range;{
    lockunfairlock;
    NSUInteger idx = [_storage indexOfObjectIdenticalTo:anObject inRange:range];
    unlockunfairlock;
    return idx;
}

- (BOOL)isEqualToArray:(NSArray *)otherArray{
    lockunfairlock;
    BOOL eq = [_storage isEqualToArray:[otherArray copy]];
    unlockunfairlock;
    return eq;
}

- (id)firstObject{
    lockunfairlock;
    id obj = [_storage firstObject];
    unlockunfairlock;
    return obj;
}

- (id)lastObject{
    lockunfairlock;
    id obj = [_storage lastObject];
    unlockunfairlock;
    return obj;
}

- (NSEnumerator *)objectEnumerator{
    lockunfairlock;
    NSEnumerator* enumerator = [_storage objectEnumerator];
    unlockunfairlock;
    return enumerator;
}

- (NSEnumerator *)reverseObjectEnumerator{
    lockunfairlock;
    NSEnumerator* enumerator = [_storage reverseObjectEnumerator];
    unlockunfairlock;
    return enumerator;
}

#pragma mark NSMutableArray
- (void)addObject:(id)anObject{
    CHECK( anObject );
    lockunfairlock;
    [_storage addObject:anObject];
    unlockunfairlock;
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;{
    CHECK( anObject );
    lockunfairlock;
    if( index > _storage.count ){
        unlockunfairlock;
        return;
    }
    [_storage insertObject:anObject atIndex:index];
    unlockunfairlock;
}

- (void)removeLastObject;{
    lockunfairlock;
    [_storage removeLastObject];
    unlockunfairlock;
}

- (void)removeObjectAtIndex:(NSUInteger)index;{
    lockunfairlock;
    if( index >= _storage.count ){
        unlockunfairlock;
        return;
    }
    [_storage removeObjectAtIndex:index];
    unlockunfairlock;
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;{
    CHECK( anObject );
    lockunfairlock;
    if( index >= _storage.count ){
        unlockunfairlock;
        return;
    }
    [_storage replaceObjectAtIndex:index withObject:anObject];
    unlockunfairlock;
}

- (void)getObjects:(__unsafe_unretained id  _Nonnull [])objects range:(NSRange)range{
    lockunfairlock;
    [_storage getObjects:objects range:range];
    unlockunfairlock;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len{
    lockunfairlock;
    NSUInteger cnt = [_storage countByEnumeratingWithState:state objects:buffer count:len];
    unlockunfairlock;
    return cnt;
}

- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(id _Nonnull, NSUInteger, BOOL * _Nonnull))block{
    lockunfairlock;
    if( !_storage.count ){
        unlockunfairlock;
        return;
    }
    NSArray* copy = [_storage copy];
    unlockunfairlock;
    [copy enumerateObjectsUsingBlock:block]; //incase you wanna do whatever you want in the very block
}

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(id _Nonnull, NSUInteger, BOOL * _Nonnull))block{
    lockunfairlock;
    if( !_storage.count ){
        unlockunfairlock;
        return;
    }
    NSArray* copy = [_storage copy];
    unlockunfairlock;
    [copy enumerateObjectsWithOptions:opts usingBlock:block];
}

#pragma mark NSExtendedMutableArray
- (void)addObjectsFromArray:(NSArray *)otherArray{
    lockunfairlock;
    [_storage addObjectsFromArray:[otherArray copy]];
    unlockunfairlock;
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2{
    lockunfairlock;
    [_storage exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
    unlockunfairlock;
}

- (void)removeAllObjects{
    lockunfairlock;
    [_storage removeAllObjects];
    unlockunfairlock;
}

- (void)removeObject:(id)anObject inRange:(NSRange)range{
    lockunfairlock;
    [_storage removeObject:anObject inRange:range];
    unlockunfairlock;
}

- (void)removeObject:(id)anObject{
    lockunfairlock;
    [_storage removeObject:anObject];
    unlockunfairlock;
}

- (void)removeObjectIdenticalTo:(id)anObject{
    lockunfairlock;
    [_storage removeObjectIdenticalTo:anObject];
    unlockunfairlock;
}

- (void)removeObjectIdenticalTo:(id)anObject inRange:(NSRange)range{
    lockunfairlock;
    [_storage removeObjectIdenticalTo:anObject inRange:range];
    unlockunfairlock;
}

- (void)removeObjectsInArray:(NSArray *)otherArray{
    lockunfairlock;
    [_storage removeObjectsInArray:[otherArray copy]];
    unlockunfairlock;
}

- (void)removeObjectsInRange:(NSRange)range{
    lockunfairlock;
    [_storage removeObjectsInRange:range];
    unlockunfairlock;
}

- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray{
    lockunfairlock;
    [_storage replaceObjectsInRange:range withObjectsFromArray:[otherArray copy]];
    unlockunfairlock;
}

- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray range:(NSRange)otherRange{
    lockunfairlock;
    [_storage replaceObjectsInRange:range withObjectsFromArray:[otherArray copy] range:otherRange];
    unlockunfairlock;
}

#pragma mark sortUsingDescriptors
- (void)sortUsingDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors{
    lockunfairlock;
    [_storage sortUsingDescriptors:[sortDescriptors copy]];
    unlockunfairlock;
}

#pragma mark predicate
- (NSArray *)filteredArrayUsingPredicate:(NSPredicate *)predicate{
    lockunfairlock;
    NSArray* arr = [_storage filteredArrayUsingPredicate:predicate];
    unlockunfairlock;
    return arr;
}

- (void)filterUsingPredicate:(NSPredicate *)predicate{
    lockunfairlock;
    [_storage filterUsingPredicate:predicate];
    unlockunfairlock;
}

#pragma mark encoding
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder;{
    return [self initWithContent:[[NSMutableArray alloc] initWithCoder:aDecoder]];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    handleunfairlock;
    [_storage encodeWithCoder:coder];
}

#pragma mark initializer
- (instancetype)initWithContent:(NSMutableArray *)arr{
    NSAssert([arr isKindOfClass:[NSMutableArray class]] && ![arr isKindOfClass:[TSMutableArray class]], @"invalid input for TSMutableArray");
    self = [super init];
    if( self )
    {
        lock = [NSRecursiveLock new];
        _storage = arr;
        if(@available(iOS 10.0,*)){
            os_unfair_lock_t ll = (os_unfair_lock_t)(&unfairlock);
            *ll = OS_UNFAIR_LOCK_INIT;
        }
    }
    return self;
}

- (instancetype)initWithVolume:(NSUInteger)num;{
    return [self initWithContent:[NSMutableArray arrayWithCapacity:num]];
}

- (instancetype)initWithCapacity:(NSUInteger)numItems;{
    return [self initWithVolume:numItems];
}

- (instancetype)init;{
    return [self initWithVolume:0];
}

- (instancetype)initWithObjects:(id  _Nonnull const [])objects count:(NSUInteger)cnt;{
    return [self initWithContent:[[NSMutableArray alloc] initWithObjects:objects count:cnt]];
}
                                                    
- (instancetype)initWithStorage:(NSArray*)arr;{
    NSMutableArray* stor = nil;
    if ( [arr isKindOfClass:[TSMutableArray class]] ) {
        stor = [(TSMutableArray*)arr _intrinsicStorageCopy];
    }
    else{
        stor = [arr mutableCopy];
    }
    if( !stor )
    {
        stor = [NSMutableArray new];
    }
    return [self initWithContent:stor];
}

#pragma mark private
- (NSMutableArray*)_intrinsicStorageCopy;{
    handleunfairlock;
    return [_storage mutableCopy];
}
@end
