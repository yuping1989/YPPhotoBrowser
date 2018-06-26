//
//  YPPhotoViewCell.h
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/7/27.
//  Copyright © 2016年 com.yp. All rights reserved.
//
//  此类的作用于UITableViewCell类似

#import <UIKit/UIKit.h>
#import "YPPhotoZoomingView.h"
#import "YPPhotoProtocol.h"

@interface YPPhotoViewCell : UIView

@property (nonatomic, strong) id<YPPhoto> photo;

// 用于显示图像和处理放大缩小等交互
@property (nonatomic, strong, readonly) YPPhotoZoomingView *photoView;

// 此属性用于记录当前cell的索引，不能在配置cell时手动设置
@property (nonatomic, assign) NSUInteger index;

// attributed标题
@property (nonatomic, strong) NSAttributedString *attributedCaption;

// 普通标题，captionColor和captionFont均为针对普通标题设置的属性
@property (nonatomic, copy) NSString *caption;
@property (nonatomic, strong) UIColor *captionColor;
@property (nonatomic, strong) UIFont *captionFont;
@property (nonatomic, assign, getter = isCptionViewHidden) BOOL captionViewHidden;

// captionView是否展开
@property (nonatomic, assign, getter = isCaptionOpened) BOOL captionOpened;

// captionView展开时的最大高度
@property (nonatomic, assign) CGFloat maxHeightOfCaptionWhenOpened;

// captionView关闭时的最大高度
@property (nonatomic, assign) CGFloat maxHeightOfCaptionWhenClosed;

// 动画的时长，默认为0.3f
@property (nonatomic, assign) CGFloat animationDuration;

// 重置cell
- (void)prepareForReuse;

- (void)setCaptionViewHidden:(BOOL)hidden animated:(BOOL)animated;

@end
