//
//  SoureModel.h
//  PictureInPictureDemo
//
//  Created by eye on 3/11/22.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, playerType) {
    playerTypeAvPlayer,
    playerTypeIJKPlayer,
};

NS_ASSUME_NONNULL_BEGIN

@interface SoureModel : NSObject
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *url;
@property(nonatomic, assign) BOOL isEncrypt;
@property(nonatomic, assign) playerType playerType;

+(instancetype)modelWithTitle:(NSString *)title
                          url:(NSString *)url
                    isEncrypt:(BOOL)isEncrypt
                   playerType:(playerType)playerType;
@end

NS_ASSUME_NONNULL_END
