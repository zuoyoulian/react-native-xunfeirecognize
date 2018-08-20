//
//  JZGSpeechRecognitionHelper.h
//  Test
//
//  Created by husj on 2018/8/2.
//  Copyright © 2018年 Beijing JingZhenGu Information Technology Co.Ltd. All rights reserved.
/*
 语音识别帮助类
 */

#import <Foundation/Foundation.h>
#import "IATConfig.h"
#import "IFlyMSC/IFlyMSC.h"
#import "ISRDataHelper.h"
#import "JZGSystemResource.h"

//语音识别初始化错误block
typedef void(^JZGASRInitErrorBlock)(void);
//语音识别开始block
typedef void(^JZGASRBeginBlock)(void);
//语音识别结束block
typedef void(^JZGASRFinishBlock)(NSString *strResult,IFlySpeechError *error);
//音量回调block
typedef void(^JZGASRVolumeChangedBlock)(int volume);


//语音识别单例
#define JZGSpeechRecognitionHelperSington  [JZGSpeechRecognitionHelper sharedInstance]
#define kAppKeyWindow               ([UIApplication sharedApplication].keyWindow)

@interface JZGSpeechRecognitionHelper : NSObject

//相关事件：
@property(nonatomic,copy) JZGASRInitErrorBlock errorInitASRBlock;//语音识别初始化
@property(nonatomic,copy) JZGASRBeginBlock beginASRBlock;//识别开始
@property(nonatomic,copy) JZGASRFinishBlock finishASRBlock;//识别结束
@property(nonatomic,copy) JZGASRVolumeChangedBlock volumeChangedBlock;//音量改变

/**
 单例方法

 @return 唯一的示例对象
 */
+(JZGSpeechRecognitionHelper *) sharedInstance;

/**
 配置语音识别相关参数
 */
- (void) configASRParams;

/**
 开始语音识别：
 */
- (void)beginASR;

/**
 停止语音识别：停止后有结果
 */
- (void) stopASR;

/**
 取消语音识别：取消后没有结果
 */
- (void)cancelASR;

/**
 停止所有语音识别组件功能:一般在控制器消失的时候调用
 */
- (void) stopAllASRCtrlFunction;


@end
