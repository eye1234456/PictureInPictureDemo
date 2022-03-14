//
//  WebServerManager.m
//  PictureInPictureDemo
//
//  Created by eye on 3/14/22.
//

#import "WebServerManager.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import "AESKeyHeader.h"
#import "NSData+FE.h"

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
