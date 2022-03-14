//
//  KeepAwakManager.m
//  PictureInPictureDemo
//
//  Created by eye on 3/14/22.
//

#import "KeepAwakManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIApplication.h>

@interface KeepAwakManager()
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation KeepAwakManager
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static KeepAwakManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self setupAudioSession];
    [self setupAudioPlayer];
}


- (void)setupAudioSession {
    // 新建AudioSession会话
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 设置后台播放
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    if (error) {
        NSLog(@"Error setCategory AVAudioSession: %@", error);
    }
    NSLog(@"%d", audioSession.isOtherAudioPlaying);
    NSError *activeSetError = nil;
    // 启动AudioSession，如果一个前台app正在播放音频则可能会启动失败
    [audioSession setActive:YES error:&activeSetError];
    if (activeSetError) {
        NSLog(@"Error activating AVAudioSession: %@", activeSetError);
    }
}

- (void)setupAudioPlayer {
    //静音文件
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PIPSilence" ofType:@"wav"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    //静音
    self.audioPlayer.volume = 0;
    //播放一次
    self.audioPlayer.numberOfLoops = 1;
    [self.audioPlayer prepareToPlay];
}



- (void)start{
   
    [self.audioPlayer play];
    [self applyforBackgroundTask];
}

- (void)stop {
    [self.audioPlayer stop];
}



//申请后台任务
- (void)applyforBackgroundTask{
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (self.backgroundTaskIdentifier!=UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
        [self start];
        
    }];
}
@end
