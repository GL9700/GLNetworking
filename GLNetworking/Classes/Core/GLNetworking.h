//
//  GLNetworking.h
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//


#import "GLRequest.h"

@interface GLNetworking : NSObject
@property (nonatomic, strong) NSMutableSet *associatedList;

/** 初始化*/
+ (instancetype)managerWithConfig:(id<GLNetworkPotocol>)config;

/** 创建Request */
+ (GLRequest *(^)(void))GET;
+ (GLRequest *(^)(void))POST;
+ (GLRequest *(^)(void))HEAD;
+ (GLRequest *(^)(void))OPTIONS;
+ (GLRequest *(^)(void))PUT;
+ (GLRequest *(^)(void))DELETE;
+ (GLRequest *(^)(void))PATCH;
+ (GLRequest *(^)(void))TRACE;
+ (GLRequest *(^)(void))CONNECT;
+ (GLRequest *(^)(void))UPLOAD;
+ (GLRequest *(^)(void))DOWNLOAD;

+ (void)cancelRequests:(NSArray *)requests;

@end
