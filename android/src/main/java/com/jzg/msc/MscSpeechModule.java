package com.jzg.msc;

import android.os.Bundle;
import android.os.Environment;
import android.text.TextUtils;
import android.util.Log;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.iflytek.cloud.ErrorCode;
import com.iflytek.cloud.InitListener;
import com.iflytek.cloud.RecognizerListener;
import com.iflytek.cloud.RecognizerResult;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechRecognizer;
import com.iflytek.cloud.SpeechUtility;
import java.util.HashMap;
import java.util.LinkedHashMap;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by admin on 2018/8/16.
 */


public class MscSpeechModule extends ReactContextBaseJavaModule {

  private static final String TAG = "IFlyRecognizer";
  private Callback callback;
  private SpeechRecognizer recognizer;
  // 引擎类型
  private String mEngineType = SpeechConstant.TYPE_CLOUD;
  private static final String TIMEOUT = "30000";
  int errorCode = 0; // 函数调用返回值
  // 用HashMap存储听写结果
  private HashMap<String, String> mIatResults = new LinkedHashMap<>();

  private String speechConent = "";//识别内容

  public MscSpeechModule(ReactApplicationContext reactContext) {
    super(reactContext);
    init(reactContext);
  }

  @Override
  public String getName() {
    return TAG;
  }

  private void init(ReactApplicationContext reactContext) {
    SpeechUtility.createUtility(reactContext, SpeechConstant.APPID + "=5b74ecd8");
    recognizer = SpeechRecognizer.createRecognizer(reactContext, mInitListener);

  }

  @ReactMethod
  public void startSpeech(Callback callback) {
    this.callback = callback;
    mIatResults.clear();
    setParam();
    errorCode = recognizer.startListening(mRecognizerListener);
    if (errorCode != ErrorCode.SUCCESS) {
      Log.i(TAG, "听写失败,错误码：" + errorCode);
//      WritableMap map = Arguments.createMap();
//      map.putInt("status", errorCode);
//      map.putString("msg", "听写失败");
//      callback.invoke(map);
      stopSpeech(errorCode, "听写失败");
    }

  }


  @ReactMethod
  public void stopSpeech() {
//    stopSpeech(200,speechConent);
    if (recognizer != null && recognizer.isListening()) {
      recognizer.stopListening();
    }
  }

  private void stopSpeech(int errorCode, String msg) {
    if (recognizer != null && recognizer.isListening()) {
      recognizer.stopListening();
    }
    WritableMap map = Arguments.createMap();
    if(TextUtils.isEmpty((msg))){
      map.putInt("status", 30001);
      map.putString("msg", "您好像没有说话额");
    }else {
      map.putInt("status", errorCode);
      map.putString("msg", msg);
    }
    callback.invoke(map);
  }


  private void setParam() {
    // 清空参数
    recognizer.setParameter(SpeechConstant.PARAMS, null);

    // 设置听写引擎
    recognizer.setParameter(SpeechConstant.ENGINE_TYPE, mEngineType);
    // 设置返回结果格式
    recognizer.setParameter(SpeechConstant.RESULT_TYPE, "json");

    // 设置语言
    recognizer.setParameter(SpeechConstant.LANGUAGE, "zh_cn");
    // 设置语言区域
    recognizer.setParameter(SpeechConstant.ACCENT, "mandarin");

    // 设置语音前端点:静音超时时间，即用户多长时间不说话则当做超时处理
    recognizer.setParameter(SpeechConstant.VAD_BOS, "5000");

    // 设置语音后端点:后端点静音检测时间，即用户停止说话多长时间内即认为不再输入， 自动停止录音
    recognizer.setParameter(SpeechConstant.VAD_EOS, "1800");

    // 设置标点符号,设置为"0"返回结果无标点,设置为"1"返回结果有标点
    recognizer.setParameter(SpeechConstant.ASR_PTT, "0");
    //设置语音识别超时
    recognizer.setParameter(SpeechConstant.KEY_SPEECH_TIMEOUT, TIMEOUT);

    // 设置音频保存路径，保存音频格式支持pcm、wav，设置路径为sd卡请注意WRITE_EXTERNAL_STORAGE权限
    // 注：AUDIO_FORMAT参数语记需要更新版本才能生效
    recognizer.setParameter(SpeechConstant.AUDIO_FORMAT, "wav");
    recognizer.setParameter(SpeechConstant.ASR_AUDIO_PATH,
        Environment.getExternalStorageDirectory() + "/msc/iat.wav");
  }


  /**
   * 初始化监听器。
   */
  private InitListener mInitListener = new InitListener() {

    @Override
    public void onInit(int code) {
      if (code == ErrorCode.SUCCESS) {
        Log.i(TAG, "onInit: 讯飞语音初始化完成");
      }
    }
  };

  /**
   * 听写监听器。
   */
  private RecognizerListener mRecognizerListener = new RecognizerListener() {
    @Override
    public void onBeginOfSpeech() {// 此回调表示：sdk内部录音机已经准备好了，用户可以开始语音输入
      Log.i(TAG, "开始说话");
    }

    @Override
    public void onError(SpeechError error) {
      // Tips： 错误码：10118(您没有说话)，可能是录音机权限被禁，需要提示用户打开应用的录音权限。
//      WritableMap map = Arguments.createMap();
      String msg;

      int errorCode = error.getErrorCode();

      if (error.getErrorCode() == 10118) {
        msg = "你好像没有说话哦";
        Log.i(TAG, "你好像没有说话哦");
      } else if (error.getErrorCode() == 20001) {
        msg = "网络不给力，请检查网络连接";
        Log.i(TAG, "网络不给力，请检查网络连接");
      } else if (error.getErrorCode() == 20006) {
        msg = "此功能需要开启【麦克风】授权，请在【设置】中开启【麦克风】的权限";
        errorCode = 30002;
      } else {
        msg = error.getPlainDescription(true);
        Log.i(TAG, error.getPlainDescription(true));
      }
      Log.i(TAG, "SpeechError:" + errorCode);

//      map.putInt("status", error.getErrorCode());
//      map.putString("msg", msg);

//      callback.invoke(map);
      stopSpeech(errorCode, msg);
    }

    @Override
    public void onEndOfSpeech() { // 此回调表示：检测到了语音的尾端点，已经进入识别过程，不再接受语音输入
      Log.i(TAG, "结束说话");
    }

    @Override
    public void onResult(RecognizerResult results, boolean isLast) {
      Log.i(TAG, "isLast:" + isLast);
      printResult(results);
      if (isLast) {
//        WritableMap map = Arguments.createMap();
//        map.putInt("status", 200);
//        map.putString("msg", speechConent);
//        callback.invoke(map);
        Log.i(TAG, "结束了");
        stopSpeech(200, speechConent);
      }
    }

    @Override
    public void onVolumeChanged(int volume, byte[] data) {
//            MyToast.showLong("当前正在说话，音量大小：" + volume);
//            Log.e(TAG, "返回音频数据："+data.length);
    }

    @Override
    public void onEvent(int eventType, int arg1, int arg2, Bundle obj) {
      Log.i(TAG, "onEvent：eventType=" + eventType);
    }
  };

  private void printResult(RecognizerResult results) {
    String text = JsonParser.parseIatResult(results.getResultString());
    String sn = null;
    try {
      JSONObject resultJson = new JSONObject(results.getResultString());
      sn = resultJson.optString("sn");
    } catch (JSONException e) {
      e.printStackTrace();
    }
    mIatResults.put(sn, text);
    StringBuffer resultBuffer = new StringBuffer();
    for (String key : mIatResults.keySet()) {
      resultBuffer.append(mIatResults.get(key));
    }
    speechConent = resultBuffer.toString();
    Log.i(TAG, "识别内容 = " + speechConent);
  }
}
