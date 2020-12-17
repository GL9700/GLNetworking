//
//  GLNetworking.m
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import "GLNetworking.h"
#import "AFHTTPSessionManager.h"

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
        [self setupConfig:globalConfig toManager:manager];
        requestQueue = [[NSOperationQueue alloc]init];
        requestQueue.maxConcurrentOperationCount = 4;
    });
    return instance;
}
/// 配置默认Config
+ (void)setupConfig:(id<GLNetworkPotocol>)conf toManager:(AFHTTPSessionManager *)man {
    man.requestSerializer = [AFHTTPRequestSerializer serializer];
    if ([conf respondsToSelector:@selector(isJsonParams)]) {
        if ([conf isJsonParams]) {
            man.requestSerializer = [AFJSONRequestSerializer serializer];
        }
    }
    if([conf respondsToSelector:@selector(requestTimeout)]){
        man.requestSerializer.timeoutInterval = [conf requestTimeout];
    }else{
        man.requestSerializer.timeoutInterval = 10;
    }
    
    man.responseSerializer = [AFHTTPResponseSerializer serializer];
    if([conf respondsToSelector: @selector(responseAllowContentTypes)]) {
        man.responseSerializer.acceptableContentTypes = [conf responseAllowContentTypes];
    }
    if([conf respondsToSelector: @selector(responseAllowStatusCodes)]) {
        man.responseSerializer.acceptableStatusCodes = [conf responseAllowStatusCodes];
    }
}

+ (BOOL)currentNetStatus {
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.baidu.com");
    SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
    CFRelease(reachabilityRef);
    return (flags != 0);
}

+ (NSMutableSet *)list {
    if (list == nil) {
        list = [[NSMutableSet alloc]init];
    }
    return list;
}

+ (GLRequest *)createRequest {
    /** 思路:改用NSOperationQueue 来控制最大并发数 */
    GLRequest *request = [[GLRequest alloc]initWithQueue:requestQueue];
    request.netStatus = [GLNetworking currentNetStatus];
    [request setValue:manager forKey:@"manager"];
    @synchronized ([GLNetworking list]) {
        [[GLNetworking list] addObject:request];
    }
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
    return ^() {
               GLRequest *req = [GLNetworking createRequest];
               req.method = GLMethodGET;
               return req;
    };
}

+ (GLRequest *(^)(void))UPLOAD {
    return ^() {
               GLRequest *req = [GLNetworking createRequest];
               return req;
    };
}

+ (GLRequest *(^)(void))DOWNLOAD {
    return ^() {
               GLRequest *req = [GLNetworking createRequest];
               return req;
    };
}

+ (void)cancelRequests:(NSArray *)requests {
    @synchronized(requests) {
        if (requests != nil) {
            for (GLRequest *req in requests) {
                [req cancelTaskWhenDownloadUseBLK:nil];
                if (req != nil) [list removeObject:req];
            }
        }
        else {
            for (GLRequest *req in list) {
                [req cancelTaskWhenDownloadUseBLK:nil];
            }
            [list removeAllObjects];
        }
    }
}

@end
