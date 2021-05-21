//
//  YPPhotoProtocol.h
//  YPPhotoBrowser
//
//  Created by 喻平 on 2018/6/21.
//  Copyright © 2018年 com.yp. All rights reserved.
//

static NSString * const YPPhotoLoadingDidEndNotification = @"YPPhotoLoadingDidEndNotification";
static NSString * const YPPhotoProgressNotification = @"YPPhotoProgressNotification";

@protocol YPPhoto <NSObject>

@required

/**
 显示的原图
 展示时会优先检查此方法是否返回图像，如果为nil，则使用thumbnailImage方法获取缩略图，
 同时调用startDownloadImageAndNotify方法开始下载图像
 */
- (id)displayImage;

@optional

- (void)preloadImage;
- (void)resetImage;

/**
 下载图片并且发送通知
 */
- (void)startDownloadImageAndNotify;

/**
 在加载正式图片时，展示的缩略图
 */
- (UIImage *)thumbnailImage;

/**
 图像的描述，这段描述会显示在图片的下方，效果参考demo
 如果是普通文字，使用caption，如果是富文本，使用attributedCaption
 */
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSAttributedString *attributedCaption;

@end
