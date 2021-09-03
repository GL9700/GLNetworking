![logo](https://github.com/GL9700/gl9700.github.io/blob/master/GLSLogo_800.png?raw=true)
# GLNetworking

[![CI Status](https://img.shields.io/travis/liandyii@msn.com/GLNetworking.svg?style=flat)](https://travis-ci.org/GL9700/GLNetworking)
[![Version](https://img.shields.io/cocoapods/v/GLNetworking.svg?style=flat)](https://cocoapods.org/pods/GLNetworking)
[![License](https://img.shields.io/cocoapods/l/GLNetworking.svg?style=flat)](https://cocoapods.org/pods/GLNetworking)
[![Platform](https://img.shields.io/cocoapods/p/GLNetworking.svg?style=flat)](https://cocoapods.org/pods/GLNetworking)

在一般的项目中，我们都需要进行网络请求，无论是为了发送数据给服务器还是接收最新的数据。
而且在请求的时候，我们希望使用者不再着重关注网络请求代码内容，而是把更多的精力放到业务逻辑上。
所以GLNetworking的目标是：`更轻量`，`更简洁`，`更灵活`。基于此实现了GLNetworking网络请求库，目前暂时基于AFN。

## Installation

GLNetworking is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GLNetworking'
#pod 'GLNetworking/Cache'
#pod 'GLNetworking/GraphQL'
```

## Simple Use

#### 首先, 我们需要对网络请求进行初始化的少量配置。
`XXConfig.h`
```objc
#import <GLNetworkPotocol.h>
@interface XXConfig : NSObject <GLNetworkPotocol>
@end
```
`XXConfig.m`
```objc
@implementation XXConfig

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
- (NSError *)interceptWithURLResponse:(NSHTTPURLResponse *)response success:(id)data;
//- (BOOL)invocationAfterRequestWS:(NSString *)webserviceORpath success:(id)response toUserFailedInfo:(NSDictionary *__autoreleasing *)userInfo;
/** HTTPS local server */
- (AFSecurityPolicy *)developmentServerSecurity;
...
@end
```
在调用网络请求之前进行初始化，一般可以放到`AppDelegate.m`中
```objc
...
[GLNetworking managerWithConfig:[XXConfig new]];
...
```

#### 接下来，我们就可以用最简便的方式在项目使用网络请求
* 简单的`GET请求`：
```objc
...
[GLNetworking.GET().path(@"app/interfaceA") success:nil failure:nil complete:nil];
...
```

* 带有参数的`POST请求`:
```objc
...
/* params(NSDictionary<NSString *, NSString *> *p) */
[GLNetworking.POST().path(@"app/interfaceA").params(@{@"city":@"Beijing",@"zip":@"100000"}) success:nil failure:nil complete:nil];
...
```

* 带有返回数据的请求
```objc
...
[GLNetworking.GET().path(@"app/interfaceA") success:^(NSURLResponse *header, id response) {
    // header : response header
    // response : response data
} failure:^(NSError *error, NSURLResponse *response, id data) {
    // error : 错误信息。
    // response : 服务器返回头。如果进行了请求返回拦截，并改变了返回，此值不为空
    // data : 服务器返回数据。如果进行了请求返回拦截，并改变了返回，此值不为空
complete:^{
    // 网络请求完成后执行 (无论 suc 或 fad 均为执行成功)
}];
...
```

> 其他请求方法组建部分
* `.customURL(NSString *)`:自定义URL地址
* `.config(id<GLNetworkProtocal>)`:自定义Config文件
* `.priority(GLPriority)`:自定义优先级
* `.encode(BOOL)`:是否启用编码(需配合config重写编码方法使用)
* `.decode(BOOL)`:是否启用解码(需配合config重写编码方法使用)
* `.webService(NSString *)`:对应其他类型请求(接口采用参数形式)
* `.ignoreCache(BOOL)`:忽略网络请求缓存(需配合config的cacheList使用)

## More Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

##   History

* 2.11.1 - 2021-09-03
    * 简单修改宏定义 
    
* 2.11.0 - 2021-07-19
    * 增加了高级选项，用于指定接收服务器的Content-Type
    * 增加Group请求方案，用于同一位置可能需要多个请求对应全部结束来进行后续展示
    
* 2.10.0 - 2021-06-25
    * 增加了网络请求的更多方法，支持 HEAD、OPTIONS、PATCH 等 
    
* 2.9.4 - 2020-12-31
    * 优化之前一个核心实例切换配置的问题。现采用2个核心，分别做不同的请求方案
    
* 2.9.3 - 2020-12-28
    * fix: GLRequest 里赋值 requestHeader的时候，如果数组项为空，则会导致Crash的兼容性问题 

* 2.9.1～2.9.2 - 2020-12-17
    * 改变引入方式
    * 针对Manager配置的Bug进行修复

* 2.9.0 - 2020-12-16
    * `GLNetworkProtocol`：增加了服务器响应时stateCode和contentType是否允许的配置方案

* 2.8.3 - 2020-12-15
    * 针对可能存在的Bug，做容错处理

* 2.8.2 - 2020-12-14
    * 做了https基本容错

* 2.7.0 - 2020-06-02
    * 使用了AFN4+的版本，由于AFN3里么使用了UIWebView，无法进行提交

* 2.6.0 - 2020-04-10
    * 暂时修复已知问题：由于此项目暂时依赖AFN3.x，但目前最新版本为4.x不兼容3.x的内容，所以暂时锁定依赖版本为“低于4.0”

* 2.5.1 - 2020-04-03
    * 优化关于地址拼接部分逻辑
    * 修复数据接收到后的控制逻辑

* 2.5.0
    * 增加拦截的功能。现在可以拦截失败的请求，进行统一处理
    
* 2.1.1
    * 支持Json方式参数传递
    
* 2.1.0
    * add GraphQL support


## Requirements

GLNetworking only User on the Objective-C platform.

## Author

liguoliang, 36617161@qq.com

## License

GLNetworking is available under the MIT license. See the LICENSE file for more info.
