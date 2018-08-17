1、yarn add react-native-xunfeirecognize --save
2、react-native link react-native-xunfeirecognize

3、link之后Android的可以直接使用，iOS功能需要添加iflyMSC.framework到主工程，并设置主工程的

//:configuration = Release
FRAMEWORK_SEARCH_PATHS = $(inherited) $(SRCROOT)/../node_modules/react-native-xunfeirecognize/ios/xunfeiRecognize/**


库名称	添加范围	功能      

iflyMSC.framework	必要	讯飞开放平台静态库。

libz.tbd	必要	用于压缩、加密算法。

AVFoundation.framework	必要	用于系统录音和播放 。

SystemConfiguration.framework	系统库	用于系统设置。

Foundation.framework	必要	基本库。

CoreTelephoney.framework	必要	用于电话相关操作。

AudioToolbox.framework	必要	用于系统录音和播放。

UIKit.framework	必要	用于界面显示。

CoreLocation.framework	必要	用于定位。

Contacts.framework	必要	用于联系人。

AddressBook.framework	必要	用于联系人。

QuartzCore.framework	必要	用于界面显示。

CoreGraphics.framework	必要	用于界面显示。

libc++.tbd	离线识别，Aiui必要	用于支持C++。

Libicucore.tbd	Aiui必要	系统正则库。