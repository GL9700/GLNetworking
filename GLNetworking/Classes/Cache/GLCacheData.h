//
//  GLCacheData.h
//  GLNetworking
//
//  Created by liguoliang on 2019/2/11.
//

#import <Foundation/Foundation.h>

@interface GLCacheData : NSObject <NSCoding>
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) id data;
@end
