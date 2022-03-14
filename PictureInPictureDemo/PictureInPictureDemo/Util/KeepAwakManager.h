//
//  KeepAwakManager.h
//  PictureInPictureDemo
//
//  Created by eye on 3/14/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeepAwakManager : NSObject
+ (instancetype)sharedInstance;
- (void)start;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
