//
//  NSInvocation+JZGAdd.h
//  JZGDetectionPlatform
//
//  Created by cuik on 16/4/7.
//  Copyright © 2016年 Mars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (JZGAdd)

+ (NSInvocation *)invocationWithTarget:(id)target selector:(SEL)selector;

+ (NSInvocation *)invocationWithTarget:(id)target selector:(SEL)selector arguments:(void*)firstArgument,...;

@end
