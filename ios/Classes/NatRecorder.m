//
//
//  NatRecorder.m
//
//  Created by huangyake on 17/1/7.
//  Copyright © 2017 Instapp. All rights reserved.
//

#import "NatRecorder.h"
#define kRecordAudioFile @"myRecord.caf"


@interface NatRecorder ()
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;
@property(nonatomic, strong)NSString *file;
@property(nonatomic, strong)NatCallback stopback;
@end
@implementation NatRecorder

+ (NatRecorder *)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}


- (void)start:(NSDictionary *)options :(NatCallback)callBack{
    if (self.audioRecorder.isRecording) {
      callBack(@{@"error":@{@"msg":@"RECORDER_BUSY",@"code":@130030}},nil);
        return;
    }
    
    if (self.audioRecorder) {
        [self.audioRecorder record];
        callBack(nil,nil);
    }else{
        AVAudioSession *audioSession=[AVAudioSession sharedInstance];
        //设置为播放和录音状态，以便可以在录制完之后播放录音
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [audioSession setActive:YES error:nil];
//        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    NSURL *url=[self getSavePath];
                    //创建录音格式设置
                    NSError *error=nil;
                    NSDictionary *setting=[self getAudioSettingWithOptions:options];
                    self.audioRecorder = [[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
                    _audioRecorder.delegate=self;
                    //        _audioRecorder.settings = @{};
                    _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
                    
                    
                    if (error) {
                        NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
                        callBack(@{@"error":@{@"msg":@"RECORDER_INTERNAL_ERROR",@"code":@130000}},nil);
                    }else{
                        [self.audioRecorder record];
                        callBack(nil,nil);
                    }

                }else{
                   callBack(@{@"error":@{@"msg":@"RECORD_AUDIO_PERMISSION_DENIED",@"code":@130020}},nil);
                }
            }];
        }
        //创建录音文件保存路径
        
    }
}
- (void)pause:(NatCallback)callBack{
    if (self.audioRecorder.isRecording) {
        [self.audioRecorder pause];
        callBack(nil,nil);

    }else{
        callBack(@{@"error":@{@"msg":@"RECORDER_NOT_STARTED",@"code":@130100}},nil);
    }
}
- (void)stop:(NatCallback)callBack{
    self.stopback = callBack;
    if (self.audioRecorder) {
        [self.audioRecorder stop];
        self.audioRecorder = nil;
        NSString *str = self.file;
        str = [@"file://" stringByAppendingString:str];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];
        callBack(nil,@{@"path":str});
    }else{
         callBack(@{@"error":@{@"msg":@"RECORDER_NOT_STARTED",@"code":@130100}},nil);
    }
}

-(NSURL *)getSavePath{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    urlStr=[urlStr stringByAppendingPathComponent:[NSString stringWithFormat:@"nat_audio_%.0lf.aac",time*1000]];
    NSLog(@"file path:%@",urlStr);
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    self.file = urlStr;
    return url;
}
-(NSDictionary *)getAudioSettingWithOptions:(NSDictionary *)options{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    NSNumber *channel;
    NSNumber *quality;
    NSNumber *bitDepth;
    if (options) {
        if (options[@"channel"]) {
            if ([options[@"channel"] isEqual:@"stereo"]) {
                channel = @2;
            }else if([options[@"channel"] isEqual:@"mono"]){
                channel = @1;
            }else{
                channel = @2;
            }
        }else{
            channel = @2;
        }
        
        if (options[@"quality"]) {
            if ([options[@"quality"] isEqual:@"low"]) {
                quality = @8000;
                bitDepth = @8;
            }else if ([options[@"quality"] isEqual:@"high"]){
                quality = @44100;
                bitDepth = @16;
            }else{
                quality = @22050;
                bitDepth = @16;
            }
        }else{
            quality = @22050;
            bitDepth = @16;
        }
    }else{
        channel = @2;
        quality = @22050;
        bitDepth = @16;
    }
    [dicM setObject:@(kAudioFormatMPEG4AAC) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:quality forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:channel forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:bitDepth forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}

- (void)close{
    [self.audioRecorder stop];
    self.audioRecorder = nil;
    NSString *str = self.file;
    if (str) {
        str = [@"file://" stringByAppendingString:str];
    }
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
}
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (!flag) {
         self.stopback(@{@"error":@{@"msg":@"RECORDER_INTERNAL_ERROR ",@"code":@130000}},nil);
    }
}
@end
