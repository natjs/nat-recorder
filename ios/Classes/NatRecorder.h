//
//
//  NatRecorder.h
//
//  Created by huangyake on 17/1/7.
//  Copyright © 2017 Nat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface NatRecorder : NSObject<AVAudioRecorderDelegate>
typedef void (^NatCallback)(id error, id result);

+ (NatRecorder *)singletonManger;
//开始录音 参数
//  channel: String (stereo, mono, def: stereo) 录音通道  默认立体声
//  quality: String (low [8000Hz, 8bit] | standard [22050Hz, 16bit] | high [44100Hz, 16bit], def: standard)  录音质量
- (void)start:(NSDictionary *)options :(NatCallback)callBack;

//暂停录音
- (void)pause:(NatCallback)callBack;
//停止录音
- (void)stop:(NatCallback)callBack;
//关闭
- (void)close;

@end
