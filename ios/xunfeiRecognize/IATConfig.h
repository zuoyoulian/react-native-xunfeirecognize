//
//  IATConfig.h
//  MSCDemo_UI
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
/*
 语音识别配置类
 */

#import <Foundation/Foundation.h>

//语音识别单例
#define IATConfigSington  [IATConfig sharedInstance]

@interface IATConfig : NSObject

+(IATConfig *)sharedInstance;


+(NSString *)mandarin;
+(NSString *)cantonese;
+(NSString *)sichuanese;
+(NSString *)chinese;
+(NSString *)english;
+(NSString *)lowSampleRate;
+(NSString *)highSampleRate;
+(NSString *)isDot;
+(NSString *)noDot;

@property (nonatomic, strong) NSString *speechTimeout;//语音识别超时时间
@property (nonatomic, strong) NSString *vadEos;//后端点超时
@property (nonatomic, strong) NSString *vadBos;//前端点超时
@property (nonatomic, strong) NSString *netTimeout;//网络超时时间

@property (nonatomic, strong) NSString *language;//语言
@property (nonatomic, strong) NSString *accent;//语言区域

@property (nonatomic, strong) NSString *dot;//识别结果是否有标点符合
@property (nonatomic, strong) NSString *sampleRate;//合成、识别、唤醒、评测、声纹等业务采样率

@property (nonatomic) BOOL  isTranslate;//是否打开翻译

@property (nonatomic, assign) BOOL haveView;//是否使用有界面控件
@property (nonatomic, strong) NSArray *accentIdentifer;
@property (nonatomic, strong) NSArray *accentNickName;

@end
