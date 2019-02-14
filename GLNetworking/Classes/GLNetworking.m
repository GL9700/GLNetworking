//
//  GLNetworking.m
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import "GLNetworking.h"
#define kMaxConcurrentCount 10


static NSMutableSet *list;
static id<GLNetworkPotocol> globalConfig;
static AFHTTPSessionManager *manager;
static NSOperationQueue *requestQueue;

@implementation GLNetworking

+ (instancetype)managerWithConfig:(id<GLNetworkPotocol>)config {
    static dispatch_once_t onceToken;
    static GLNetworking *instance;
    dispatch_once(&onceToken, ^{
        instance = [[GLNetworking alloc]init];
        globalConfig = config;
        manager = [AFHTTPSessionManager manager];
        if([config respondsToSelector:@selector(supJSONReq)]){
            if(config.supJSONReq){
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
            }
        }
        manager.requestSerializer.timeoutInterval = (NSTimeInterval)config.timeout;
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

+ (GLRequest *)createRequest {
    /** 思路:改用NSOperationQueue 来控制最大并发数 */
    GLRequest *request = [[GLRequest alloc]initWithQueue:requestQueue];
    request.manager = manager;
    [[GLNetworking list] addObject:request];
    request.config(globalConfig);
    return request;
}

+ (GLRequest *(^)(void))DELETE {
    return ^() {
        GLRequest *req = [GLNetworking createRequest];
        req.method = GLMethodDELETE;
        return req;
    };
}

+ (GLRequest *(^)(void))PUT {
    return ^() {
        GLRequest *req = [GLNetworking createRequest];
        req.method = GLMethodPUT;
        return req;
    };
}

+ (GLRequest *(^)(void))POST {
    return ^() {
        GLRequest *req = [GLNetworking createRequest];
        req.method = GLMethodPOST;
        return req;
    };
}

+ (GLRequest *(^)(void))GET {
    return ^(){
        GLRequest *req = [GLNetworking createRequest];
        req.method = GLMethodGET;
        return req;
    };
}

+ (GLRequest *(^)(void))UPLOAD {
    return ^(){
        GLRequest *req = [GLNetworking createRequest];
        return req;
    };
}

+ (GLRequest *(^)(void))DOWNLOAD {
    return ^(){
        GLRequest *req = [GLNetworking createRequest];
        return req;
    };
}

+ (void)cancelRequests:(NSArray *)requests {
    @synchronized(requests){
        if(requests!=nil) {
            for(GLRequest *req in requests) {
                [req cancelTaskWhenDownloadUseBLK:nil];
                if(req!=nil)
                    [list removeObject:req];
            }
        } else {
            for(GLRequest *req in list) {
                [req cancelTaskWhenDownloadUseBLK:nil];
            }
            [list removeAllObjects];
        }
    }
}

@end
