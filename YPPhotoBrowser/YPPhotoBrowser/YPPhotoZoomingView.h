//
//  YPPhotoZoomingView.h
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/8/25.
//  Copyright © 2016年 com.yp. All rights reserved.
//

typedef NS_ENUM(NSInteger, YPPhotoContentMode) {
    YPPhotoContentModeCenter,
    YPPhotoContentModeScaleFill,
    YPPhotoContentModeScaleFillHeight,
};

#import <UIKit/UIKit.h>
#import <FLAnimatedImage/FLAnimatedImage.h>

@class YPPhoto;
@class YPPhotoProgressView;

extern NSString * const YPPhotoViewCellSingleTappedNotification;

@interface YPPhotoZoomingView : UIScrollView

@property (nonatomic, strong, readonly) FLAnimatedImageView *photoImageView;
@property (nonatomic, strong, readonly) YPPhotoProgressView *progressView;

// 动画时长，默认为0.3f
@property (nonatomic, assign) CGFloat animationDuration;

@property (nonatomic, assign) YPPhotoContentMode photoContentMode;

/**
 *  显示image对象
 */
- (void)displayImage:(id)image animatied:(BOOL)animatied;

// 重置最大和最小缩放比例
- (void)updateZoomScaleForCurrentBounds;

@end
