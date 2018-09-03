//
//  YPPhotoUtil.m
//  YPAlbum
//
//  Created by 喻平 on 2018/7/21.
//  Copyright © 2018年 com.yp. All rights reserved.
//

#import "YPPhotoUtil.h"

@implementation YPPhotoUtil

+ (BOOL)isImageWithPath:(NSString *)path {
    if (path.length == 0) {
        return NO;
    }
    NSString *pathExt = [path.pathExtension lowercaseString];
    if ([pathExt isEqualToString:@"jpg"] ||
        [pathExt isEqualToString:@"png"] ||
        [pathExt isEqualToString:@"jpeg"] ||
        [pathExt isEqualToString:@"webp"] ||
        [pathExt isEqualToString:@"tiff"] ||
        [pathExt isEqualToString:@"gif"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isGifWithPath:(NSString *)path {
    if (path.length == 0) {
        return NO;
    }
    NSString *pathExt = [path.pathExtension lowercaseString];
    if ([pathExt isEqualToString:@"gif"]) {
        return YES;
    } else {
        UIImageType type = [self imageTypeWithPath:path];
        return type == UIImageTypeGIF;
    }
    return NO;
}

+ (UIImageType)imageTypeWithPath:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self imageTypeWithData:data];
}

+ (UIImageType)imageTypeWithData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return UIImageTypeJPG;
        case 0x89:
            return UIImageTypePNG;
        case 0x47:
            return UIImageTypeGIF;
        case 0x49:
        case 0x4D:
            return UIImageTypeTIFF;
        case 0x52: {
            if ([data length] < 12) {
                return UIImageTypeUnkown;
            }
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return UIImageTypeWEBP;
            }
        }
    }
    return UIImageTypeUnkown;
}

+ (BOOL)isVideoWithPath:(NSString *)path {
    if (path.length == 0) {
        return NO;
    }
    NSString *pathExt = [path.pathExtension lowercaseString];
    if ([pathExt isEqualToString:@"mp4"]) {
        return YES;
    }
    return NO;
}

+ (YPFileType)fileTypeWithPath:(NSString *)path {
    BOOL isDic = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDic];
    if (isDic) {
        return YPFileTypeDirectory;
    } else if ([YPPhotoUtil isImageWithPath:path]) {
        return YPFileTypeImage;
    } else if ([YPPhotoUtil isVideoWithPath:path]) {
        return YPFileTypeVideo;
    }
    return YPFileTypeVideoUnknown;
}

@end
