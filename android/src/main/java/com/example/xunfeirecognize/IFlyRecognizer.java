package com.example.xunfeirecognize;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.iflytek.cloud.ErrorCode;
import com.iflytek.cloud.InitListener;
import com.iflytek.cloud.RecognizerListener;
import com.iflytek.cloud.RecognizerResult;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechRecognizer;
import com.iflytek.cloud.SpeechUtility;
import com.iflytek.cloud.ui.RecognizerDialog;

import com.iflytek.cloud.ui.RecognizerDialogListener;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.util.HashMap;
import java.util.LinkedHashMap;

/**
 * Created by robin on 16/11/18.
 */
public class IFlyRecognizer extends ReactContextBaseJavaModule {
    SpeechRecognizer mAsr;
    Callback rctCallback;
    String originRes;
    String finalRes;
    private SharedPreferences mSharedPreferences;
    private ReactApplicationContext mReactContext;
    private static String TAG = IFlyRecognizer.class.getSimpleName();

    private HashMap<String, String> mIatResults = new LinkedHashMap<String, String>();
    public IFlyRecognizer(ReactApplicationContext reactContext) {
        super(reactContext);
        mReactContext = reactContext;
        SpeechUtility.createUtility(reactContext, SpeechConstant.APPID +"=59db28ec");
    }

    @Override
    public String getName() {
        return "IFlyRecognizer";
    }

    /**
     * 初始化监听器。
     */
    private InitListener mInitListener = new InitListener() {

        @Override
        public void onInit(int code) {
            Log.d("123", "SpeechRecognizer init() code = " + code);
            if (code != ErrorCode.SUCCESS) {
                Log.d("123", "初始化失败，错误码：" + code);
            }
        }
    };

    private RecognizerListener mRecognizerListener = new RecognizerListener() {

        @Override
        public void onVolumeChanged(int volume, byte[] data) {
            Log.d(TAG, "返回音频数据："+data.length);
        }

        @Override
        public void onResult(final RecognizerResult result, boolean isLast) {
            if (null != result) {
                Log.d(TAG, "recognizer result：" + result.getResultString());
                if (isLast){
                    String text = JsonParser.parseGrammarResult(result.getResultString());
                    rctCallback.invoke(originRes + text);
                }

            } else {
                Log.d(TAG, "recognizer result : null");
            }
        }

        @Override
        public void onEndOfSpeech() {
            // 此回调表示：检测到了语音的尾端点，已经进入识别过程，不再接受语音输入
        }

        @Override
        public void onBeginOfSpeech() {
            // 此回调表示：sdk内部录音机已经准备好了，用户可以开始语音输入
        }

        @Override
        public void onError(SpeechError error) {
        }

        @Override
        public void onEvent(int eventType, int arg1, int arg2, Bundle obj) {
            // 以下代码用于获取与云端的会话id，当业务出错时将会话id提供给技术支持人员，可用于查询会话日志，定位出错原因
            // 若使用本地能力，会话id为null
            //	if (SpeechEvent.EVENT_SESSION_ID == eventType) {
            //		String sid = obj.getString(SpeechEvent.KEY_EVENT_SESSION_ID);
            //		Log.d(TAG, "session id =" + sid);
            //	}
        }

    };


    @ReactMethod
    public void startRecognizer(String textString ,final Callback successCallback){
        rctCallback = successCallback;
        originRes = textString;

        // 初始化识别对象
        mAsr = SpeechRecognizer.createRecognizer(mReactContext, mInitListener);
        mAsr.setParameter( SpeechConstant.CLOUD_GRAMMAR, null );
        mAsr.setParameter( SpeechConstant.SUBJECT, null );
        mAsr.setParameter(SpeechConstant.ASR_PTT,"0");

        mAsr.startListening(mRecognizerListener);
    }

    @ReactMethod
    public void startRecognizerWithView(String textString ,final Callback successCallback){


        rctCallback = successCallback;
        originRes = textString;

        Handler mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                // 已在主线程中，可以更新UI
                Log.d("123", "run:主线程中，可以更新UI ");
                RecognizerDialog iatDialog = new RecognizerDialog(getCurrentActivity(),mInitListener);
                //2.设置听写参数，同上节
                iatDialog.setParameter(SpeechConstant.LANGUAGE, "zh_cn");
                iatDialog.setParameter(SpeechConstant.ACCENT, "mandarin");
                //3.设置回调接口
                iatDialog.setListener(recognizerDialogListener);
                iatDialog.setParameter(SpeechConstant.ASR_PTT,"0");
                //4.开始听写
                iatDialog.show();
            }
        });

    }

    private RecognizerDialogListener recognizerDialogListener = new RecognizerDialogListener() {
        @Override
        public void onResult(RecognizerResult recognizerResult, boolean b) {
            printResult(recognizerResult);
            if (b){
                rctCallback.invoke(originRes + finalRes);
            }
        }


        @Override
        public void onError(SpeechError speechError) {

        }
    };

    private void printResult(RecognizerResult results) {
        String text = parseIatResult(results.getResultString());

        String sn = null;
        // 读取json结果中的sn字段
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

        finalRes = resultBuffer.toString();
        Log.d("printResult: ", finalRes);

    }

    public static String parseIatResult(String json) {
        StringBuffer ret = new StringBuffer();
        try {
            JSONTokener tokener = new JSONTokener(json);
            JSONObject joResult = new JSONObject(tokener);

            JSONArray words = joResult.getJSONArray("ws");
            for (int i = 0; i < words.length(); i++) {
                // 转写结果词，默认使用第一个结果
                JSONArray items = words.getJSONObject(i).getJSONArray("cw");
                JSONObject obj = items.getJSONObject(0);
                ret.append(obj.getString("w"));
//				如果需要多候选结果，解析数组其他字段
//				for(int j = 0; j < items.length(); j++)
//				{
//					JSONObject obj = items.getJSONObject(j);
//					ret.append(obj.getString("w"));
//				}
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return ret.toString();
    }

}
