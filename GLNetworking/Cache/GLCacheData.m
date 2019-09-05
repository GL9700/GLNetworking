//
//  GLCacheData.m
//  GLNetworking
//
//  Created by liguoliang on 2019/2/11.
//

#import "GLCacheData.h"

@implementation GLCacheData
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.data forKey:NSStringFromSelector(@selector(data))];
    [aCoder encodeObject:self.response forKey:NSStringFromSelector(@selector(response))];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if((self = [super init])){
        self.data = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(data))];
        self.response = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(response))];
    }
    return self;
}
@end
