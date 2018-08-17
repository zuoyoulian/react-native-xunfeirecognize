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
        [self startASRSpeech:callback];
    });
}

RCT_EXPORT_METHOD(stopSpeech)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopASRSpeech];
    });
}

- (void)startASRSpeech:(RCTResponseSenderBlock)getLocal{
    [JZGSpeechRecognitionHelperSington configASRParams];
    [JZGSpeechRecognitionHelperSington beginASR];
    //初始化错误
    JZGSpeechRecognitionHelperSington.errorInitASRBlock = ^{
    };
    //识别结果
    JZGSpeechRecognitionHelperSington.finishASRBlock = ^(NSString *strResult,IFlySpeechError *error) {
        if (error) {
            NSDictionary *result = @{
                                     @"status":@(error.errorCode),
                                     @"msg": error.errorDesc,
                                     };
            getLocal(@[result]);
        } else {
            NSDictionary *result = @{
                                     @"status": @"200",
                                     @"msg": strResult,
                                     };
            getLocal(@[result]);
        }
    };
}

- (void)stopASRSpeech{
    [JZGSpeechRecognitionHelperSington stopASR];
}

@end
