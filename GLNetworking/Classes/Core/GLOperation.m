//
//  GLOperation.m
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import "GLOperation.h"

@implementation GLOperation

- (void)main {
    if (self.isCancelled || self.isFinished) return;
    if (self.operationBlock) {
        self.operationBlock();
        self.operationBlock = nil;
    }
}

@end
