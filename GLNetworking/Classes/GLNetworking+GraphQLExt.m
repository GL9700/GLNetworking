//
//  GLNetworking+GraphQLExt.m
//  GLNetworking
//
//  Created by liguoliang on 2019/7/8.
//

#import "GLNetworking+GraphQLExt.h"
#import <YYModel/YYModel.h>

@implementation GLNetworking (GraphQLExt)

/*
 matrix:
 seminar_view(seminarInfoId:ID!):SeminarInfo ----- {"query":"query {<methodName><(paramString)><{rtn}>}"}
 */
+ (NSDictionary *)gQueryStringWithMethod:(NSString *)method params:(NSDictionary<NSString *, NSObject *> *)params returns:(NSArray<NSString *> *)returns {
    NSString *matrix = @"query {%@%@%@}";
    NSString *methodName = [[GLNetworking managerWithConfig:nil] methodNameWithMethod:method];
    NSString *paramString = [[GLNetworking managerWithConfig:nil] graphQLStrWithDictionary:params];
    NSString *rtn = [NSString stringWithFormat:@"{%@}", [returns componentsJoinedByString:@","]];
    NSString *result = [NSString stringWithFormat:matrix, methodName, paramString, rtn];
    return @{@"query":result};
}

/*
 matrix:
 seminar_save(seminarInfo:SeminarSaveInfo,image:ImageInput,file:[FileInput]):IdInfo -----
 {"query":"mutation (<paramType>){<methodName><(paramPoint)><{return}>}, variables:"{<Points>}"}
 */
+ (NSDictionary *)gMutationStringWithMethod:(NSString *)method variables:(NSDictionary *)variables returns:(NSArray<NSString *> *)returns {
    NSString *mtrix = @"mutation %@%@{%@%@%@}";  // methodName point1 methodName point2 <{returns}>
    NSString *methodName= [[GLNetworking managerWithConfig:nil] methodNameWithMethod:method];
    NSDictionary *plist = [[GLNetworking managerWithConfig:nil] methodParamsListWithMethod:method];
    
    NSDictionary *paramsDict = [[GLNetworking managerWithConfig:nil] paramArgsWithParamDict:plist Variables:variables];
    NSString *point1 = [paramsDict[@"point1"] stringByReplacingOccurrencesOfString:@"{" withString:@"("];
    point1 = [point1 stringByReplacingOccurrencesOfString:@"}" withString:@")"];
    NSString *point2 = [paramsDict[@"point2"] stringByReplacingOccurrencesOfString:@"{" withString:@"("];
    point2 = [point2 stringByReplacingOccurrencesOfString:@"}" withString:@")"];
    
    NSString *item1 = [NSString stringWithFormat:mtrix, methodName, point1, methodName, point2, [NSString stringWithFormat:@"{%@}", [returns componentsJoinedByString:@","]]];
    
    return @{
             @"query":item1,
             @"variables":paramsDict[@"variables"]
             };
}

#pragma mark- GraphQL
/** -graphql- method name */
- (NSString *)methodNameWithMethod:(NSString *)method {
    NSRange range = [method rangeOfString:@"("];
    return [method substringToIndex:range.location];
}
/** -graphql- method params List */
- (NSDictionary *)methodParamsListWithMethod:(NSString *)method {
    NSRange range = [method rangeOfString:@"("];
    NSString *content = [method substringFromIndex:range.location+1];
    range = [content rangeOfString:@")"];
    content = [content substringToIndex:range.location];
    content = [content stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *itemStr in [content componentsSeparatedByString:@","]) {
        NSRange r = [itemStr rangeOfString:@":"];
        dict[[itemStr substringToIndex:r.location]] = [itemStr substringFromIndex:r.location+1];
    }
    return [dict copy];
}
/** -graphql- method return Type */
- (NSString *)methodReturnTypeWithMethod:(NSString *)method {
    NSString *content = [method stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSRange r = [content rangeOfString:@"):"];
    NSString *ret = [content substringFromIndex:r.location+2];
    return ret;
}

#pragma mark- Query 系列
/** -query- params to string */
- (NSString *)graphQLStrWithDictionary:(NSDictionary<NSString *, NSObject *> *)dict {
    if(dict==nil || dict.allKeys.count==0){
        return @"";
    }
    NSMutableArray *parlist = [@[] mutableCopy];
    for(NSString *key in dict.allKeys) {
        /* 调整Key, 删除掉"[" 和 "]" */
        NSString *nk = key;
        if([nk hasPrefix:@"["]){
            nk = [nk substringFromIndex:1];
        }
        if([nk hasSuffix:@"]"]){
            nk = [nk substringToIndex:1];
        }
        /* 配置 value */
        NSObject *value = [dict[key] graphQLString];
        [parlist addObject:[NSString stringWithFormat:@"'%@':'%@'", nk, value]];
    }
    return [NSString stringWithFormat:@"(%@)", [parlist componentsJoinedByString:@","]];
}

#pragma mark- Mutation 系列
/** -mutation params Point1 point variables 三个位置 */
- (NSDictionary *)paramArgsWithParamDict:(NSDictionary *)pdict Variables:(NSDictionary<NSString *, id> *)vars {
    __block NSUInteger index = 0;
    NSMutableDictionary *point1 = [NSMutableDictionary dictionary];
    NSMutableDictionary *point2 = [NSMutableDictionary dictionary];
    NSMutableDictionary *point3 = [NSMutableDictionary dictionary];
    NSArray *pdictKeys = pdict.allKeys;
    [vars enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if([pdictKeys containsObject:key]){
            index++;
            NSString *tempIndex = [NSString stringWithFormat:@"T%lu", index];
            point1[[NSString stringWithFormat:@"$%@", tempIndex]] = [pdict objectForKey:key];
            point2[key] = [NSString stringWithFormat:@"$%@", tempIndex];
            point3[tempIndex] = [obj yy_modelToJSONObject];
        }
    }];
    NSDictionary *retDict = @{
                              @"point1":[point1 graphQLString],
                              @"point2":[point2 graphQLString],
                              @"variables":point3
                              };
    return retDict;
}
@end
