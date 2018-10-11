//
//  GLRequest.m
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import "GLRequest.h"

#define weak(o)      autoreleasepool{} __weak typeof(o) o##Weak = o;
#define strong(o)    autoreleasepool{} __strong typeof(o) o = o##Weak;

#define klogInDEBUG(str,...)        self._config.isDebug==YES?printf("\n[ %p GLNetworking ] %s\n",self,[[NSString stringWithFormat:str, ##__VA_ARGS__] UTF8String]):NULL

#define kCPT(blk)           self.isCancel==NO?dispatch_async(dispatch_get_main_queue(), ^{blk==nil?:blk();}):nil
#define kSUC(blk , p1)      self.isCancel==NO?dispatch_async(dispatch_get_main_queue(), ^{blk==nil?:blk(p1);}):nil
#define kFAD(blk , p1 , p2) self.isCancel==NO?dispatch_async(dispatch_get_main_queue(), ^{blk==nil?:blk(p1 , p2);}):nil

#define kErrorCustomUserInfo(usif)  [NSError errorWithDomain:@"InvocationAssertError" code:-30001 userInfo:((usif)==nil)?@{@"responseObject":responseObject}:(usif)]
#define kErrorResponseNonEncode     [NSError errorWithDomain:@"数据无内容非编码格式,请增加Decode(NO)" code:-30002 userInfo:@{@"responseObject":responseObject}]
#define kErrorResponseNULL          [NSError errorWithDomain:@"ResponseObject无效,需重新请求" code:-30003 userInfo:@{@"responseObject":@"(NULL)"}]


@interface GLRequest()
@property (nonatomic , assign) BOOL isCancel;
@property (nonatomic , assign) float _priority;
@property (nonatomic , strong) id<GLNetworkPotocol> _config;
@property (nonatomic , strong) NSDictionary *_params;
@property (nonatomic , strong) NSString *_wsvsname;
@property (nonatomic , strong) NSString *_path;
@property (nonatomic , strong) NSString *url;
@property (nonatomic , strong) NSString *cusurl;
@property (nonatomic , assign) BOOL obstructEncode; // 非NO 阻断
@property (nonatomic , assign) BOOL obstructDecode; // 非NO 阻断
@property (nonatomic , strong) NSURLSessionTask *task;
@property (nonatomic , strong) NSOperationQueue *queue;
@property (nonatomic , assign) BOOL resume;
@end

@implementation GLRequest

- (instancetype)initWithQueue:(NSOperationQueue *)queue {
    if((self = [super init])) {
        self.queue = queue;
        self.operation = [[GLOperation alloc]init];
    }
    return self;
}

- (void)cancel {
    self.isCancel = YES;
    if(self.task.state==NSURLSessionTaskStateRunning)
        [self.task cancel];
    [self.operation cancel];
}

- (GLRequest *(^)(BOOL))supportResume {
    return ^(BOOL sresume) {
        self.resume = sresume;
        return self;
    };
}

- (GLRequest *(^)(GLPriority))priority {
    return ^(GLPriority p) {
        switch(p) {
            case GLPriorityDefault:
                self.operation.queuePriority = NSOperationQueuePriorityNormal;
                break;
            case GLPriorityLow:
                self.operation.queuePriority = NSOperationQueuePriorityLow;
                break;
            case GLPriorityHigh:
                self.operation.queuePriority = NSOperationQueuePriorityHigh;
                break;
        }
        return self;
    };
}

- (GLRequest *(^)(id<GLNetworkPotocol>))config {
    return ^(id<GLNetworkPotocol> conf) {
        if(conf!=nil){
            self._config = conf;
            self.manager.requestSerializer.timeoutInterval = self._config.timeout;
        }
        for(NSString *key in [self._config.header allKeys]){
            [self.manager.requestSerializer setValue:[self._config.header objectForKey:key] forHTTPHeaderField:key];
        }
        return self;
    };
}

- (GLRequest *(^)(NSDictionary *))params {
    return ^(NSDictionary * dic) {
        if(dic!=nil){
            self._params = dic; // 参数
        }
        return self;
    };
}

- (GLRequest *(^)(BOOL))encode {
    return ^(BOOL willEncode) {
        self.obstructEncode = !willEncode;
        return self;
    };
}

- (GLRequest *(^)(BOOL))decode {
    return ^(BOOL willDecode) {
        self.obstructDecode = !willDecode;
        return self;
    };
}

- (GLRequest *(^)(NSString *))path {
    return ^(NSString *p) {
        if(p!=nil)
            self._path = p;
        return self;
    };
}

- (GLRequest *(^)(NSString *))webService{
    return ^(NSString *wsn) {
        self._wsvsname = wsn;
        return self;
    };
}

- (GLRequest *(^)(NSString *))customURL {
    return ^(NSString *curl) {
        if(curl!=nil)
            self.cusurl = curl;
        return self;
    };
}

- (NSString *)currentURL {
    if(self.cusurl==nil){
        return self._config.host;
    }else{
        return self.cusurl;
    }
}

/** GETTER AND SETTER */
- (NSString *)url {
    if(_url==nil)
        _url = [self.currentURL stringByAppendingPathComponent:self._path];
    
    if(![_url hasPrefix:@"http"]) {
        _url = [@"http://" stringByAppendingString:_url];
    }
    
    /* HTTPS */
    if([_url hasPrefix:@"https"]) {
       [self securityPolicy];
    }
    
    return _url;
}

/** https */
- (void)securityPolicy {
    self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    if([self._config respondsToSelector:@selector(developmentServerSecurity)]) {
        AFSecurityPolicy *sp = [self._config developmentServerSecurity];
        if(sp!=nil){
            self.manager.securityPolicy = sp;
        }else{
            self.manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        }
    }
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

/** 解析并转换数据 */
- (id)analyResponse:(id)response withTask:(NSURLSessionTask *)task {
    id resp;
    NSError *err = nil;
    
    /* 解码 */
    if(self.obstructDecode==NO && [self._config respondsToSelector:@selector(responseObjectForResponse:data:error:)]){
        response = [self._config responseObjectForResponse:task.response data:response error:nil];
    }
    
    /* 尝试 data -> id */
    if([response isKindOfClass:[NSData class]]) {   // 非明文
        resp = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&err];
    }else{
        resp = response;
    }
    
    /* 尝试 data -> String */
    if(resp == nil){
        resp = [[NSString alloc]initWithData:response encoding:NSUTF8StringEncoding];
    }
    
    /* 转换失败 返回 原值 */
    if(resp == nil) {
        resp = response;
    }
    
    return resp;
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconditional-type-mismatch"
/** 数据请求 */
- (GLRequest *)success:(void (^)(id))sucBLK failure:(void (^)(NSError *, id))fadBLK complete:(void (^)(void))complete {
    
    NSDictionary *encodedParam;
    
    /** 编码参数 webService 优先 */
    if(self._wsvsname!=nil)
        encodedParam = [self encodeParams:self._params ws:self._wsvsname];
    else if(self._path!=nil && self._wsvsname==nil)
        encodedParam = [self encodeParams:self._params ws:self._path];
    
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime-(int)stTime)*1000);
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        /* 开始 */
        switch (self.method) {
            case GLMethodGET: {
                klogInDEBUG(@"-->网络请求(GET):%d | 开始 | URL:%@ | PATH(WS):%@ | PARAMS:%@" , uniq , self.url , self._wsvsname!=nil?self._wsvsname:self._path, self._params);
                self.task = [self.manager GET:self.url parameters:encodedParam progress:^(NSProgress * _Nonnull downloadProgress) {} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    
                    klogInDEBUG(@"-->网络请求(GET):%d | 已得到数据 | 耗时:%.3f's",uniq , CACurrentMediaTime()-stTime);
                    if(responseObject == nil) {
                        kFAD(fadBLK , kErrorResponseNULL , nil);
                        
                    }else{
                        id resp = [self analyResponse:responseObject withTask:task];
                        klogInDEBUG(@"-->网络请求(GET):%d | 已解析数据 | 耗时:%.3f's | RESP:%@" , uniq , CACurrentMediaTime()-stTime , resp);
                        
                        BOOL userFailure = NO;
                        NSDictionary *userInfo = nil;
                        if([self._config respondsToSelector:@selector(invocationAfterRequestWS:success:toUserFailedInfo:)]) {
                            userFailure = ![self._config invocationAfterRequestWS:self._wsvsname!=nil?self._wsvsname:self._path
                                                                          success:resp
                                                                 toUserFailedInfo:&userInfo];
                        }
                        
                        if(userFailure==YES) {
                            kFAD(fadBLK , kErrorCustomUserInfo(userInfo) , resp);
                        }else{
                            kSUC(sucBLK , resp);
                        }
                    }
                    dispatch_semaphore_signal(sem);
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    klogInDEBUG(@"-->网络请求(GET):%d | 失败 | 耗时:%.3f's | ERR:%@" , uniq , CACurrentMediaTime()-stTime , error);
                    kFAD(fadBLK , error , nil);
                    dispatch_semaphore_signal(sem);
                }];
                break;
            }
            case GLMethodPOST:{
                klogInDEBUG(@"-->网络请求(POST):%d | 开始 | URL:%@ | PATH(WS):%@ | PARAMS:%@" , uniq , self.url , self._wsvsname!=nil?self._wsvsname:self._path, self._params);
                self.task = [self.manager POST:self.url parameters:encodedParam progress:^(NSProgress * _Nonnull uploadProgress) {} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    
                    klogInDEBUG(@"-->网络请求(POST):%d | 已得到数据 | 耗时:%.3f's",uniq , CACurrentMediaTime()-stTime);
                    if(responseObject == nil) {
                        kFAD(fadBLK , kErrorResponseNULL , nil);
                        
                    }else{
                        id resp = [self analyResponse:responseObject withTask:task];
                        klogInDEBUG(@"-->网络请求(POST):%d | 已解析数据 | 耗时:%.3f's | RESP:%@" , uniq , CACurrentMediaTime()-stTime , resp);
                        
                        BOOL userFailure = NO;
                        NSDictionary *userInfo = nil;
                        if([self._config respondsToSelector:@selector(invocationAfterRequestWS:success:toUserFailedInfo:)]) {
                            userFailure = ![self._config invocationAfterRequestWS:self._wsvsname!=nil?self._wsvsname:self._path
                                                                          success:resp
                                                                 toUserFailedInfo:&userInfo];
                        }
                        
                        if(userFailure==YES) {
                            kFAD(fadBLK , kErrorCustomUserInfo(userInfo) , resp);
                        }else{
                            kSUC(sucBLK , resp);
                        }
                    }
                    dispatch_semaphore_signal(sem);
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    klogInDEBUG(@"-->网络请求(GET):%d | 失败 | 耗时:%.3f's | ERR:%@" , uniq , CACurrentMediaTime()-stTime , error);
                    kFAD(fadBLK , error , nil);
                    dispatch_semaphore_signal(sem);
                }];
                break;
            }
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        klogInDEBUG(@"-->网络请求:%d | 完成 | 共耗时:%.3f's" , uniq , CACurrentMediaTime()-stTime);
        kCPT(complete);
    };
    [self.queue addOperation:self.operation];
    
    return self;
}

/** 下载请求 */
- (GLRequest *)writeToLocalPath:(NSString *)path progress:(void (^)(float))progBLK success:(void (^)(id))sucBLK failure:(void (^)(NSError *, id))fadBLK complete:(void (^)(void))complete {
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [req setTimeoutInterval:self._config.timeout];
    [req setAllHTTPHeaderFields:self._config.header];
    
    if(self.resume){
        NSFileManager *fm = [NSFileManager defaultManager];
        if([fm fileExistsAtPath:path]) {
            NSDictionary *fileAttributes = [fm attributesOfItemAtPath:path error:nil];
            if(fileAttributes){
                long long localFileSize = [[fileAttributes objectForKey:NSFileSize] longLongValue];
                [req setValue:[NSString stringWithFormat:@"bytes %llu-" , localFileSize] forHTTPHeaderField:@"Content-Range:"];
            }
        }
    }
    
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime-(int)stTime)*1000);
        klogInDEBUG(@"-->网络请求(下载):%d | 开始 | URL:%@" , uniq , self.url);
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        self.task = [self.manager downloadTaskWithRequest:req progress:^(NSProgress * _Nonnull downloadProgress) {
            klogInDEBUG(@"-->网络请求(下载):%d | 进度更新 | PROGRESS:%.2f" , uniq , (double)downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
            kSUC(progBLK,(double)downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:path];
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            klogInDEBUG(@"-->网络请求(下载):%d | 成功 | LOCAL:%@" , uniq , filePath);
            if(error==nil) {
                kSUC(sucBLK,response);
            }else{
                kFAD(fadBLK , error , nil);
            }
            dispatch_semaphore_signal(sem);
        }];
        [self.task resume];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        klogInDEBUG(@"-->网络请求(下载):%d | 完成 |  此次请求耗时:%.3f's",uniq , CACurrentMediaTime()-stTime);
        kCPT(complete);
    };
    [self.queue addOperation:self.operation];
    return self;
}

/** 上传请求 fileData: @{FILE_TYPE , @{ FILE_NAME , FILE_DATA }} || @{ FILE_TYPE , FILE_DATA } */
- (GLRequest *)readFromFileDatas:(NSDictionary<NSString *,id> *)fileDatas progress:(void (^)(float))progBLK success:(void (^)(id))sucBLK failure:(void (^)(NSError *, id))fadBLK complete:(void (^)(void))complete {
    
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime-(int)stTime)*1000);
        klogInDEBUG(@"-->网络请求(上传):%d | 开始 | URL:%@" , uniq , self.url);
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        self.task = [self.manager POST:self.url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
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
            klogInDEBUG(@"-->网络请求(上传):%d | 进度更新 | PROGRESS:%.2f" , uniq , (double)uploadProgress.completedUnitCount/uploadProgress.totalUnitCount);
            kSUC(progBLK,(double)uploadProgress.completedUnitCount/uploadProgress.totalUnitCount);
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            klogInDEBUG(@"-->网络请求(上传):%d | 成功 | RESP:%@" , uniq , responseObject);
            
            /* 新解密方案 */
            if(self.obstructDecode==NO && [self._config respondsToSelector:@selector(responseObjectForResponse:data:error:)]){
                NSError *error;
                responseObject = [self._config responseObjectForResponse:task.response data:responseObject error:&error];
            }else{
                
                if([responseObject isKindOfClass:[NSString class]])
                    responseObject = responseObject;
                else if([responseObject isKindOfClass:[NSData class]])
                    responseObject = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
            }
            /* 正常流程 */
            if(responseObject==nil) {   //返回 空
                kFAD(fadBLK,kErrorResponseNULL , nil);
                
            }else{
                BOOL userFailure = NO;
                NSDictionary *customUserInfo = nil;
                NSError *jsonError = nil;

                // string -> dictionary
                id resp = [NSJSONSerialization JSONObjectWithData:[responseObject dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&jsonError];
                
                // user 2 failed
                if([self._config respondsToSelector:@selector(invocationAfterRequestWS:success:toUserFailedInfo:)]) {
                    userFailure = ![self._config invocationAfterRequestWS:self._wsvsname!=nil?self._wsvsname:self._path
                                                                      success:resp
                                                             toUserFailedInfo:&customUserInfo];
                }
                
                if(jsonError!=nil) {    // to dictionary Failed
                    kFAD(fadBLK,kErrorResponseNonEncode , nil);
                    
                }else{    // to dictionary Success
                    if(userFailure==YES) {  // user to Failed
                        kFAD(fadBLK,kErrorCustomUserInfo(customUserInfo) , resp);
                        
                    }else{  //user not to failed
                        kSUC(sucBLK,resp);
                    }
                }
            }
            dispatch_semaphore_signal(sem);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            klogInDEBUG(@"-->网络请求(上传):%d | 失败 | ERR:%@" , uniq , error);
            kFAD(fadBLK , error , nil);
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        klogInDEBUG(@"-->网络请求(上传):%d | 完成 | 共耗时:%.3f's" , uniq , CACurrentMediaTime()-stTime);
        kCPT(complete);
    };
    [self.queue addOperation:self.operation];
    return self;
}
#pragma clang diagnostic pop
@end
