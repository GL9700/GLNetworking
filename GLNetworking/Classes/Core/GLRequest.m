//
//  GLRequest.m
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import "GLRequest.h"
#import <CommonCrypto/CommonDigest.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <GLOperation.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import <GLNetworkPotocol.h>

#if __has_include(<GLCacheData.h>)
#import <GLCacheData.h>
#endif

#define weak(o)                autoreleasepool {} __weak typeof(o) o ## Weak = o;
#define strong(o)              autoreleasepool {} __strong typeof(o) o = o ## Weak;
#define LOG(str, ...)          [self._config respondsToSelector:@selector(logMessage:)] ? [self._config logMessage:[NSString stringWithFormat:str, ## __VA_ARGS__]] : nil
#define kBLK0(blk)             self.isCancel == NO ? dispatch_async(dispatch_get_main_queue(), ^{ blk == nil ? : blk(); }) : nil
#define kBLK1(blk, p1)         self.isCancel == NO ? dispatch_async(dispatch_get_main_queue(), ^{ blk == nil ? : blk(p1); }) : nil
#define kBLK2(blk, p1, p2)     self.isCancel == NO ? dispatch_async(dispatch_get_main_queue(), ^{ blk == nil ? : blk(p1, p2); }) : nil
#define kBLK3(blk, p1, p2, p3) self.isCancel == NO ? dispatch_async(dispatch_get_main_queue(), ^{ blk == nil ? : blk(p1, p2, p3); }) : nil

const char *methodList[] = {
    "POST", "GET", "DELETE", "PUT"
};

static NSMutableSet *kAssociatedList;

@interface NSString (MD5Ext)
- (NSString *)md5;
@end
@implementation NSString (MD5Ext)
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
    dispatch_once_t onceFlagForHttps;
    dispatch_once_t onceFlagForConfig;
}
@property (nonatomic, strong) GLOperation *operation;
@property (nonatomic, strong) AFHTTPSessionManager *managerNormal;
@property (nonatomic, strong) AFHTTPSessionManager *managerJson;
@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, assign) float _priority;
@property (nonatomic, strong) id<GLNetworkPotocol> _config;
@property (nonatomic, strong) id _params;
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
                   if([self._config respondsToSelector:@selector(requestTimeout)]) {
                       if([self._config respondsToSelector:@selector(isJsonParams)] && [self._config isJsonParams]==YES) {
                           self.managerJson.requestSerializer.timeoutInterval = [self._config requestTimeout];
                       }else{
                           self.managerNormal.requestSerializer.timeoutInterval = [self._config requestTimeout];
                       }
                   }
               }
               return self;
    };
}

- (GLRequest *(^)(id))params {
    return ^(id dic) {
               if (dic != nil) {
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
        return [self._config requestHost];
    }
    else {
        return self.cusurl;
    }
}

#pragma mark- Getter & Setter
- (NSString *)url {
    NSURLComponents *url = [NSURLComponents componentsWithString:self.currentURL];
    if (url) {
        // scheme
        if ([url.scheme isEqual:nil]) {
            url.scheme = @"http";
        }
        if ([url.scheme isEqualToString:@"https"]) {
            [self securityPolicy];
        }
        // host
        // <NSURLComponents 0x28153cfa0>
        // {scheme = (null), user = (null), password = (null), host = (null), port = (null), path = baidu.com, query = (null), fragment = (null)}
        // {scheme = (null), user = (null), password = (null), host = (null), port = (null), path = baidu.com/aa/bb, query = (null), fragment = (null)}
        if (![url.path hasPrefix:@"/"] && url.host == nil) {
            NSInteger location = [url.path rangeOfString:@"/"].location;
            if (location < url.path.length) {
                url.host = [url.path substringToIndex:location];
                url.path = [url.path substringFromIndex:location];
            }
            else {
                url.host = url.path;
                url.path = @"";
            }
        }
        // path
        if ([url.path isEqualToString:@""]) {
            url.path = @"/";
        }
        url.path = [url.path stringByAppendingPathComponent:self._path];
        _url = url.URL.absoluteString;
    }
    else {
        _url = [self.currentURL stringByAppendingPathComponent:self._path];
        if (![_url hasPrefix:@"http"]) {
            _url = [@"http://" stringByAppendingString:_url];
        }
        else if ([_url hasPrefix:@"https://"]) {
            [self securityPolicy];
        }
    }
    return _url;
}

/** 使设置生效 */
- (AFHTTPSessionManager *)managerForConfig:(id<GLNetworkPotocol>)config {
    AFHTTPSessionManager *manager = nil;
    if([config respondsToSelector:@selector(isJsonParams)] && [config isJsonParams] == YES) {
        manager = self.managerJson;
    }else{
        manager = self.managerNormal;
    }
    [self setupResponseInConfig:self._config inManager:manager];
    return manager;
}

- (void)setupResponseInConfig:(id<GLNetworkPotocol>)config inManager:(AFHTTPSessionManager *)manager {
    if(manager && manager.responseSerializer) {
        if ([config respondsToSelector:@selector(responseAllowContentTypes)]) {
            manager.responseSerializer.acceptableContentTypes = [config responseAllowContentTypes];
        }
        if ([config respondsToSelector:@selector(responseAllowStatusCodes)]) {
            manager.responseSerializer.acceptableStatusCodes = [config responseAllowStatusCodes];
        }
    }
}

#pragma mark- Actions

/** https */
- (void)securityPolicy {
    if ([self._config respondsToSelector:@selector(developmentServerSecurity)]) {
        AFSecurityPolicy *sp = [self._config developmentServerSecurity];
        self.managerJson.securityPolicy = self.managerNormal.securityPolicy = sp ? sp : [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }
}

/** 加密参数 */
- (NSDictionary *)encodeParams:(NSDictionary *)originParams ws:(NSString *)ws {
    NSDictionary *encodedParam = originParams;
    if (self.obstructEncode == NO) {
        if ([self._config respondsToSelector:@selector(paramsProcessedWithOriginParams:path:)]) {
            /** 优先使用“WebSericeName”进行加密。如果没有ws则传入path*/
            if (ws != nil || self._path != nil) {
                encodedParam = [self._config paramsProcessedWithOriginParams:self._params path:ws != nil ? ws : self._path];
            }
        }
    }
    return encodedParam;
}

/** 解析并转换数据 */
- (id)analyResponse:(id)data withResponse:(NSURLResponse *)respheader {
    id resp = nil;
    if (data != nil) {
        // 解密
        if (self.obstructDecode == NO && [self._config respondsToSelector:@selector(responseObjectForResponse:data:)]) {
            data = [self._config responseObjectForResponse:(NSHTTPURLResponse *)respheader data:data];
        }
        if ([data isKindOfClass:[NSData class]]) {
            // 尝试使用json解析Data
            resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            // json失败，尝试转换为字符串
            if (resp == nil) {
                resp = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
        if (resp == nil) {
            resp = data;
        }
    }
    return resp;
}

@end

@implementation GLRequest (CacheManagerExt)
- (GLRequest *(^)(BOOL))ignoreCache {
    return ^(BOOL p) {
               self->ignoreCache = p;
               return self;
    };
}

- (NSString *)jsonFromDictionary:(NSDictionary *)dic {
    NSMutableArray *arr = [dic.allKeys mutableCopy];
    [arr sortUsingComparator: ^NSComparisonResult (id _Nonnull obj1, id _Nonnull obj2) {
        return NSOrderedAscending;
    }];
    NSMutableString *ret = [@"{" mutableCopy];
    [arr enumerateObjectsUsingBlock: ^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([dic[obj] isKindOfClass:[NSString class]]) {
            [ret appendFormat:@"%@=%@,", obj, dic[obj]];
        }
    }];
    ret = [[ret substringToIndex:ret.length - 1] mutableCopy];
    [ret appendString:@"}"];
    return [ret copy];
}

#if __has_include(<GLCacheData.h>)
- (NSString *)URLhash {
    if (_URLhash == nil) {
        NSDictionary *header = [self._config requestHeaderWithPath:self._path];
        NSMutableString *value = [NSMutableString stringWithFormat:@"%d", self.method];
        [value appendString:self._path ? [NSString stringWithFormat:@"|%@", self._path] : @""];
        self._params ? [value appendString:[self jsonFromDictionary:self._params]] : nil;
        header ? [value appendString:[self jsonFromDictionary:header]] : nil;
        _URLhash = [value md5];
    }
    return _URLhash;
}

- (NSString *)cacheFolder {
    if (!_cacheFolder) {
        _cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"GLCache"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_cacheFolder]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_cacheFolder withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _cacheFolder;
}

- (void)cacheAddToAccociatedList {
    if ([self._config respondsToSelector:@selector(cacheList)] == NO) return;
    @synchronized (kAssociatedList) {
        if (![kAssociatedList containsObject:self.URLhash]) [kAssociatedList addObject:self.URLhash];
    }
}

- (BOOL)cacheContainInAccociatedList {
    if ([self._config respondsToSelector:@selector(cacheList)] == NO) return NO;
    if (kAssociatedList == nil) {
        kAssociatedList = [NSMutableSet set];
    }
    return [kAssociatedList containsObject:self.URLhash];
}

- (BOOL)cacheContainInCacheList {
    if ([self._config respondsToSelector:@selector(cacheList)] == NO) return NO;
    BOOL container = NO;
    if (self._config.cacheList) {
        container = [self._config.cacheList containsObject:self._path];
    }
    return container;
}

- (void)cacheSaveData:(id)data resp:(NSURLResponse *)urlresponse {
    if ([self._config respondsToSelector:@selector(cacheList)] == NO) {
        return;
    }
    NSString *path = [self.cacheFolder stringByAppendingPathComponent:self.URLhash];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if ([self cacheContainInCacheList]) {
        LOG(@"在缓存名单中");
        GLCacheData *cachedata = [GLCacheData new];
        cachedata.data = data;
        cachedata.response = urlresponse;
        if ([NSKeyedArchiver archiveRootObject:cachedata toFile:path]) {
            [self cacheAddToAccociatedList];
            LOG(@"写入成功:%@", path);
        }
        else {
            LOG(@"写入失败:%@", path);
        }
    }
    else {
        LOG(@"不在缓存名单中，放弃操作");
    }
}

- (GLCacheData *)cacheLoadData {
    GLCacheData *cdata = nil;
    if ([self._config respondsToSelector:@selector(cacheList)] == NO) return cdata;
    NSString *path = [self.cacheFolder stringByAppendingPathComponent:self.URLhash];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        LOG(@"找到缓存的文件");
        cdata = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
    else {
        LOG(@"没找到缓存的文件");
    }
    LOG(@"从缓存中读取:URL:%@|LocalPath:%@|REL:%@", self.url, path, cdata != nil ? @"SUC" : @"FAD");
    return cdata;
}

- (void)cacheDelete {
    NSString *path = [self.cacheFolder stringByAppendingPathComponent:self.URLhash];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if ([kAssociatedList containsObject:self.URLhash]) {
        @synchronized (kAssociatedList) {
            [kAssociatedList removeObject:self.URLhash];
        }
    }
}

#endif
@end

@implementation GLRequest (RequestExt)

/**
 * 判断是否主动改为失败，来统一处理啊其他信息
 *  如果请求成功，可以--请求成功 或 请求失败
 *  如果请求失败，必须--请求失败
 */
- (void)switchSucOrFadWithURL:(NSString *)urlString
              HTTPURLResponse:(NSHTTPURLResponse *)httpURLResponse
                     respData:(id)data
                    respError:(NSError *)error
                    handleSuc:(void (^)(NSURLResponse *, id))sucBLK
                    handleFad:(void (^)(NSError *, NSURLResponse *, id))fadBLK {
    NSError *userError = error;
    if ([self._config respondsToSelector:@selector(interceptWithURL:Header:Success:Failed:)]) {
        userError = [self._config interceptWithURL:urlString Header:httpURLResponse Success:data Failed:error];
    }
    if (userError) {
        kBLK3(fadBLK, userError, httpURLResponse, data);
    }
    else {
        kBLK2(sucBLK, httpURLResponse, data);
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconditional-type-mismatch"
/** 数据请求 */
- (GLRequest *)success:(void (^)(NSURLResponse *, id))sucBLK failure:(void (^)(NSError *, NSURLResponse *, id))fadBLK complete:(void (^)(void))complete {
    id encodedParam = self._params;
    /** 编码参数 webService 优先 */
    if ([self._params isKindOfClass:[NSDictionary class]]) { // 加密仅支持NSDictonary类型参数
        if (self._wsvsname != nil) {
            encodedParam = [self encodeParams:(NSDictionary *)self._params ws:self._wsvsname];
        }
        else {
            if (self._path != nil && self._wsvsname == nil) {
                encodedParam = [self encodeParams:(NSDictionary *)self._params ws:self._path];
            }
        }
    }
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        AFHTTPSessionManager *manager = [self managerForConfig:self._config];
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime - (int)stTime) * 1000) + arc4random() % 10;
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);

#if __has_include(<GLCacheData.h>)
        BOOL containerSelf = [self cacheContainInAccociatedList];
        if (containerSelf && self->ignoreCache == NO) {
            // 找到关联关系 并且不忽略缓存
            LOG(@"网络请求状态:%d | Online:Yes | hasCache:Yes | -- use Cache", uniq);
            GLCacheData *cdata = [self cacheLoadData];
            id resp = [self analyResponse:cdata.data withResponse:cdata.response];
            [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)cdata.response respData:resp respError:nil handleSuc:sucBLK handleFad:fadBLK];
            dispatch_semaphore_signal(sem);
        }
        else    // 不存在关联关系
#endif
        {
            if (!self.url) {
                kBLK3(fadBLK, [NSError errorWithDomain:@"请求地址不正确" code:-9000 userInfo:nil], nil, nil);
            }
            else if ([self netStatus]) {
                LOG(@"网络状态检查:%d | Online:Yes | hasCache:~ | -- ignore Cache", uniq);
                LOG(@"网络请求开始:%d | Method:%s | URL:%@ | path:%@ | params:%@", uniq, methodList[self.method], self.url, self._path, self._params);
                switch (self.method) {
                    case GLMethodGET: {
                        self.task = [manager GET:self.url parameters:encodedParam headers:[self._config requestHeaderWithPath:self._path] progress: ^(NSProgress *_Nonnull downloadProgress) {} success: ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                            LOG(@"网络请求成功:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
                            if (responseObject != nil) {
                                #if __has_include(<GLCacheData.h>)
                                [self cacheSaveData:responseObject resp:task.response];
                                #endif
                                id resp = [self analyResponse:responseObject withResponse:task.response];
                                LOG(@"网络请求整理数据:%d | Time:%.3f's | RESP:%@", uniq, CACurrentMediaTime() - stTime, resp);
                                [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:resp respError:nil handleSuc:sucBLK handleFad:fadBLK];
                            }
                            dispatch_semaphore_signal(sem);
                        } failure: ^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                            LOG(@"网络请求失败:%d | Method:%s | Time:%.3f's | ERR:%@", uniq, methodList[self.method], CACurrentMediaTime() - stTime, error);
                            [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:nil respError:error handleSuc:sucBLK handleFad:fadBLK];
                            dispatch_semaphore_signal(sem);
                        }];
                        break;
                    }
                    case GLMethodPOST: {
                        self.task = [manager POST:self.url parameters:encodedParam headers:[self._config requestHeaderWithPath:self._path] progress: ^(NSProgress *_Nonnull uploadProgress) {} success: ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                            LOG(@"网络请求成功:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
                            if (responseObject != nil) {
                                #if __has_include(<GLCacheData.h>)
                                [self cacheSaveData:responseObject resp:task.response];
                                #endif
                                id resp = [self analyResponse:responseObject withResponse:task.response];
                                LOG(@"网络请求整理数据:%d | Time:%.3f's | RESP:%@", uniq, CACurrentMediaTime() - stTime, resp);
                                [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:resp respError:nil handleSuc:sucBLK handleFad:fadBLK];
                            }
                            dispatch_semaphore_signal(sem);
                        } failure: ^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                            LOG(@"网络请求失败:%d | Method:%s | Time:%.3f's | ERR:%@", uniq, methodList[self.method], CACurrentMediaTime() - stTime, error);
                            [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:nil respError:error handleSuc:sucBLK handleFad:fadBLK];
                            dispatch_semaphore_signal(sem);
                        }];
                        break;
                    }
                    case GLMethodPUT: {
                        self.task = [manager PUT:self.url parameters:encodedParam headers:[self._config requestHeaderWithPath:self._path] success: ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                            LOG(@"网络请求成功:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
                            if (responseObject != nil) {
                                #if __has_include(<GLCacheData.h>)
                                [self cacheSaveData:responseObject resp:task.response];
                                #endif
                                id resp = [self analyResponse:responseObject withResponse:task.response];
                                LOG(@"网络请求整理数据:%d | Time:%.3f's | RESP:%@", uniq, CACurrentMediaTime() - stTime, resp);
                                [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:resp respError:nil handleSuc:sucBLK handleFad:fadBLK];
                            }
                            dispatch_semaphore_signal(sem);
                        } failure: ^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                            LOG(@"网络请求失败:%d | Method:%s | Time:%.3f's | ERR:%@", uniq, methodList[self.method],  CACurrentMediaTime() - stTime, error);
                            [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:nil respError:error handleSuc:sucBLK handleFad:fadBLK];
                            dispatch_semaphore_signal(sem);
                        }];
                        break;
                    }
                    case GLMethodDELETE: {
                        self.task = [manager DELETE:self.url parameters:encodedParam headers:[self._config requestHeaderWithPath:self._path] success: ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                            LOG(@"网络请求成功:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
                            if (responseObject != nil) {
                                #if __has_include(<GLCacheData.h>)
                                [self cacheSaveData:responseObject resp:task.response];
                                #endif
                                id resp = [self analyResponse:responseObject withResponse:task.response];
                                LOG(@"网络请求整理数据:%d | Time:%.3f's | RESP:%@", uniq, CACurrentMediaTime() - stTime, resp);
                                [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:resp respError:nil handleSuc:sucBLK handleFad:fadBLK];
                            }
                            dispatch_semaphore_signal(sem);
                        } failure: ^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                            LOG(@"网络请求失败:%d | Method:%s | Time:%.3f's | ERR:%@",  uniq, methodList[self.method], CACurrentMediaTime() - stTime, error);
                            [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:nil respError:error handleSuc:sucBLK handleFad:fadBLK];
                            dispatch_semaphore_signal(sem);
                        }];
                        break;
                    }
                }
            }
            else {
                #if __has_include(<GLCacheData.h>)
                // 强制查找缓存
                GLCacheData *cdata = [self cacheLoadData];
                if (cdata != nil) {
                    LOG(@"网络请求状态:%d | Online:No | hasCache:Yes | -- use Cache", uniq);
                    [self cacheAddToAccociatedList];
                    id resp = [self analyResponse:cdata.data withResponse:cdata.response];
                    [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)cdata.response respData:resp respError:nil handleSuc:sucBLK handleFad:fadBLK];
                    dispatch_semaphore_signal(sem);
                }
                else
                #endif
                {
                    LOG(@"网络请求状态:%d | Online:No | hasCache:No | -- no Data", uniq);
                    NSURLResponse *eresp = [[NSHTTPURLResponse alloc]initWithURL:[NSURL URLWithString:self.url] statusCode:1001 HTTPVersion:nil headerFields:nil];
                    NSError *noCacheError = [NSError errorWithDomain:@"Offline And notFound cache data" code:-1301 userInfo:nil];
                    [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)eresp respData:nil respError:noCacheError handleSuc:sucBLK handleFad:fadBLK];
                    dispatch_semaphore_signal(sem);
                    // 无网 - 无缓存
                }
            }
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        LOG(@"网络请求完成:%d | Time:%.3f's", uniq, CACurrentMediaTime() - stTime);
        kBLK0(complete);
    };
    [self.queue addOperation:self.operation];
    return self;
}

/** 下载请求 */
/** 注意，下载不能被拦截 */
- (GLRequest *)writeToLocalPath:(NSString *)path resumeInfo:(NSData *)resumeData progress:(void (^)(uint64_t, uint64_t))progBLK success:(void (^)(NSURLResponse *, id))sucBLK failure:(void (^)(NSError *, NSURLResponse *, id))fadBLK complete:(void (^)(void))complete {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    NSTimeInterval time = [self._config respondsToSelector:@selector(requestTimeout)] ? [self._config requestTimeout] : 10;
    NSDictionary *header = [self._config requestHeaderWithPath:self._path];
    [req setTimeoutInterval:time];
    [req setAllHTTPHeaderFields:header];
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        AFHTTPSessionManager *manager = [self managerForConfig:self._config];
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime - (int)stTime) * 1000);
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        if (resumeData != nil) {
            LOG(@"网络请求(下载):%d | 恢复 | URL:%@", uniq, self.url);
            self.task = [manager downloadTaskWithResumeData:resumeData progress: ^(NSProgress *_Nonnull downloadProgress) {
                LOG(@"网络请求(下载):%d | 进度更新 | PROGRESS:%.2f", uniq, (double)downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                kBLK2(progBLK, downloadProgress.totalUnitCount, downloadProgress.completedUnitCount);
            } destination: ^NSURL *_Nonnull (NSURL *_Nonnull targetPath, NSURLResponse *_Nonnull response) {
                return [NSURL fileURLWithPath:path];
            } completionHandler: ^(NSURLResponse *_Nonnull response, NSURL *_Nullable filePath, NSError *_Nullable error) {
                LOG(@"网络请求(下载):%d | 成功 | LOCAL:%@", uniq, filePath);
                error ? kBLK3(fadBLK, error, response, nil) : kBLK2(sucBLK, response, nil);
                dispatch_semaphore_signal(sem);
            }];
        }
        else {
            LOG(@"网络请求(下载):%d | 开始 | URL:%@", uniq, self.url);
            self.task = [manager downloadTaskWithRequest:req progress: ^(NSProgress *_Nonnull downloadProgress) {
                LOG(@"网络请求(下载):%d | 进度更新 | PROGRESS:%.2f", uniq, (double)downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                kBLK2(progBLK, downloadProgress.totalUnitCount, downloadProgress.completedUnitCount);
            } destination: ^NSURL *_Nonnull (NSURL *_Nonnull targetPath, NSURLResponse *_Nonnull response) {
                return [NSURL fileURLWithPath:path];
            } completionHandler: ^(NSURLResponse *_Nonnull response, NSURL *_Nullable filePath, NSError *_Nullable error) {
                LOG(@"网络请求(下载):%d | 成功 | LOCAL:%@", uniq, filePath);
                error ? kBLK3(fadBLK, error, response, nil) : kBLK2(sucBLK, response, nil);
                dispatch_semaphore_signal(sem);
            }];
        }
        [self.task resume];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        LOG(@"网络请求(下载):%d | 完成 |  此次请求耗时:%.3f's", uniq, CACurrentMediaTime() - stTime);
        kBLK0(complete);
    };
    [self.queue addOperation:self.operation];
    return self;
}

- (GLRequest *)readFromFileDatas:(NSDictionary<NSString *, id> *)fileDatas progress:(void (^)(float))progBLK success:(void (^)(NSURLResponse *, id))sucBLK failure:(void (^)(NSError *, NSURLResponse *, id))fadBLK complete:(void (^)(void))complete {
    @weak(self)
    self.operation.operationBlock = ^{
        @strong(self)
        AFHTTPSessionManager *manager = [self managerForConfig:self._config];
        CFTimeInterval stTime = CACurrentMediaTime();
        int uniq = (int)((stTime - (int)stTime) * 1000);
        LOG(@"网络请求(上传):%d | 开始 | URL:%@", uniq, self.url);
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);

        self.task = [manager POST:self.url parameters:nil headers:[self._config requestHeaderWithPath:self._path] constructingBodyWithBlock: ^(id<AFMultipartFormData>  _Nonnull formData) {
            for (NSString *key in [fileDatas allKeys]) {
                if ([fileDatas[key] isKindOfClass:[NSDictionary class]]) {
                    // 带名字类型
                    [formData appendPartWithFileData:[fileDatas[key] allValues].firstObject
                                                name:key
                                            fileName:[fileDatas[key] allKeys].firstObject
                                            mimeType:@"multipart/form-data"];
                }
                else if ([fileDatas[key] isKindOfClass:[NSData class]]) {
                    // 无名字类型
                    [formData appendPartWithFileData:[fileDatas valueForKeyPath:key]
                                                name:key
                                            fileName:key
                                            mimeType:@"multipart/form-data"];
                }
            }
        } progress: ^(NSProgress *_Nonnull uploadProgress) {
            LOG(@"网络请求(上传):%d | 进度更新 | PROGRESS:%.2f", uniq, (double)uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
            kBLK1(progBLK, (double)uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
        } success: ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
            LOG(@"网络请求(上传):%d | 成功 | RESP:%@", uniq, responseObject);
            /* 新解密方案 */
            if (self.obstructDecode == NO && [self._config respondsToSelector:@selector(responseObjectForResponse:data:)]) {
                responseObject = [self._config responseObjectForResponse:(NSHTTPURLResponse *)task.response data:responseObject];
            }
            else {
                if ([responseObject isKindOfClass:[NSString class]]) responseObject = responseObject;
                else if ([responseObject isKindOfClass:[NSData class]]) responseObject = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
            }
            if (responseObject != nil) {
                id resp = [self analyResponse:responseObject withResponse:task.response];
                [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:resp respError:nil handleSuc:sucBLK handleFad:fadBLK];
            }
            dispatch_semaphore_signal(sem);
        } failure: ^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
            LOG(@"网络请求(上传):%d | 失败 | ERR:%@", uniq, error);
            [self switchSucOrFadWithURL:self.url HTTPURLResponse:(NSHTTPURLResponse *)task.response respData:nil respError:error handleSuc:sucBLK handleFad:fadBLK];
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        LOG(@"网络请求(上传):%d | 完成 | 共耗时:%.3f's", uniq, CACurrentMediaTime() - stTime);
        kBLK0(complete);
    };
    [self.queue addOperation:self.operation];
    return self;
}

- (void)cancelTaskWhenDownloadUseBLK:(void (^)(NSData *resumeInfoData))didDownloadData {
    self.isCancel = YES;
    if ([self.task isKindOfClass:[NSURLSessionDownloadTask class]]) {
        [(NSURLSessionDownloadTask *)self.task cancelByProducingResumeData: ^(NSData *_Nullable resumeData) {
            if (didDownloadData) didDownloadData(resumeData);
        }];
    }
    else {
        if (self.task.state == NSURLSessionTaskStateRunning) [self.task cancel];
    }
    [self.operation cancel];
}

#pragma clang diagnostic pop
@end
