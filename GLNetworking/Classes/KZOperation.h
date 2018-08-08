//
//  KZOperation.h
//  AFNetworking
//
//  Created by qianye on 2018/6/19.
//

#import <Foundation/Foundation.h>

typedef void (^KZNetworkOperationBlock)(void);

@interface KZOperation : NSOperation

@property (nonatomic, copy) KZNetworkOperationBlock operationBlock;

@end
