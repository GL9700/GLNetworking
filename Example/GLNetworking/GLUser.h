//
//  GLUser.h
//  GLNetworking_Example
//
//  Created by liguoliang on 2019/7/5.
//  Copyright © 2019 liandyii@msn.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+GraphQLExt.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLUser : NSObject
@property (nonatomic, strong) NSString *seminarInfoId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSUInteger age;
@end

NS_ASSUME_NONNULL_END
