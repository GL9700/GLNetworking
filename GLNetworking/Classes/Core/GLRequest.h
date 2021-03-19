//
//  GLRequest.h
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import "GLNetworkPotocol.h"

typedef NS_ENUM (uint, GLPriority) {
    GLPriorityDefault = 0,  //全局创建即为默认
    GLPriorityLow     = 1, //低于默认
    GLPriorityHigh    = 2 //高于默认
};

typedef NS_ENUM (uint, GLNetMethod) {
    GLMethodPOST,
    GLMethodGET,
    GLMethodDELETE,
    GLMethodPUT
};

@class AFSecurityPolicy;

@interface GLRequest : NSObject
@property (nonatomic, assign) BOOL netStatus;
@property (nonatomic, assign) GLNetMethod method;   // post | get
@property (nonatomic, strong) AFSecurityPolicy *security;

@property (nonatomic, assign) int idex;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithQueue:(NSOperationQueue *)queue;
/** 自定义配置项 (包括网络地址，请求头，超时)*/
- (GLRequest *(^)(id<GLNetworkPotocol>))config;
/** 自定义优先级 */
- (GLRequest *(^)(GLPriority))priority;
/** 参数 (NSDictionary | NSString(JSON):参数) */
- (GLRequest *(^)(id))params;
/** 是否使用编/解码 (默认YES) */
- (GLRequest *(^)(BOOL))encode;
- (GLRequest *(^)(BOOL))decode;
/** 针对这次请求自定义URL */
- (GLRequest *(^)(NSString *))customURL;
/** 默认host后追加URL路径 */
- (GLRequest *(^)(NSString *))path;
/** 设置请求的 Web Service Name */
- (GLRequest *(^)(NSString *))webService;



@end

@interface GLRequest (CacheManagerExt)
- (GLRequest *(^)(BOOL))ignoreCache;
@end

@interface GLRequest (RequestExt)
/** 数据请求 */
- (GLRequest *)success:(void (^)(NSURLResponse *header, id response))sucBLK
               failure:(void (^)(NSError *error, NSURLResponse *response, id data))fadBLK
              complete:(void (^)(void))complete;

/** 下载请求 */
- (GLRequest *)writeToLocalPath:(NSString *)path resumeInfo:(NSData *)resumeData
                       progress:(void (^)(uint64_t totalByte, uint64_t loadedByte))progBLK
                        success:(void (^)(NSURLResponse *header, id response))sucBLK
                        failure:(void (^)(NSError *error, NSURLResponse *response, id data))fadBLK
                       complete:(void (^)(void))complete;

/** 上传请求 fileData: @{MimeType:@{FileName:FileData}} || @{MimeType:FileData}
 mimeType: "multipart/form-data" | "image/jpg" | ... ...
 FileName: 名称，可为空
 FileData: 文件的二进制数据 //图像数据可使用UIImageJPEGRepresentation(img, 0.8)
 */
- (GLRequest *)readFromFileDatas:(NSDictionary<NSString *, id > *)fileDatas
                        progress:(void (^)(float prog))progBLK
                         success:(void (^)(NSURLResponse *header, id response))sucBLK
                         failure:(void (^)(NSError *error, NSURLResponse *response, id data))fadBLK
                        complete:(void (^)(void))complete;

- (void)cancelTaskWhenDownloadUseBLK:(void (^)(NSData *resumeInfoData))didDownloadData;
@end
