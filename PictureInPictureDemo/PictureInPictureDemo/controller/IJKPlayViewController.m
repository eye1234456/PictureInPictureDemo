//
//  IJKPlayViewController.m
//  PictureInPictureDemo
//
//  Created by Flow on 3/11/22.
//

#import "IJKPlayViewController.h"
#import <ZFPlayer/ZFIJKPlayerManager.h>

@interface IJKPlayViewController ()

@end

@implementation IJKPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (id<ZFPlayerMediaPlayback>)playerManager {
    return [[ZFIJKPlayerManager alloc] init];
}

@end
////
////  EPVPIPManager.m
////  PictureInPicture
////
////  Created by nsobject on 2020/11/5.
////
//
//#import "EPVPIPManager.h"
//#import <AVKit/AVKit.h>
//#import "GCDWebServer.h"
//#import "GCDWebDAVServer.h"
//#import <CommonCrypto/CommonCrypto.h>
//#import "GCDWebServerDataResponse.h"
//#import "GCDWebServerFileResponse.h"
//#import "EPVMovieInfoModel.h"
//
//
//#import "EPVPIPKeepAppAwakeTool.h"
//@implementation EPVPIPOption
//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        _timeOut = 10.0;
//
//    }
//    return self;
//}
//@end
//@interface EPVPIPManager()<AVPictureInPictureControllerDelegate>
//@property (nonatomic,strong) GCDWebServer *decodeWebSever;
//@property (nonatomic,strong) GCDWebDAVServer *localServer;
//@property (nonatomic,strong) AVPlayer *player;
//@property (nonatomic,strong) AVPlayerLayer *playerLayer;
//@property (nonatomic,strong) AVPictureInPictureController *pipController;
//@property (nonatomic,strong) EPVPIPOption *option;
//@property (nonatomic,assign) BOOL pipAlreadyStartedFlag;
//@property (nonatomic,strong) UIView *avPlayerLayerContainerView;
//@property (nonatomic,assign) BOOL pipIsActuallyShowing;
////#define kDecodeWebSeverPort 10086
////#define kLocalServerPort 10010
//@end
//@implementation EPVPIPManager
//+ (EPVPIPManager *)sharedManager{
//    static EPVPIPManager *manager = nil;
//    static dispatch_once_t once;
//    dispatch_once(&once, ^{
//        manager = [[EPVPIPManager alloc] init];
//
//    });
//    return manager;;
//}
//- (void)destroy{
//    [NSNotificationCenter.defaultCenter removeObserver:self];
//    [_playerLayer removeFromSuperlayer];
//    [_avPlayerLayerContainerView removeFromSuperview];
//    @try {
//        [_player removeObserver:self forKeyPath:@"status"];
//        [_player removeObserver:self forKeyPath:@"timeControlStatus"];
//    }@catch (NSException *exception) {
////        NSLog(@"%@",exception);
//    }
//
//    [_pipController stopPictureInPicture];
//    [_player replaceCurrentItemWithPlayerItem:nil];
//    if (_decodeWebSever.isRunning) {
//        [_decodeWebSever stop];
//    }
//    if (_localServer.isRunning) {
//        [_localServer stop];
//    }
//    [self.class cancelPreviousPerformRequestsWithTarget:self];
//    _player = nil;
//    _playerLayer = nil;
//    _avPlayerLayerContainerView = nil;
//    _decodeWebSever = nil;
//    _localServer = nil;
//    _pipController = nil;
//    _option = nil;
//    _failBlock = nil;
//    _successBlock = nil;
//    _restoreBlock = nil;
//    _getCurrentPlayTimeBlock = nil;
////    _stoppedBlock = nil;
//    _videoInfoDic = nil;
//    _pipAlreadyStartedFlag = NO;
//    _pipIsActuallyShowing = NO;
//}
//- (void)playWithOption:(EPVPIPOption *)option{
//    [self destroy];
//    _option = option;
//    if (_option.isLocalVideo) {
//        [self setupLocalServer];
//    }
//
//    [self setupDecodeServer];
//
//    NSString *decodeServerUrl = [NSString stringWithFormat:@"%@%@",_decodeWebSever.serverURL.absoluteString,_option.url];
//    [self setupPlayerWithDecodeServerUrl:decodeServerUrl];
//
//    [self performSelector:@selector(timeOutHandle) withObject:nil afterDelay:_option.timeOut];
//
//}
//- (void)timeOutHandle{
//    if (!self.pipIsActuallyShowing) {
//        [self failHandle];
//    }
//
//}
////本地视频服务器
//- (void)setupLocalServer{
//    NSAssert(_option.m3u8FileName, @"本地视频必须设置m3u8FileName");
//    NSString *uploadDirectory = [_option.url stringByReplacingOccurrencesOfString:_option.m3u8FileName withString:@""];
//     _localServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:uploadDirectory];
//    int port = [self getRandomLocalServerPort];
//    [_localServer startWithPort:port bonjourName:nil];
//    //本地服务器取随机port,因为解码时候用到的NSURLSessionDataTask有缓存机制,port写死的话,会因为链接相同而取缓存的数据,可能会造成视频串到之前播放的本地视频
//    _option.url = [NSString stringWithFormat:@"%@%@",_localServer.serverURL.absoluteString,_option.m3u8FileName];
//    NSLog(@"%@",_option.url);
//}
////解密服务器
//- (void)setupDecodeServer{
//
//    _decodeWebSever = [[GCDWebServer alloc] init];
//    @weakify(self)
//    [_decodeWebSever addHandlerWithMatchBlock:^GCDWebServerRequest * _Nullable(NSString * _Nonnull requestMethod, NSURL * _Nonnull requestURL, NSDictionary<NSString *,NSString *> * _Nonnull requestHeaders, NSString * _Nonnull urlPath, NSDictionary<NSString *,NSString *> * _Nonnull urlQuery) {
////        @strongify(self)
//        NSString *path = [urlPath stringByReplacingOccurrencesOfString:@"/http" withString:@"http"];
//        GCDWebServerRequest *req = [[GCDWebServerRequest alloc] initWithMethod:requestMethod url:[NSURL URLWithString:path] headers:requestHeaders path:urlPath query:urlQuery];
//        return  req;
//    } asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
//        @strongify(self)
//        NSString *urlPath = request.URL.absoluteString;
//        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlPath]];
//        NSURLSession *session = [NSURLSession sharedSession];
//        NSURLSessionDataTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//            NSData *deCodedData = nil;
//            if (!error && data) {
//                deCodedData  =  [self deCodeData:data];
//            }
//            GCDWebServerDataResponse *res = [GCDWebServerDataResponse responseWithData:deCodedData contentType:@"audio/mpegurl"];
//            completionBlock(res);
//
//        }];
//        [task resume];
//
//    }];
//
//    [_decodeWebSever startWithPort:10000 bonjourName:nil];
//
//}
//
//- (int)getRandomLocalServerPort{
//    //20000-99999随机数,包含20000和99999
//    return  (20000+(arc4random()%(99999-20000+1)));
//}
//
//- (void)setupPlayerWithDecodeServerUrl:(NSString *)decodeServerUrl{
//    _player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:decodeServerUrl]];
//    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
////    _playerLayer.backgroundColor = UIColor.blackColor.CGColor;
//
//    //_playerLayer 不能直接加在window上
//    _avPlayerLayerContainerView = [[UIView alloc] init];
//    [UIApplication.sharedApplication.delegate.window addSubview:_avPlayerLayerContainerView];
//    [_avPlayerLayerContainerView.layer addSublayer:_playerLayer];
//    _avPlayerLayerContainerView.frame = _option.startFrame;
//    _playerLayer.frame = _avPlayerLayerContainerView.bounds;
//    _avPlayerLayerContainerView.hidden = YES;
//
//
//    [self.player  addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//    [self.player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
//    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
//    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(becomeAcitve) name:UIApplicationDidBecomeActiveNotification object:nil];
//    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(failHandle) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
//
//}
//- (void)enterBackground{
//    [EPVPIPKeepAppAwakeTool.sharedInstance start];
//}
//- (void)becomeAcitve{
//    [EPVPIPKeepAppAwakeTool.sharedInstance stop];
//}
//
//- (void)startPip{
//    if (self.isPipAvailable) {
//        NSError *error = nil;
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
//        [[AVAudioSession sharedInstance] setActive:YES error:&error];
//
//        if (error) {
//            NSLog(@"请求权限失败的原因为%@",error);
//            [self failHandle];
//        }else{
//
//            self.pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:_playerLayer];
//            self.pipController.delegate = self;
//         //延迟一秒开始,不然有时候会开启失败
//            [self performSelector:@selector(finalStartPip) withObject:nil afterDelay:1];
//
//        }
//
//
//    }else{
//        [self failHandle];
//    }
//
//}
//- (void)finalStartPip{
////    NSLog(@"%ld",UIApplication.sharedApplication.applicationState);
//    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) { //此时如果app不是在前台运行,画中画会启动不了
//        [self.pipController startPictureInPicture];
//    }else{
//        [self failHandle];
//    }
//
//}
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
//
//        if ([keyPath isEqualToString:@"status"]) {
//             switch (self.player.status) {
//                 case AVPlayerStatusUnknown:{
//                     NSLog(@"KVO：未知状态，此时不能播放");
//                     [self failHandle];
//                     break;
//                 }
//                 case AVPlayerStatusReadyToPlay:{
//                      NSLog(@"KVO：准备完毕，可以播放");
//                     int32_t timeScale = self.player.currentItem.asset.duration.timescale;
//
//                     NSTimeInterval currentPlayTime = 0;
//                     if (_getCurrentPlayTimeBlock) {
//                         currentPlayTime =  _getCurrentPlayTimeBlock();
//                     }
//
//                     Float64 seekTo = currentPlayTime;
//                     CMTime time = CMTimeMakeWithSeconds(seekTo, timeScale);
//                     BOOL fail = NO;
//                     @try {
//                         [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
//                     } @catch (NSException *exception) {
//                         NSLog(@"%@",exception);
//                         fail = YES;
//
//                     }
//                     if (fail) {
//                         [self failHandle];
//                     }else{
//                         [self.player play];
//                     }
//
//
//                       break;
//                 }
//                 case AVPlayerStatusFailed:{
////                     AVPlayerItem * item = (AVPlayerItem *)object;
////                     NSLog(@"加载异常 %@",item.error);
//                     [self failHandle];
//               break;
//                 }
//                 default:{
//
//                 }
//               break;
//             }
//        }else if ([keyPath isEqualToString:@"timeControlStatus"]){
//            if (@available(iOS 10.0, *)) {
//                if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
//                    //这个可能会多次回调,所以判断一下,防止多次调用[self startPip]
//                    if (!_pipAlreadyStartedFlag) {
//                        //真正开始播放时候 再seek一下, 使播放点更准确
//                        int32_t timeScale = self.player.currentItem.asset.duration.timescale;
//                        NSTimeInterval currentPlayTime = 0;
//                        if (_getCurrentPlayTimeBlock) {
//                            currentPlayTime =  _getCurrentPlayTimeBlock();
//                        }
//                        Float64 seekTo = currentPlayTime+2; //真正开始画中画 大概在2秒之后
//                        CMTime time = CMTimeMakeWithSeconds(seekTo, timeScale);
//                        BOOL fail = NO;
//                        @try {
//                            [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
//                        } @catch (NSException *exception) {
//                            NSLog(@"%@",exception);
//                            fail = YES;
//                        }
//                        if (fail) {
//                            [self failHandle];
//                        }else{
//                            [self startPip];
//                            _pipAlreadyStartedFlag = YES;
//                        }
//
//
//                    }
//
//                }
//            } else {
//                // 不用处理,因为画中画只有ios14才有
//            }
//        }
//
//
//}
//
////解密
//- (NSData *)deCodeData:(NSData *)originalData{
//    NSString *key = @"saIZXc4yMvq0Iz56";
//    char keyPtr[kCCKeySizeAES128 + 1];
//     memset(keyPtr, 0, sizeof(keyPtr));
//     [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
//     NSUInteger dataLength = [originalData length];
//    size_t bufferSize = dataLength + kCCBlockSizeAES128;
//    void *buffer = malloc(bufferSize);
//   size_t numBytesCrypted = 0;
//    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,kCCAlgorithmAES128,kCCOptionPKCS7Padding|kCCOptionECBMode,keyPtr,kCCBlockSizeAES128,NULL,[originalData bytes],dataLength,buffer,bufferSize,&numBytesCrypted);
//    if (cryptStatus == kCCSuccess) {
//        NSData *decodedData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
////      NSString * m3u8Str = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
////        NSLog(@"%@",m3u8Str);
//        return decodedData;
//    }else{
//        return nil;
//    }
//
//
//
//}
//#pragma mark - AVPictureInPictureControllerDelegate
//-(void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
//    if (self.successBlock) {
//        self.successBlock();
//    }
//    self.pipIsActuallyShowing = YES;
//    DLog(@"即将开启画中画功能");
//    [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"ViewMethod3"];
//}
//
//-(void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
//    DLog(@"已经开启画中画功能");
//
//}
//
//-(void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
//    DLog(@"即将停止画中画功能");
//    NSDictionary *videoInfoDic = self.videoInfoDic;
//    NSTimeInterval sec = CMTimeGetSeconds(_player.currentTime);
//    if (isnan(sec)) {
//        sec = 0;
//    }
//    if (videoInfoDic[@"videoId"]) {
//        [[NSUserDefaults standardUserDefaults] setFloat:sec forKey:videoInfoDic[@"videoId"]];
//    }
//    EPVMovieInfoModel *model = [EPVMovieInfoModel modelWithJSON:[videoInfoDic objectForKey:@"movie"]];
//    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"is_mother":@([model.video_type isEqualToString:@"0"]),@"country_real":model.country_name,@"is_membermovie":@(model.play_ctrl),@"is_goldcoinmovie":@(@(model.is_point != 0).boolValue)}];
//    [dict addEntriesFromDictionary:[EPVConfigModel getDetailSensorDataWithDict:[videoInfoDic objectForKey:@"detailDict"] entryStr:[videoInfoDic objectForKey:@"entryStr"]]];
//    [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"ViewMethod3" withProperties:dict];
//    [self destroy];
//
//}
//
//-(void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
//    DLog(@"已经停止画中画功能");
//
//}
//
//- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error {
//    DLog(@"开启画中画功能失败，原因是%@",error);
//    [self failHandle];
//}
//
//- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL restored))completionHandler{
//    NSLog(@"%lld",_player.currentTime.value);
//    NSTimeInterval sec = CMTimeGetSeconds(_player.currentTime);
//    if (isnan(sec)) {
//        sec = 0;
//    }
//
//
//    if (_restoreBlock) {
//        _restoreBlock(sec);
//    }
//    completionHandler(YES);
//}
//- (void)failHandle{
//    if (self.failBlock) {
//        self.failBlock();
//    }
//    [self destroy];
//
//}
//- (BOOL)isPipAvailable{
//    return AVPictureInPictureController.isPictureInPictureSupported;
//}
//@end

