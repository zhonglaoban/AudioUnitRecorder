//
//  ZFAudioUnitRecorder.h
//  AudioUnitRecorder
//
//  Created by 钟凡 on 2019/12/24.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZFAudioUnitRecorder;

@protocol ZFAudioUnitRecorderDelegate <NSObject>

///获取到音频数据
- (void)audioRecorder:(ZFAudioUnitRecorder *)audioRecorder didRecoredAudioData:(void *)data length:(unsigned int)length;

@end

@interface ZFAudioUnitRecorder : NSObject

@property (nonatomic, weak) id<ZFAudioUnitRecorderDelegate> delegate;

- (instancetype)initWithAsbd:(AudioStreamBasicDescription)asbd;

- (void)startRecord;
- (void)stopRecord;

@end

NS_ASSUME_NONNULL_END
