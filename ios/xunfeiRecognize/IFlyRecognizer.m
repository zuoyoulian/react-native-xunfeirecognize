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

@interface IFlyRecognizer()<IFlySpeechRecognizerDelegate,IFlyRecognizerViewDelegate>{
  RCTResponseSenderBlock rctCallBack;
  NSString *strRes;
}
@property (nonatomic, strong) IFlySpeechRecognizer *iflySpeechRecognizer;//不带界面的识别对象
@property (nonatomic, strong) IFlyRecognizerView *iflyRecognizerView;//带界面的识别对象

@property (nonatomic, strong) IFlyPcmRecorder *iflyPcmRecorder;//录音对象
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

RCT_EXPORT_METHOD(startRecognizer:(NSString *)textString callback:(RCTResponseSenderBlock)callback){
  
    if(_iflySpeechRecognizer == nil)
    {
        [self initRecognizer ];
    }
    strRes = textString;
    rctCallBack = callback;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    BOOL ret = [_iflySpeechRecognizer startListening];
    if (ret) {
      NSLog(@"启动语音识别成功");
    }
    else{
  
      NSLog(@"启动语音识别失败");
    }
  });

}

RCT_EXPORT_METHOD(startRecognizerWithView:(NSString *)textString callback:(RCTResponseSenderBlock)callback){
    
    if(_iflyRecognizerView == nil)
    {
        
        [self initRecognizerWithView];
    }
    strRes = textString;
    rctCallBack = callback;
    
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        BOOL ret = [_iflyRecognizerView start];
        if (ret) {
            
            NSLog(@"启动语音识别成功");
        }
        else{
            
            NSLog(@"启动语音识别失败");
        }
    });
    
}


/**
 设置识别参数
 ****/
-(void)initRecognizer
{
    //创建语音识别对象
    _iflySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
    _iflySpeechRecognizer.delegate = self;
    //设置识别参数
    
    //设置为听写模式
    [_iflySpeechRecognizer setParameter: @"iat" forKey: [IFlySpeechConstant IFLY_DOMAIN]];

    //asr_audio_path 是录音文件名，设置value为nil或者为空取消保存，默认保存目录在Library/cache下。
    [_iflySpeechRecognizer setParameter:@"iat.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];

    //设置是否返回标点符号
    [_iflySpeechRecognizer setParameter:0 forKey:[IFlySpeechConstant ASR_PTT]];
}

/**
 有界面，听写结果回调
 resultArray：听写结果
 isLast：表示最后一次
 ****/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
  NSMutableString *result = [[NSMutableString alloc] init];
  NSDictionary *dic = [results objectAtIndex:0];
  
  for (NSString *key in dic) {
  
    [result appendFormat:@"%@",key];
  }
  strRes = [NSString stringWithFormat:@"%@%@",strRes,result];
  NSLog(@"%@",strRes);
  if (isLast) {
    rctCallBack(@[strRes]);
  }
  
}

/**
 设置识别参数
 ****/
-(void)initRecognizerWithView
{
    
    NSLog(@"%s",__func__);
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGSize size = rect.size;
    //单例模式，UI的实例
    if (_iflyRecognizerView == nil) {
        
        //UI显示剧中
        _iflyRecognizerView= [[IFlyRecognizerView alloc] initWithCenter:CGPointMake(size.width / 2, size.height / 2)];
        
        [_iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        
        //设置听写模式
        [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    }
    _iflyRecognizerView.delegate = self;
    
    if (_iflyRecognizerView != nil) {
        
        IATConfig *instance = [IATConfig sharedInstance];
        
        //设置音频来源为麦克风
        [_iflyRecognizerView setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //设置听写结果格式为json
        [_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
        [_iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        //设置最长录音时间
        [_iflyRecognizerView setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        //设置后端点
        [_iflyRecognizerView setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        //设置前端点
        [_iflyRecognizerView setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        //网络等待时间
        [_iflyRecognizerView setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
        
        //设置采样率，推荐使用16K
        [_iflyRecognizerView setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        if ([instance.language isEqualToString:[IATConfig chinese]]) {
            
            //设置语言
            [_iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            //设置方言
            [_iflyRecognizerView setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
        }else if ([instance.language isEqualToString:[IATConfig english]]) {
            
            //设置语言
            [_iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        }
        //设置是否返回标点符号
        [_iflyRecognizerView setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
    }
}

/**
 有界面，听写结果回调
 resultArray：听写结果
 isLast：表示最后一次
 ****/
- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast
{
    
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];
    
    for (NSString *key in dic) {
        
        [result appendFormat:@"%@",key];
    }
    strRes = [NSString stringWithFormat:@"%@%@",strRes,result];
    NSLog(@"%@",strRes);
    if (isLast) {
        rctCallBack(@[strRes]);
    }
    
}

/**
 听写结束回调（注：无论听写是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void) onError:(IFlySpeechError *) error
{
  
  NSLog(@"%s",__func__);
  
  NSLog(@"22222222");
}

//power:0-100,注意控件返回的音频值为0-30
- (void) onIFlyRecorderVolumeChanged:(int) power
{
}


@end
