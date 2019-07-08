//
//  SeminarInfo.h
//  GLNetworking_Example
//
//  Created by liguoliang on 2019/7/8.
//  Copyright © 2019 liandyii@msn.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface File : NSObject
@property (nonatomic, strong) NSString *fileID; //#附件id
@property (nonatomic, strong) NSString *name;   //# 附件名称
@property (nonatomic, strong) NSString *format; //# 附件格式
@property (nonatomic, strong) NSString *size;   //# 附件大小
@property (nonatomic, strong) NSString *address;    //# 附件地址
@end

@interface Person : NSObject
@property (nonatomic, strong) id personId;  //# 主键id
@property (nonatomic, strong) NSString *account;    //# 用户账号
@property (nonatomic, strong) NSString *uname;  //# 用户名称
@property (nonatomic, strong) NSString *type;   //# 用户类型
@property (nonatomic, strong) NSString *orgId;  //# 组织机构id
@property (nonatomic, strong) NSString *orgType;    //# 组织机构类型
@property (nonatomic, strong) NSString *orgCode;    //# 组织机构code
@property (nonatomic, strong) NSString *orgName;    //# 组织机构名称
@property (nonatomic, assign) BOOL ifHost;  //# 是否主持人(0-否1-是)
@property (nonatomic, strong) NSString *state;  //# 状态(0-未到、1-已到)
@end



@interface SeminarInfo : NSObject
@property (nonatomic, strong) NSString *title;  //# 活动标题
@property (nonatomic, strong) NSString *remark; //# 活动说明
@property (nonatomic, strong) NSString *seminarTime;    //# 网络教研活动开始时间 (yyyy-MM-dd HH:mm:ss)
@property (nonatomic, strong) NSString *seminarEndTime; //# 网络教研活动结束时间 (yyyy-MM-dd HH:mm:ss)
@property (nonatomic, strong) NSArray<NSString *> *subject; //# 多学科
@property (nonatomic, assign) BOOL isShare; //# 是否共享附件
@property (nonatomic, strong) NSString *model;  //# 活动模式01-邀请02-公开 03-密钥
@property (nonatomic, strong) NSString *password;   //# 密钥密码
@property (nonatomic, strong) NSArray<NSString *> *tagList;  //# 标签列表
@property (nonatomic, strong) NSString *location;   //# 所在区域
@end

/** http://upyun.bejson.com/bj/imgs/upyun_300.png */
@interface MyImages:NSObject
@property (nonatomic, strong) NSString *name;   //# 图片名称
@property (nonatomic, strong) NSString *format; //# 图片格式
@property (nonatomic, strong) NSString *size;   //# 图片大小
@property (nonatomic, strong) NSString *address;    //# 图片地址
@end
