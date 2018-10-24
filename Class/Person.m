//
//  Person.m
//  GitLearn
//
//  Created by 王延磊 on 2018/10/24.
//  Copyright © 2018 王延磊. All rights reserved.
//

#import "Person.h"

@implementation Person
+ (instancetype)share{
    static Person *p;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        p = [[Person alloc]init];
    });
    return p;
}
@end

