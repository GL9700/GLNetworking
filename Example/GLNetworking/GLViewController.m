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

#import "GLUser.h"

@interface NetworkingConfig : NSObject<GLNetworkPotocol>

@end

@implementation NetworkingConfig
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


@interface GLViewController ()
@property (nonatomic, strong) NSMutableString *output;
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@end

@implementation GLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [GLNetworking managerWithConfig:[NetworkingConfig new]];
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
- (IBAction)onClickGraphQLQuery:(UIButton *)sender {
    GLUser *user = [GLUser new];
    user.seminarInfoId = @"200";
    user.name = @"abc";
    user.age = 10;
    
    NSString *path = @"graphql";
    NSString *pString = [user gQueryStringWithMethod:@"seminar_view(seminarInfoId:ID!):SeminarInfo"
                                              params:@{@"seminarInfoId":user.seminarInfoId}
                                             returns:@[@"name"]];
    [GLNetworking.POST().customURL(@"http://192.168.9.140:8080").params(pString).path(path) success:^(NSURLResponse *header, id response) {
        NSLog(@"--suc--");
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"--fad--");
    } complete:^{
        NSLog(@"--cpm--");
    }];
}
- (IBAction)onClickGraphQLMutation:(UIButton *)sender {
    
}

@end
