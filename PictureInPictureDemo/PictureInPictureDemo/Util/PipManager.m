//
//  PipManager.m
//  PictureInPictureDemo
//
//  Created by eye on 3/14/22.
//

#import "PipManager.h"
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFIJKPlayerManager.h>
#import "KeepAwakManager.h"

@interface PipManager() <AVPictureInPictureControllerDelegate>
@property(nonatomic, strong) ZFPlayerController *originPlayer;
// 只有ijkplayer进入才有
@property(nonatomic, strong) UIView *avPlayerLayerContainerView;
@property (nonatomic,strong) AVPlayer *avPlayer;
// avplayer+ijkPlayer进入都有
@property(nonatomic,strong) AVPlayerLayer *avPlayerLayer;


@property(nonatomic, strong) AVPictureInPictureController *pipVC;
@property(nonatomic, assign) BOOL pipAlreadyStartedFlag;
@end

@implementation PipManager
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static PipManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (void)showPipWithPlayer:(ZFPlayerController *)player {
    
    if (self.isPipAvailable) {
        self.originPlayer = player;
        if ([player.currentPlayerManager isKindOfClass:ZFAVPlayerManager.class]) {
            ZFAVPlayerManager *manager = (ZFAVPlayerManager *)player.currentPlayerManager;
            self.avPlayerLayer = manager.avPlayerLayer;
            
            [self setupPip];
        }else {
            ZFIJKPlayerManager *manager = (ZFIJKPlayerManager *)player.currentPlayerManager;
            UIView *ijkContainerView = player.containerView;
            UIView *superView = nil;
            if ([UIApplication.sharedApplication.delegate respondsToSelector:@selector(window)]) {
                superView = UIApplication.sharedApplication.delegate.window;
            }else if (ijkContainerView.window != nil){
                superView = ijkContainerView.window;
            }
            
            // 将ijkplayer的frame转换为window的坐标体系
            CGRect ijkPlayerFrame = [superView convertRect:ijkContainerView.frame toView:superView];
            // 创建一个隐藏的AvPlayer
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
           
            if (error) {
                NSLog(@"请求权限失败的原因为%@",error);
                return;
            }
            self.avPlayer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:manager.assetURL.absoluteString]];
            self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
            
            // 将创建的player添加到window上
            self.avPlayerLayerContainerView = [[UIView alloc] init];
            self.avPlayerLayerContainerView.frame = ijkPlayerFrame;
            [superView addSubview:self.avPlayerLayerContainerView];
            [self.avPlayerLayerContainerView.layer addSublayer:self.avPlayerLayer];
            self.avPlayerLayer.frame = self.avPlayerLayerContainerView.bounds;
            self.avPlayerLayerContainerView.hidden = YES;
            
            // 将之前正在播放的ijkplayer暂停
            if(manager.isPlaying){
                [manager pause];
            }
            
            // 只有ijkplayer进入才会有player
            [self.avPlayer  addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
            [self.avPlayer addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
        }
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(becomeAcitve) name:UIApplicationDidBecomeActiveNotification object:nil];
    }else {
        // 不支持画中画
        NSLog(@"不支持画中画");
    }
}

- (void)enterBackground{
    [KeepAwakManager.sharedInstance start];
}
- (void)becomeAcitve{
    [KeepAwakManager.sharedInstance stop];
}

- (void)setupPip {
    /// 配置画中画
    
    AVPictureInPictureController *pipVC = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.avPlayerLayer];
    pipVC.delegate = self;
    self.pipVC = pipVC;
    ///要有延迟 否则可能开启不成功
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.pipVC startPictureInPicture];
    });
}

- (void)destroy {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    if (_avPlayerLayerContainerView != nil) {
        // 如果是ijkplayer进入的
        [_avPlayerLayer removeFromSuperlayer];
        [_avPlayerLayerContainerView removeFromSuperview];
        _avPlayerLayerContainerView = nil;
        [_avPlayer replaceCurrentItemWithPlayerItem:nil];
        
        @try {
            [_avPlayer removeObserver:self forKeyPath:@"status"];
            [_avPlayer removeObserver:self forKeyPath:@"timeControlStatus"];
        }@catch (NSException *exception) {
    //        NSLog(@"%@",exception);
        }
        
        _avPlayer = nil;
    }
    [_pipVC stopPictureInPicture];
    _avPlayerLayer = nil;
    _pipVC = nil;
    _originPlayer = nil;
    _pipAlreadyStartedFlag = NO;
    [self.class cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
        if ([keyPath isEqualToString:@"status"]) {
            [self fakeAvPlayerStatusChangeofObject:object];
        }else if ([keyPath isEqualToString:@"timeControlStatus"]){
            [self fakeAvPlayerTimeStatusChangeofObject:object];
        }
}
#pragma mark 创建的模拟播放器状态变化
- (void)fakeAvPlayerStatusChangeofObject:(id)object {
    
    switch (self.avPlayer.status) {
        case AVPlayerStatusUnknown:{
            NSLog(@"KVO：未知状态，此时不能播放");
            break;
        }
        case AVPlayerStatusReadyToPlay:{
             NSLog(@"KVO：准备完毕，可以播放");
            // 准备完毕，获取当前创建的avplyaer的时间
            int32_t timeScale = self.avPlayer.currentItem.asset.duration.timescale;
            // 获取原始的ijkplayer的播放时间
            NSTimeInterval currentPlayTime = self.originPlayer.currentTime;
            Float64 seekTo = currentPlayTime;
            // 将时间转换
            CMTime time = CMTimeMakeWithSeconds(seekTo, timeScale);
            BOOL fail = NO;
            @try {
                // 将播放器的播放时间与原始ijkplayer的播放地方同步
                [self.avPlayer seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            } @catch (NSException *exception) {
                NSLog(@"%@",exception);
                fail = YES;
            }
            if (fail) {
            }else{
                [self.avPlayer play];
            }
            break;
        }
        case AVPlayerStatusFailed:{
            AVPlayerItem * item = (AVPlayerItem *)object;
            NSLog(@"加载异常 %@",item.error);
            
            break;
        }
        default:{

        }
      break;
    }
}
- (void)fakeAvPlayerTimeStatusChangeofObject:(id)object {
    if (@available(iOS 10.0, *)) {}
    else {
        return;
    }
    if (self.avPlayer.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
        //这个可能会多次回调,所以判断一下,防止多次调用[self startPip]
        if (!self.pipAlreadyStartedFlag) {
            //真正开始播放时候 再seek一下, 使播放点更准确
            int32_t timeScale = self.avPlayer.currentItem.asset.duration.timescale;
            NSTimeInterval currentPlayTime = self.originPlayer.currentTime;
            Float64 seekTo = currentPlayTime; //真正开始画中画 大概在2秒之后
            CMTime time = CMTimeMakeWithSeconds(seekTo, timeScale);
            BOOL fail = NO;
            @try {
                [self.avPlayer seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            } @catch (NSException *exception) {
                NSLog(@"%@",exception);
                fail = YES;
            }
            if (fail) {
                
            }else{
                // 等player开始播放后再开启pip
                [self setupPip];
                self.pipAlreadyStartedFlag = YES;
            }


        }

    }
}

#pragma mark - AVPictureInPictureControllerDelegate
-(void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"即将开启画中画功能");
}

-(void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"已经开启画中画功能");

}

-(void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"即将停止画中画功能");
    if (self.avPlayer != nil) {
        // ijkplayer进入才需要恢复之前的播放时间
//        int32_t timeScale = self.avPlayer.currentItem.asset.duration.timescale;
        NSTimeInterval currentPlayTime = CMTimeGetSeconds(self.avPlayer.currentTime);
        Float64 seekTo = currentPlayTime; //真正开始画中画 大概在2秒之后
//        CMTime time = CMTimeMakeWithSeconds(seekTo, timeScale);
        __weak typeof(self) weakself = self;
        [self.originPlayer seekToTime:seekTo completionHandler:^(BOOL finished) {
            // 销毁内容
            if (weakself.avPlayer.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
                [weakself.originPlayer.currentPlayerManager play];
            }else if (weakself.avPlayer.timeControlStatus == AVPlayerTimeControlStatusPaused) {
                [weakself.originPlayer.currentPlayerManager play];
                [weakself.originPlayer.currentPlayerManager pause];
            }
            [weakself destroy];
        }];
        
    }else {
        // 销毁内容
        [self destroy];
    }
    
    

}

-(void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    // 一只不走这个回调
    NSLog(@"已经停止画中画功能");

}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error {
    NSLog(@"开启画中画功能失败，原因是%@",error);
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL restored))completionHandler{
    // 点击右上角，将画中画恢复成原生播放
    NSLog(@"画中画功能恢复成原生播放，currentTime:%f",CMTimeGetSeconds(self.avPlayer.currentTime));
    // 结束回调
    completionHandler(YES);
}

#pragma mark - getter
- (BOOL)isPipAvailable{
    return AVPictureInPictureController.isPictureInPictureSupported;
}
@end
