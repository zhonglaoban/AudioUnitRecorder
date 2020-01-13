//
//  ZFAudioUnitRecorder.m
//  AudioUnitRecorder
//
//  Created by 钟凡 on 2019/12/24.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ZFAudioUnitRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface ZFAudioUnitRecorder()

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) AudioStreamBasicDescription asbd;
@property (nonatomic) AUGraph graph;
@property (nonatomic) AudioUnit ioUnit;
@property (nonatomic) AudioComponentDescription ioUnitDesc;
@property (nonatomic, assign) double sampleTime;
@property (nonatomic, assign) double sampleRate;

@end


@implementation ZFAudioUnitRecorder
- (instancetype)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create("zf.audioRecorder", DISPATCH_QUEUE_SERIAL);
        [self getAudioSessionProperty];
        [self setupAudioFormat];
        dispatch_async(_queue, ^{
//            [self createInputUnit];
            [self getAudioUnits];
            [self setupAudioUnits];
        });
    }
    return self;
}
- (void)setupAudioFormat {
    UInt32 mChannelsPerFrame = 1;
    _asbd.mFormatID = kAudioFormatLinearPCM;
    _asbd.mSampleRate = _sampleRate;
    _asbd.mChannelsPerFrame = mChannelsPerFrame;
    //pcm数据范围(−2^16 + 1) ～ (2^16 - 1)
    _asbd.mBitsPerChannel = 16;
    //16 bit = 2 byte
    _asbd.mBytesPerPacket = mChannelsPerFrame * 2;
    //下面设置的是1 frame per packet, 所以 frame = packet
    _asbd.mBytesPerFrame = mChannelsPerFrame * 2;
    _asbd.mFramesPerPacket = 1;
    _asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    _ioUnitDesc.componentType = kAudioUnitType_Output;
    //vpio模式
    _ioUnitDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    _ioUnitDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    _ioUnitDesc.componentFlags = 0;
    _ioUnitDesc.componentFlagsMask = 0;
}
- (void)getAudioSessionProperty {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    _sampleTime = audioSession.IOBufferDuration;
    _sampleRate = audioSession.sampleRate;
    
    printf("_sampleTime %f \n", _sampleTime);
    printf("_sampleTime %f \n", _sampleRate);
}
- (void)getAudioUnits {
    OSStatus status = NewAUGraph(&_graph);
    printf("create graph %d \n", (int)status);
    
    AUNode ioNode;
    status = AUGraphAddNode(_graph, &_ioUnitDesc, &ioNode);
    printf("add ioNote %d \n", (int)status);

    //instantiate the audio units
    status = AUGraphOpen(_graph);
    printf("open graph %d \n", (int)status);
    
    //obtain references to the audio unit instances
    status = AUGraphNodeInfo(_graph, ioNode, NULL, &_ioUnit);
    printf("get ioUnit %d \n", (int)status);
}
- (void)createInputUnit {
    AudioComponent comp = AudioComponentFindNext(NULL, &_ioUnitDesc);
    if (comp == NULL) {
        printf("can't get AudioComponent");
    }
    OSStatus status = AudioComponentInstanceNew(comp, &(_ioUnit));
    printf("creat audio unit %d \n", (int)status);
}
- (void)setupAudioUnits {
    OSStatus status;
    //音频输入默认是关闭的，需要开启 0:关闭，1:开启
    UInt32 enableInput = 1; // to enable input
    UInt32 propertySize;
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  1,
                                  &enableInput,
                                  sizeof(enableInput));
    printf("enable input %d \n", (int)status);
    
    //关闭音频输出
    UInt32 disableOutput = 0; // to disable output
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  0,
                                  &disableOutput,
                                  sizeof(disableOutput));
    printf("disable output %d \n", (int)status);
    
    //设置stram format
    propertySize = sizeof (AudioStreamBasicDescription);
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  1,
                                  &_asbd,
                                  propertySize);
    printf("set input format %d \n", (int)status);
    //检查是否设置成功
    AudioStreamBasicDescription deviceFormat;
    status = AudioUnitGetProperty(_ioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &deviceFormat,
                                  &propertySize);
    printf("get input format %d \n", (int)status);
    
    //设置最大采集帧数
    UInt32 maxFramesPerSlice = 4096;
    propertySize = sizeof(UInt32);
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &maxFramesPerSlice,
                                  propertySize);
    printf("set max frame per slice: %d, %d \n", (int)maxFramesPerSlice, (int)status);
    AudioUnitGetProperty(_ioUnit,
                         kAudioUnitProperty_MaximumFramesPerSlice,
                         kAudioUnitScope_Global, 0,
                         &maxFramesPerSlice,
                         &propertySize);
    printf("get max frame per slice: %d, %d \n", (int)maxFramesPerSlice, (int)status);
    
    //设置回调
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = &inputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *_Nullable)(self);
    
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Input,
                                  0,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    printf("set render callback %d \n", (int)status);
}
- (void)startRecord {
    dispatch_async(_queue, ^{
        OSStatus status;
//        status = AudioUnitInitialize(self.ioUnit);
//        printf("AudioUnitInitialize %d \n", (int)status);
//        status = AudioOutputUnitStart(self.ioUnit);
//        printf("AudioOutputUnitStart %d \n", (int)status);
        
        status = AUGraphInitialize(self.graph);
        printf("AUGraphInitialize %d \n", (int)status);
        status = AUGraphStart(self.graph);
        printf("AUGraphStart %d \n", (int)status);
    });
}
- (void)stopRecord {
    dispatch_async(_queue, ^{
        OSStatus status;
        status = AUGraphStop(self.graph);
        printf("AUGraphStop %d \n", (int)status);
    });
}
OSStatus inputCallback(void *inRefCon,
                       AudioUnitRenderActionFlags *ioActionFlags,
                       const AudioTimeStamp *inTimeStamp,
                       UInt32 inBusNumber,
                       UInt32 inNumberFrames,
                       AudioBufferList *__nullable ioData) {

    ZFAudioUnitRecorder *recorder = (__bridge ZFAudioUnitRecorder *)inRefCon;

    AudioBuffer buffer;
    
    /**
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    UInt32 size = inNumberFrames * recorder.asbd.mBytesPerFrame;
    buffer.mDataByteSize = size; // sample size
    buffer.mNumberChannels = 1; // one channel
    buffer.mData = malloc(size); // buffer size
    
    // we put our buffer into a bufferlist array for rendering
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status = noErr;
    
    status = AudioUnitRender(recorder.ioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, &bufferList);
    
    if (status != noErr) {
        printf("AudioUnitRender %d \n", (int)status);
        return status;
    }
    if ([recorder.delegate respondsToSelector:@selector(audioRecorder:didRecoredAudioData:length:)]) {
        [recorder.delegate audioRecorder:recorder didRecoredAudioData:buffer.mData length:buffer.mDataByteSize];
    }
    
    return status;
}

@end
