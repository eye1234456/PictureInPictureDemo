//
//  WebServerManager.m
//  PictureInPictureDemo
//
//  Created by eye on 3/14/22.
//

#import "WebServerManager.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <GCDWebServer/GCDWebServerFileResponse.h>
#import "AESKeyHeader.h"
#import "NSData+FE.h"
#import <GCDWebUploader.h>
#import <GCDWebDAVServer.h>

@interface WebServerManager()
@property(nonatomic, strong) GCDWebServer *webServer;
@property(nonatomic, strong) GCDWebUploader *uploadServer;
@property(nonatomic, strong) GCDWebServer *davServer;
@property(nonatomic, assign) BOOL isStarting;
@end

@implementation WebServerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static WebServerManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
        [instance setupServers];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (void)setupServers {
    [self setupWebServer];
    [self setupDAVServer];
//    [self setupUploaderServer];
}
- (void)setupWebServer {
    self.webServer = [[GCDWebServer alloc] init];
    [self.webServer addHandlerWithMatchBlock:^GCDWebServerRequest * _Nullable(NSString * _Nonnull requestMethod, NSURL * _Nonnull requestURL, NSDictionary<NSString *,NSString *> * _Nonnull requestHeaders, NSString * _Nonnull urlPath, NSDictionary<NSString *,NSString *> * _Nonnull urlQuery) {
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
    
    [self.webServer startWithPort:8081 bonjourName:nil];
}

- (void)setupUploaderServer {
    NSString *documentsPath = [NSString stringWithFormat:@"%@%@",NSHomeDirectory(),@"/Documents"];
       self.uploadServer = [[GCDWebUploader alloc] initWithUploadDirectory:documentsPath];
       [self.uploadServer startWithPort:8082 bonjourName:@"Web Based Uploads"];
}

- (void)setupDAVServer {
    //初始化文件管理类
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //获取本地磁盘缓存文件夹路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *path = [paths lastObject];
    NSString *diskCachePath = [NSString stringWithFormat:@"%@%@",path,@"/webCache"];
    NSLog(@"diskCachePath: %@",diskCachePath);
    //判断是否创建本地磁盘缓存文件夹
    BOOL isDirectory = NO;
    BOOL isExisted = [fileManager fileExistsAtPath:diskCachePath isDirectory:&isDirectory];
    if (!isDirectory || !isExisted){
        NSError *error;
        [fileManager createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
            return;
        }
    }
    self.davServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:diskCachePath];
    
//    __weak typeof(self) weakself = self;
    [self.davServer addHandlerWithMatchBlock:^GCDWebServerRequest * _Nullable(NSString * _Nonnull requestMethod, NSURL * _Nonnull requestURL, NSDictionary<NSString *,NSString *> * _Nonnull requestHeaders, NSString * _Nonnull urlPath, NSDictionary<NSString *,NSString *> * _Nonnull urlQuery) {
        NSString *path = [urlPath stringByReplacingOccurrencesOfString:@"/http" withString:@"http"];
        if (![path.lowercaseString hasPrefix:@"http"]) {
            return nil;
        }
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
//            GCDWebServerDataResponse *res = [GCDWebServerDataResponse responseWithData:deCodedData contentType:@"video/webm"];
            GCDWebServerFileResponse *res =
            [GCDWebServerFileResponse responseWithFile:@"/Users/flow/Library/Developer/CoreSimulator/Devices/8CA5A90B-807B-49B1-9D3B-273BBF27DCB8/data/Containers/Data/Application/E5F0DCD4-0BDD-44CF-95FA-6D1F5BC65F78/Documents/3.webm" byteRange:request.byteRange];
            // 回调完成
            completionBlock(res);
        }];
        [task resume];
    }];
        
    [self.davServer startWithPort:8083 bonjourName:@"WebDAV Server"];
}
- (void)start {
    if (!self.webServer.isRunning) {
        [self.webServer start];
    }
    if (!self.uploadServer.isRunning) {
        [self.uploadServer start];
    }
    if (!self.davServer.isRunning) {
        [self.davServer start];
    }
}

- (void)stop {
    if (self.webServer.isRunning) {
        [self.webServer stop];
    }
    if (self.uploadServer.isRunning) {
        [self.uploadServer stop];
    }
    if (self.davServer.isRunning) {
        [self.davServer stop];
    }
}

- (void)destroy {
    [self stop];
    self.webServer = nil;
    self.uploadServer = nil;
    self.davServer = nil;
}

+ (NSURL *)proxyUrl:(NSString *)url {
    NSURL *proxyURL = [[WebServerManager.sharedInstance.webServer serverURL] URLByAppendingPathComponent:url];
    return proxyURL;
}

+ (NSURL *)davProxyUrl:(NSString *)url {
    NSURL *proxyServer = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%ld", WebServerManager.sharedInstance.davServer.port]];
    NSURL *proxyURL = [proxyServer URLByAppendingPathComponent:url];
    return proxyURL;
}
@end
