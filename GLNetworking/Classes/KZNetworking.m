//
//  KZNetworking.m
//  KZNetworking
//
//  Created by liguoliang on 2018/3/12.
//

#import "KZNetworking.h"

#define kMaxConcurrentCount 10

static NSMutableSet *list;
static id<KZNetworkPotocol> globalConfig;
static AFHTTPSessionManager *manager;
static NSOperationQueue *requestQueue;
@implementation KZNetworking
+ (instancetype)managerWithConfig:(id<KZNetworkPotocol>)config {
    static dispatch_once_t onceToken;
    static KZNetworking *instance;
    dispatch_once(&onceToken, ^{
        instance = [[KZNetworking alloc]init];
        globalConfig = config;
        manager = [AFHTTPSessionManager manager];
        requestQueue = [[NSOperationQueue alloc]init];
        requestQueue.maxConcurrentOperationCount = 4;
        
    });
    return instance;
}

+ (NSMutableSet *)list {
    if(list==nil) {
        list = [[NSMutableSet alloc]init];
    }
    return list;
}

+ (KZRequest *)createRequest {
    /** 思路:改用NSOperationQueue 来控制最大并发数 */
    KZRequest *request = [[KZRequest alloc]initWithQueue:requestQueue];
    request.manager = manager;
    [[KZNetworking list] addObject:request];
    request.config(globalConfig);
    return request;
}

+ (KZRequest *(^)(void))POST {
    return ^() {
        KZRequest *req = [KZNetworking createRequest];
        req.method = KZMethodPOST;
        return req;
    };
}

+ (KZRequest *(^)(void))GET {
    return ^(){
        KZRequest *req = [KZNetworking createRequest];
        req.method = KZMethodGET;
        return req;
    };
}

+ (KZRequest *(^)(void))UPLOAD {
    return ^(){
        KZRequest *req = [KZNetworking createRequest];
        return req;
    };
}

+ (KZRequest *(^)(void))DOWNLOAD {
    return ^(){
        KZRequest *req = [KZNetworking createRequest];
        return req;
    };
}

+ (void)cancelRequests:(NSArray *)requests {
    @synchronized(requests){
        if(requests!=nil) {
            for(KZRequest *req in requests) {
                [req cancel];
                if(req!=nil)
                    [list removeObject:req];
            }
        } else {
            for(KZRequest *req in list) {
                [req cancel];
            }
            [list removeAllObjects];
        }
    }
}

@end
