# 使用 Audio Unit 录制音频
- [使用 Audio Unit 录制音频](#%e4%bd%bf%e7%94%a8-audio-unit-%e5%bd%95%e5%88%b6%e9%9f%b3%e9%a2%91)
  - [Audio Unit 能做什么](#audio-unit-%e8%83%bd%e5%81%9a%e4%bb%80%e4%b9%88)
  - [Audio Unit 的一些相关知识点](#audio-unit-%e7%9a%84%e4%b8%80%e4%ba%9b%e7%9b%b8%e5%85%b3%e7%9f%a5%e8%af%86%e7%82%b9)
    - [AUGraph](#augraph)
    - [AudioUnit](#audiounit)
    - [AudioStreamBasicDescription](#audiostreambasicdescription)
    - [AudioComponentDescription](#audiocomponentdescription)
  - [Audio Unit 实现音频录制功能](#audio-unit-%e5%ae%9e%e7%8e%b0%e9%9f%b3%e9%a2%91%e5%bd%95%e5%88%b6%e5%8a%9f%e8%83%bd)
    - [初始化](#%e5%88%9d%e5%a7%8b%e5%8c%96)
    - [设置AudioComponentDescription](#%e8%ae%be%e7%bd%aeaudiocomponentdescription)
    - [获取Audio Unit实例](#%e8%8e%b7%e5%8f%96audio-unit%e5%ae%9e%e4%be%8b)
    - [设置Audio Unit属性](#%e8%ae%be%e7%bd%aeaudio-unit%e5%b1%9e%e6%80%a7)
    - [开始录制](#%e5%bc%80%e5%a7%8b%e5%bd%95%e5%88%b6)
    - [停止录制](#%e5%81%9c%e6%ad%a2%e5%bd%95%e5%88%b6)
    - [AURenderCallback](#aurendercallback)

## Audio Unit 能做什么
Audio Unit 可以实现混音、均衡器、音频格式转化、实时的音频录制和播放等功能，它们可以动态的装载和卸载，具有高度可扩展性。因为 Audio Unit 是 iOS 系统里面比较底层的音频处理模块，所以使用起来比起其他iOS上的音频库需要更深入的理解。如果你不是需要实时性高、延迟低或者其他特殊处理的话，首先应该考虑使用 Media Player, AV Foundation, OpenAL, 或者 Audio Toolbox frameworks等库。它们都是基于Audio Unit 更高等级的封装，使用起来更加方便。
![音频库的结构图](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/Art/Audio_frameworks_2x.png)
## Audio Unit 的一些相关知识点
### AUGraph
Audio Unit的管理者，能够动态的加载、卸载Audio Unit，从而实现混音、变音、录制、播放等效果。
### AudioUnit
一个音频单元，有converter、effect、mixer、i/o这几种类型
### AudioStreamBasicDescription
描述音频数据的结构体，有采样率、声道、音频格式等参数。
### AudioComponentDescription
描述Audio Unit的结构体，有类型、厂商等参数。

## Audio Unit 实现音频录制功能
![录制音频流程图](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/Art/IO_unit_2x.png)

使用Audio Unit录制的时候，过程相对简单，我们使用一个Audio Unit就可以完成了，步骤如下：
1. 设置好AudioComponentDescription，确定我们使用的Audio Unit类型
2. 获取Audio Unit实例，我们有两种获取方式，通过AUGraph获取，通过AudioComponent获取。
3. 设置Audio Unit的属性，告诉系统我们需要使用Audio Unit的哪些功能以及需要采集什么样的数据。
4. 开始录制和结束录制的控制。
5. 从回调函数中取得音频数据。

### 初始化
```objc
- (instancetype)initWithAsbd:(AudioStreamBasicDescription)asbd {
    self = [super init];
    if (self) {
        _asbd = asbd;
        _queue = dispatch_queue_create("zf.audioRecorder", DISPATCH_QUEUE_SERIAL);
        [self setupAcd];
        dispatch_async(_queue, ^{
//            [self createInputUnit];
            [self getAudioUnits];
            [self setupAudioUnits];
        });
    }
    return self;
}
```

### 设置AudioComponentDescription
```objc
- (void)setupAcd {
    _ioUnitDesc.componentType = kAudioUnitType_Output;
    //vpio模式
    _ioUnitDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    _ioUnitDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    _ioUnitDesc.componentFlags = 0;
    _ioUnitDesc.componentFlagsMask = 0;
}
```

### 获取Audio Unit实例
通过AUGraph获取实例
```objc
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
```
通过AudioComponent获取实例
```objc
- (void)createInputUnit {
    AudioComponent comp = AudioComponentFindNext(NULL, &_ioUnitDesc);
    if (comp == NULL) {
        printf("can't get AudioComponent");
    }
    OSStatus status = AudioComponentInstanceNew(comp, &(_ioUnit));
    printf("creat audio unit %d \n", (int)status);
}
```
### 设置Audio Unit属性
```objc
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
                                  kAudioUnitScope_Output,
                                  1,
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
                         kAudioUnitScope_Global,
                         0,
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
```
### 开始录制
注释的部分是不使用AUGraph的方式。
```objc
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
```

### 停止录制
```objc
- (void)stopRecord {
    dispatch_async(_queue, ^{
        OSStatus status;
        status = AUGraphStop(self.graph);
        printf("AUGraphStop %d \n", (int)status);
    });
}
```

### AURenderCallback
```objc
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
    free(buffer.mData);
    
    return status;
}
```
1. 回调函数中并没有真正获取到数据，还需要调用AudioUnitRender去取数据。
2. 我们使用了malloc开辟了一块内存空间，我们需要用free释放调。
