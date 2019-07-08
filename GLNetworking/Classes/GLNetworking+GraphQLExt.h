//
//  GLNetworking+GraphQLExt.h
//  GLNetworking
//
//  Created by liguoliang on 2019/7/8.
//

#import "GLNetworking.h"
#import "NSObject+GraphQLExt.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLNetworking (GraphQLExt)

/** GraphQL Query 方法  content-Type:Application/Json */
- (NSDictionary *)gQueryStringWithMethod:(NSString *)method params:(NSDictionary<NSString *, NSObject *> *)params returns:(NSArray<NSString *> *)returns;

/** GraphQL Mutation 方法  content-Type:Application/Json */
- (NSDictionary *)gMutationStringWithMethod:(NSString *)method variables:(NSDictionary *)variables returns:(NSArray<NSString *> *)returns;

@end

NS_ASSUME_NONNULL_END
