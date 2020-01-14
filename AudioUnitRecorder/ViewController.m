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
    
    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = 16000;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    asbd.mBytesPerPacket = 2;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 2;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel = 16;
    
    _audioRecorder = [[ZFAudioUnitRecorder alloc] initWithAsbd:asbd];
    _audioRecorder.delegate = self;
    
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [NSString stringWithFormat:@"%@/test.aif", directory];
    NSLog(@"%@", filePath);
    _audioWriter = [[ZFAudioFileManager alloc] initWithAsbd:asbd];
    [_audioWriter openFileWithFilePath:filePath];
}
- (void)audioRecorder:(ZFAudioUnitRecorder *)audioRecorder didRecoredAudioData:(void *)data length:(unsigned int)length {
    [_audioWriter writeData:data length:length];
}
@end
