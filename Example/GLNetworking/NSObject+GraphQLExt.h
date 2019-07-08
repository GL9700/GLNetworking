//
//  NSObject+GraphQLExt.h
//  GLNetworking_Example
//
//  Created by liguoliang on 2019/7/5.
//  Copyright © 2019 liandyii@msn.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (GraphQLExt)
- (NSString *)gQueryStringWithMethod:(NSString *)method params:(NSDictionary *)params returns:(NSArray<NSString *> *)returns;
- (NSString *)gMutationStringWithMethod:(NSString *)method returns:(NSArray<NSString *> *)returns;
@end

NS_ASSUME_NONNULL_END
