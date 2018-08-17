//
//  JZGSpeechRecognitionHelper.m
//  Test
//
//  Created by husj on 2018/8/2.
//  Copyright © 2018年 Beijing JingZhenGu Information Technology Co.Ltd. All rights reserved.
//

#import "JZGSpeechRecognitionHelper.h"

@interface JZGSpeechRecognitionHelper()<IFlySpeechRecognizerDelegate,IFlyRecognizerViewDelegate,IFlyPcmRecorderDelegate>

@property(nonatomic,strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//不带界面的控件
@property(nonatomic,strong) IFlyRecognizerView *iflyRecognizerView;//带界面的控件
@property(nonatomic,strong) IFlyPcmRecorder *pcmRecorder;//PCM Recorder to be used to demonstrate Audio Stream Recognition.
@property(nonatomic,strong) NSString * result;//识别结果
@property(nonatomic,assign) BOOL isCanceled;//是否取消
@property(nonatomic,assign) BOOL isStreamRec;//是否是音频流识别
@property(nonatomic,assign) BOOL isBeginOfSpeech;//Whether or not SDK has invoke the delegate methods of beginOfSpeech.

@property(nonatomic,strong) NSString *textTemp;//语音识别结果文本缓存

@end

@implementation JZGSpeechRecognitionHelper

+(JZGSpeechRecognitionHelper *) sharedInstance{
    static JZGSpeechRecognitionHelper *instance = nil;
    static dispatch_once_t predict;
    dispatch_once(&predict, ^{
        instance = [[JZGSpeechRecognitionHelper alloc] init];
    });
    return instance;
}

#pragma mark - delegate
#pragma mark - IFlySpeechRecognizerDelegate
//识别会话结束返回代理
- (void)onCompleted: (IFlySpeechError *) error{
    NSLog(@"onCompleted识别结果字符串：%@",self.textTemp);
    
    if (IATConfigSington.haveView) {
        [self showTips:NSLocalizedString(@"识别完成", nil)];
        NSLog(@"errorCode:%d",[error errorCode]);
    }else {
        NSString *text ;
        if (self.isCanceled) {
            text = NSLocalizedString(@"识别取消", nil);
        } else if (error.errorCode == 0 ) {
            if (_result.length == 0) {
                text = NSLocalizedString(@"识别无结果", nil);
            }else {
                text = NSLocalizedString(@"识别成功", nil);
                //empty results
                _result = nil;
            }
        }else {
            text = [NSString stringWithFormat:@"错误：%d %@", error.errorCode,error.errorDesc];
            
            if (self.finishASRBlock) {
                self.finishASRBlock(self.textTemp,error);
            }
            return;
        }
        NSLog(@"识别结束: %@",text);
//        [self showTips:text];
    }

    if (self.finishASRBlock) {
        self.finishASRBlock(self.textTemp,nil);
    }
}

//停止录音回调
- (void) onEndOfSpeech{
    NSLog(@"onEndOfSpeech");
    
    [_pcmRecorder stop];
//    [JZGHudManager showTips:NSLocalizedString(@"停止录音", nil)];
}

//开始录音回调
- (void) onBeginOfSpeech{
    NSLog(@"onBeginOfSpeech");
    
    if (self.isStreamRec == NO){
        self.isBeginOfSpeech = YES;
//        [JZGHudManager showTips:NSLocalizedString(@"开始录音", nil)];
    }
}
//音量回调函数
- (void) onVolumeChanged: (int)volume{
    if (self.isCanceled) {
        return;
    }

    if (self.volumeChangedBlock) {
        CGFloat op = volume/30.0;
        self.volumeChangedBlock(op);
    }
}

//会话取消回调
- (void) onCancel{
    NSLog(@"识别取消...");
}

//识别结果返回代理
/**
 result :带界面控件的识别结果
 results:不带界面控件的识别结果集
 isLast :是否是最后一个结果
 **/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    NSLog(@"不带界面控件的识别结果........................");
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    
    _result =[NSString stringWithFormat:@"%@%@", self.textTemp,resultString];
    
    NSString * resultFromJson =  nil;
    if([IATConfig sharedInstance].isTranslate){
        resultFromJson = [self _getTranslateStringWithResultString:resultString];
    }else{
        resultFromJson = [ISRDataHelper stringFromJson:resultString];
    }
    
    self.textTemp = [NSString stringWithFormat:@"%@%@", self.textTemp,resultFromJson];
    
    if (isLast){
        NSLog(@"识别结果集Results(json)：%@",  self.result);
    }
    NSLog(@"_result=%@",_result);
    NSLog(@"识别结果字符串=%@",resultFromJson);
    NSLog(@"isLast=%d,文本框内容=%@",isLast,self.textTemp);
}

#pragma mark - IFlyRecognizerViewDelegate
/*! 回调返回识别结果*/
- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast
{
    NSLog(@"带界面控件的识别结果........................");
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];
    
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    
    NSString * resultFromJson =  nil;
    if([IATConfig sharedInstance].isTranslate){
        resultFromJson = [self _getTranslateStringWithResultString:resultString];
    }else{
        resultFromJson = [NSString stringWithFormat:@"%@",resultString];//;[ISRDataHelper stringFromJson:resultString];
    }
    
    self.textTemp = [NSString stringWithFormat:@"%@%@", self.textTemp,resultFromJson];
}

#pragma mark - IFlyPcmRecorderDelegate
- (void) onIFlyRecorderBuffer: (const void *)buffer bufferSize:(int)size{
    NSData *audioBuffer = [NSData dataWithBytes:buffer length:size];
    
    BOOL ret = [self.iFlySpeechRecognizer writeAudio:audioBuffer];
    if (!ret){
        [self.iFlySpeechRecognizer stopListening];
        //一般后续会设置操作按钮可用：如self.btnSpeech.enabled = YES;
    }
}

- (void) onIFlyRecorderError:(IFlyPcmRecorder*)recoder theError:(int) error{
    
}

//range from 0 to 30
- (void) onIFlyRecorderVolumeChanged:(int) power
{
    NSLog(@"%s,power=%d",__func__,power);
    
    if (self.isCanceled) {
        return;
    }
    
    NSString * vol = [NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"录音音量", nil),power];
    [self showTips:vol];
}

#pragma mark - Public
#pragma mark - 开始语音识别
- (void)beginASR {
    NSLog(@"%s[IN]",__func__);
    //清空textTemp内容
    self.textTemp = @"";
    
    BOOL isBeginASR;
    if (IATConfigSington.haveView) {//带界面的控件
        isBeginASR = [self.iflyRecognizerView start];
    }else {//不带界面的控件
        self.isCanceled = NO;
        self.isStreamRec = NO;
        
        [self.iFlySpeechRecognizer cancel];
        isBeginASR = [self.iFlySpeechRecognizer startListening];
    }
    
    if (isBeginASR) {
        if (self.beginASRBlock) {
            self.beginASRBlock();
        }
    }else{
        //Last session may be not over, recognition not supports concurrent multiplexing.
        if (self.errorInitASRBlock) {
            self.errorInitASRBlock();
        }
    }
}

- (void)beginASRMethod{
    
}

#pragma mark 停止语音识别
- (void) stopASR {
    NSLog(@"%s",__func__);
    
    if(self.isStreamRec && !self.isBeginOfSpeech){
        NSLog(@"%s,stop recording",__func__);
        [_pcmRecorder stop];
    }
    
    [self.iFlySpeechRecognizer stopListening];
}

#pragma mark 取消语音识别
- (void)cancelASR {
    NSLog(@"%s",__func__);
    
    if(self.isStreamRec && !self.isBeginOfSpeech){
        NSLog(@"%s,stop recording",__func__);
        [_pcmRecorder stop];
    }
    
    self.isCanceled = YES;
    
    [self.iFlySpeechRecognizer cancel];
}

#pragma mark 停止所有语音识别组件
- (void) stopAllASRCtrlFunction{
    if ([IATConfig sharedInstance].haveView) {
        [self.iflyRecognizerView cancel];
        [self.iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        self.iflyRecognizerView.delegate = nil;
        self.iflyRecognizerView = nil;
    }else{
        [self.iFlySpeechRecognizer cancel];
        [self.iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        self.iFlySpeechRecognizer.delegate = nil;
        self.iFlySpeechRecognizer = nil;
        
        [self.pcmRecorder stop];
        self.pcmRecorder.delegate = nil;
    }
}

#pragma mark 配置语音识别相关参数
- (void) configASRParams{
    //初始化一些数据
    IATConfig *iatConfig = [IATConfig sharedInstance];
    //是否有界面
    iatConfig.haveView = NO;
    //识别语言：普通话、粤语、四川话、英语
    iatConfig.language = [IFlySpeechConstant LANGUAGE_CHINESE];
    iatConfig.accent = [IFlySpeechConstant ACCENT_MANDARIN];
    //识别结果是否有标点
//    iatConfig.dot = [IFlySpeechConstant ASR_PTT_HAVEDOT];
    iatConfig.dot = [IFlySpeechConstant ASR_PTT_NODOT];
    //是否翻译
    //    iatConfig.isTranslate = YES;
    iatConfig.isTranslate = NO;
    //录音超时：正常语音超时时间：默认30s
    iatConfig.speechTimeout =  @"30000";
    //前端点超时：多久不说话算超时:1~10s,默认5s
    iatConfig.vadBos =   @"5000";
    //后端点超时：说话结束多久没监听到算超时：1~10s，默认1.8s
    iatConfig.vadEos =   @"1800";
    //网络超时时间
    iatConfig.netTimeout = @"20000";
}

#pragma mark 注册语音识别
- (void) registerASR
{
     //注册讯飞语音服务
     NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",kXunFeiASRAppKey];
     [IFlySpeechUtility createUtility:initString];
}

#pragma mark - Private
#pragma mark - 将识别的字符串翻译成需要的字符串
- (NSString *) _getTranslateStringWithResultString:(NSString *) resultString
{
    NSString * resultFromJson =  nil;
    //The result type must be utf8, otherwise an unknown error will happen.
    NSDictionary *resultDic  = [NSJSONSerialization JSONObjectWithData:
                                [resultString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    if(resultDic){
        NSDictionary *trans_result = [resultDic objectForKey:@"trans_result"];
        if([IATConfigSington.language isEqualToString:@"en_us"]){
            NSString *dst = [trans_result objectForKey:@"dst"];
            NSLog(@"dst=%@",dst);
            resultFromJson = [NSString stringWithFormat:@"%@\ndst:%@",resultString,dst];
        }else{
            NSString *src = [trans_result objectForKey:@"src"];
            NSLog(@"src=%@",src);
            resultFromJson = [NSString stringWithFormat:@"%@\nsrc:%@",resultString,src];
        }
    }
    
    return resultFromJson;
}

#pragma mark 根据语言转换
-(void) _translationByLanguage
{
    if([[IATConfig sharedInstance].language isEqualToString:@"en_us"]){
        if([IATConfig sharedInstance].isTranslate){
            [self _translation:NO];
        }
    }else{
        if([IATConfig sharedInstance].isTranslate){
            [self _translation:YES];
        }
    }
}

#pragma mark 根据条件设置参数
-(void) _translation:(BOOL) langIsZh{
    if ([IATConfig sharedInstance].haveView == NO) {
        [_iFlySpeechRecognizer setParameter:@"1" forKey:[IFlySpeechConstant ASR_SCH]];
        
        if(langIsZh){
            [_iFlySpeechRecognizer setParameter:@"cn" forKey:@"orilang"];
            [_iFlySpeechRecognizer setParameter:@"en" forKey:@"translang"];
        }else{
            [_iFlySpeechRecognizer setParameter:@"en" forKey:@"orilang"];
            [_iFlySpeechRecognizer setParameter:@"cn" forKey:@"translang"];
        }
        
        [_iFlySpeechRecognizer setParameter:@"translate" forKey:@"addcap"];
        [_iFlySpeechRecognizer setParameter:@"its" forKey:@"trssrc"];
    }else{
        [_iflyRecognizerView setParameter:@"1" forKey:[IFlySpeechConstant ASR_SCH]];
        
        if(langIsZh){
            [_iflyRecognizerView setParameter:@"cn" forKey:@"orilang"];
            [_iflyRecognizerView setParameter:@"en" forKey:@"translang"];
        }else{
            [_iflyRecognizerView setParameter:@"en" forKey:@"orilang"];
            [_iflyRecognizerView setParameter:@"cn" forKey:@"translang"];
        }
        
        [_iflyRecognizerView setParameter:@"translate" forKey:@"addcap"];
        [_iflyRecognizerView setParameter:@"its" forKey:@"trssrc"];
    }
}

#pragma mark 显示提醒
- (void) showTips:(NSString *) msg
{
}

#pragma mark - getter && setter
#pragma mark -
-(IFlySpeechRecognizer *)iFlySpeechRecognizer
{
    if (!_iFlySpeechRecognizer) {
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        //设置扩展参数
        [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        //设置应用领域
        [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        //设置代理
        _iFlySpeechRecognizer.delegate = self;
        //根据配置设置一些参数
        IATConfig *instance = [IATConfig sharedInstance];
        //设置语音超时时间
        [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        //设置后端点超时时间
        [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        //设置前端点超时时间
        [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        //设置网络超时时间
        [_iFlySpeechRecognizer setParameter:instance.netTimeout forKey:[IFlySpeechConstant NET_TIMEOUT]];
        //设置采样率, 16K as a recommended option
        [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        //设置语言
        [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        //设置语言区域
        [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
        //设置识别结束是否有标点符号
        [_iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];

        //设置麦克风作为音频源
        [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        //设置识别结果数据类型
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        //asr.pcm是录音文件名，设置value为nil或者为空取消保存，默认保存目录在Library/cache下。
//        [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        [_iFlySpeechRecognizer setParameter:nil forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        //设置录音代理
        self.pcmRecorder.delegate = self;

        //根据语言翻译
        [self _translationByLanguage];
    }

    return _iFlySpeechRecognizer;
}

-(IFlyPcmRecorder *)pcmRecorder
{
    if (!_pcmRecorder) {
        _pcmRecorder = [IFlyPcmRecorder sharedInstance];
        [_pcmRecorder setSample:[IATConfig sharedInstance].sampleRate];
        [_pcmRecorder setSaveAudioPath:nil]; //not save the audio file
    }
    return _pcmRecorder;
}

-(IFlyRecognizerView *)iflyRecognizerView
{
    if (!_iflyRecognizerView) {
        //recognition singleton with view
        _iflyRecognizerView= [[IFlyRecognizerView alloc] initWithCenter:kAppKeyWindow.center];
        [_iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        //set recognition domain
        [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        _iflyRecognizerView.delegate = self;
        
        //根据配置设置一些参数
        IATConfig *instance = [IATConfig sharedInstance];
        //set timeout of recording
        [_iflyRecognizerView setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        //set VAD timeout of end of speech(EOS)
        [_iflyRecognizerView setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        //set VAD timeout of beginning of speech(BOS)
        [_iflyRecognizerView setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        //set network timeout
        [_iflyRecognizerView setParameter:instance.netTimeout forKey:[IFlySpeechConstant NET_TIMEOUT]];
        
        //set sample rate, 16K as a recommended option
        [_iflyRecognizerView setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        
        //set language
        [_iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        //set accent
        [_iflyRecognizerView setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
        //set whether or not to show punctuation in recognition results
        [_iflyRecognizerView setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
        
        //Set microphone as audio source
        [_iflyRecognizerView setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        //Set result type
        [_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
        //Set the audio name of saved recording file while is generated in the local storage path of SDK,by default in library/cache.
//        [_iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        [_iFlySpeechRecognizer setParameter:nil forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        [self _translationByLanguage];
    }
    return _iflyRecognizerView;
}


@end
