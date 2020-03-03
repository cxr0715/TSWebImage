//
//  TSMutableSet.m
//  ChannelProject
//
//  Created by 方阳 on 2018/12/28.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "TSMutableSet.h"
#import "TSDefine.h"

@interface TSMutableSet()
{
    NSRecursiveLock*        lock;
    NSMutableSet*           _storage; //设计上不存在为nil的情况
}

@end

@implementation TSMutableSet

+ (instancetype)setWithSet:(NSSet *)set;{
    return [[TSMutableSet alloc] initWithStorage:set];
}

- (id)copy{
    handlelock;
    return [_storage copy];
}

- (id)mutableCopy;{
    return [[TSMutableSet alloc] initWithStorage:self];
}

- (NSUInteger)count{
    [lock lock];
    NSUInteger cnt = [_storage count];
    [lock unlock];
    return cnt;
}

- (id)member:(id)object{
    [lock lock];
    id mem = [_storage member:object];
    [lock unlock];
    return mem;
}

- (NSEnumerator *)objectEnumerator{
    [lock lock];
    NSEnumerator* enumerator =  [_storage objectEnumerator];
    [lock unlock];
    return enumerator;
}

#pragma mark NSExtendedSet
- (NSArray *)allObjects{
    [lock lock];
    NSArray* arr = [_storage allObjects];
    [lock unlock];
    return arr;
}

- (id)anyObject{
    [lock lock];
    id obj = [_storage anyObject];
    [lock unlock];
    return obj;
}

- (BOOL)containsObject:(id)anObject{
    [lock lock];
    BOOL contains = [_storage containsObject:anObject];
    [lock unlock];
    return contains;
}

- (BOOL)intersectsSet:(NSSet *)otherSet{
    [lock lock];
    BOOL intersect = [_storage intersectsSet:[otherSet copy]];
    [lock unlock];
    return intersect;
}

- (BOOL)isEqualToSet:(NSSet *)otherSet{
    [lock lock];
    BOOL eq = [_storage isEqualToSet:[otherSet copy]];
    [lock unlock];
    return eq;
}

- (BOOL)isSubsetOfSet:(NSSet *)otherSet{
    [lock lock];
    BOOL sub = [_storage isSubsetOfSet:[otherSet copy]];
    [lock unlock];
    return sub;
}

- (NSSet *)setByAddingObject:(id)anObject{
    [lock lock];
    NSSet* set = [_storage setByAddingObject:anObject];
    [lock unlock];
    return set;
}

- (NSSet *)setByAddingObjectsFromSet:(NSSet *)other{
    [lock lock];
    NSSet* set = [_storage setByAddingObjectsFromSet:[other copy]];
    [lock unlock];
    return set;
}

- (NSSet *)setByAddingObjectsFromArray:(NSArray *)other{
    [lock lock];
    NSSet* set = [_storage setByAddingObjectsFromArray:[other copy]];
    [lock unlock];
    return set;
}

- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(id _Nonnull, BOOL * _Nonnull))block{
    [lock lock];
    [_storage enumerateObjectsUsingBlock:block];
    [lock unlock];
}

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(id _Nonnull, BOOL * _Nonnull))block{
    [lock lock];
    [_storage enumerateObjectsWithOptions:opts usingBlock:block];
    [lock unlock];
}

#pragma mark NSMutableSet
- (void)addObject:(id)object{
    CHECK(object);
    [lock lock];
    [_storage addObject:object];
    [lock unlock];
}

- (void)removeObject:(id)object{
    CHECK(object);
    [lock lock];
    [_storage removeObject:object];
    [lock unlock];
}

#pragma mark NSExtendedMutableSet
- (void)addObjectsFromArray:(NSArray *)array{
    [lock lock];
    [_storage addObjectsFromArray:[array copy]];
    [lock unlock];
}

- (void)intersectSet:(NSSet *)otherSet{
    [lock lock];
    [_storage intersectSet:[otherSet copy]];
    [lock unlock];
}

- (void)minusSet:(NSSet *)otherSet{
    [lock lock];
    [_storage minusSet:[otherSet copy]];
    [lock unlock];
}

- (void)removeAllObjects{
    [lock lock];
    [_storage removeAllObjects];
    [lock unlock];
}

- (void)unionSet:(NSSet *)otherSet{
    [lock lock];
    [_storage unionSet:[otherSet copy]];
    [lock unlock];
}

- (void)setSet:(NSSet *)otherSet{
    [lock lock];
    [_storage setSet:[otherSet copy]];
    [lock unlock];
}

#pragma mark api
- (void)performBlock:(dispatch_block_t)block;{
    CHECK(block);
    handlelock;
    block();
}

#pragma mark init
- (instancetype)initWithContent:(NSMutableSet*)set;{
    self = [super init];
    if( self )
    {
        lock = [NSRecursiveLock new];
        _storage = set;
    }
    return self;
}

- (instancetype)initWithStorage:(NSSet*)set;{
    NSMutableSet* stor = nil;
    if( [set isKindOfClass:[TSMutableSet class]] ){
        stor = [self _intrinsicStorageCopy];
    }
    else{
        stor = [set mutableCopy];
    }
    if( !stor ){
        stor = [NSMutableSet new];
    }
    return [self initWithContent:stor];
}

- (instancetype)init
{
    return [self initWithStorage:nil];
}

- (instancetype)initWithObjects:(id  _Nonnull const [])objects count:(NSUInteger)cnt{
    return [self initWithContent:[[NSMutableSet alloc] initWithObjects:objects count:cnt]];
}

- (instancetype)initWithCapacity:(NSUInteger)numItems{
    return [self initWithContent:[NSMutableSet new]];
}

#pragma mark encoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithContent:[[NSMutableSet alloc] initWithCoder:aDecoder]];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    handlelock;
    [_storage encodeWithCoder:coder];
}

#pragma mark predicate
- (NSSet *)filteredSetUsingPredicate:(NSPredicate *)predicate{
    [lock lock];
    NSSet* set = [_storage filteredSetUsingPredicate:predicate];
    [lock unlock];
    return set;
}

- (void)filterUsingPredicate:(NSPredicate *)predicate{
    [lock lock];
    [_storage filterUsingPredicate:predicate];
    [lock unlock];
}

#pragma mark _intrinsic
- (NSMutableSet*)_intrinsicStorageCopy;{
    handlelock;
    return [_storage copy];
}
@end
