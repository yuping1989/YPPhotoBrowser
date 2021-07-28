//
//  YPNewPhotoBrowser.h
//  YPNewPhotoBrowser
//
//  Created by 喻平 on 16/7/27.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YPPhoto.h"
#import "YPNewPhotoPageView.h"
#import "YPPhotoZoomingView.h"

@class YPNewPhotoBrowser;

@protocol YPNewPhotoBrowserDelegate <NSObject>

@optional
- (NSUInteger)numberOfPhotos:(YPNewPhotoBrowser *)browser;
- (YPPhotoViewCell *)photoBrowser:(YPNewPhotoBrowser *)browser cellForPhotoAtIndex:(NSUInteger)index;

- (void)photoBrowser:(YPNewPhotoBrowser *)browser willDisplayCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(YPNewPhotoBrowser *)browser displayingCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(YPNewPhotoBrowser *)browser didEndDeceleratingOnCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(YPNewPhotoBrowser *)browser didEndDisplayingCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;

- (void)photoBrowser:(YPNewPhotoBrowser *)browser didDeleteCellAtIndex:(NSUInteger)index;

- (void)photoBrowser:(YPNewPhotoBrowser *)browser didClickCellAtIndex:(NSUInteger)index;
- (void)photoBrowserDidClickMoreButton:(YPNewPhotoBrowser *)browser;

- (UIImageView *)photoBrowser:(YPNewPhotoBrowser *)browser animationImageViewForPhotoAtIndex:(NSUInteger)index;

@end

typedef NS_ENUM(NSInteger, YPNewPhotoBrowserAnimation) {
    YPNewPhotoBrowserAnimationNone,
    YPNewPhotoBrowserAnimationTransition, // frame过渡模式，类似于QQ客户端的图片展示动画
    YPNewPhotoBrowserAnimationFade, // 渐变模式
};

@interface YPNewPhotoBrowser : UIViewController <YPNewPhotoPageViewDataSource, YPNewPhotoPageViewDelegate>

@property (nonatomic, strong, readonly) NSMutableArray<YPPhoto *> *photos;

@property (nonatomic, weak) id<YPNewPhotoBrowserDelegate> delegate;

@property (nonatomic, strong) YPNewPhotoPageView *photoPageView;

@property (nonatomic, assign) NSUInteger displayingIndex;

// 隐藏分页指示器，默认为NO
@property (nonatomic, assign) BOOL pageIndicatorHidden;

// 隐藏操作按钮，默认为NO
@property (nonatomic, assign) BOOL moreButtonHidden;

// 隐藏照片描述
@property (nonatomic, assign) BOOL captionHidden;

@property (nonatomic, assign) YPPhotoContentMode photoContentMode;

// 转场动画模式，默认为YPNewPhotoBrowserAnimationNone
@property (nonatomic, assign) YPNewPhotoBrowserAnimation animationStyle;

/**
 *  当animationStyle属性为YPNewPhotoBrowserAnimationTransition时，需设置原始的view对象的contentMode
 *  默认为UIViewContentModeScaleAspectFill
 */
@property (nonatomic, assign) UIViewContentMode transitionAnimationImageContentMode;

// 动画的展示时间，默认为0.3f
@property (nonatomic, assign) CGFloat animationDuration;

/**
 *  创建YPNewPhotoBrowser
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
