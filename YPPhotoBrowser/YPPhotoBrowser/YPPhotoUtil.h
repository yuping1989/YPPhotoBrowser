//
//  YPPhotoUtil.h
//  YPAlbum
//
//  Created by 喻平 on 2018/7/21.
//  Copyright © 2018年 com.yp. All rights reserved.
//

typedef NS_ENUM(NSInteger, UIImageType) {
    UIImageTypeUnkown,
    UIImageTypeJPG,
    UIImageTypePNG,
    UIImageTypeGIF,
    UIImageTypeTIFF,
    UIImageTypeWEBP,
};

typedef NS_ENUM(NSInteger, YPFileType) {
    YPFileTypeVideoUnknown,
    YPFileTypeDirectory,
    YPFileTypeImage,
    YPFileTypeVideo
};

#import <Foundation/Foundation.h>

@interface YPPhotoUtil : NSObject

+ (BOOL)isImageWithPath:(NSString *)path;

+ (BOOL)isGifWithPath:(NSString *)path;

+ (UIImageType)imageTypeWithPath:(NSString *)path;

+ (UIImageType)imageTypeWithData:(NSData *)data;

+ (BOOL)isVideoWithPath:(NSString *)path;

+ (YPFileType)fileTypeWithPath:(NSString *)path;

@end
