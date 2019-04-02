//
//  GLRequest.m
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import "GLRequest.h"
#import "GLCacheData.h"
#import <CommonCrypto/CommonDigest.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define weak(o) autoreleasepool {} __weak typeof(o)o ## Weak = o;
#define strong(o) autoreleasepool {} __strong typeof(o)o = o ## Weak;
#define klogInDEBUG(str, ...) self._config.isDebug==YES?NSLog(@"GLNetworking-->%@",[NSString stringWithFormat:str, ## __VA_ARGS__]):NULL
#define kBLK0(blk) self.isCancel==NO?dispatch_async(dispatch_get_main_queue(),^{blk==nil?:blk();}):nil
#define kBLK1(blk,p1) self.isCancel==NO?dispatch_async(dispatch_get_main_queue(),^{blk==nil?:blk(p1);}):nil
#define kBLK2(blk,p1,p2) self.isCancel==NO?dispatch_async(dispatch_get_main_queue(),^{blk==nil?:blk(p1,p2);}):nil
#define kBLK3(blk,p1,p2,p3) self.isCancel==NO?dispatch_async(dispatch_get_main_queue(),^{blk==nil?:blk(p1,p2,p3);}):nil
#define kErrorCustomUserInfo(usif,responseData) [NSError errorWithDomain:@"InvocationAssertError" code:-30001 userInfo:((usif) == nil) ? @{ @"responseObject": (responseData)} : (usif)]
#define kErrorResponseNonEncode [NSError errorWithDomain:@"数据无内容非编码格式,请增加Decode(NO)" code:-30002 userInfo:@{ @"responseObject": responseObject }]
#define kErrorResponseNULL [NSError errorWithDomain:@"ResponseObject无效,需重新请求" code:-30003 userInfo:@{ @"responseObject": @"(NULL)" }]

static NSMutableSet *kAssociatedList;

@interface NSString (MD5Ext)
- (NSString *)md5;
@end
@implementation NSString(MD5Ext)
- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char result[32];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}
@end

@interface GLRequest ()
{
    __block BOOL ignoreCache;
}
@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, assign) float _priority;
@property (nonatomic, strong) id<GLNetworkPotocol> _config;
@property (nonatomic, strong) NSDictionary *_params;
@property (nonatomic, strong) NSString *_wsvsname;
@property (nonatomic, strong) NSString *_path;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *cusurl;
@property (nonatomic, assign) BOOL obstructEncode;  // 非NO 阻断
@property (nonatomic, assign) BOOL obstructDecode;  // 非NO 阻断
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSOperationQueue *queue;
#pragma mark- use for CachedExt
@property (nonatomic, strong) NSString *URLhash;
@property (nonatomic, strong) NSString *cacheFolder;
@end

@implementation GLRequest
#pragma mark- Initialization
- (instancetype)initWithQueue:(NSOperationQueue *)queue {
    if ((self = [super init])) {
        self.queue = queue;
        self.operation = [[GLOperation alloc]init];
    }
    return self;
}

#pragma mark- Setting
- (GLRequest *(^)(GLPriority))priority {
    return ^(GLPriority p) {
        switch (p) {
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
        if (conf != nil) {
            self._config = conf;
            self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            if([conf respondsToSelector:@selector(supJSONReq)]){
                conf.supJSONReq ? self.manager.requestSerializer = [AFJSONRequestSerializer serializer]:nil;
            }
            self.manager.requestSerializer.timeoutInterval = conf.timeout;
            for (NSString *key in [conf.header allKeys]) {
                [self.manager.requestSerializer setValue:[conf.header objectForKey:key] forHTTPHeaderField:key];
            }
        }
        return self;
    };
}
- (GLRequest *(^)(NSDictionary *))params {
    return ^(NSDictionary *dic) {
        if (dic != nil) self._params = dic; // 参数
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
        if (p != nil) self._path = p;
        return self;
    };
}
- (GLRequest *(^)(NSString *))webService {
    return ^(NSString *wsn) {
        self._wsvsname = wsn;
        return self;
    };
}
- (GLRequest *(^)(NSString *))customURL {
    return ^(NSString *curl) {
        if (curl != nil) self.cusurl = curl;
        return self;
    };
}
- (NSString *)currentURL {
    if (self.cusurl == nil) {
        return self._config.host;
    } else {
        return self.cusurl;
    }
}

#pragma mark- Getter & Setter
- (NSString *)url {
    if (_url == nil) _url = [self.currentURL stringByAppendingPathComponent:self._path];
    if (![_url hasPrefix:@"http"]) _url = [@"http://" stringByAppendingString:_url];
    /* HTTPS */
    if ([_url hasPrefix:@"https"]) [self securityPolicy];
    return _url;
}

#pragma mark- Actions


/** https */
- (void)securityPolicy {
    self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    if ([self._config respondsToSelector:@selector(developmentServerSecurity)]) {
        AFSecurityPolicy *sp = [self._config developmentServerSecurity];
        self.manager.securityPolicy = sp ? sp : [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }
}
/** 加密参数 */
- (NSDictionary *)encodeParams:(NSDictionary *)originParams ws:(NSString *)ws {
    // 加密
    NSDictionary *encodedParam = originParams;
    if (self.obstructEncode == NO) {
        if ([self._config respondsToSelector:@selector(paramsProcessedWithOriginParams:WebServiceName:)]) {
            /** 优先使用“WebSericeName”进行加密。如果没有ws则传入path*/
            if (ws != nil || self._path != nil) encodedParam = [self._config paramsProcessedWithOriginParams:self._params WebServiceName:ws != nil ? ws : self._path];
        }
    }
    return encodedParam;
}
/** 解析并转换数据 */
- (id)analyResponse:(id)response withResponse:(NSURLResponse *)taskResponse {
    id resp;
    NSError *err = nil;
    /* 解码 */
    if (self.obstructDecode == NO &&
        [self._config respondsToSelector:@selector(responseObjectForResponse:data:error:)]) response = [self._config responseObjectForResponse:taskResponse data:response error:nil];
    /* 尝试 data -> id */
    if ([response isKindOfClass:[NSData class]])                                                    // 非明文
        resp = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&err];
    else resp = response;
    if (resp == nil) resp = [[NSString alloc]initWithData:response encoding:NSUTF8StringEncoding];  /* 尝试 data -> String */
    if (resp == nil) resp = response;                                                               /* 转换失败 返回 原值 */
    return resp;
}
@end

@implementation GLRequest(CacheManagerExt)
- (GLRequest *(^)(BOOL))ignoreCache {
    return ^(BOOL p){
        self->ignoreCache = p;
        return self;
    };
}
- (NSString *)jsonFromDictionary:(NSDictionary *)dic {
    NSMutableArray *arr = [dic.allKeys mutableCopy];
    [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return NSOrderedAscending;
    }];
    NSMutableString *ret = [@"{" mutableCopy];
    [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([dic[obj] isKindOfClass:[NSString class]]){
            [ret appendFormat:@"%@=%@,",obj, dic[obj]];
        }
    }];
    ret = [[ret substringToIndex:ret.length-1] mutableCopy];
    [ret appendString:@"}"];
    return [ret copy];
}
- (NSString *)URLhash {
    if(_URLhash==nil){
        NSMutableString *value = [NSMutableString stringWithFormat:@"%d", self.method];
        [value appendString:self._path?[NSString stringWithFormat:@"|%@", self._path]:@""];
        self._params?[value appendString:[self jsonFromDictionary:self._params]]:nil;
        self._config.header?[value appendString:[self jsonFromDictionary:self._config.header]]:nil;
        _URLhash = [value md5];
    }
    return _URLhash;
}
- (NSString *)cacheFolder {
    if(!_cacheFolder){
        _cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"GLCache"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:_cacheFolder]){
            [[NSFileManager defaultManager] createDirectoryAtPath:_cacheFolder withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _cacheFolder;
}
- (void)cacheAddToAccociatedList {
    if([self._config respondsToSelector:@selector(cacheList)] == NO)
        return;
    @synchronized (kAssociatedList) {
        if(![kAssociatedList containsObject:self.URLhash])
            [kAssociatedList addObject:self.URLhash];
    }
}
- (BOOL)cacheContainInAccociatedList {
    if([self._config respondsToSelector:@selector(cacheList)]==NO)
        return NO;
    if(kAssociatedList==nil){
        kAssociatedList = [NSMutableSet set];
    }
    return [kAssociatedList containsObject:self.URLhash];
}
- (BOOL)cacheContainInCacheList {
    if([self._config respondsToSelector:@selector(cacheList)] == NO)
        return NO;
    BOOL container = NO;
    if(self._config.cacheList){
        container = [self._config.cacheList containsObject:self._path];
    }
    return container;
}
- (void)cacheSaveData:(id)data resp:(NSURLResponse *)urlresponse {
    if([self._config respondsToSelector:@selector(cacheList)] == NO){
        return;
    }
    NSString *path = [self.cacheFolder stringByAppendingPathComponent:self.URLhash];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if([self cacheContainInCacheList]){
        klogInDEBUG(@"在缓存名单中");
        GLCacheData *cachedata = [GLCacheData new];
        cachedata.data = data;
        cachedata.response = urlresponse;
        if([NSKeyedArchiver archiveRootObject:cachedata toFile:path]){
            [self cacheAddToAccociatedList];
            klogInDEBUG(@"写入成功:%@" ,path);
        }else{
            klogInDEBUG(@"写入失败:%@" ,path);
        }
    }else{
        klogInDEBUG(@"不在缓存名单中，放弃操作");
    }
}
- (GLCacheData *)cacheLoadData {
    GLCacheData *cdata = nil;
    if([self._config respondsToSelector:@selector(cacheList)] == NO)
        return cdata;
    NSString *path = [self.cacheFolder stringByAppendingPathComponent:self.URLhash];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        klogInDEBUG(@"找到缓存的文件");
        cdata = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }else{
        klogInDEBUG(@"没找到缓存的文件");
    }
    klogInDEBUG(@"从缓存中读取:URL:%@|LocalPath:%@|REL:%@" ,self.url, path ,cdata!=nil?@"SUC":@"FAD");
    return cdata;
}
- (void)cacheDelete {
    NSString *path = [self.cacheFolder stringByAppendingPathComponent:self.URLhash];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if([kAssociatedList containsObject:self.URLhash]){
        @synchronized (kAssociatedList) {
            [kAssociatedList removeObject:self.URLhash];
        }
    }
}
@end

@implementation GLRequest(RequestExt)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconditional-type-mismatch"
/** 数据请求 */
- (GLRequest *)success:(void (^)(id))sucBLK failure:(void (^)(NSError *, NSURLResponse *, id))fadBLK complete:(void (^)(void))complete {
    NSDictionary *encodedParam;
    
    /** 编码参数 webService 优先 */
    if (self._wsvsname != nil) encodedParam = [self encodeParams:self._params ws:self._wsvsname];
    else if (self._path != nil && self._wsvsname == nil) encodedParam = [self encodeParams:self._params ws:self._path];
    
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime - (int)stTime) * 1000) + arc4random() % 10;
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        BOOL containerSelf = [self cacheContainInAccociatedList];
        if(containerSelf && self->ignoreCache==NO)   // 找到关联关系 并且不忽略缓存
        {
            klogInDEBUG(@"网络请求状态:%d | Online:Yes | hasCache:Yes | -- use Cache", uniq);
            GLCacheData *cdata = [self cacheLoadData];
            id resp = [self analyResponse:cdata.data withResponse:cdata.response];
            BOOL userFailure = NO;
            NSDictionary *userInfo = nil;
            if([self._config respondsToSelector:@selector(interceptWithURLResponse:success:toUserFailedInfo:)]) {
                userFailure = ![self._config interceptWithURLResponse:cdata.response success:resp toUserFailedInfo:&userInfo];
            }
            userFailure ? kBLK3(fadBLK, kErrorCustomUserInfo(userInfo,cdata.data), cdata.response, resp) : kBLK1(sucBLK, resp);
            dispatch_semaphore_signal(sem);
        }
        else    // 不存在关联关系
        {
            if([self netStatus])
            {
                klogInDEBUG(@"网络请求状态:%d | Online:Yes | hasCache:~ | -- ignore Cache", uniq);
                klogInDEBUG(@"网络请求开始(%d):%d | URL:%@ | path:%@ | params:%@",self.method, uniq, self.url, self._path, self._params);
                switch (self.method) {
                    case GLMethodGET: {
                        self.task = [self.manager GET:self.url parameters:encodedParam progress:^(NSProgress *_Nonnull downloadProgress) {} success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                            klogInDEBUG(@"网络请求成功:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
                            if (responseObject == nil) {
                                kBLK3(fadBLK, kErrorResponseNULL, task.response, nil);
                            } else {
                                [self cacheSaveData:responseObject resp:task.response];
                                id resp = [self analyResponse:responseObject withResponse:task.response];
                                klogInDEBUG(@"网络请求整理数据:%d | Time:%.3f's | RESP:%@", uniq, CACurrentMediaTime() - stTime, resp);
                                BOOL userFailure = NO;
                                NSDictionary *userInfo = nil;
                                if([self._config respondsToSelector:@selector(interceptWithURLResponse:success:toUserFailedInfo:)]) {
                                    userFailure = ![self._config interceptWithURLResponse:task.response success:resp toUserFailedInfo:&userInfo];
                                }
                                userFailure ? kBLK3(fadBLK, kErrorCustomUserInfo(userInfo,responseObject), task.response , resp) : kBLK1(sucBLK, resp);
                            }
                            dispatch_semaphore_signal(sem);
                        } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                            klogInDEBUG(@"网络请求失败(%d):%d | Time:%.3f's | ERR:%@",self.method, uniq, CACurrentMediaTime() - stTime, error);
                            kBLK3(fadBLK, error, task.response, nil);
                            dispatch_semaphore_signal(sem);
                        }];
                        break;
                    }
                    case GLMethodPOST: {
                        self.task = [self.manager POST:self.url parameters:encodedParam progress:^(NSProgress *_Nonnull uploadProgress) {} success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                            klogInDEBUG(@"网络请求成功:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
                            if (responseObject == nil) {
                                kBLK3(fadBLK, kErrorResponseNULL, task.response, nil);
                            } else {
                                [self cacheSaveData:responseObject resp:task.response];
                                id resp = [self analyResponse:responseObject withResponse:task.response];
                                klogInDEBUG(@"网络请求整理数据:%d | Time:%.3f's | RESP:%@", uniq, CACurrentMediaTime() - stTime, resp);
                                BOOL userFailure = NO;
                                NSDictionary *userInfo = nil;
                                if([self._config respondsToSelector:@selector(interceptWithURLResponse:success:toUserFailedInfo:)]) {
                                    userFailure = ![self._config interceptWithURLResponse:task.response success:resp toUserFailedInfo:&userInfo];
                                }
                                userFailure ? kBLK3(fadBLK, kErrorCustomUserInfo(userInfo,responseObject), task.response, resp) : kBLK1(sucBLK, resp);
                            }
                            dispatch_semaphore_signal(sem);
                        } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                            klogInDEBUG(@"网络请求失败(%d):%d | Time:%.3f's | ERR:%@",self.method, uniq, CACurrentMediaTime() - stTime, error);
                            kBLK3(fadBLK, error, task.response, nil);
                            dispatch_semaphore_signal(sem);
                        }];
                        break;
                    }
                    case GLMethodPUT: {
                        self.task = [self.manager PUT:self.url parameters:encodedParam success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                            klogInDEBUG(@"网络请求成功:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
                            if (responseObject == nil) {
                                kBLK3(fadBLK, kErrorResponseNULL, task.response, nil);
                            } else {
                                [self cacheSaveData:responseObject  resp:task.response];
                                id resp = [self analyResponse:responseObject withResponse:task.response];
                                klogInDEBUG(@"网络请求整理数据:%d | Time:%.3f's | RESP:%@", uniq, CACurrentMediaTime() - stTime, resp);
                                BOOL userFailure = NO;
                                NSDictionary *userInfo = nil;
                                if([self._config respondsToSelector:@selector(interceptWithURLResponse:success:toUserFailedInfo:)]) {
                                    userFailure = ![self._config interceptWithURLResponse:task.response success:resp toUserFailedInfo:&userInfo];
                                }
                                userFailure ? kBLK3(fadBLK, kErrorCustomUserInfo(userInfo,responseObject), task.response, resp) : kBLK1(sucBLK, resp);
                            }
                            dispatch_semaphore_signal(sem);
                        } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                            klogInDEBUG(@"网络请求失败(%d):%d | Time:%.3f's | ERR:%@",self.method, uniq, CACurrentMediaTime() - stTime, error);
                            kBLK3(fadBLK, error, task.response, nil);
                            dispatch_semaphore_signal(sem);
                        }];
                        break;
                    }
                    case GLMethodDELETE: {
                        self.task = [self.manager DELETE:self.url parameters:encodedParam success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                            klogInDEBUG(@"网络请求成功:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
                            if (responseObject == nil) {
                                kBLK3(fadBLK, kErrorResponseNULL, task.response, nil);
                            } else {
                                [self cacheSaveData:responseObject  resp:task.response];
                                id resp = [self analyResponse:responseObject withResponse:task.response];
                                klogInDEBUG(@"网络请求整理数据:%d | Time:%.3f's | RESP:%@", uniq, CACurrentMediaTime() - stTime, resp);
                                BOOL userFailure = NO;
                                NSDictionary *userInfo = nil;
                                if([self._config respondsToSelector:@selector(interceptWithURLResponse:success:toUserFailedInfo:)]) {
                                    userFailure = ![self._config interceptWithURLResponse:task.response success:resp toUserFailedInfo:&userInfo];
                                }
                                userFailure ? kBLK3(fadBLK, kErrorCustomUserInfo(userInfo,responseObject), task.response, resp) : kBLK1(sucBLK, resp);
                            }
                            dispatch_semaphore_signal(sem);
                        } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                            klogInDEBUG(@"网络请求失败(%d):%d | Time:%.3f's | ERR:%@",self.method, uniq, CACurrentMediaTime() - stTime, error);
                            kBLK3(fadBLK, error, task.response, nil);
                            dispatch_semaphore_signal(sem);
                        }];
                        break;
                    }
                }
            }else{
                // 强制查找缓存
                GLCacheData *cdata = [self cacheLoadData];
                if(cdata!=nil){
                    klogInDEBUG(@"网络请求状态:%d | Online:No | hasCache:Yes | -- use Cache", uniq);
                    [self cacheAddToAccociatedList];
                    id resp = [self analyResponse:cdata.data withResponse:cdata.response];
                    BOOL userFailure = NO;
                    NSDictionary *userInfo = nil;
                    if([self._config respondsToSelector:@selector(interceptWithURLResponse:success:toUserFailedInfo:)]) {
                        userFailure = ![self._config interceptWithURLResponse:cdata.response success:resp toUserFailedInfo:&userInfo];
                    }
                    userFailure ? kBLK3(fadBLK, kErrorCustomUserInfo(userInfo,cdata.data), cdata.response, resp) : kBLK1(sucBLK, resp);
                    dispatch_semaphore_signal(sem);
                }else{
                    klogInDEBUG(@"网络请求状态:%d | Online:No | hasCache:No | -- no Data", uniq);
                    NSURLResponse *eresp = [[NSHTTPURLResponse alloc]initWithURL:[NSURL URLWithString:self.url] statusCode:1001 HTTPVersion:nil headerFields:nil];
                    kBLK3(fadBLK, [NSError errorWithDomain:@"无网-无Cache数据" code:30010 userInfo:nil], eresp, nil);
                    dispatch_semaphore_signal(sem);
                    // 无网 - 无缓存
                }
            }
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        klogInDEBUG(@"网络请求完成:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
        kBLK0(complete);
    };
    [self.queue addOperation:self.operation];
    return self;
}
/** 下载请求 */
- (GLRequest *)writeToLocalPath:(NSString *)path resumeInfo:(NSData *)resumeData progress:(void (^)(uint64_t, uint64_t))progBLK success:(void (^)(id))sucBLK failure:(void (^)(NSError *, NSURLResponse *, id))fadBLK complete:(void (^)(void))complete {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [req setTimeoutInterval:self._config.timeout];
    [req setAllHTTPHeaderFields:self._config.header];
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime - (int)stTime) * 1000);
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        if (resumeData != nil) {
            klogInDEBUG(@"网络请求(下载):%d | 恢复 | URL:%@", uniq, self.url);
            self.task = [self.manager downloadTaskWithResumeData:resumeData progress:^(NSProgress *_Nonnull downloadProgress) {
                klogInDEBUG(@"网络请求(下载):%d | 进度更新 | PROGRESS:%.2f", uniq, (double)downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                kBLK2(progBLK, downloadProgress.totalUnitCount, downloadProgress.completedUnitCount);
            } destination:^NSURL *_Nonnull (NSURL *_Nonnull targetPath, NSURLResponse *_Nonnull response) {
                return [NSURL fileURLWithPath:path];
            } completionHandler:^(NSURLResponse *_Nonnull response, NSURL *_Nullable filePath, NSError *_Nullable error) {
                klogInDEBUG(@"网络请求(下载):%d | 成功 | LOCAL:%@", uniq, filePath);
                error ? kBLK3(fadBLK, error, response, nil) : kBLK1(sucBLK, response);
                dispatch_semaphore_signal(sem);
            }];
        } else {
            klogInDEBUG(@"网络请求(下载):%d | 开始 | URL:%@", uniq, self.url);
            self.task = [self.manager downloadTaskWithRequest:req progress:^(NSProgress *_Nonnull downloadProgress) {
                klogInDEBUG(@"网络请求(下载):%d | 进度更新 | PROGRESS:%.2f", uniq, (double)downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                kBLK2(progBLK, downloadProgress.totalUnitCount, downloadProgress.completedUnitCount);
            } destination:^NSURL *_Nonnull (NSURL *_Nonnull targetPath, NSURLResponse *_Nonnull response) {
                return [NSURL fileURLWithPath:path];
            } completionHandler:^(NSURLResponse *_Nonnull response, NSURL *_Nullable filePath, NSError *_Nullable error) {
                klogInDEBUG(@"网络请求(下载):%d | 成功 | LOCAL:%@", uniq, filePath);
                error ? kBLK3(fadBLK, error, response, nil) : kBLK1(sucBLK, response);
                dispatch_semaphore_signal(sem);
            }];
        }
        [self.task resume];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        klogInDEBUG(@"网络请求(下载):%d | 完成 |  此次请求耗时:%.3f's", uniq, CACurrentMediaTime() - stTime);
        kBLK0(complete);
    };
    [self.queue addOperation:self.operation];
    return self;
}

- (GLRequest *)readFromFileDatas:(NSDictionary<NSString *, id> *)fileDatas progress:(void (^)(float))progBLK success:(void (^)(id))sucBLK failure:(void (^)(NSError *, NSURLResponse *, id))fadBLK complete:(void (^)(void))complete {
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime - (int)stTime) * 1000);
        klogInDEBUG(@"网络请求(上传):%d | 开始 | URL:%@", uniq, self.url);
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        self.task = [self.manager POST:self.url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            for (NSString *key in [fileDatas allKeys]) {
                if ([fileDatas[key] isKindOfClass:[NSDictionary class]]) {
                    // 带名字类型
                    [formData appendPartWithFileData:[fileDatas[key] allValues].firstObject
                                                name:key
                                            fileName:[fileDatas[key] allKeys].firstObject
                                            mimeType:@"multipart/form-data"];
                } else if ([fileDatas[key] isKindOfClass:[NSData class]]) {
                    // 无名字类型
                    [formData appendPartWithFileData:[fileDatas valueForKeyPath:key]
                                                name:key
                                            fileName:key
                                            mimeType:@"multipart/form-data"];
                }
            }
        } progress:^(NSProgress *_Nonnull uploadProgress) {
            klogInDEBUG(@"网络请求(上传):%d | 进度更新 | PROGRESS:%.2f", uniq, (double)uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
            kBLK1(progBLK, (double)uploadProgress.completedUnitCount/uploadProgress.totalUnitCount);
        } success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
            klogInDEBUG(@"网络请求(上传):%d | 成功 | RESP:%@", uniq, responseObject);
            /* 新解密方案 */
            if (self.obstructDecode == NO && [self._config respondsToSelector:@selector(responseObjectForResponse:data:error:)]) {
                NSError *error;
                responseObject = [self._config responseObjectForResponse:task.response data:responseObject error:&error];
            } else {
                if ([responseObject isKindOfClass:[NSString class]]) responseObject = responseObject;
                else if ([responseObject isKindOfClass:[NSData class]]) responseObject = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
            }
            /* 正常流程 */
            if (responseObject == nil) {   //返回 空
                kBLK3(fadBLK, kErrorResponseNULL, task.response, nil);
            } else {
                BOOL userFailure = NO;
                NSDictionary *userInfo = nil;
                NSError *jsonError = nil;
                // string -> dictionary
                id resp = [self analyResponse:responseObject withResponse:task.response];
                if([self._config respondsToSelector:@selector(interceptWithURLResponse:success:toUserFailedInfo:)]) {
                    userFailure = ![self._config interceptWithURLResponse:task.response success:resp toUserFailedInfo:&userInfo];
                }
                if (jsonError != nil) {    // to dictionary Failed
                    kBLK3(fadBLK, kErrorResponseNonEncode, task.response, nil);
                } else {  // to dictionary Success
                    userFailure ? kBLK3(fadBLK, kErrorCustomUserInfo(userInfo,responseObject), task.response, resp) : kBLK1(sucBLK, resp);
                }
            }
            dispatch_semaphore_signal(sem);
        } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
            klogInDEBUG(@"网络请求(上传):%d | 失败 | ERR:%@", uniq, error);
            kBLK3(fadBLK, error, task.response, nil);
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        klogInDEBUG(@"网络请求(上传):%d | 完成 | 共耗时:%.3f's", uniq, CACurrentMediaTime() - stTime);
        kBLK0(complete);
    };
    [self.queue addOperation:self.operation];
    return self;
}
- (void)cancelTaskWhenDownloadUseBLK:(void (^)(NSData *resumeInfoData))didDownloadData {
    self.isCancel = YES;
    if ([self.task isKindOfClass:[NSURLSessionDownloadTask class]]) {
        [(NSURLSessionDownloadTask *)self.task cancelByProducingResumeData:^(NSData *_Nullable resumeData) {
            if (didDownloadData) didDownloadData(resumeData);
        }];
    } else {
        if (self.task.state == NSURLSessionTaskStateRunning) [self.task cancel];
    }
    [self.operation cancel];
}

#pragma clang diagnostic pop
@end
