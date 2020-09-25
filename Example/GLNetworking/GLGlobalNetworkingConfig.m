//
//  GLGlobalNetworkingConfig.m
//  GLNetworking_Example
//
//  Created by liguoliang on 2020/9/25.
//  Copyright © 2020 36617161@qq.com. All rights reserved.
//

#import "GLGlobalNetworkingConfig.h"

@implementation GLGlobalNetworkingConfig

- (NSString *)requestHost {
    return @"https://www.baidu.com";
}

- (NSTimeInterval)requestTimeout {
    return 10;
}

- (NSDictionary *)requestHeaderWithPath:(NSString *)path {
    return @{};
}

- (BOOL)isDebugMode {
    return NO;
}

//- (void)logMessage:(NSString *)msg {
//    NSLog(@"logMessage:%@", msg);
//}

@end
