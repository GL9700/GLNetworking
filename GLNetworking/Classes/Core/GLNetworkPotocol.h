//
//  GLNetworkPotocol.h
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

typedef BOOL (^BLKIsOnline)(void);

@class AFSecurityPolicy;

@protocol GLNetworkPotocol <NSObject>
//@required
//@property (nonatomic, strong) NSString *host;           //host地址
//@property (nonatomic, assign) NSUInteger timeout;       // 超时
//@property (nonatomic, strong) NSDictionary *header;     // 请求头
//
//@optional
//@property (nonatomic, assign) BOOL isDebug;         // YES 输出debug信息
//@property (nonatomic, assign) BOOL isJsonParams;    // 使用JSON格式进行body传递（默认NO），且自动设定Content-Type为Application/Json
//@property (nonatomic, strong) NSSet *cacheList;     // 缓存名单

@required
/** host地址 */
- (NSString *)requestHost;
/** 设置请求头, 可根据 请求path 来更改 */
- (NSDictionary *)requestHeaderWithPath:(NSString *)path;

@optional
/** 使用JSON格式进行body传递, 默认NO, 且自动在请求头中追加"Content-Type":"Application/Json" */
- (BOOL)isJsonParams;
/** 超时时长(秒), 默认:10*/
- (NSTimeInterval)requestTimeout;
/** 是否输出Debug信息, 默认:NO*/
- (BOOL)isDebugMode;
/** 缓存名单 */
- (NSSet *)cacheList;

@optional

/**
* @brief 加密（编码方案）
* @return 加密后的值，供网络请求使用
* @param params 即将进行请求的加密前参数列表
* @param path 请求时的接口路径, 可作为Key使用
* @discussion
*  由于加密和解密一般成对出现，且各个项目可能使用的方案不同。所以此方法留给使用者自己定义。
*/
- (id)paramsProcessedWithOriginParams:(NSDictionary *)params path:(NSString *)path;

/**
 * @brief 解密
 * @return 解密后的值，供网络请求使用
 * @param response 服务器返回头信息
 * @param data 服务器返回数据
 * @discussion
 *  由于加密和解密一般成对出现，且各个项目可能使用的方案不同。所以此方法留给使用者自己定义。通过data接收服务器的加密后的信息，然后进行解密后返回。
 */
- (id)responseObjectForResponse:(NSHTTPURLResponse *)response data:(NSData *)data;

/**
 * @brief 请求成功后进行拦截调用(此方法在子线程被执行)
 * @return
 *      为空   : 直接回到成功;
 * @return
 *      不为空 : 说明进行了处理，返回用户定义的Error或请求的系统的Error;
 * @param response 服务器返回头信息
 * @param data 服务器返回数据
 * @discussion
 *      1. 如果请求发送出去，中间产生网络错误，则不会进入此方法，直接返回Failed。
 * @discussion
 *      2. 如果没有产生网络错误，但是返回的数据内有需要进行判断的内容，则需要实现此方法，并依据数据(data参数)，进行判断，是否需要返回Error信息。
 * @warning 定义ErrorCode时尽量避免如下区间：-1，-999，-1000～-1120，-1200～-1206，-2000，-3000～-3007 (详见:NSURLError.h)
 */
- (NSError *)interceptWithURL:(NSString *)url Header:(NSHTTPURLResponse *)header Success:(id)data Failed:(NSError *)error;
//- (BOOL)invocationAfterRequestWS:(NSString *)webserviceORpath success:(id)response toUserFailedInfo:(NSDictionary *__autoreleasing *)userInfo;
/** HTTPS local server */
- (AFSecurityPolicy *)developmentServerSecurity;
@end
