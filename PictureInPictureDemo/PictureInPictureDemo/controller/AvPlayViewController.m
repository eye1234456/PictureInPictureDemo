//
//  AvPlayViewController.m
//  PictureInPictureDemo
//
//  Created by Flow on 3/11/22.
//

#import "AvPlayViewController.h"
#import "AESKeyHeader.h"
#import "NSData+FE.h"
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>

#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>

//#import "AVFoundation/AVFoundation.h"
#import <AVKit/AVKit.h>

@interface AvPlayViewController ()
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) UIImageView *containerView;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *pipBtn;
@property(nonatomic, strong) GCDWebServer *encrptWebServer;

@property(nonatomic, strong) AVPictureInPictureController *pipVC;
@end

@implementation AvPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = self.model.title;
    
    [self.view addSubview:self.containerView];
    [self.view addSubview:self.playBtn];
    [self.view addSubview:self.pipBtn];
    [self setupEncryptWebServer];
    [self setupPlayer];
    
    // 由于m3u8是分ts存储成多个段的，对每个段进行分别加密，播放器播放时也是一次性请求一个ts，这样对ts进行解密没任何问题
    // mp4进行整体加密，播放器播放时时通过range进行下载的，对单个range进行解密，解密后的数据是不正确的
}

- (void)dealloc {
    _player = nil;
    if (_player.currentPlayerManager.isPlaying) {
        [_player.currentPlayerManager stop];
    }
    if (_encrptWebServer.isRunning) {
        [_encrptWebServer stop];
    }
    [self.class cancelPreviousPerformRequestsWithTarget:self];
}

- (id<ZFPlayerMediaPlayback>)playerManager {
    return [[ZFAVPlayerManager alloc] init];
}

- (void)setupPlayer {
    id<ZFPlayerMediaPlayback> playerManager = [self playerManager];
    playerManager.shouldAutoPlay = YES;
    
    /// 播放器相关
    self.player = [ZFPlayerController playerWithPlayerManager:playerManager containerView:self.containerView];
    /// 设置退到后台继续播放
    self.player.pauseWhenAppResignActive = NO;
    
    // 播放完成
    __weak typeof(self) weakself = self;
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        [weakself.player seekToTime:0 completionHandler:^(BOOL finished) {
            [weakself.player.currentPlayerManager play];
        }];
    };

    // 设置播放地址
    if (self.model.isEncrypt) {
        // 加密地址，使用代理地址播放
       NSURL *proxyURL = [[self.encrptWebServer serverURL] URLByAppendingPathComponent:self.model.url];
        self.player.assetURL = proxyURL;
    }else {
        // 未加密地址使用原始地址播放
        self.player.assetURL = [NSURL URLWithString:self.model.url];
    }
    
    [self.player playTheIndex:0];
    
}

- (void)setupEncryptWebServer {
    // 不是加密数据，不需要设置代理解密
    if (!self.model.isEncrypt) {
        return;
    }
    self.encrptWebServer = [[GCDWebServer alloc] init];
//    __weak typeof(self) weakSelf = self;
    [self.encrptWebServer addHandlerWithMatchBlock:^GCDWebServerRequest * _Nullable(NSString * _Nonnull requestMethod, NSURL * _Nonnull requestURL, NSDictionary<NSString *,NSString *> * _Nonnull requestHeaders, NSString * _Nonnull urlPath, NSDictionary<NSString *,NSString *> * _Nonnull urlQuery) {
        // 从地址中取出真实的地址
        // 代理地址： http://localhost:12345/https://www.baidu.com/hello.index?a=1
        // 原始地址：https://www.baidu.com/hello.index?age=100&name=ming
        // 此处的urlPath：/https://www.baidu.com/hello.index?age=100&name=ming
        // 此处的urlQuery：{}
        // 获取到真实的地址
        NSString *path = [urlPath stringByReplacingOccurrencesOfString:@"/http" withString:@"http"];
        // 将真实地址构建成新的真实的请求
        GCDWebServerRequest *request = [[GCDWebServerRequest alloc] initWithMethod:requestMethod url:[NSURL URLWithString:path] headers:requestHeaders path:urlPath query:urlQuery];
        return request;
    } asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        
        // 将GCD的request构造成真实请求的request
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:request.URL];
        NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:req.allHTTPHeaderFields];
        if (request.headers[@"Range"] != nil) {
            headers[@"Accept"] = request.headers[@"Accept"];
            headers[@"X-Playback-Session-Id"] = request.headers[@"X-Playback-Session-Id"];
            headers[@"Range"] = request.headers[@"Range"];
            headers[@"User-Agent"] = request.headers[@"User-Agent"];
            headers[@"Accept-Language"] = request.headers[@"Accept-Language"];
            headers[@"Accept-Encoding"] = request.headers[@"Accept-Encoding"];
        }
        
        req.HTTPMethod = request.method;
        req.allHTTPHeaderFields = headers;
//        req.timeoutInterval = 120;
        
        // 使用NSURLSession进行网络请求
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSData *deCodedData = nil;
            // 对原始数据进行解密
            if (!error && data) {
                deCodedData  = [data fe_aesDecryptWithKey:kAESKey];
            }
            // 使用解密的数据组装响应返回
            GCDWebServerDataResponse *res = [GCDWebServerDataResponse responseWithData:deCodedData contentType:@"audio/mpegurl"];
            // 回调完成
            completionBlock(res);
        }];
        [task resume];
    }];
    
    [self.encrptWebServer startWithPort:12345 bonjourName:nil];
}


- (void)pipBtnClick {
    if (self.isPipAvailable) {
        /// 配置画中画
        ZFAVPlayerManager *manager = (ZFAVPlayerManager *)self.player.currentPlayerManager;
        AVPictureInPictureController *vc = [[AVPictureInPictureController alloc] initWithPlayerLayer:manager.avPlayerLayer];
        self.pipVC = vc;
        ///要有延迟 否则可能开启不成功
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.pipVC startPictureInPicture];
        });
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
        [self.player.currentPlayerManager play];
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


@end
