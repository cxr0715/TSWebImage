//
//  TSList.m
//  ImageDemo
//
//  Created by YYInc on 2019/4/20.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import "TSList.h"

@implementation TSListNode

@end

@implementation TSList
- (instancetype)init {
    if (self = [super init]) {
        self.dictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)insertNode:(TSListNode *)node {
    if (!node) {
        return;
    }
    TSListNode *node1 = [self. dictionary objectForKey:node.key];
    if (node1) {
        [self removeNode:node1];
        node1.next = self.head;
        self.head = node1;
    }
    if (!self.head && !self.currentNode) {
        self.head = node;
        self.currentNode = node;
    } else {
        node.forward = self.currentNode;
        self.currentNode.next = node;
        self.currentNode = node;
    }
    [self.dictionary setObject:node forKey:node.key];
}

- (UIImage *)getValueWithKey:(NSString *)key {
    if (key.length == 0) {
        return nil;
    }
    TSListNode *node = [self.dictionary objectForKey:key];
    if (node) {
        [self removeNode:node];
        if (node.forward != nil) {
            node.next = self.head;
            self.head.forward = node;
            node.forward = nil;
            self.head = node;            
        }
    }
    return node.value;
}

- (void)removeNode:(TSListNode *)node {
    if (!node) {
        return;
    }
    if ([self.dictionary.allValues containsObject:node]) {
        node.forward.next = node.next;
        if (node.forward != nil) {
            node.next.forward = node.forward;            
        }
        node = nil;
    }
}
@end
