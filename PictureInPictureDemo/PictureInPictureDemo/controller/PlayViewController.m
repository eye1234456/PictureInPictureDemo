//
//  PlayViewController.m
//  PictureInPictureDemo
//
//  Created by eye on 3/11/22.
//

#import "PlayViewController.h"
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFIJKPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import "PipManager.h"
#import "WebServerManager.h"

@interface PlayViewController ()
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) UIImageView *containerView;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *pipBtn;
@property (nonatomic, strong) UIButton *scaleModeBtn;

@end

@implementation PlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = self.model.title;
    
    [self.view addSubview:self.containerView];
    [self.view addSubview:self.playBtn];
    [self.view addSubview:self.pipBtn];
    [self.view addSubview:self.scaleModeBtn];
    [self updateShowMode];
    if (self.model.isEncrypt) {
        [WebServerManager.sharedInstance start];
    }
    [self setupPlayer];
    
    // 由于m3u8是分ts存储成多个段的，对每个段进行分别加密，播放器播放时也是一次性请求一个ts，这样对ts进行解密没任何问题
    // mp4进行整体加密，播放器播放时时通过range进行下载的，对单个range进行解密，解密后的数据是不正确的
}

- (void)dealloc {
    _player = nil;
    if (_player.currentPlayerManager.isPlaying) {
        [_player.currentPlayerManager stop];
    }
    [self.class cancelPreviousPerformRequestsWithTarget:self];
}

- (id<ZFPlayerMediaPlayback>)playerManager {
    if (self.model.playerType == PlayerTypeAvPlayer) {
        return [[ZFAVPlayerManager alloc] init];
    }else {
        return [[ZFIJKPlayerManager alloc] init];
    }
    
}

- (void)setupPlayer {
    id<ZFPlayerMediaPlayback> playerManager = [self playerManager];
    playerManager.shouldAutoPlay = YES;
    
    /// 播放器相关
    self.player = [ZFPlayerController playerWithPlayerManager:playerManager containerView:self.containerView];
    self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeAspectFill;
    self.player.currentPlayerManager.view.backgroundColor = UIColor.blueColor;
    /// 设置退到后台继续播放
    self.player.pauseWhenAppResignActive = NO;
    
    // 播放完成
    self.player.playerDidToEnd = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset) {
        // 播放完成循环播放
        [asset replay];
    };
    
    self.player.playerPlayFailed = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, id  _Nonnull error) {
        NSLog(@"%@",error);
    };

    // 设置播放地址
    if (self.model.isEncrypt) {
        // 加密地址，使用代理地址播放
//       NSURL *proxyURL = [WebServerManager proxyUrl:self.model.url];
////        proxyURL = [NSURL URLWithString:@"http://10.64.32.106:8080/download?path=/3.webm"];
//        proxyURL = [NSURL URLWithString:@"http://localhost:8082/3.webm"];
////        proxyURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",@"http://localhost:8082",self.model.url]];
//        self.player.assetURL = proxyURL;
        
        if (self.model.serverType == ServerTypeLocalBundle) {
            NSURL *url = [[NSBundle mainBundle] URLForResource:self.model.url withExtension:nil];
            self.player.assetURL = url;
        }else if (self.model.serverType == ServerTypeLocalSandBox){
            
        }else if (self.model.serverType == ServerTypeRemote){
            self.player.assetURL = [WebServerManager proxyUrl:self.model.url];
        }else {
            self.player.assetURL = [WebServerManager proxyUrl:self.model.url];
        }
    }else {
        // 未加密地址使用原始地址播放
        if (self.model.serverType == ServerTypeLocalBundle) {
            NSURL *url = [[NSBundle mainBundle] URLForResource:self.model.url withExtension:nil];
            self.player.assetURL = url;
        }else if (self.model.serverType == ServerTypeLocalSandBox){
            NSURL *url = [WebServerManager davProxyUrl:self.model.url];
            self.player.assetURL = url;
        }else if (self.model.serverType == ServerTypeRemote){
            NSURL *url = [NSURL URLWithString:self.model.url];
            self.player.assetURL = url;
        }else {
            self.player.assetURL = [NSURL URLWithString:self.model.url];
        }
        
    }
    
//    [self.player playTheIndex:0];
    
}


- (void)pipBtnClick {
    if (self.isPipAvailable) {
        /// 配置画中画
        [PipManager.sharedInstance showPipWithPlayer:self.player];
    }else {
        // 不支持画中画
        NSLog(@"不支持画中画");
    }
    
}

- (BOOL)isPipAvailable{
    return AVPictureInPictureController.isPictureInPictureSupported;
}

- (void)playClick:(UIButton *)sender {
    if (self.player.currentPlayerManager.isPlaying) {
        [self.player.currentPlayerManager pause];
    }else {
//        [self.player.currentPlayerManager play];
//        [self.player.currentPlayerManager replay];
        __weak typeof(self) weakself = self;
        [self.player.currentPlayerManager seekToTime:5 completionHandler:^(BOOL finished) {
            [weakself.player.currentPlayerManager play];
        }];
    }
}

- (void)modeBtnClick:(UIButton *)sender {
//    ZFPlayerScalingModeNone,       // No scaling.
//    ZFPlayerScalingModeAspectFit,  // Uniform scale until one dimension fits.
//    ZFPlayerScalingModeAspectFill, // Uniform scale until the movie fills the visible bounds. One dimension may have clipped contents.
//    ZFPlayerScalingModeFill
    if (self.player.currentPlayerManager.scalingMode == ZFPlayerScalingModeNone) {
        self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeAspectFit;
    }else if (self.player.currentPlayerManager.scalingMode == ZFPlayerScalingModeAspectFit) {
        self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeAspectFill;
    }else if (self.player.currentPlayerManager.scalingMode == ZFPlayerScalingModeAspectFill) {
        self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeFill;
    }else if (self.player.currentPlayerManager.scalingMode == ZFPlayerScalingModeFill) {
        self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeNone;
    }
    [self updateShowMode];
    
}
- (void)updateShowMode {
    if (self.player.currentPlayerManager.scalingMode == ZFPlayerScalingModeNone) {
        [self.scaleModeBtn setTitle:@"current:None next:AspectFit" forState:UIControlStateNormal];
        
    }else if (self.player.currentPlayerManager.scalingMode == ZFPlayerScalingModeAspectFit) {
        [self.scaleModeBtn setTitle:@"current:AspectFit next:AspectFill" forState:UIControlStateNormal];
        
    }else if (self.player.currentPlayerManager.scalingMode == ZFPlayerScalingModeAspectFill) {
        [self.scaleModeBtn setTitle:@"current:AspectFill next:Fill" forState:UIControlStateNormal];
        
    }else if (self.player.currentPlayerManager.scalingMode == ZFPlayerScalingModeFill) {
        [self.scaleModeBtn setTitle:@"current:Fill next:None" forState:UIControlStateNormal];
    }
}

#pragma mark - getter
- (UIImageView *)containerView {
    if (!_containerView) {
        _containerView = [UIImageView new];
        _containerView.backgroundColor = UIColor.greenColor;
        _containerView.frame = CGRectMake(0, 100, self.view.bounds.size.width, self.view.bounds.size.width/2);
    }
    return _containerView;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _playBtn.frame = CGRectMake(50, 400, 100, 40);
        [_playBtn setTitle:@"播放/暂停" forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)pipBtn {
    if (!_pipBtn) {
        _pipBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _pipBtn.frame = CGRectMake(150, 400, 160, 40);
        [_pipBtn setTitle:@"开启画中画" forState:UIControlStateNormal];
        [_pipBtn addTarget:self action:@selector(pipBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pipBtn;
}

- (UIButton *)scaleModeBtn {
    if (!_scaleModeBtn) {
        _scaleModeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _scaleModeBtn.frame = CGRectMake(0, 500, self.view.bounds.size.width, 40);
        [_scaleModeBtn setTitle:@"scalingMode: AspectFill" forState:UIControlStateNormal];
        [_scaleModeBtn addTarget:self action:@selector(modeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _scaleModeBtn;
}
@end
