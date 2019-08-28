# GLNetworking

[![CI Status](https://img.shields.io/travis/liandyii@msn.com/GLNetworking.svg?style=flat)](https://travis-ci.org/liandyii@msn.com/GLNetworking)
[![Version](https://img.shields.io/cocoapods/v/GLNetworking.svg?style=flat)](https://cocoapods.org/pods/GLNetworking)
[![License](https://img.shields.io/cocoapods/l/GLNetworking.svg?style=flat)](https://cocoapods.org/pods/GLNetworking)
[![Platform](https://img.shields.io/cocoapods/p/GLNetworking.svg?style=flat)](https://cocoapods.org/pods/GLNetworking)

在一般的项目中，我们都需要进行网络请求，无论是为了发送数据给服务器还是接收最新的数据。
而且在请求的时候，我们希望使用者不再着重关注网络请求代码内容，而是把更多的精力放到业务逻辑上。
所以GLNetworking的目标是：`更轻量`，`更简洁`，`更灵活`。基于此我们有了GLNetworking网络请求库。

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
/*
    host 请求地址
    header 请求头
    timeout 超时时长(秒)，默认10
    isJsonParams 是否需要转换为Json参数进行请求(Content-Type也会随之改变)，默认否
    cacheList 缓存名单(白名单)
*/
@synthesize host, header;
...
{
    host = @"http://api.xxx.com"
    header = @{
        @"user-Agent":@"xxx",
        @"Content-Type":@"xxx",
        ...
    };
}
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

## Requirements

GLNetworking only User on the Objective-C platform.

## Installation

GLNetworking is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GLNetworking'
```

## Author

liandyii@msn.com, 36617161@qq.com

## License

GLNetworking is available under the MIT license. See the LICENSE file for more info.
