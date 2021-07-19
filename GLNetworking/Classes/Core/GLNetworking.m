//
//  GLNetworking.m
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import "GLNetworking.h"
#import <AFNetworking/AFHTTPSessionManager.h>

#define kMaxConcurrentCount 10

@interface GLNetworking ()
@property (nonatomic) NSMutableSet *list;
@property (nonatomic) id<GLNetworkPotocol> defaultConfig;
@property (nonatomic) AFHTTPSessionManager *managerNormal;
@property (nonatomic) AFHTTPSessionManager *managerJson;
@property (nonatomic) NSOperationQueue *queue;
@end

@implementation GLNetworking

+ (instancetype)defaultNetworking {
    static dispatch_once_t onceToken;
    static GLNetworking *instance;
    dispatch_once(&onceToken, ^{
        instance = [GLNetworking new];
    });
    return instance;
}

+ (instancetype)managerWithConfig:(id<GLNetworkPotocol>)config {
    GLNetworking *network = [GLNetworking defaultNetworking];
    network.defaultConfig = config;
    network.queue = [[NSOperationQueue alloc]init];
    network.queue.maxConcurrentOperationCount = kMaxConcurrentCount;
    return network;
}

/// 当前网络是否可用
+ (BOOL)currentNetStatus {
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.baidu.com");
    SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
    CFRelease(reachabilityRef);
    return (flags != 0);
}

/// 创建 GLRequest
- (GLRequest *)createRequest {
    GLRequest *request = [[GLRequest alloc]initWithQueue:self.queue];
    [request setValue:self.managerNormal forKey:@"managerNormal"];
    [request setValue:self.managerJson forKey:@"managerJson"];
    [request setValue:self.defaultConfig forKey:@"_config"]; // 设定默认
    request.netStatus = [GLNetworking currentNetStatus];
    @synchronized (self.list) {
        [self.list addObject:request];
    }
    return request;
}





+ (GLRequest *(^)(void))GET {
    return ^() {
        GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
        req.method = GLMethodGET;
        return req;
    };
}
+ (GLRequest *(^)(void))POST {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               req.method = GLMethodPOST;
               return req;
    };
}
+ (GLRequest *(^)(void))HEAD {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               req.method = GLMethodHEAD;
               return req;
    };
}
+ (GLRequest *(^)(void))OPTIONS {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               req.method = GLMethodOPTIONS;
               return req;
    };
}
+ (GLRequest *(^)(void))PUT {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               req.method = GLMethodPUT;
               return req;
    };
}
+ (GLRequest *(^)(void))PATCH {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               req.method = GLMethodPATCH;
               return req;
    };
}
+ (GLRequest *(^)(void))DELETE {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               req.method = GLMethodDELETE;
               return req;
    };
}
+ (GLRequest *(^)(void))TRACE {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               req.method = GLMethodTRACE;
               return req;
    };
}
+ (GLRequest *(^)(void))CONNECT {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               req.method = GLMethodCONNECT;
               return req;
    };
}
+ (GLRequest *(^)(void))UPLOAD {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               return req;
    };
}
+ (GLRequest *(^)(void))DOWNLOAD {
    return ^() {
               GLRequest *req = [[GLNetworking defaultNetworking] createRequest];
               return req;
    };
}

+ (void)cancelRequests:(NSArray *)requests {
    @synchronized(requests) {
        if (requests != nil) {
            for (GLRequest *req in requests) {
                [req cancelTaskWhenDownloadUseBLK:nil];
                if (req != nil) {
                    [[GLNetworking defaultNetworking].list removeObject:req];
                }
            }
        }
        else {
            for (GLRequest *req in [GLNetworking defaultNetworking].list) {
                [req cancelTaskWhenDownloadUseBLK:nil];
            }
            [[GLNetworking defaultNetworking].list removeAllObjects];
        }
    }
}

- (NSMutableSet *)list {
    if (!_list) {
        _list = [[NSMutableSet alloc]init];
    }
    return _list;
}

- (AFHTTPSessionManager *)managerNormal {
    if(!_managerNormal) {
        _managerNormal = [AFHTTPSessionManager manager];
        _managerNormal.requestSerializer = [AFHTTPRequestSerializer serializer];
        _managerNormal.responseSerializer = [AFHTTPResponseSerializer serializer];
        if([self.defaultConfig respondsToSelector:@selector(requestTimeout)]){
            _managerNormal.requestSerializer.timeoutInterval = [self.defaultConfig requestTimeout];
        }else{
            _managerNormal.requestSerializer.timeoutInterval = 10;
        }
    }
    return _managerNormal;
}

- (AFHTTPSessionManager *)managerJson {
    if(!_managerJson) {
        _managerJson = [AFHTTPSessionManager manager];
        _managerJson.requestSerializer = [AFJSONRequestSerializer serializer];
        _managerJson.responseSerializer = [AFHTTPResponseSerializer serializer];
        if([self.defaultConfig respondsToSelector:@selector(requestTimeout)]){
            _managerJson.requestSerializer.timeoutInterval = [self.defaultConfig requestTimeout];
        }else{
            _managerJson.requestSerializer.timeoutInterval = 10;
        }
    }
    return _managerJson;
}
@end

@implementation GLNetworking (ExtGroup)

+ (GLGroupRequest *(^)(void))GROUP {
    return ^(){
        GLGroupRequest *groupReq = [GLGroupRequest new];
        return groupReq;
    };
}
@end
