//
//  GLRequest.h
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import <AFNetworking/AFNetworking.h>
#import "GLNetworkPotocol.h"
#import "GLOperation.h"

typedef NS_ENUM(uint , GLPriority){
    GLPriorityDefault=0,  //全局创建即为默认
    GLPriorityLow=1,      //低于默认
    GLPriorityHigh=2      //高于默认
};

typedef NS_ENUM(uint , GLNetMethod) {
    GLMethodPOST,
    GLMethodGET,
    GLMethodDELETE,
    GLMethodPUT
};

@class AFSecurityPolicy;

@interface GLRequest : NSObject

@property (nonatomic , strong) AFHTTPSessionManager *manager;
@property (nonatomic , assign) GLNetMethod method;  // post | get
@property (nonatomic , strong) AFSecurityPolicy *security;
@property (nonatomic , strong) GLOperation *operation;
@property (nonatomic , assign) int idex;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithQueue:(NSOperationQueue *)queue;


/** 自定义配置项 (包括网络地址，请求头，超时)*/
- (GLRequest *(^)(id<GLNetworkPotocol>))config;

/** 自定义优先级 */
- (GLRequest *(^)(GLPriority))priority;

/** 参数 (NSDictionary:参数) */
- (GLRequest *(^)(NSDictionary *))params;

/** 是否使用编/解码 (默认YES) */
- (GLRequest *(^)(BOOL))encode;
- (GLRequest *(^)(BOOL))decode;

/** 针对这次请求自定义URL */
- (GLRequest *(^)(NSString *))customURL;

/** 默认host后追加URL路径 */
- (GLRequest *(^)(NSString *))path;

/** 设置请求的 Web Service Name */
- (GLRequest *(^)(NSString *))webService;

/** 下载请求是否支持断点续传 , 默认 NO */
- (GLRequest *(^)(BOOL))supportResume;

/** 数据请求 */
- (GLRequest *)success:(void(^)(id response))sucBLK
               failure:(void(^)(NSError *error , id response))fadBLK
              complete:(void(^)(void))complete;

/** 下载请求 */
- (GLRequest *)writeToLocalPath:(NSString *)path
                       progress:(void(^)(float progress))progBLK
                        success:(void(^)(id response))sucBLK
                        failure:(void(^)(NSError *error , id response))fadBLK
                        complete:(void(^)(void))complete;

/** 上传请求 fileData: @{FILE_TYPE , @{ FILE_NAME , FILE_DATA }} || @{ FILE_TYPE , FILE_DATA } */
- (GLRequest *)readFromFileDatas:(NSDictionary<NSString * , id > *)fileDatas
                        progress:(void(^)(float prog))progBLK
                         success:(void(^)(id response))sucBLK
                         failure:(void(^)(NSError *error , id response))fadBLK
                        complete:(void(^)(void))complete;

- (void)cancel;

@end