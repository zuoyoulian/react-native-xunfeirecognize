//
//  LocationModule.m
//  JZGProfessional_App_ReactNative
//
//  Created by bufb on 2018/7/27.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "JZGASRModule.h"
#import "JZGSpeechRecognitionHelper.h"

@interface JZGASRModule ()

@end

@implementation JZGASRModule

RCT_EXPORT_MODULE(MscSpeechModule);

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
