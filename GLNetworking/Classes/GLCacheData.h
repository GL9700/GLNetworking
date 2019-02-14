//
//  GLCacheData.h
//  GLNetworking
//
//  Created by liguoliang on 2019/2/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface GLCacheData : NSObject <NSCoding>
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) id data;
@end
NS_ASSUME_NONNULL_END
