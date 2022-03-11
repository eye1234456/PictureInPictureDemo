//
//  AppDelegate.m
//  PictureInPictureDemo
//
//  Created by Flow on 3/11/22.
//

#import "AppDelegate.h"
#import "AESKeyHeader.h"
#import "NSData+FE.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 将未加密数据转换为加密数据
//    [self createEncryptVideos];
    return YES;
}


#pragma mark - UISceneSession lifecycle


/**
 准备图片资源，原始图片+加密图片
 */
- (void)createEncryptVideos {
    NSString *projectSourcePath = @"/Users/xx/xx/xx/PictureInPictureDemo/video";
    NSString *originFolder = @"originVideo";
    NSString *encrypthFolder = @"encryptVideo";
    NSArray *originImages = @[@"1.mp4",
                              @"big_buck_bunny/index.m3u8",
                              @"big_buck_bunny/big_buck_bunny0.ts",
                              @"big_buck_bunny/big_buck_bunny1.ts",
                              @"big_buck_bunny/big_buck_bunny2.ts",
                              @"big_buck_bunny/big_buck_bunny3.ts",
                              @"big_buck_bunny/big_buck_bunny4.ts",
                              @"big_buck_bunny/big_buck_bunny5.ts",
                              
    ];
    for (NSString *originName in originImages) {
        NSString *originImagePath = [NSString stringWithFormat:@"%@/%@/%@",projectSourcePath,originFolder,originName];
        NSString *encryptImagePath = [NSString stringWithFormat:@"%@/%@/%@",projectSourcePath,encrypthFolder,originName];
        NSData *data = [NSData dataWithContentsOfFile:originImagePath];
        NSData *encryptData = [data fe_aesEncryptWithKey:kAESKey];
        [encryptData writeToFile:encryptImagePath atomically:YES];
    }
}



@end
