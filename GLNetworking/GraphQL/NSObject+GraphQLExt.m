//
//  NSObject+GraphQLExt.m
//  GLNetworking
//
//  Created by liguoliang on 2019/7/8.
//

#import "NSObject+GraphQLExt.h"

@implementation NSObject (GraphQLExt)
- (NSString *)graphQLString {
    @synchronized (self) {
        NSMutableString *ret = [NSMutableString string];
        if([self isKindOfClass:[NSArray class]]){
            switch (((NSArray *)self).count) {
                case 0:
                    [ret appendString:@""];
                    break;
                case 1:
                    [ret appendString:((NSArray *)self).firstObject];
                    break;
                default:
                    [ret appendString:@"["];
                    [ret appendString:((NSArray *)self).firstObject];
                    for (int i=1; i<((NSArray *)self).count; i++) {
                        [ret appendFormat:@",%@", ((NSArray *)self)[i]];
                    }
                    [ret appendString:@"]"];
                    break;
            }
        }
        else if ([self isKindOfClass:[NSDictionary class]]){
            [ret appendString:@"{"];
            [((NSDictionary *)self) enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if(ret.length>1){
                    [ret appendString:@","];
                }
                [ret appendFormat:@"%@:%@", key, obj];
            }];
            [ret appendString:@"}"];
        }
        else {
            return [self description];
        }
        return [ret copy];
    }
}
@end
