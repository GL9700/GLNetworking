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



@interface CustomConfig03:NSObject <GLNetworkPotocol>

@end
    
@implementation CustomConfig03
- (NSString *)requestHost {
    return @"https://www.amazon.com";
}
- (NSDictionary *)requestHeaderWithPath:(NSString *)path {
    return @{
        @"pageNum":@"1",
        @"pageSize":@"2"
    };
}
@end


// MARK: - 自定义config，继承自globalConfig
@interface CustomConfig01: GLGlobalNetworkingConfig
@end
@implementation CustomConfig01
- (NSDictionary *)requestHeaderWithPath:(NSString *)path {
    return @{
        @"actor":@"46",
        @"branch":@"1",
        @"organ":@"1",
        @"token":@"606DF0B47240A7C1A681495549928221-1"
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
//        [GLNetworking managerWithConfig:[GLGlobalNetworkingConfig new]];
        [GLNetworking managerWithConfig:[CustomConfig03 new]];
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
    [GLNetworking.HEAD().customURL(@"http://header.json-json.com/") success:^(NSURLResponse *header, id response) {
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

- (void)req_test_01 {
    for(int i=0;i<500;i++){
        NSArray* confs = @[[CustomConfig01 new], [CustomConfig02 new], [CustomConfig03 new]];
        int useConfIndex = random()%3;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"增加请求%d", i);
            [GLNetworking.POST().path(@"train/v1/train/student/trainList").params(@{@"pageNum":@"1",@"pageSize":@"2"}).config(confs[useConfIndex]) success:^(NSURLResponse *header, id response) {
                NSLog(@"--suc--");
            } failure:^(NSError *error, NSURLResponse *response, id data) {
                NSLog(@"--fad--");
            } complete:^{
                NSLog(@"--cpt-%d-useConfig:%d", i, useConfIndex);
            }];
        });
    }
    NSLog(@"增加");
}
- (void)req_test_02 {
    [GLNetworking.GET().path(@"usercenter/v1/user/findUserOrganList") success:^(NSURLResponse *header, id response) {
        NSLog(@"--suc--");
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"--fad--");
    } complete:^{
        NSLog(@"--cpt--");
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
                                 action:@selector(request_advanced_04)],
            [self createButtonWithTitle:@"回溯崩溃数据请求01x10"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(req_test_01)],
            [self createButtonWithTitle:@"回溯崩溃数据请求02x30"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(req_test_02)]
        ];
    }
    return _buttons;
}

@end
