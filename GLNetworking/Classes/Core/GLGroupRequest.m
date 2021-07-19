//
//  GLGroupRequest.m
//  GLNetworking
//
//  Created by liguoliang on 2021/2/4.
//

#import "GLGroupRequest.h"

@interface GLGroupRequest()
@property (nonatomic) GroupMode mode;
@property (nonatomic) BOOL prop_ignore;
@property (nonatomic) NSMutableArray<GLRequest *> *requestList;
@property (nonatomic) id prev_req_resp;
@property (nonatomic) NSError *prev_req_error;
@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic) NSString *identify;
@property (nonatomic) NSString *gotoIdentify;
@property (nonatomic) NSURLResponse *prev_req_head;
@end

@implementation GLGroupRequest

- (GLGroupRequest *(^)(NSArray<GLRequest *> *))requests {
    self.mode = GroupModeConcurrent;
    return ^(NSArray<GLRequest *> *elements){
        self.requestList = [elements mutableCopy];
        return self;
    };
}

- (GLGroupRequest *(^)(NSString *))nextIdentify {
    return ^(NSString *str) {
        self.identify = str;
        return self;
    };
}

- (GLGroupRequest *(^)(blk_req))next {
    self.mode = GroupModeSerial;
    if(self.gotoIdentify!=nil && (self.identify == nil || ![self.gotoIdentify isEqualToString:self.identify])) {
        return ^(blk_req blk){
            return self;
        };
    }else{
        self.gotoIdentify = nil;
    }
    return ^(blk_req blk){
        if(blk) {
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            NSString *gotoIdentify;
            GLRequest *req = blk(self.prev_req_head, self.prev_req_resp, self.prev_req_error, &gotoIdentify);
            if(self.gotoIdentify == nil){
                self.gotoIdentify = gotoIdentify;
            }
            [req success:^(NSURLResponse *header, id response) {
                self.prev_req_head = header;
                self.prev_req_resp = response;
            } failure:^(NSError *error, NSURLResponse *response, id data) {
                self.prev_req_error = error;
            } complete:^{
                dispatch_group_leave(group);
            }];
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        }
        return self;
    };
}

- (GLGroupRequest *(^)(blk_req_final))finally {
    return ^(blk_req_final blk){
        if(blk) {
            blk(self.prev_req_head, self.prev_req_resp, self.prev_req_error);
        }
        return self;
    };
}


- (GLGroupRequest *(^)(BOOL))ignoreFailed {
    return ^(BOOL ignore) {
        self.prop_ignore = ignore;
        return self;
    };
}

/// Request Result
/// 由于GroupModeSerial模式需要依据上一次请求的结果来定义下一次的前提条件
/// 所以不能全部提取再一次动作，需要按照每次请求的结果来判断下次请求是否进行

- (GLGroupRequest *)success:(void (^)(NSURLResponse *header, id response))sucBLK
               failure:(void (^)(NSError *error, NSURLResponse *response, id data))fadBLK
                   complete:(void (^)(void))complete {
    if(self.mode == GroupModeConcurrent) {
        dispatch_queue_t requestQueue = dispatch_queue_create("GLNetworking.GroupConcurrent.Queue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(requestQueue, ^{
            dispatch_group_t g = dispatch_group_create();
            ///
            /// TODO: not write
            ///
            //            for(int i=0;i<)
            dispatch_group_notify(g, dispatch_get_main_queue(), ^{
                if(complete){
                    complete();
                }
            });
        });
    }
    return self;
}

- (NSMutableArray<GLRequest *> *)requestList {
    if(!_requestList) {
        _requestList = [NSMutableArray array];
    }
    return _requestList;
}
- (dispatch_queue_t)serialQueue {
    if(!_serialQueue) {
        _serialQueue = dispatch_queue_create("serial.group.networking", DISPATCH_QUEUE_SERIAL);
    }
    return _serialQueue;
}
@end
