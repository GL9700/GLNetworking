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
#import <GLRequest.h>



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

- (void)request_group_01 {
    [GLNetworking.GROUP().requests(@[
        GLNetworking.GET().customURL(@"https://home.baidu.com/home/index/contact_us"),
        GLNetworking.GET(),
        GLNetworking.GET().customURL(@"https://www.apple.com")
                                   ])
     success:^(NSURLResponse *header, id response) {
        NSLog(@"--request_group_01 suc--");
        
    } failure:^(NSError *error, NSURLResponse *response, id data) {
        NSLog(@"--request_group_01 fad--");
        
    } complete:^{
        NSLog(@"--request_group_01 cmp--");
        
    }];
}
- (void)request_group_02 {
    NSLog(@"-- will start [request_group_02] --");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        GLNetworking.GROUP().next(^(NSURLResponse *header, id resp, NSError *error, NSString **gotoIdentify) {
            NSLog(@"-- 构建请求-1 --");
            return GLNetworking.GET().customURL(@"https://finance.china.com/industrial/11173306/20210204/37249139.html");
            
        }).nextIdentify(@"r2").next(^(NSURLResponse *header, id resp, NSError *error, NSString **gotoIdentify) {
            NSLog(@"-- 接收请求结果-1 (length: %lu)-- 构建请求-2 --", (unsigned long)((NSData *)resp).length);
            return GLNetworking.GET().customURL(@"https://finance.china.com/stock/13003071/20210204/37249142.html");
            
        }).nextIdentify(@"r3").next(^(NSURLResponse *header, id resp, NSError *error, NSString **gotoIdentify) {
            NSLog(@"-- 接收请求结果-2 (length: %lu)-- 构建请求-3 --", (unsigned long)((NSData *)resp).length);
            *gotoIdentify = @"r6";
            return GLNetworking.GET().customURL(@"https://finance.china.com/consume/11173302/20210204/37249150.html");
            
        }).nextIdentify(@"r4").next(^(NSURLResponse *header, id resp, NSError *error, NSString **gotoIdentify) {
            NSLog(@"-- 接收请求结果-3 (length: %lu)-- 构建请求-4 --", (unsigned long)((NSData *)resp).length);
            return GLNetworking.GET().customURL(@"https://finance.china.com/tech/13001906/20210204/37249143.html");
            
        }).nextIdentify(@"r5").next(^(NSURLResponse *header, id resp, NSError *error, NSString **gotoIdentify) {
            NSLog(@"-- 接收请求结果-4 (length: %lu)-- 构建请求-5 --", (unsigned long)((NSData *)resp).length);
            return GLNetworking.GET().customURL(@"https://finance.china.com/house/data/37235704.html");
            
        }).nextIdentify(@"r6").next(^(NSURLResponse *header, id resp, NSError *error, NSString **gotoIdentify) {
            NSLog(@"-- 接收请求结果-5 (length: %lu)-- 构建请求-6 --", (unsigned long)((NSData *)resp).length);
            return GLNetworking.GET().customURL(@"https://finance.china.com/insurance/13003065/20210203/37249094.html");
            
        }).nextIdentify(@"final").finally(^(NSURLResponse *header, id resp, NSError *error) {
            NSLog(@"-- 接收请求结果-6 (length: %lu)-- 整体结束 --", (unsigned long)((NSData *)resp).length);
            
        });
    });
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
            [self createButtonWithTitle:@"高级请求 ｜ 组队模式 ｜ 并行"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(request_group_01)],
            [self createButtonWithTitle:@"高级请求 ｜ 组队模式 ｜ 串行"
                              fontColor:[UIColor whiteColor]
                        backgroundColor:[UIColor blueColor]
                                 action:@selector(request_group_02)]
        ];
    }
    return _buttons;
}

@end
