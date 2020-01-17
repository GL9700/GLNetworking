//
//  GLOperation.h
//  GLNetworking
//
//  Created by liguoliang on 2018/8/23.
//

#import <Foundation/Foundation.h>

typedef void (^GLNetworkOperationBlock)(void);

@interface GLOperation : NSOperation
@property (nonatomic, copy) GLNetworkOperationBlock operationBlock;
@end
