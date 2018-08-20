//
//  JZGSystemResource.m
//  JZGDetectionPlatform
//
//  Created by cuik on 16/3/30.
//  Copyright © 2016年 Mars. All rights reserved.
//

#import "JZGSystemResource.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import "NSInvocation+JZGAdd.h"
#import <UIKit/UIKit.h>

#define kSystemVersion          ([[[UIDevice currentDevice] systemVersion] floatValue])
#define iOS6                    ((kSystemVersion >= 6.0) ? YES : NO)
#define iOS7                    ((kSystemVersion >= 7.0) ? YES : NO)
#define iOS8                    ((kSystemVersion >= 8.0) ? YES : NO)
#define iOS9                    ((kSystemVersion >= 9.0) ? YES : NO)
#define iOS10                   ((kSystemVersion >= 10.0) ? YES : NO)
#define iOS10_3                 ((kSystemVersion >= 10.3) ? YES : NO)

@implementation JZGSystemResource

+ (instancetype)share{
    static dispatch_once_t t;
    static JZGSystemResource *service = nil;
    dispatch_once(&t, ^{
        service = [[JZGSystemResource alloc] init];
    });
    return service;
}

+ (BOOL)isAlowPosition;{
    return ([CLLocationManager locationServicesEnabled]
            && ( kCLAuthorizationStatusDenied !=  [CLLocationManager authorizationStatus]));
}

+ (BOOL)isAllowAccessCamera{
    AVAuthorizationStatus AVStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (AVStatus == AVAuthorizationStatusAuthorized) {
        return YES;
    }
    return NO;
}

+ (BOOL)isAllowAccessPhotos{
    ALAuthorizationStatus ALStatus = [ALAssetsLibrary authorizationStatus];
    if (ALStatus == ALAuthorizationStatusAuthorized) {
        return YES;
    }
    return NO;
}

+ (BOOL)isAllowAccessMicrophone{
    __block BOOL bCanRecord = NO;
    if (iOS7) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                }else {
                    bCanRecord = NO;
                }
            }];
        }
    }
    return bCanRecord;
}

+ (BOOL)isAllowAccessTelephone{
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPod touch"]
       || [deviceType isEqualToString:@"iPad"]
       || [deviceType isEqualToString:@"iPhone Simulator"]){
        return NO;
    }
    return YES;
}

/**
 *  2016年09月03日 add by 胡仕君： 处理调用相机
 *
 *  @param target   响应方法的界面
 *  @param selector 允许使用相机资源后调用的方法
 */
- (void)handleAccessCameraWithTarget:(id) target selecter:(SEL)selector
{
    NSInvocation *invocation = [NSInvocation invocationWithTarget:target selector:selector];
    [[JZGSystemResource share] handleAccessCamera:invocation];
}

/**
 *  2016年09月03日 add by 胡仕君： 处理调用相册
 *
 *  @param target   响应方法的界面
 *  @param selector 允许使用相册资源后调用的方法
 */
- (void)handleAccessPhotosWithTarget:(id) target selecter:(SEL)selector
{
    NSInvocation *invocation = [NSInvocation invocationWithTarget:target selector:selector];
    [[JZGSystemResource share] handleAccessPhotos:invocation];
}

/**
 2016年09月19日 add by 胡仕君：处理调用麦克风
 
 @param target   响应方法的界面
 @param selector 允许使用麦克风资源后调用的方法
 */
- (void)handleAccessMicrophoneWithTarget:(id) target selecter:(SEL)selector
{
    NSInvocation *invocation = [NSInvocation invocationWithTarget:target selector:selector];
    [[JZGSystemResource share] handleAccessMicrophone:invocation];
}

- (void)handleAccessCamera:(NSInvocation *)allowInvocation
{
    if ([[self class] isAllowAccessCamera])
    {
        [allowInvocation invoke];
        return;
    }

    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    NSString *promtpMessage = [NSString stringWithFormat:@"【%@】需要打开您的【相机】权限",kAppName];

    if(status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted){
        [self showAlertWithMsg:promtpMessage];
    }
    
    if(status == AVAuthorizationStatusNotDetermined)
    {
        
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted)
         {
             
             BOOL isMain = [[NSThread currentThread] isMainThread];
             if (isMain)
             {
                 if(granted)
                 {
                     [allowInvocation invoke];
                 } else {
                     [self showAlertWithMsg:promtpMessage];
                 }
             }else{
                 dispatch_sync(dispatch_get_main_queue(), ^{
                     if(granted)
                     {
                         [allowInvocation invoke];
                     } else {
                         [self showAlertWithMsg:promtpMessage];
                     }
                 });
             }
         }];
    }
}

- (void)handleAccessPhotos:(NSInvocation *)allowInvocation{
    if ([[self class] isAllowAccessPhotos])
    {
        [allowInvocation invoke];
        return;
    }
    
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusNotDetermined) {
        [allowInvocation invoke];
        return;
    }
    
    NSString *promtpMessage = [NSString stringWithFormat:@"【%@】需要打开您的【照片】权限",kAppName];
    [self showAlertWithMsg:promtpMessage];
}

- (void)handleAccessMicrophone:(NSInvocation *)allowInvocation{
    if ([[self class] isAllowAccessMicrophone])
    {
        [allowInvocation invoke];
        return;
    }

    NSString *promtpMessage = [NSString stringWithFormat:@"【%@】需要打开您的【麦克风】权限",kAppName];
    [self showAlertWithMsg:promtpMessage];
}

#pragma mark - 显示提示消息
- (void) showAlertWithMsg:(NSString *) msg
{
  UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"提示"
                                                   message:msg
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:@"去设置",nil];
  [alert show];
}
                         
#pragma mark - <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
