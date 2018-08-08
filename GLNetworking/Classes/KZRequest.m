//
//  KZRequest.m
//  KZNetwork
//
//  Created by liguoliang on 2018/3/8.
//

#import "KZRequest.h"


#define kMainQueueRun(_method_) didCancel==NO?dispatch_async(dispatch_get_main_queue(), ^{_method_}):nil;



#define kErrorCustomUserInfo(usif)  [NSError errorWithDomain:@"InvocationAssertError" code:30001 userInfo:((usif)==nil)?@{@"responseObject":responseObject}:(usif)]
#define kErrorResponseNonEncode     [NSError errorWithDomain:@"数据无内容非编码格式,请增加Decode(NO)" code:30002 userInfo:@{@"responseObject":responseObject}]
#define kErrorResponseNULL          [NSError errorWithDomain:@"ResponseObject无效,需重新请求" code:30003 userInfo:@{@"responseObject":@"(NULL)"}]


@interface KZRequest()
{
    BOOL didCancel;
}
@property (nonatomic , assign) float _priority;
@property (nonatomic , strong) id<KZNetworkPotocol> _config;
@property (nonatomic , strong) NSDictionary *_params;
@property (nonatomic , strong) NSString *_wsvsname;
@property (nonatomic , strong) NSString *_path;
@property (nonatomic , strong) NSString *url;
@property (nonatomic , assign) BOOL obstructEncode; // 非NO 阻断
@property (nonatomic , assign) BOOL obstructDecode; // 非NO 阻断
@property (nonatomic , strong) NSURLSessionTask *task;
@property (nonatomic , strong) NSOperationQueue *queue;
@end

@implementation KZRequest

- (instancetype)initWithQueue:(NSOperationQueue *)queue {
    if((self = [super init])) {
        self.queue = queue;
        self.operation = [[KZOperation alloc]init];
    }
    return self;
}

/**
 *  DEPRECATED
 *  use -initWithQueue:
 */
- (instancetype)initWithHQ:(dispatch_queue_t)hq DQ:(dispatch_queue_t)dq LQ:(dispatch_queue_t)lq {
    if((self = [super init])) {
        //        self.hq = hq;
        //        self.dq = dq;
        //        self.lq = lq;
        //        self.queue = self.dq;
    }
    return self;
}

- (void)cancel {
    didCancel = YES;
    if(self.task.state==NSURLSessionTaskStateRunning)
        [self.task cancel];
    [self.operation cancel];
}

- (KZRequest *(^)(KZPriority))priority {
    return ^(KZPriority p) {
        switch(p) {
            case KZPriorityDefault:
                self.operation.queuePriority = NSOperationQueuePriorityNormal;
                break;
            case KZPriorityLow:
                self.operation.queuePriority = NSOperationQueuePriorityLow;
                break;
            case KZPriorityHigh:
                self.operation.queuePriority = NSOperationQueuePriorityHigh;
                break;
        }
        return self;
    };
}

- (KZRequest *(^)(id<KZNetworkPotocol>))config {
    return ^(id<KZNetworkPotocol> conf) {
        if(conf!=nil)
            self._config = conf;
        for(NSString *key in [self._config.requestHeader allKeys]){
            [self.manager.requestSerializer setValue:[self._config.requestHeader objectForKey:key] forHTTPHeaderField:key];
        }
        return self;
    };
}

- (KZRequest *(^)(NSDictionary *))params {
    return ^(NSDictionary * dic) {
        if(dic!=nil){
            self._params = dic; // 参数
        }
        return self;
    };
}

- (KZRequest *(^)(BOOL))encode {
    return ^(BOOL willEncode) {
        self.obstructEncode = !willEncode;
        return self;
    };
}
- (KZRequest *(^)(BOOL))decode {
    return ^(BOOL willDecode) {
        self.obstructDecode = !willDecode;
        return self;
    };
}


- (KZRequest *(^)(NSString *))path {
    return ^(NSString *p) {
        if(p!=nil)
            self._path = p;
        return self;
    };
}

- (KZRequest *(^)(NSString *))webService{
    return ^(NSString *wsn) {
        self._wsvsname = wsn;
        return self;
    };
}

- (KZRequest *(^)(NSString *))customURL {
    return ^(NSString *curl) {
        if(curl!=nil)
            self.url = curl;
        return self;
    };
}

/** GETTER AND SETTER */
- (NSString *)url {
    if(_url==nil)
        _url = [self._config.host stringByAppendingPathComponent:self._path];
    
    if(![_url hasPrefix:@"http"]) {
        _url = [@"http://" stringByAppendingString:_url];
    }
    
    if(self._config.scheme!=nil) {
        NSURLComponents *urlcomp = [NSURLComponents componentsWithString:_url];
        if(urlcomp!=nil && self._config.scheme!=nil) {
            [urlcomp setScheme:self._config.scheme];
            _url = urlcomp.URL.absoluteString;
        }
    }
    return _url;
}

/** 加密参数 */
- (NSDictionary *)encodeParams:(NSDictionary *)originParams ws:(NSString *)ws {
    // 加密
    NSDictionary *encodedParam = originParams;
    if(self.obstructEncode==NO) {
        if([self._config respondsToSelector:@selector(paramsProcessedWithOriginParams:WebServiceName:)]) {
            /** 优先使用“WebSericeName”进行加密。如果没有ws则传入path*/
            if(ws!=nil || self._path!=nil)
                encodedParam = [self._config paramsProcessedWithOriginParams:self._params WebServiceName:ws!=nil?ws:self._path];
        }
    }
    return encodedParam;
}

/** https */
- (void)securityPolicy {
    if([self._config respondsToSelector:@selector(developmentServerSecurity)]) {
        AFSecurityPolicy *sp = [self._config developmentServerSecurity];
        if(sp!=nil){
            self.manager.securityPolicy = sp;
        }else{
            self.manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        }
    }
}

/** 数据请求 */
- (KZRequest *)success:(void(^)(id result))sucBLK Failure:(void(^)(NSError *error))fadBLK Complete:(void(^)(void))complete {
    
    NSDictionary *encodedParam;
    
    /** 编码参数 webService 优先 */
    if(self._wsvsname!=nil)
        encodedParam = [self encodeParams:self._params ws:self._wsvsname];
    else if(self._path!=nil && self._wsvsname==nil)
        encodedParam = [self encodeParams:self._params ws:self._path];
    
//    ** 对结果进行解码
//     *  替换成为每个请求线程自行解密 ， 原方法存在问题 单例 manager 单一 config 问题
//     *
//    if(self.obstructDecode==YES){
        self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//    }else{
//        if([self._config respondsToSelector:@selector(responseObjectForResponse:data:error:)]) {
//            self.manager.responseSerializer = self._config;
//        }
//    }
    
    /** HTTPS */
    if([self.url hasPrefix:@"https"]) {
        [self securityPolicy];
    }
    __weak KZRequest *wself = self;
    self.operation.operationBlock = ^{
        __strong typeof(wself) sself = wself;
        
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime-(int)stTime)*1000);
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        /** 开始 */
        switch (sself.method) {
            case KZMethodGET: {
                sself._config.debugMode==YES?NSLog(@"-->服务器连接开始(GET):%d | URL:%@ | PATH(WS):%@ | PARAMS:%@" , uniq , sself.url , sself._wsvsname!=nil?sself._wsvsname:sself._path, sself._params):nil;
                sself.task = [sself.manager GET:sself.url parameters:encodedParam progress:^(NSProgress * _Nonnull downloadProgress) {} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    sself._config.debugMode==YES?NSLog(@"-->服务器连接成功(GET):%d | RESPONSE:%@" , uniq , responseObject):nil;
                    /** 新解密方案 */
                    if(sself.obstructDecode==NO && [sself._config respondsToSelector:@selector(responseObjectForResponse:data:error:)]){
                        NSError *error;
                        responseObject = [sself._config responseObjectForResponse:task.response data:responseObject error:&error];
                    }else{
                        responseObject = responseObject;
                    }
                    /** 正常流程 */
                    if(responseObject==nil){
                        kMainQueueRun(fadBLK==nil?:fadBLK(kErrorResponseNULL);)
                    }else{
                        BOOL willChange2Fail = NO;
                        NSDictionary *customUserInfo = nil;
                        
                        if([sself._config respondsToSelector:@selector(invocationAfterRequestWS:Success:failureErrorUserInfo:)]) {
                            willChange2Fail = ![sself._config invocationAfterRequestWS:sself._wsvsname!=nil?sself._wsvsname:sself._path Success:responseObject failureErrorUserInfo:&customUserInfo];
                        }
                        
                        if(willChange2Fail==YES) {
                            kMainQueueRun(fadBLK==nil?:fadBLK(kErrorCustomUserInfo(customUserInfo));)
                        }else{
                            kMainQueueRun(sucBLK==nil?:sucBLK(responseObject);)
                        }
                    }
                    dispatch_semaphore_signal(sem);
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    sself._config.debugMode==YES?NSLog(@"-->服务器连接失败(GET):%d | ERROR:%@" , uniq , error):nil;
                    kMainQueueRun(fadBLK==nil?:fadBLK(error);)
                    dispatch_semaphore_signal(sem);
                }];
                break;
            }
            case KZMethodPOST:{
                sself._config.debugMode==YES?NSLog(@"-->服务器连接开始(POST):%d | URL:%@ | PATH(WS):%@ | PARAMS:%@" , uniq , sself.url , sself._wsvsname!=nil?sself._wsvsname:sself._path, sself._params):nil;
                sself.task = [sself.manager POST:sself.url parameters:encodedParam progress:^(NSProgress * _Nonnull uploadProgress) {} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    /** 新解密方案 */
                    NSData *data = responseObject;
                    if(sself.obstructDecode==NO && [sself._config respondsToSelector:@selector(responseObjectForResponse:data:error:)]){
                        NSError *error;
                        responseObject = [sself._config responseObjectForResponse:task.response data:responseObject error:&error];
                    }else{
                        responseObject = responseObject;
                    }
                    sself._config.debugMode==YES?NSLog(@"-->服务器连接成功(POST):%d | RESPONSE:%@" , uniq , responseObject):nil;
                    /** 正常流程 */
                    if(responseObject==nil) {
                        kMainQueueRun(fadBLK==nil?:fadBLK(kErrorResponseNULL);)
                    }else{
                        BOOL willChange2Fail = NO;
                        NSDictionary *customUserInfo = nil;
                        
                        if([sself._config respondsToSelector:@selector(invocationAfterRequestWS:Success:failureErrorUserInfo:)]) {
                            willChange2Fail = ![sself._config invocationAfterRequestWS:sself._wsvsname!=nil?sself._wsvsname:sself._path Success:responseObject failureErrorUserInfo:&customUserInfo];
                        }
                        
                        if(willChange2Fail==YES) {
                            kMainQueueRun(fadBLK==nil?:fadBLK(kErrorCustomUserInfo(customUserInfo));)
                        }else{
                            kMainQueueRun(sucBLK==nil?:sucBLK(responseObject);)
                        }
                    }
                    dispatch_semaphore_signal(sem);
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    sself._config.debugMode==YES?NSLog(@"-->服务器连接失败(POST):%d | ERROR:%@" , uniq , error):nil;
                    kMainQueueRun(fadBLK==nil?:fadBLK(error);)
                    dispatch_semaphore_signal(sem);
                }];
                break;
            }
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        sself._config.debugMode==YES?NSLog(@"-->服务器连接完成:%d |  此次请求耗时:%.3f's",uniq , CACurrentMediaTime()-stTime):nil;
        kMainQueueRun(complete==nil?:complete();)
    };
    [self.queue addOperation:self.operation];
    return self;
}


/** 下载请求 */
- (KZRequest *)writeToLocalPath:(NSString *)path Progress:(void(^)(float prog))progBLK Success:(void(^)(id result))sucBLK Failure:(void(^)(NSError  *error))fadBLK Complete:(void(^)(void))complete {
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [req setTimeoutInterval:self._config.timeout];
    [req setAllHTTPHeaderFields:self._config.requestHeader];
    
    /** HTTPS */
    if([_url hasPrefix:@"https"])
        [self securityPolicy];
    
    __weak KZRequest *wself = self;
    self.operation.operationBlock = ^{
        __strong typeof(wself) sself = wself;
        
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime-(int)stTime)*1000);
        
        /** 下载得到数据，不进行结果解码 */
        sself.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        sself._config.debugMode==YES?NSLog(@"-->服务器连接开始 下载:%d | URL:%@<--" , uniq , sself.url):nil;
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        sself.task = [sself.manager downloadTaskWithRequest:req progress:^(NSProgress * _Nonnull downloadProgress) {
            sself._config.debugMode==YES?NSLog(@"-->服务器传输进度 更新:%d | PROGRESS:%.2f<--" , uniq , (double)downloadProgress.completedUnitCount/downloadProgress.totalUnitCount):nil;
            kMainQueueRun(progBLK==nil?:progBLK((double)downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);)
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:path];
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            sself._config.debugMode==YES?NSLog(@"-->服务器传输成功 下载:%d | LOCAL:%@<--" , uniq , filePath):nil;
            if(error==nil) {
                kMainQueueRun(sucBLK==nil?:sucBLK(response);)
            }else{
                kMainQueueRun(fadBLK==nil?:fadBLK(error);)
            }
            dispatch_semaphore_signal(sem);
        }];
        [sself.task resume];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        sself._config.debugMode==YES?NSLog(@"-->服务器连接完成 下载:%d |  此次请求耗时:%.3f's",uniq , CACurrentMediaTime()-stTime):nil;
        kMainQueueRun(complete==nil?:complete();)
    };
    [self.queue addOperation:self.operation];
    return self;
}


/** 上传请求 fileData: @{FILE_TYPE , @{ FILE_NAME , FILE_DATA }} || @{ FILE_TYPE , FILE_DATA } */
- (KZRequest *)readFromFileDatas:(NSDictionary<NSString * , id > *)fileDatas Progress:(void(^)(float prog))progBLK Success:(void(^)(id result))sucBLK Failure:(void(^)(NSError  *error))fadBLK Complete:(void(^)(void))complete {

    /** HTTPS */
    if([_url hasPrefix:@"https"])
        [self securityPolicy];

    __weak KZRequest *wself = self;
    self.operation.operationBlock = ^{
        __strong typeof(wself) sself = wself;
        
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime-(int)stTime)*1000);
        
        sself.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        sself._config.debugMode==YES?NSLog(@"-->服务器连接开始 上传:%d | URL:%@<--" , uniq , sself.url):nil;
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        sself.task = [sself.manager POST:sself.url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            for (NSString *key in [fileDatas allKeys]) {
                if([fileDatas[key] isKindOfClass:[NSDictionary class]]) {
                    //                    带名字类型
                    [formData appendPartWithFileData:[fileDatas[key] allValues].firstObject
                                                name:key
                                            fileName:[fileDatas[key] allKeys].firstObject
                                            mimeType:@"multipart/form-data"];
                }else if([fileDatas[key] isKindOfClass:[NSData class]]) {
                    //                    无名字类型
                    [formData appendPartWithFileData:[fileDatas valueForKeyPath:key] name:key fileName:@"file" mimeType:@"multipart/form-data"];
                }
            }
            
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            sself._config.debugMode==YES?NSLog(@"-->服务器上传进度 更新:%d | PROGRESS:%.2f<--" , uniq , (double)uploadProgress.completedUnitCount/uploadProgress.totalUnitCount):nil;
            kMainQueueRun(progBLK==nil?:progBLK((double)uploadProgress.completedUnitCount/uploadProgress.totalUnitCount);)
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            sself._config.debugMode==YES?NSLog(@"-->服务器连接成功 上传:%d | RESPONSE:%@<--" , uniq , responseObject):nil;
            /** 新解密方案 */
            if(sself.obstructDecode==NO && [sself._config respondsToSelector:@selector(responseObjectForResponse:data:error:)]){
                NSError *error;
                responseObject = [sself._config responseObjectForResponse:task.response data:responseObject error:&error];
            }else{
                
                if([responseObject isKindOfClass:[NSString class]])
                    responseObject = responseObject;
                else if([responseObject isKindOfClass:[NSData class]])
                    responseObject = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
            }
            /** 正常流程 */
            if(responseObject==nil) {   //返回 空
                kMainQueueRun(fadBLK==nil?:fadBLK(kErrorResponseNULL);)
                
            }else{
                BOOL willChange2Fail = NO;
                NSDictionary *customUserInfo = nil;
                NSError *jsonError = nil;
                
                
                // string -> dictionary
                id result = [NSJSONSerialization JSONObjectWithData:[responseObject dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&jsonError];
                
                // user 2 failed
                if([sself._config respondsToSelector:@selector(invocationAfterRequestWS:Success:failureErrorUserInfo:)]) {
                    willChange2Fail = ![sself._config invocationAfterRequestWS:sself._wsvsname!=nil?sself._wsvsname:sself._path Success:result failureErrorUserInfo:&customUserInfo];
                }
                
                if(jsonError!=nil) {    // to dictionary Failed
                    kMainQueueRun(fadBLK==nil?:fadBLK(kErrorResponseNonEncode);)
                    
                }else{    // to dictionary Success
                    if(willChange2Fail==YES) {  // user to Failed
                        kMainQueueRun(fadBLK==nil?:fadBLK(kErrorCustomUserInfo(customUserInfo));)
                        
                    }else{  //user not to failed
                        kMainQueueRun(sucBLK==nil?:sucBLK(result);)
                        
                    }
                }
            }
            dispatch_semaphore_signal(sem);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            sself._config.debugMode==YES?NSLog(@"-->服务器连接失败 上传:%d | ERROR:%@<--" , uniq , error):nil;
            kMainQueueRun(fadBLK==nil?:fadBLK(error);)
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        sself._config.debugMode==YES?NSLog(@"-->服务器连接完成 下载:%d |  此次请求耗时:%.3f's" , uniq , CACurrentMediaTime()-stTime):nil;
        kMainQueueRun(complete==nil?:complete();)
    };
    [self.queue addOperation:self.operation];
    return self;
}



/** 后续 暂不使用
 static inline void DBugLog(BOOL inDebugMode, NSString* format , ...) {
 if(!inDebugMode){
 return;
 }
 va_list args;
 va_start(args, format);
 NSLogv(format , args);
 va_end(args);
 }
 */
@end
