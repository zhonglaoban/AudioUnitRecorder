//
//  ViewController.m
//  AudioQueuePlayer
//
//  Created by 钟凡 on 2019/11/20.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "ZFAudioUnitRecorder.h"
#import "ZFAudioSession.h"
#import "ZFAudioFileManager.h"

@interface ViewController ()<ZFAudioUnitRecorderDelegate>

@property (strong, nonatomic) ZFAudioUnitRecorder *audioRecorder;
@property (strong, nonatomic) ZFAudioFileManager *audioWriter;

@end

@implementation ViewController
- (IBAction)playAndRecord:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    if (sender.isSelected) {
        [_audioRecorder startRecord];
    }else {
        [_audioWriter closeFile];
        [_audioRecorder stopRecord];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [ZFAudioSession setPlayAndRecord];
    [ZFAudioSession setSampleRate:16000 duration:0.02];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    double sampleRate = audioSession.sampleRate;
    
    AudioStreamBasicDescription absd = {0};
    absd.mSampleRate = sampleRate;
    absd.mFormatID = kAudioFormatLinearPCM;
    absd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    absd.mBytesPerPacket = 2;
    absd.mFramesPerPacket = 1;
    absd.mBytesPerFrame = 2;
    absd.mChannelsPerFrame = 1;
    absd.mBitsPerChannel = 16;
    
    _audioRecorder = [[ZFAudioUnitRecorder alloc] init];
    _audioRecorder.delegate = self;
    
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [NSString stringWithFormat:@"%@/test.aif", directory];
    NSLog(@"%@", filePath);
    _audioWriter = [[ZFAudioFileManager alloc] initWithAsbd:absd];
    [_audioWriter openFileWithFilePath:filePath];
}
- (void)audioRecorder:(ZFAudioUnitRecorder *)audioRecorder didRecoredAudioData:(void *)data length:(unsigned int)length {
    [_audioWriter writeData:data length:length];
}
@end
