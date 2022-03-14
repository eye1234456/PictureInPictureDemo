//
//  PipManager.h
//  PictureInPictureDemo
//
//  Created by eye on 3/14/22.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <ZFPlayer/ZFPlayerController.h>
NS_ASSUME_NONNULL_BEGIN

@interface PipManager : NSObject
+ (instancetype)sharedInstance;
- (void)showPipWithPlayer:(ZFPlayerController *)player;
@end

NS_ASSUME_NONNULL_END
