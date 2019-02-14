//
//  GLNetworkPotocol.h
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

typedef BOOL(^BLKIsOnline)(void);

@class AFSecurityPolicy;

@protocol GLNetworkPotocol <NSObject>
@required
@property (nonatomic, assign) BOOL isDebug;    // YES 输出debug信息
@property (nonatomic, strong) NSString *host;  //host地址
@property (nonatomic, assign) BOOL supJSONReq; //  是否使用JSON格式进行body传递（默认NO）JsonSerializer
@property (nonatomic, strong) NSSet *cacheList;    // 缓存名单
@property (nonatomic, assign) NSUInteger timeout;  // 超时
@property (nonatomic, strong) NSDictionary *header;    // 请求头
@property (nonatomic, strong) BLKIsOnline blkIsOnline;
@optional
/** 编码方案 | params:原始参数 | encodeKey:编码key(优先使用WebServiceName,WS为空后使用path)| */
- (NSDictionary *)paramsProcessedWithOriginParams:(NSDictionary *)params WebServiceName:(NSString *)wsn;
/** 解密方案 | */
- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error;
/**
 * 请求成功后进行拦截调用
 * @return YES:继续返回成功 NO:拦截处理返回失败 |
 * @param webserviceORpath :webservice或path , 优先webservice
 * @param response :请求数据
 * @param userInfo :自定义failed Error UserInfo 内容
 * 如果没有进行设置则网络请求是以请求后网络作为判定
 */
- (BOOL)invocationAfterRequestWS:(NSString *)webserviceORpath success:(id)response toUserFailedInfo:(NSDictionary *__autoreleasing *)userInfo;
/** HTTPS local server */
- (AFSecurityPolicy *)developmentServerSecurity;
@end
