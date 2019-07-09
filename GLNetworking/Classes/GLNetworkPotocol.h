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
@property (nonatomic, strong) NSString *host;           //host地址
@property (nonatomic, assign) NSUInteger timeout;       // 超时
@property (nonatomic, strong) NSDictionary *header;     // 请求头

@optional
@property (nonatomic, assign) BOOL isDebug;         // YES 输出debug信息
@property (nonatomic, assign) BOOL isJsonParams;    // 使用JSON格式进行body传递（默认NO），且自动设定Content-Type为Application/Json
@property (nonatomic, strong) NSSet *cacheList;     // 缓存名单

/** 编码方案 | params:原始参数 | encodeKey:编码key(优先使用WebServiceName,WS为空后使用path)| */
- (NSDictionary *)paramsProcessedWithOriginParams:(NSDictionary *)params WebServiceName:(NSString *)wsn;
/** 解密方案 | */
- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error;
/**
 * 请求成功后进行拦截调用(此方法中并不建议调用UI相关操作，如需调用需在主线程)
 * @return YES :继续返回成功 NO:拦截处理返回失败 |
 * @param data :服务器返回数据
 * @param userInfo :自定义failed Error UserInfo 内容
 * 如果没有进行设置则网络请求是以请求后网络作为判定
 */
- (BOOL)interceptWithURLResponse:(NSURLResponse *)response success:(id)data toUserFailedInfo:(NSDictionary *__autoreleasing*)userInfo;
//- (BOOL)invocationAfterRequestWS:(NSString *)webserviceORpath success:(id)response toUserFailedInfo:(NSDictionary *__autoreleasing *)userInfo;
/** HTTPS local server */
- (AFSecurityPolicy *)developmentServerSecurity;
@end
