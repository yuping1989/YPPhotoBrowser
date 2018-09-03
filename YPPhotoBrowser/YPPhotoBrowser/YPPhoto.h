//
//  YPPhoto.h
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/7/27.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YPPhotoProtocol.h"
#import <FLAnimatedImage/FLAnimatedImage.h>

@interface YPPhoto : NSObject <YPPhoto>

// 这4个属性传入一个即可
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) NSURL *thumbnailURL;

@property (nonatomic, assign) CGRect originFrame; // 用来记录该photo的transition动画原始frame

- (void)saveImageToAlbumWithCompletionBlock:(void (^)(NSError *error))completion;

/**
 *  根据一个UIView对象转换该photo的transition动画原始frame
 */
- (void)convertOriginFrameByView:(UIView *)view;

@end
