import {
    NativeModules
}from 'react-native';
const IFlyRecognizer = NativeModules.IFlyRecognizer;
export default class IFlyRecognizer {
    /**
     * callbake 返回参数类型
     *
     * { msg: '你好像没有说话哦', status: 10118 }
     * { msg: '正确识别内容', status: 200 }
     */
    static startSpeech(callback) {
        IFlyRecognizer.startSpeech(callback)
    }
  
    static stopSpeech() {
        IFlyRecognizer.stopSpeech()
    }
  }