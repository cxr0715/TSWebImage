//
//  TSList.h
//  ImageDemo
//
//  Created by YYInc on 2019/4/20.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TSListNode : NSObject
@property (nonatomic, strong) TSListNode *forward;
@property (nonatomic, strong) TSListNode *next;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) UIImage *value;
@end

@interface TSList : NSObject
@property (nonatomic, strong) NSMutableDictionary <NSString *, TSListNode *>*dictionary;
@property (nonatomic, strong) TSListNode *head;
@property (nonatomic, strong) TSListNode *currentNode;
- (void)insertNode:(TSListNode *)node;
- (UIImage *)getValueWithKey:(NSString *)key;
@end

