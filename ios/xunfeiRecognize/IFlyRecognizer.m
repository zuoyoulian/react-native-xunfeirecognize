//
//  IFlyRecognizer.m
//  eSafety
//
//  Created by Robin on 16/11/18.
//  Copyright © 2016年 Facebook. All rights reserved.
//

#import "IFlyRecognizer.h"
#import "IATConfig.h"
#import "JZGSpeechRecognitionHelper.h"

@interface IFlyRecognizer(){
}

@property(nonatomic, copy)RCTResponseSenderBlock getLocal;

@end

@implementation IFlyRecognizer
RCT_EXPORT_MODULE()

-(instancetype)init{
    if (self = [super init]) {
      //Appid是应用的身份信息，具有唯一性，初始化时必须要传入Appid。
      NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", @"59db28be"];
      [IFlySpeechUtility createUtility:initString];
    }
    return self;
}

/**
 *  向RN暴露接口
 *
 *  返回值：
 *  @[@{
 @"status":@“”,//科大讯飞错误码或200
 @"msg": @"",//科大讯飞错误原因或识别出的文字
 }]
 */
RCT_EXPORT_METHOD(startSpeech:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.getLocal = callback;
        [self openAccessMicrophone];
    });
}

RCT_EXPORT_METHOD(stopSpeech)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopASRSpeech];
    });
}

- (void)openAccessMicrophone{
    [[JZGSystemResource share] handleAccessMicrophoneWithTarget:self selecter:@selector(startASRSpeech)];
    if (![JZGSystemResource isAllowAccessMicrophone]) {
        NSDictionary *result = @{
                                 @"status": @"30002",
                                 @"msg": [NSString stringWithFormat:@"此功能需要开启【麦克风】授权，请在【设置-隐私-麦克风】中开启【%@】的权限",kAppName],
                                 };
        self.getLocal(@[result]);
    }
}

- (void)startASRSpeech{
    [JZGSpeechRecognitionHelperSington configASRParams];
    [JZGSpeechRecognitionHelperSington beginASR];
    //初始化错误
    JZGSpeechRecognitionHelperSington.errorInitASRBlock = ^{
        //科大讯飞初始化遇到问题
        NSDictionary *result = @{
                                 @"status":@"30003",
                                 @"msg": @"",
                                 };
        self.getLocal(@[result]);
    };
    //识别结果
    JZGSpeechRecognitionHelperSington.finishASRBlock = ^(NSString *strResult,IFlySpeechError *error) {
        if (error) {
            if (error.errorCode == 20001) {
                NSDictionary *result = @{
                                         @"status":@(error.errorCode),
                                         @"msg": @"网络不给力，请检查网络连接",
                                         };
                self.getLocal(@[result]);
                return;
            }
            NSDictionary *result = @{
                                     @"status":@(error.errorCode),
                                     @"msg": error.errorDesc,
                                     };
            self.getLocal(@[result]);
        } else {
            if (strResult && strResult.length) {
                NSDictionary *result = @{
                                         @"status": @"200",
                                         @"msg": strResult,
                                         };
                self.getLocal(@[result]);
                return;
            }
            NSDictionary *result = @{
                                     @"status": @"30001",
                                     @"msg": @"您好像没有说话额",
                                     };
            self.getLocal(@[result]);
        }
    };
}

- (void)stopASRSpeech{
    [JZGSpeechRecognitionHelperSington stopASR];
}

@end
