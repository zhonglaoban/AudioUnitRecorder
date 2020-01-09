//
//  ZFAudioSession.m
//  AudioUnitRecorder
//
//  Created by 钟凡 on 2019/11/21.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ZFAudioSession.h"
#import <AVFoundation/AVFoundation.h>

@implementation ZFAudioSession

+ (void)setPlayAndRecord {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *sessionError;
    BOOL result;
    result = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker |
              AVAudioSessionCategoryOptionAllowBluetooth |
              AVAudioSessionCategoryOptionMixWithOthers
                                 error:&sessionError];
    
    printf("setCategory %d \n", result);
    // Activate the audio session
    result = [audioSession setActive:YES error:&sessionError];
    printf("setActive %d \n", result);
}
+ (void)setPlayback {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *sessionError;
    BOOL result;
    result = [audioSession setCategory:AVAudioSessionCategoryPlayback
                           withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth
                                 error:&sessionError];
    
    printf("setCategory %d \n", result);
    // Activate the audio session
    result = [audioSession setActive:YES error:&sessionError];
    printf("setActive %d \n", result);
}
+ (void)setSampleRate:(double)sampleRate duration:(double)duration {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *sessionError;
    BOOL result;
    result = [audioSession setPreferredIOBufferDuration:duration error:&sessionError];
    printf("setIOBufferDuration %d \n", result);
    result = [audioSession setPreferredSampleRate:sampleRate error:&sessionError];
    printf("setSampleRate %d \n", result);
    result = [audioSession setActive:YES error:&sessionError];
    printf("setActive %d \n", result);
}
- (void)beginObserver {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:audioSession];
}
- (void)endObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@\n", routeDescription);
    NSLog(@"Current route:\n");
    NSLog(@"%@\n", [AVAudioSession sharedInstance].currentRoute);
}
@end
