//
//  KZNetworkProtocol.h
//  KZNetwork
//
//  Created by liguoliang on 2018/1/3.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFURLResponseSerialization.h>

@class AFSecurityPolicy;

@protocol KZNetworkPotocol <AFURLResponseSerialization>

@required
@property (nonatomic , strong) NSString *host;
@property (nonatomic , strong) NSString *scheme;    // http or https or nil
@property (nonatomic , strong) NSDictionary *requestHeader;
@property (nonatomic , assign) NSTimeInterval timeout;
@property (nonatomic , assign) BOOL debugMode;  // YES 请求信息输出 , 默认为 NO

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
- (BOOL)invocationAfterRequestWS:(NSString *)webserviceORpath Success:(id)response failureErrorUserInfo:(NSDictionary *__autoreleasing *)userInfo;

- (AFSecurityPolicy *)developmentServerSecurity;
@end
