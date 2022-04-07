//
//  WebServerManager.h
//  PictureInPictureDemo
//
//  Created by eye on 3/14/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebServerManager : NSObject
+ (instancetype)sharedInstance;
- (void)start;
+ (NSURL *)proxyUrl:(NSString *)url;
+ (NSURL *)davProxyUrl:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
