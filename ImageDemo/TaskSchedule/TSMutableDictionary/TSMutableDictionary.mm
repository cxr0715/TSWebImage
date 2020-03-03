//
//  TSMutableDictionary.mm
//  ChannelProject
//
//  Created by 方阳 on 2018/12/20.
//  Copyright © 2018年 YY. All rights reserved.
//

#import "TSMutableDictionary.h"
//#import "CrashGuardGeneralLock.h"
#import "TSDefine.h"

void ts_executeCleanupBlock (__strong dispatch_block_t *block) {(*block)();}

@interface TSMutableDictionary()
{
    NSRecursiveLock*        lock;
    NSMutableDictionary*    _storage; //设计上不存在为nil的情况
}
@end

@implementation TSMutableDictionary

+ (instancetype)dictionaryWithDictionary:(NSDictionary *)dict{
    return [[TSMutableDictionary alloc] initWithStorage:dict];
}

- (void)performBlock:(dispatch_block_t)block;{
    CHECK(block);
    handlelock;
    block();
}

#pragma mark NSCopying,NSMutableCoping
- (id)copy{
    handlelock;
    return [_storage copy];
}

- (id)mutableCopy{
    return [[TSMutableDictionary alloc] initWithStorage:self];
}

#pragma mark initialization
- (instancetype)init{
    return [self initWithVolume:0];
}

- (instancetype)initWithCapacity:(NSUInteger)numItems{
    return [self initWithVolume:numItems];
}

- (instancetype)initWithVolume:(NSUInteger)volume;{
    return [self initWithContent:[[NSMutableDictionary alloc] initWithCapacity:volume]];
}

- (instancetype)initWithStorage:(nullable NSDictionary*)value;
{
    NSMutableDictionary* stor = nil;
    if( [value isKindOfClass:[TSMutableDictionary class]] )
    {
        stor = [(TSMutableDictionary*)value _intrinsicStorageCopy];
    }
    else
    {
        stor = [value mutableCopy];
    }
    if( !stor )
    {
        stor = [NSMutableDictionary new];
    }
    return [self initWithContent:stor];
}

- (instancetype)initWithContent:(NSMutableDictionary *)content{
    NSAssert([content isKindOfClass:[NSMutableDictionary class]] && ![content isKindOfClass:[TSMutableDictionary class]], @"invalid input for tsmutabledicationary");
    self = [super init];
    if( self )
    {
        lock = [NSRecursiveLock new];
        _storage = content;
    }
    return self;
}

#pragma mark NSDictionary
- (NSUInteger)count;{
    [lock lock];
    NSUInteger count = _storage.count;
    [lock unlock];
    return count;
}

- (nullable id)objectForKey:(id)aKey;{
    CHECKANDRET(aKey, nil);
    [lock lock];
    id obj = [_storage objectForKey:aKey];
    [lock unlock];
    return obj;
}

- (NSEnumerator*)keyEnumerator;{
    [lock lock];
    NSEnumerator* enumerator = [_storage keyEnumerator];
    [lock unlock];
    return enumerator;
}

#pragma mark NSExtendedDictionary
- (NSArray *)allKeys{
    handlelock;
    return [_storage allKeys];
}

- (NSArray *)allKeysForObject:(id)anObject{
    handlelock;
    return [_storage allKeysForObject:anObject];
}

- (NSArray *)allValues{
    handlelock;
    return [_storage allValues];
}

- (NSString *)description{
    handlelock;
    return _storage.description;
}

- (NSString *)descriptionInStringsFileFormat{
    handlelock;
    return _storage.descriptionInStringsFileFormat;
}

- (NSString *)descriptionWithLocale:(id)locale{
    handlelock;
    return [_storage descriptionWithLocale:locale];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level{
    handlelock;
    return [_storage descriptionWithLocale:locale indent:level];
}

- (NSEnumerator *)objectEnumerator{
    [lock lock];
    NSEnumerator* enumerator = [_storage objectEnumerator];
    [lock unlock];
    return enumerator;
}

- (NSArray *)objectsForKeys:(NSArray *)keys notFoundMarker:(id)marker{
    handlelock;
    return [_storage objectsForKeys:keys notFoundMarker:marker];
}

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error;{
    handlelock;
    return [_storage writeToURL:url error:error];
}

- (NSArray *)keysSortedByValueUsingSelector:(SEL)comparator{
    handlelock;
    return [_storage keysSortedByValueUsingSelector:comparator];
}

- (void)getObjects:(__unsafe_unretained id  _Nonnull [])objects andKeys:(__unsafe_unretained id  _Nonnull [])keys count:(NSUInteger)count{
    handlelock;
    [_storage getObjects:objects andKeys:keys count:count];
}

- (id)objectForKeyedSubscript:(id)key{
    handlelock;
    return [_storage objectForKeyedSubscript:key];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))block{
    [lock lock];
    [_storage enumerateKeysAndObjectsUsingBlock:block];
    [lock unlock];
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))block{
    [lock lock];
    [_storage enumerateKeysAndObjectsWithOptions:opts usingBlock:block];
    [lock unlock];
}

- (NSArray *)keysSortedByValueUsingComparator:(NSComparator NS_NOESCAPE)cmptr{
    handlelock;
    return [_storage keysSortedByValueUsingComparator:cmptr];
}

- (NSArray *)keysSortedByValueWithOptions:(NSSortOptions)opts usingComparator:(NSComparator NS_NOESCAPE)cmptr{
    handlelock;
    return [_storage keysSortedByValueWithOptions:opts usingComparator:cmptr];
}

- (NSSet *)keysOfEntriesPassingTest:(BOOL (NS_NOESCAPE ^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))predicate;{
    handlelock;
    return [_storage keysOfEntriesPassingTest:predicate];
}

- (NSSet *)keysOfEntriesWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (NS_NOESCAPE ^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))predicate{
    handlelock;
    return [_storage keysOfEntriesWithOptions:opts passingTest:predicate];
}

#pragma mark NSMutableDictionary
- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey{
    CHECK( anObject && aKey );
    [lock lock];
    [_storage setObject:anObject forKey:aKey];
    [lock unlock];
}

- (void)removeObjectForKey:(id)aKey{
    CHECK( aKey );
    [lock lock];
    [_storage removeObjectForKey:aKey];
    [lock unlock];
}

#pragma mark NSExtendedMutableDictionary
- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary{
    handlelock;
    [_storage addEntriesFromDictionary:[otherDictionary copy]];
}

- (void)removeAllObjects{
    handlelock;
    [_storage removeAllObjects];
}

- (void)removeObjectsForKeys:(NSArray *)keyArray{
    handlelock;
    [_storage removeObjectsForKeys:keyArray];
}

- (void)setDictionary:(NSDictionary *)otherDictionary{
    handlelock;
    [_storage setDictionary:[otherDictionary copy]];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key{
    handlelock;
    [_storage setObject:obj forKeyedSubscript:key];
}

#pragma mark countByEnumeratingWithState
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len{
    handlelock;
    return [_storage countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark creation
+ (nullable NSMutableDictionary *)dictionaryWithContentsOfFile:(NSString *)path;{
    return [[self alloc] initWithContent:[NSMutableDictionary dictionaryWithContentsOfFile:path]];
}

+ (nullable NSMutableDictionary *)dictionaryWithContentsOfURL:(NSURL *)url;{
    return [[self alloc] initWithContent:[NSMutableDictionary dictionaryWithContentsOfURL:url]];
}

- (nullable NSMutableDictionary*)initWithContentsOfFile:(NSString *)path;{
    return [self initWithContent:[[NSMutableDictionary alloc] initWithContentsOfFile:path]];
}

- (nullable NSMutableDictionary*)initWithContentsOfURL:(NSURL *)url;{
    return [self initWithContent:[[NSMutableDictionary alloc] initWithContentsOfURL:url]];
}

- (instancetype)initWithObjects:(id  _Nonnull const [])objects forKeys:(id<NSCopying>  _Nonnull const [])keys count:(NSUInteger)cnt{
    return [self initWithContent:[[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:cnt]];
}

#pragma mark encoding
- (void)encodeWithCoder:(NSCoder *)aCoder{
    handlelock;
    [_storage encodeWithCoder:aCoder];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithContent:[[NSMutableDictionary alloc] initWithCoder:aDecoder]];
}

#pragma mark private
- (NSMutableDictionary*)_intrinsicStorageCopy;{
    handlelock;
    return [_storage copy];
}
@end
