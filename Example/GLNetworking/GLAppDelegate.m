//
//  GLAppDelegate.m
//  GLNetworking
//
//  Created by 36617161@qq.com on 09/25/2020.
//  Copyright (c) 2020 36617161@qq.com. All rights reserved.
//

#import "GLAppDelegate.h"

@implementation GLAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [[UINavigationController alloc]initWithRootViewController:[WDViewController new]];
    return YES;
}
@end
