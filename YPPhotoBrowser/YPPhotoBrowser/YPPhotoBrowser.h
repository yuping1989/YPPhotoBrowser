//
//  YPPhotoBrowser.h
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/7/27.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YPPhoto.h"
#import "YPPhotoPageView.h"
#import "YPPhotoZoomingView.h"

@class YPPhotoBrowser;

@protocol YPPhotoBrowserDelegate <NSObject>

@optional
- (NSUInteger)numberOfPhotos:(YPPhotoBrowser *)browser;
- (YPPhotoViewCell *)photoBrowser:(YPPhotoBrowser *)browser cellForPhotoAtIndex:(NSUInteger)index;

- (void)photoBrowser:(YPPhotoBrowser *)browser willDisplayCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(YPPhotoBrowser *)browser displayingCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(YPPhotoBrowser *)browser didEndDeceleratingOnCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(YPPhotoBrowser *)browser didEndDisplayingCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;

- (void)photoBrowser:(YPPhotoBrowser *)browser didClickCellAtIndex:(NSUInteger)index;
- (void)photoBrowserDidClickMoreButton:(YPPhotoBrowser *)browser;

- (UIImageView *)photoBrowser:(YPPhotoBrowser *)browser animationImageViewForPhotoAtIndex:(NSUInteger)index;

@end

typedef NS_ENUM(NSInteger, YPPhotoBrowserAnimation) {
    YPPhotoBrowserAnimationNone,
    YPPhotoBrowserAnimationTransition, // frame过渡模式，类似于QQ客户端的图片展示动画
    YPPhotoBrowserAnimationFade, // 渐变模式
};

@interface YPPhotoBrowser : UIViewController <YPPhotoPageViewDataSource, YPPhotoPageViewDelegate>

@property (nonatomic, weak) id<YPPhotoBrowserDelegate> delegate;

@property (nonatomic, strong) YPPhotoPageView *photoPageView;

@property (nonatomic, assign) NSUInteger displayingIndex;

// 隐藏分页指示器，默认为NO
@property (nonatomic, assign) BOOL pageIndicatorHidden;

// 隐藏操作按钮，默认为NO
@property (nonatomic, assign) BOOL moreButtonHidden;

// 隐藏照片描述
@property (nonatomic, assign) BOOL captionHidden;

@property (nonatomic, assign) YPPhotoContentMode photoContentMode;

// 转场动画模式，默认为YPPhotoBrowserAnimationNone
@property (nonatomic, assign) YPPhotoBrowserAnimation animationStyle;

/**
 *  当animationStyle属性为YPPhotoBrowserAnimationTransition时，需设置原始的view对象的contentMode
 *  默认为UIViewContentModeScaleAspectFill
 */
@property (nonatomic, assign) UIViewContentMode transitionAnimationImageContentMode;

// 动画的展示时间，默认为0.3f
@property (nonatomic, assign) CGFloat animationDuration;

/**
 *  创建YPPhotoBrowser
 *
 *  @param photos photo数组，数组的元素可以是YPPhoto, NSString, NSURL, UIImage四种类型及其子类
 */
- (instancetype)initWithPhotos:(NSArray *)photos;


- (void)show;

/**
 *  设置navigation item，此方法可根据不同需求重写
 */
- (void)setupNavigationItem;

@end
