//
//  GLViewController.m
//  GLNetworking
//
//  Created by 36617161@qq.com on 09/25/2020.
//  Copyright (c) 2020 36617161@qq.com. All rights reserved.
//

#import "GLViewController.h"
#import "GLGlobalNetworkingConfig.h"
#import <GLNetworking.h>

// MARK: - 自定义config，继承自globalConfig
@interface CustomConfig01: GLGlobalNetworkingConfig
@end
@implementation CustomConfig01
- (NSDictionary *)requestHeaderWithPath:(NSString *)path {
    return @{
        @"userId":@"123456",
        @"Content-Type":@"text/plain"
    };
}
@end

@interface CustomConfig02: GLGlobalNetworkingConfig
@end
@implementation CustomConfig02
- (NSError *)interceptWithURL:(NSString *)url Header:(NSHTTPURLResponse *)header Success:(id)data Failed:(NSError *)error {
    /// Failed to Success
    if(error.code == 401){
        // yeah , i just want Unauthorized. and i want change to request Success
        return nil;
    }
    
    /// Success to failed
    if(((NSData *)data).length < 10240){
        return [NSError errorWithDomain:@"拦截数据，自定义NSError" code:-12345 userInfo:nil];
    }
    
    return nil;
}
@end



@interface GLViewController ()

@end

@interface GLViewController()
{
    UIStackView *stack;
}
@property (nonatomic) NSArray<UIButton *> *buttons;
@end

@implementation GLViewController

- (instancetype)init {
    if((self = [super init])) {
        self.title = @"首页";
        [GLNetworking managerWithConfig:[GLGlobalNetworkingConfig new]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    CGFloat topheight = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    CGRect bound = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        bound.origin.x = bound.origin.x + self.view.safeAreaInsets.left;
        bound.origin.y = bound.origin.y + self.view.safeAreaInsets.top;
        bound.size.width = bound.size.width - bound.origin.x - self.view.safeAreaInsets.right;
        bound.size.height = bound.size.height - bound.origin.y - topheight - self.view.safeAreaInsets.bottom;
    }
    stack = [[UIStackView alloc] initWithFrame:CGRectInset(bound, 20, 20)];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 15;
    stack.alignment = UIStackViewAlignmentFill;
    stack.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:stack];
    
    for (UIButton *button in self.buttons) {
        [stack addArrangedSubview:button];
    }
}

- (UIButton *)createButtonWithTitle:(NSString *)title fontColor:(UIColor *)fcolor backgroundColor:(UIColor *)bgcolor action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 4.f;
    button.titleLabel.numberOfLines = 0;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:fcolor forState:UIControlStateNormal];
    [button setBackgroundColor:bgcolor];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)request_01 {
    [GLNetworking.GET() success:^(NSURLResponse *header, id response) {
        NSLog(@"-- success -->> dataLength:%ld", ((NSData *)response).length);
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"-- error:%@ --", error);
    } complete:^{
        NSLog(@"-- complete --");
    }];
}

- (void)request_02 {
    NSMutableDictionary<NSString *, NSString *> * params = [@{} mutableCopy];
    params[@"wd"] = @"apple";
    NSString *path = @"s";
    [GLNetworking.GET().path(path).params(params) success:^(NSURLResponse *header, id response) {
        NSLog(@"-- success -->> dataLength:%ld", ((NSData *)response).length);
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"-- error:%@ --", error);
    } complete:^{
        NSLog(@"-- complete --");
    }];
}

- (void)request_advanced_01 {
    [GLNetworking.GET().customURL(@"https://home.baidu.com/home/index/contact_us") success:^(NSURLResponse *header, id response) {
        NSLog(@"-- success -->> dataLength:%ld", ((NSData *)response).length);
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"-- error:%@ --", error);
    } complete:^{
        NSLog(@"-- complete --");
    }];
}

- (void)request_advanced_02 {
    [GLNetworking.GET().config([CustomConfig01 new]) success:^(NSURLResponse *header, id response) {
        NSLog(@"-- success -->> dataLength:%ld", ((NSData *)response).length);
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"-- error:%@ --", error);
    } complete:^{
        NSLog(@"-- complete --");
    }];
}

- (void)request_advanced_03 {
    for (int i=0; i<50; i++) {
        [GLNetworking.GET().priority(i%3==0?GLPriorityHigh:GLPriorityLow) success:^(NSURLResponse *header, id response) {
            NSLog(@"-- success -->> 序号i:%d, %@", i, i%3==0?@"[priority:High]":@"[priority:low]");
        } failure:^(NSError *error, NSURLResponse *response, id data) {
            NSLog(@"-- error:%@ --", error);
        } complete:^{
            NSLog(@"-- complete --");
        }];
    }
}
- (void)request_advanced_04 {
    [GLNetworking.GET().config([CustomConfig02 new]) success:^(NSURLResponse *header, id response) {
        NSLog(@"-- success -->> dataLength:%ld", ((NSData *)response).length);
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"-- error:%@ --", error);
    } complete:^{
        NSLog(@"-- complete --");
    }];
}

// MARK: - Lazy property
- (NSArray<UIButton *> *)buttons {
    if(_buttons == nil) {
        _buttons = @[
            [self createButtonWithTitle:@"基本请求 | 无参 ｜ 无路径"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(request_01)],
            [self createButtonWithTitle:@"基本请求 | 有参 ｜ 有路径"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(request_02)],
            [self createButtonWithTitle:@"高级请求 | 临时自定义地址"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(request_advanced_01)],
            [self createButtonWithTitle:@"高级请求 | 自定义请求头"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(request_advanced_02)],
            [self createButtonWithTitle:@"高级请求 | 自定义请求优先级"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(request_advanced_03)],
            [self createButtonWithTitle:@"高级请求 | 返回数据拦截"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(request_advanced_04)]
        ];
    }
    return _buttons;
}

@end
