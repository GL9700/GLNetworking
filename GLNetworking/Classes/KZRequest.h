//
//  KZRequest.h
//  KZNetwork
//
//  Created by liguoliang on 2018/3/8.
//


#import <AFNetworking/AFNetworking.h>
#import "KZNetworkProtocol.h"
#import "KZOperation.h"

typedef NS_ENUM(uint , KZPriority){
    KZPriorityDefault=0,  //全局创建即为默认
    KZPriorityLow=1,      //低于默认
    KZPriorityHigh=2      //高于默认
};

typedef NS_ENUM(uint , KZNetMethod) {
    KZMethodPOST,
    KZMethodGET
};

@class AFSecurityPolicy;

@interface KZRequest : NSObject
@property (nonatomic , strong) AFHTTPSessionManager *manager;
@property (nonatomic , assign) KZNetMethod method;  // post | get
@property (nonatomic , strong) AFSecurityPolicy *security;
@property (nonatomic , strong) KZOperation *operation;
@property (nonatomic , assign) int idex;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithHQ:(dispatch_queue_t)hq DQ:(dispatch_queue_t)dq LQ:(dispatch_queue_t)lq OBJC_DEPRECATED("USE -initWithQueue , Thread Manager Exchange NSOperation");

- (instancetype)initWithQueue:(NSOperationQueue *)queue;


/** 自定义配置项 (包括网络地址，请求头，超时)*/
- (KZRequest *(^)(id<KZNetworkPotocol>))config;

/** 自定义优先级 */
- (KZRequest *(^)(KZPriority))priority;

/** 参数 (NSDictionary:参数) */
- (KZRequest *(^)(NSDictionary *))params;

/** 是否使用编/解码 (默认YES) */
- (KZRequest *(^)(BOOL))encode;
- (KZRequest *(^)(BOOL))decode;

/** 针对这次请求自定义URL */
- (KZRequest *(^)(NSString *))customURL;

/** 默认host后追加URL路径 */
- (KZRequest *(^)(NSString *))path;

/** 设置请求的 Web Service Name */
- (KZRequest *(^)(NSString *))webService;

/** 数据请求 */
- (KZRequest *)success:(void(^)(id result))sucBLK Failure:(void(^)(NSError  *error))fadBLK Complete:(void(^)(void))complete;

/** 下载请求 */
- (KZRequest *)writeToLocalPath:(NSString *)path Progress:(void(^)(float prog))progBLK Success:(void(^)(id result))sucBLK Failure:(void(^)(NSError  *error))fadBLK Complete:(void(^)(void))complete;

/** 上传请求 fileData: @{FILE_TYPE , @{ FILE_NAME , FILE_DATA }} || @{ FILE_TYPE , FILE_DATA } */
- (KZRequest *)readFromFileDatas:(NSDictionary<NSString * , id > *)fileDatas Progress:(void(^)(float prog))progBLK Success:(void(^)(id result))sucBLK Failure:(void(^)(NSError  *error))fadBLK Complete:(void(^)(void))complete;

- (void)cancel;
@end
