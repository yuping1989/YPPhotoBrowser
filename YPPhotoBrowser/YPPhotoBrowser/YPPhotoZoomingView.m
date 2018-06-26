//
//  YPPhotoZoomingView.m
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/8/25.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import "YPPhotoZoomingView.h"
#import "YPPhoto.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDImageCache.h>
#import "YPPhotoProgressView.h"

NSString * const YPPhotoViewCellSingleTappedNotification =  @"YPPhotoViewCellSingleTappedNotification";

@interface YPPhotoZoomingView () <UIScrollViewDelegate>

@end

@implementation YPPhotoZoomingView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)_setup {
    
    _photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _photoImageView.backgroundColor = [UIColor clearColor];
    [self addSubview:_photoImageView];
    
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    [self addGestureRecognizer:singleTap];
    [self addGestureRecognizer:doubleTap];
    
    _progressView = [[YPPhotoProgressView alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
    
    _progressView.userInteractionEnabled = NO;
    _progressView.roundedCorners = 2;
    _progressView.progressLabel.font = [UIFont boldSystemFontOfSize:11];
    _progressView.progressLabel.textColor = [UIColor whiteColor];
    [self addSubview:_progressView];
    _progressView.hidden = YES;
    
    [self moveViewToCenter:_progressView];
    
    _animationDuration = 0.3f;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.progressView.hidden) {
        [self moveViewToCenter:self.progressView];
    }
    [self moveViewToCenter:self.photoImageView];
}

- (void)moveViewToCenter:(UIView *)view {
    CGRect frameToCenter = view.frame;
    CGSize boundsSize = self.bounds.size;
    
    // 水平方向
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // 竖直方向
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    if (!CGRectEqualToRect(view.frame, frameToCenter)) {
        view.frame = frameToCenter;
    }
}

/**
 *  显示image对象
 */
- (void)displayImage:(UIImage *)image animatied:(BOOL)animatied {
    self.photoImageView.image = image;
    
    // 根据run loop判断是否有scroll view滚动的情况，如果有，则不显示动画
    if (animatied &&
        image &&
        self.animationDuration > 0.0f &&
        [[NSRunLoop mainRunLoop].currentMode isEqualToString:NSDefaultRunLoopMode]) {
        
        [UIView animateWithDuration:self.animationDuration
                         animations:^{
                             [self moveImageViewToCenterAndFix];
                         } completion:^(BOOL finished) {
                             [self setMaxMinZoomScalesForCurrentBounds];
                         }];
    } else {
        [self moveImageViewToCenterAndFix];
        [self setMaxMinZoomScalesForCurrentBounds];
    }
}

/**
 *  将图片移到容器中央并匹配其宽高
 */
- (void)moveImageViewToCenterAndFix {
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = self.photoImageView.image.size;
    
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    if (imageSize.width > 0.0f && imageSize.height > 0.0f) {
        // 当图片的宽高均大于0时，计算缩放比例
        CGFloat xScale = boundsSize.width / imageSize.width;
        CGFloat yScale = boundsSize.height / imageSize.height;
        if (xScale < 1.0f || yScale < 1.0f) {
            CGFloat minScale = MIN(xScale, yScale);
            width = imageSize.width * minScale;
            height = imageSize.height * minScale;
        }
    }
    CGFloat x = floorf((boundsSize.width - width) / 2.0f);
    CGFloat y = floorf((boundsSize.height - height) / 2.0f);
    self.photoImageView.frame = CGRectMake(x, y, width, height);
}

/**
 *  初始化最大和最小缩放比例
 */
- (void)setMaxMinZoomScalesForCurrentBounds {
    
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    if (!self.photoImageView.image) {
        return;
    }
    
    // 初始化photoImageView的size
    self.photoImageView.frame = CGRectMake(0, 0, self.photoImageView.image.size.width, self.photoImageView.image.size.height);
    
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = self.photoImageView.image.size;
    
    // 计算最小缩放比例
    CGFloat xScale = boundsSize.width / imageSize.width;
    CGFloat yScale = boundsSize.height / imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);
    
    // 计算最大缩放比例
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // 在iPad上，支持更大缩放比例
        maxScale = 4;
    }
    
    // 如果图像比屏幕更小，不缩放
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0;
    }
    
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // 初始化缩放比例
    self.zoomScale = minScale;
    
    self.scrollEnabled = NO;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    // 设置为支持滚动
    self.scrollEnabled = YES;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.photoImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Handle tap gesture

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [[NSNotificationCenter defaultCenter] postNotificationName:YPPhotoViewCellSingleTappedNotification object:nil];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint touchPoint = [recognizer locationInView:self.photoImageView];
    if (self.zoomScale != self.minimumZoomScale) {
        // 恢复初始缩放比例
        [self setZoomScale:self.minimumZoomScale animated:YES];
    } else {
        // 放大以显示双击的位置
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize) animated:YES];
    }
}

@end
