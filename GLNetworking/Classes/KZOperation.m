//
//  KZOperation.m
//  AFNetworking
//
//  Created by qianye on 2018/6/19.
//

#import "KZOperation.h"

@implementation KZOperation

- (void)main {
    if (self.isCancelled || self.isFinished) return;
    if (self.operationBlock) {
        self.operationBlock();
        self.operationBlock = nil;
    }
}

@end
