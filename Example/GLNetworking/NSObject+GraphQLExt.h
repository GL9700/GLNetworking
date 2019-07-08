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

/** GraphQL Query 方法  content-Type:Application/Json */
- (NSDictionary *)gQueryStringWithMethod:(NSString *)method params:(NSDictionary<NSString *, NSObject *> *)params returns:(NSArray<NSString *> *)returns;

/** GraphQL Mutation 方法  content-Type:Application/Json */
- (NSDictionary *)gMutationStringWithMethod:(NSString *)method variables:(NSDictionary *)variables returns:(NSArray<NSString *> *)returns;
@end

NS_ASSUME_NONNULL_END
