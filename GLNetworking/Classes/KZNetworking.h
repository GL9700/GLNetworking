//
//  KZNetworking.h
//  KZNetworking
//
//  Created by liguoliang on 2018/3/12.
//

#import <Foundation/Foundation.h>
#import "KZRequest.h"

@interface KZNetworking : NSObject

/** 初始化*/
+ (instancetype)managerWithConfig:(id<KZNetworkPotocol>)config;

/** 创建Request */
+ (KZRequest *(^)(void))POST;
+ (KZRequest *(^)(void))GET;
+ (KZRequest *(^)(void))UPLOAD;
+ (KZRequest *(^)(void))DOWNLOAD;

+ (void)cancelRequests:(NSArray *)requests;

@end
