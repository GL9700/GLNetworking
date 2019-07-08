//
//  NSObject+GraphQLExt.m
//  GLNetworking_Example
//
//  Created by liguoliang on 2019/7/5.
//  Copyright © 2019 liandyii@msn.com. All rights reserved.
//

#import "NSObject+GraphQLExt.h"
#import <objc/message.h>
#import <NSObject+Extension.h>

@implementation NSObject (GraphQLExt)
- (NSString *)gQueryStringWithMethod:(NSString *)method params:(NSDictionary *)params returns:(NSArray<NSString *> *)returns {
    NSString *matrix = @"{\"query\":\"query {%@(%@)}}\"}";
    NSString *value = [self JSONString];
    NSString *result = @"";
    return result;
}

- (NSString *)gMutationStringWithMethod:(NSString *)method returns:(NSArray<NSString *> *)returns {
    
    return nil;
}

- (NSDictionary *)dictionaryWithPropertys {
    return [self propertysWithInstance:self];
}

- (NSDictionary *)propertysWithInstance:(NSObject *)targetObj {
    uint outCount=0;
    objc_property_t *propertys = class_copyPropertyList(targetObj.class, &outCount);
    NSMutableDictionary *mdict_p = [NSMutableDictionary dictionaryWithCapacity:outCount];
    while (outCount>0) {
        objc_property_t pt = propertys[outCount-1];
        const char *pt_name = property_getName(pt);
        const char *pt_att = property_getAttributes(pt);

        NSString *pName = [NSString stringWithCString:pt_name encoding:NSUTF8StringEncoding];
        id pValue = [targetObj valueForKey:pName];
        mdict_p[pName] = pValue;
        outCount--;
    }
    free(propertys);
    return mdict_p;
}
@end



