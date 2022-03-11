//
//  SoureModel.m
//  PictureInPictureDemo
//
//  Created by Flow on 3/11/22.
//

#import "SoureModel.h"

@implementation SoureModel
+(instancetype)modelWithTitle:(NSString *)title
                          url:(NSString *)url
                    isEncrypt:(BOOL)isEncrypt
                   playerType:(playerType)playerType {
    SoureModel *model = [[self alloc] init];
    model.title = title;
    model.url = url;
    model.isEncrypt = isEncrypt;
    model.playerType = playerType;
    return model;
}
@end
