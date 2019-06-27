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


@interface NetworkingConfig : NSObject<GLNetworkProtocol>

@end

@implementation NetworkingConfig


@end


@interface GLViewController ()
@property (nonatomic, strong) NSMutableString *output;
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@end

@implementation GLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)oLog:(NSString *)log {
    if(self.output==nil){
        self.output = [NSMutableString string];
    }
    [self.output appendString:log];
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
    [GLNetworking.GET().params(params).path(path) success:^(id response) {
        [self oLog:response];
    } failure:^(NSError *error, id response) {
        [self oLog:[NSString stringWithFormat:@"Response:%@\n--Error--:\nCode:%ld\ndomain:%@\nuserInfo:%@", response, (long)error.code, error.domain, error.userInfo] ];
    } complete:^{
        [self oLog:@"------------End------------"];
    }];
}

- (IBAction)onClickPOSTRequest:(UIButton *)sender {
    [self clearLog];
    NSString *path = @"weatherApi";
    NSMutableDictionary *params = [@{} mutableCopy];
    params[@"city"] = @"北京";
    [self oLog:@"------------Start------------"];
    [GLNetworking.POST().params(params).path(path) success:^(id response) {
        [self oLog:response];
    } failure:^(NSError *error, id response) {
        [self oLog:[NSString stringWithFormat:@"Response:%@\n--Error--:\nCode:%ld\ndomain:%@\nuserInfo:%@", response, (long)error.code, error.domain, error.userInfo] ];
    } complete:^{
        [self oLog:@"------------End------------"];
    }];
}

@end
