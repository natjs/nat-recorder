package com.nat.recorder;

import android.media.AudioFormat;
import android.media.MediaRecorder;

import java.io.File;
import java.io.IOException;
import java.util.Date;
import java.util.HashMap;

import omrecorder.AudioChunk;
import omrecorder.AudioSource;
import omrecorder.OmRecorder;
import omrecorder.PullTransport;
import omrecorder.Recorder;

/**
 * Created by xuqinchao on 17/1/7.
 *  Copyright (c) 2017 Nat. All rights reserved.
 * 
 */

public class HLRecorderModule {
    private Recorder mRecorder;
    private File mFile;
    private boolean mIsRecording;
    private boolean mIsPausing;

    private static volatile HLRecorderModule instance = null;

    private HLRecorderModule(){
    }

    public static HLRecorderModule getInstance() {
        if (instance == null) {
            synchronized (HLRecorderModule.class) {
                if (instance == null) {
                    instance = new HLRecorderModule();
                }
            }
        }

        return instance;
    }

    public void start(HashMap<String, String> options, HLModuleResultListener listener){
        int audioChannel = AudioFormat.CHANNEL_IN_STEREO;
        if (options.get("channel").equals("mono")) audioChannel = AudioFormat.CHANNEL_IN_MONO;
        int sampleRate = 22050;
        int audioBit = AudioFormat.ENCODING_PCM_16BIT;
        switch (options.get("quality")) {
            case "low":
                sampleRate = 8000;
                audioBit = AudioFormat.ENCODING_PCM_8BIT;
                break;
            case "high":
                sampleRate = 44100;
                audioBit = AudioFormat.ENCODING_PCM_16BIT;
                break;
        }

        if (mIsRecording) {
            if (mIsPausing) {
                if (mRecorder != null)mRecorder.resumeRecording();
                mIsPausing = false;
                listener.onResult(null);
            } else {
                listener.onResult(HLUtil.getError(HLConstant.RECORDER_BUSY, HLConstant.RECORDER_BUSY_CODE));
            }
        } else {
            String time_str = new Date().getTime() + "";
            try {
                mFile = HLUtil.getHLFile(time_str + ".wav");
            } catch (IOException e) {
                e.printStackTrace();
                listener.onResult(HLUtil.getError(HLConstant.MEDIA_INTERNAL_ERROR, HLConstant.MEDIA_INTERNAL_ERROR_CODE));
            }
            mRecorder = OmRecorder.wav(
                    new PullTransport.Default(getMic(audioBit, audioChannel, sampleRate), new PullTransport.OnAudioChunkPulledListener() {
                        @Override
                        public void onAudioChunkPulled(AudioChunk audioChunk) {

                        }
                    }), mFile);
            mRecorder.startRecording();
            mIsRecording = true;
            listener.onResult(null);
        }
    }

    public void pause(HLModuleResultListener listener) {
        if (!mIsRecording) {
            listener.onResult(HLUtil.getError(HLConstant.RECORDER_NOT_STARTED, HLConstant.RECORDER_NOT_STARTED_CODE));
            return;
        }
        if (mIsPausing) {
            listener.onResult(null);
            return;
        }
        if (mRecorder != null) {
            mRecorder.pauseRecording();
            mIsPausing = true;
            listener.onResult(null);
        }
    }

    public void stop(HLModuleResultListener listener) {
        if (!mIsRecording) {
            listener.onResult(HLUtil.getError(HLConstant.RECORDER_NOT_STARTED, HLConstant.RECORDER_NOT_STARTED_CODE));
            return;
        }
        if (mRecorder != null) {
            mRecorder.stopRecording();
            mIsPausing = false;
            mIsRecording = false;
            HashMap<String, String> result = new HashMap<>();
            result.put("path", mFile.getAbsolutePath());
            listener.onResult(result);
        }
    }

    private AudioSource getMic(int audioBit, int channel, int frequency) {
        return new AudioSource.Smart(MediaRecorder.AudioSource.MIC, audioBit, channel, frequency);
    }
}
