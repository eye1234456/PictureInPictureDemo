//
//  SoureModel.m
//  PictureInPictureDemo
//
//  Created by eye on 3/11/22.
//

#import "SoureModel.h"

@implementation SoureModel
+(instancetype)modelWithTitle:(NSString *)title
                          url:(NSString *)url
                    isEncrypt:(BOOL)isEncrypt
                   playerType:(PlayerType)playerType {
    return [SoureModel modelWithTitle:title url:url isEncrypt:isEncrypt playerType:playerType serverType:ServerTypeRemote];
}

+(instancetype)modelWithTitle:(NSString *)title
                          url:(NSString *)url
                    isEncrypt:(BOOL)isEncrypt
                   playerType:(PlayerType)playerType
                   serverType:(ServerType)serverType {
    SoureModel *model = [[self alloc] init];
    model.title = title;
    model.url = url;
    model.isEncrypt = isEncrypt;
    model.playerType = playerType;
    model.serverType = serverType;
    return model;
}
@end
