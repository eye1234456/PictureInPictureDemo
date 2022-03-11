//
//  NSData+FE.h
//  SDWebImageEncrypt
//
//  Created by lonelyEye on 3/10/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (FE)
- (NSData *)fe_aesEncryptWithKey:(NSString *)aesKey;
- (NSData *)fe_aesEncryptWithKey:(NSString *)aesKey iv:(NSString *)iv;
- (NSData *)fe_aesDecryptWithKey:(NSString *)aesKey;
- (NSData *)fe_aesDecryptWithKey:(NSString *)aesKey iv:(NSString *)iv;

@end

NS_ASSUME_NONNULL_END
