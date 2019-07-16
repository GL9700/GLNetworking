//
//  GLViewController.m
//  GLNetworking
//
//  Created by liandyii@msn.com on 08/08/2018.
//  Copyright (c) 2018 liandyii@msn.com. All rights reserved.
//

/**
 公共API - 获取天气接口
 https://www.apiopen.top/weatherApi?city=成都
 */

#import "GLViewController.h"
#import <GLNetworking.h>
#import <GLNetworkPotocol.h>

#import "SeminarInfo.h"
#import "GLUser.h"

/** ========================================= NetNormalConfig =========================================  */
@interface NetNormalConfig : NSObject<GLNetworkPotocol>

@end

@implementation NetNormalConfig
@synthesize host, header, timeout, isDebug;
- (instancetype)init {
    if((self = [super init])) {
        host = @"https://www.apiopen.top";
        timeout = 10;
        header = @{};
        isDebug = YES;
    }
    return self;
}
@end


/** ========================================= GraphQL config =========================================  */
@interface NetGraphQLConfig : NSObject<GLNetworkPotocol>

@end

@implementation NetGraphQLConfig
@synthesize host, header, timeout, isDebug, isJsonParams;
- (instancetype)init {
    if((self = [super init])) {
        host = @"http://jypt-tr.xqngx.net";
        timeout = 10;
        header = @{};
        isDebug = YES;
        isJsonParams = YES;
    }
    return self;
}
@end


/** ========================================= ViewController =========================================  */
@interface GLViewController ()
@property (nonatomic, strong) NSMutableString *output;
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@end

@implementation GLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [GLNetworking managerWithConfig:[NetNormalConfig new]];
}

- (void)oLog:(id)log {
    if(self.output==nil){
        self.output = [NSMutableString string];
    }
    [self.output appendString:[log description]];
    self.outputTextView.text = self.output;
}
- (void)clearLog {
    self.output = nil;
}

#pragma mark-  Request With HTTP/s GET
- (IBAction)onClickGETRequest:(UIButton *)sender {
    [self clearLog];
    NSString *path = @"weatherApi";
    NSMutableDictionary *params = [@{} mutableCopy];
    params[@"city"] = @"北京";
    [self oLog:@"------------Start------------"];
    [GLNetworking.GET().params(params).path(path) success:^(NSURLResponse *header, id response) {
        [self oLog:@"\n\n*** *** Response Head *** ***\n"];
        [self oLog:((NSHTTPURLResponse *)header).allHeaderFields];
        [self oLog:@"\n\n*** *** Response Data *** ***\n"];
        [self oLog:response];
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        [self oLog:[NSString stringWithFormat:@"Response:%@\n--Error--:\nCode:%ld\ndomain:%@\nuserInfo:%@", response, (long)error.code, error.domain, error.userInfo] ];
    } complete:^{
        [self oLog:@"\n\n------------End------------\n\n"];
    }];
}

#pragma mark-  Request With HTTP/s Post
- (IBAction)onClickPOSTRequest:(UIButton *)sender {
    [self clearLog];
    NSString *path = @"weatherApi";
    NSMutableDictionary *params = [@{} mutableCopy];
    params[@"city"] = @"北京";
    [self oLog:@"------------Start------------\n"];
    [GLNetworking.POST().params(params).path(path) success:^(NSURLResponse *header, id response) {
        [self oLog:((NSHTTPURLResponse *)header).allHeaderFields];
        [self oLog:@"\n-------------\n"];
        [self oLog:response];
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        [self oLog:[NSString stringWithFormat:@"Response:%@\n--Error--:\nCode:%ld\ndomain:%@\nuserInfo:%@", response, (long)error.code, error.domain, error.userInfo] ];
    } complete:^{
        [self oLog:@"------------End------------\n"];
    }];
}

#pragma mark- Request With GraphQL Query
- (IBAction)onClickGraphQLQuery:(UIButton *)sender {
    /* Model 正常实例化 */
    GLUser *user = [GLUser new];
    user.seminarInfoId = @"1847635073457717248";
    user.name = @"abc";
    user.age = 10;
    
    /* -------------请求代码--------------- */
    /* 设置Path */
    NSString *path = @"tr/v2/graphql";
    
    /* 构建参数 */
    NSDictionary *params = [GLNetworking gQueryStringWithMethod:@"seminar_view(seminarInfoId:ID!):SeminarInfo" // 服务器给出的方法名称
                                              params:@{@"seminarInfoId":user.seminarInfoId} // 传给服务器的内容（Key与方法中参数一致）
                                             returns:@[@"seminarId"]];  // 返回值（方法返回值中的属性名称）
    
    /* 请求开始 */
    [GLNetworking.POST().config([NetGraphQLConfig new]).params(params).path(path) success:^(NSURLResponse *header, id response) {
        NSLog(@"--suc--");
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"--fad--");
    } complete:^{
        NSLog(@"--cpm--");
    }];
}

#pragma mark- Request With GraphQL Mutation
- (IBAction)onClickGraphQLMutation:(UIButton *)sender {
    /* Model 正常实例化 */
    SeminarInfo *si = [SeminarInfo new];
    si.title = @"测试",
    si.remark=@"活动说明1",
    si.seminarTime=@"2019-06-27 11:39:20",
    si.seminarEndTime=@"2019-06-28 11:39:20",
    si.subject=@[@"01_13",@"01_15"],
    si.isShare=@"true",
    si.model=@"01",
    si.password=@"",
    si.tagList=@[@"aaaa",@"bbbb"],
    si.location=@"100000";
    
    MyImages *img = [MyImages new];
    img.name = @"i'm image";
    img.format = @"png";
    img.size = @"300x300";
    img.address = @"http://upyun.bejson.com/bj/imgs/upyun_300.png";
    
    /* -------------请求代码--------------- */
    /* 设置 Path */
    NSString *path = @"tr/v2/graphql";
    
    /* 配置参数 */
    NSDictionary *params = [GLNetworking gMutationStringWithMethod:@"seminar_save(seminarInfo:SeminarSaveInfo,image:ImageInput,file:[FileInput]):IdInfo"
                                               variables:@{@"seminarInfo":si, @"image":img}
                                                 returns:@[@"id"]];
    
    /* 请求开始 */
    [GLNetworking.POST().config([NetGraphQLConfig new]).params(params).path(path) success:^(NSURLResponse *header, id response) {
        NSLog(@"--suc--");
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"--fad--");
    } complete:^{
        NSLog(@"--cpm--");
    }];
}

@end
