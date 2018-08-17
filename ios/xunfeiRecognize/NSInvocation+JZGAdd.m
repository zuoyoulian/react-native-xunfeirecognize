//
//  NSInvocation+JZGAdd.m
//  JZGDetectionPlatform
//
//  Created by cuik on 16/4/7.
//  Copyright © 2016年 Mars. All rights reserved.
//

#import "NSInvocation+JZGAdd.h"

@implementation NSInvocation (JZGAdd)

+ (NSInvocation *)invocationWithTarget:(id)target selector:(SEL)selector
{
    return [[self class] invocationWithTarget:target selector:selector arguments:NULL];
}

+ (NSInvocation *)invocationWithTarget:(id)target selector:(SEL)selector arguments:(void*)firstArgument,...
{
    NSMethodSignature *signature = [[target class] instanceMethodSignatureForSelector:selector];
    NSInvocation *invoction = [NSInvocation invocationWithMethodSignature:signature];
    [invoction setTarget:target];
    [invoction setSelector:selector];
    
    if (firstArgument)
    {
        va_list arg_list;
        va_start(arg_list, firstArgument);
        [invoction setArgument:firstArgument atIndex:2];
        
        for (NSUInteger i = 0; i < signature.numberOfArguments; i++) {
            void *argument = va_arg(arg_list, void *);
            [invoction setArgument:argument atIndex:i];
        }
        va_end(arg_list);
    }
    
    return invoction;
}

@end
