# PictureInPictureDemo
webm可以使用ijkplayer播放，但是不能使用AVPlayer播放
###画中画demo: `https://github.com/eye1234456/PictureInPictureDemo.git`

在线mp4转m3u8： `https://mp4.to/m3u8/`
测试视频下载：`https://www.cnblogs.com/v5captain/p/12144699.html`
`https://www.jianshu.com/p/cab2cd7b3f1c`
`http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8`
m3u8在线播放：

###一、AVPlayer进行画中画
如果播放器是AVPlayer，直接使用系统提供的`AVPictureInPictureController`进行播放即可

```
- (void)pipWithAvplayer:(AVPlayer *)avPlayer {
  AVPlayerLayer *avPlayerLayer = manager.avPlayerLayer;
  AVPictureInPictureController *pipVC = [[AVPictureInPictureController alloc] initWithPlayerLayer:avPlayerLayer];
    pipVC.delegate = self;
    ///要有延迟 否则可能开启不成功
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.pipVC startPictureInPicture];
    });
}
```
----
###二、 ijkplayer进行画中画

如果播放器是IJKPlayer的，需要创建一个隐藏的`AVPlayer`，然后再通过`avplayer`进行画中画，这个过程，需要将`ijkplayer`的播放进度同步给`avplayer`，同时画中画结束时，也需要将`avaplayer`的进度同步到原始的`ijkplayer`

```
- (void)showPipWithPlayer:(ZFPlayerController *)player {
    
    if (self.isPipAvailable) {
        self.originPlayer = player;
        if ([player.currentPlayerManager isKindOfClass:ZFAVPlayerManager.class]) {

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
        
  
    }else {
        // 不支持画中画
        NSLog(@"不支持画中画");
    }
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
```

将原始ijkplayer的时间进度同步到avplayer里

```

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
```

pip执行删除或恢复时，将avplayer的时间进度同步到ijk里

```
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
           
            }];
        
    }else {
        // 销毁内容
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
```
-----
###三、解决加密视屏创建代理服务器进行解密
`GCDWebServer`

```
@interface WebServerManager()
@property(nonatomic, strong) GCDWebServer *encrptWebServer;
@property(nonatomic, assign) BOOL isStarting;
@end

@implementation WebServerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static WebServerManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (void)setupEncryptWebServer {
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

- (void)start {
    if (!self.isStarting) {
        [self setupEncryptWebServer];
        self.isStarting = YES;
    }
    
}
+ (NSURL *)proxyUrl:(NSString *)url {
    NSURL *proxyURL = [[WebServerManager.sharedInstance.encrptWebServer serverURL] URLByAppendingPathComponent:url];
    return proxyURL;
}
@end
```