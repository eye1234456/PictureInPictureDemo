//
//  SoureModel.h
//  PictureInPictureDemo
//
//  Created by eye on 3/11/22.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, PlayerType) {
    PlayerTypeAvPlayer,
    PlayerTypeIJKPlayer,
};

typedef NS_ENUM(NSInteger, ServerType) {
    ServerTypeRemote, // 使用http、https访问远程服务器
    ServerTypeLocalBundle, // 访问通过NSBundle加载的项目中的文件
    ServerTypeLocalSandBox, // 访问保存在沙盒里的文件
};

NS_ASSUME_NONNULL_BEGIN

@interface SoureModel : NSObject
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *url;
@property(nonatomic, assign) BOOL isEncrypt;
@property(nonatomic, assign) PlayerType playerType;
@property(nonatomic, assign) ServerType serverType;

+(instancetype)modelWithTitle:(NSString *)title
                          url:(NSString *)url
                    isEncrypt:(BOOL)isEncrypt
                   playerType:(PlayerType)playerType;

+(instancetype)modelWithTitle:(NSString *)title
                          url:(NSString *)url
                    isEncrypt:(BOOL)isEncrypt
                   playerType:(PlayerType)playerType
                   serverType:(ServerType)serverType;
@end

NS_ASSUME_NONNULL_END
