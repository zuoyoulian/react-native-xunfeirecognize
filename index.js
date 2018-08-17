import {
    NativeModules
}from 'react-native';
const IFlyRecognizerz = NativeModules.IFlyRecognizer;
export default class IFlyRecognizer {
    /**
     * callbake 返回参数类型
     *
     * { msg: '你好像没有说话哦', status: 10118 }
     * { msg: '正确识别内容', status: 200 }
     */
    static startSpeech(callback) {
        IFlyRecognizerz.startSpeech(callback)
    }
  
    static stopSpeech() {
        IFlyRecognizerz.stopSpeech()
    }
  }