//
//  GLGroupRequest.h
//  GLNetworking
//
//  Created by liguoliang on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import "GLRequest.h"

typedef enum : NSUInteger {
    GroupModeConcurrent,
    GroupModeSerial,
} GroupMode;

typedef GLRequest *(^blk_req)(NSURLResponse *header, id resp, NSError *error, NSString **gotoIdentify);
typedef void(^blk_req_final)(NSURLResponse *header, id resp, NSError *error);


@interface GLGroupRequest : NSObject


#pragma mark- Serial

/// 下一个请求的标示 ( "only Serial" )
- (GLGroupRequest *(^)(NSString *))nextIdentify;

/// 下一个请求 ( "only Serial" )
- (GLGroupRequest *(^)(blk_req))next;

/// 所有请求都结束了，需要使用此来返回最后一个请求的结果 ( "only Serial" )
- (GLGroupRequest *(^)(blk_req_final))finally;

#pragma mark- Concurrent
/// 使用请求创建组 ( "only Concurrent" )
- (GLGroupRequest *(^)(NSArray<GLRequest *> *))requests;

/// 忽略队列中的失败 ( "only Concurrent" )
- (GLGroupRequest *(^)(BOOL))ignoreFailed;

/// ( "only Concurrent" )
- (GLGroupRequest *)success:(void (^)(NSURLResponse *header, id response))sucBLK
               failure:(void (^)(NSError *error, NSURLResponse *response, id data))fadBLK
              complete:(void (^)(void))complete;
@end
