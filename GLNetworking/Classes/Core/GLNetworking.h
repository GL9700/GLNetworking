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
+ (GLRequest *(^)(void))DELETE;
+ (GLRequest *(^)(void))PUT;
+ (GLRequest *(^)(void))POST;
+ (GLRequest *(^)(void))GET;
+ (GLRequest *(^)(void))UPLOAD;
+ (GLRequest *(^)(void))DOWNLOAD;

+ (void)cancelRequests:(NSArray *)requests;

@end
