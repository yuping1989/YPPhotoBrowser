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
NSString * const YPPhotoViewCellLongPressedNotification =  @"YPPhotoViewCellLongPressedNotification";

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
    
    _photoImageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectZero];
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
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self addGestureRecognizer:longPress];
    
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
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // 竖直方向
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2);
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
- (void)displayImage:(id)image animatied:(BOOL)animatied {
    if ([image isKindOfClass:[UIImage class]]) {
        self.photoImageView.image = image;
    } else if ([image isKindOfClass:[FLAnimatedImage class]]) {
        self.photoImageView.animatedImage = image;
    } else {
        self.photoImageView.image = nil;
    }
    
    // 根据run loop判断是否有scroll view滚动的情况，如果有，则不显示动画
    if (animatied &&
        image &&
        self.animationDuration > 0 &&
        [[NSRunLoop mainRunLoop].currentMode isEqualToString:NSDefaultRunLoopMode]) {
        
        [UIView animateWithDuration:self.animationDuration
                         animations:^{
                             [self moveImageViewToCenterAndFix];
                         } completion:^(BOOL finished) {
                             [self updateFrameAndZoomScaleForImageView];
                         }];
    } else {
        [self updateFrameAndZoomScaleForImageView];
    }
}

/**
 *  将图片移到容器中央并匹配其宽高
 */
- (void)moveImageViewToCenterAndFix {
    CGSize imageSize = self.photoImageView.image.size;
    CGFloat scale = [self scaleWithImageSize:imageSize];
    
    CGFloat width = imageSize.width * scale;
    CGFloat height = imageSize.height * scale;
    CGFloat x = (self.bounds.size.width - width) / 2;
    CGFloat y = (self.bounds.size.height - height) / 2;
    self.photoImageView.frame = CGRectMake(x, y, width, height);
}

/**
 *  初始化最大和最小缩放比例
 */
- (void)updateFrameAndZoomScaleForImageView {
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    if (!self.photoImageView.image) {
        return;
    }
    // 初始化photoImageView的size
    CGFloat x = (self.bounds.size.width - self.photoImageView.image.size.width) / 2;
    CGFloat y = (self.bounds.size.height - self.photoImageView.image.size.height) / 2;
    self.photoImageView.frame = CGRectMake(x,
                                           y,
                                           self.photoImageView.image.size.width,
                                           self.photoImageView.image.size.height);
    
    [self updateZoomScaleForCurrentBounds];
}

- (void)updateZoomScaleForCurrentBounds {
    // 计算最大缩放比例
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // 在iPad上，支持更大缩放比例
        maxScale = 4;
    }
    
    CGFloat scale = [self scaleWithImageSize:self.photoImageView.image.size];
    CGFloat minScale = MIN(scale, 1);
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // 初始化缩放比例
    self.zoomScale = scale;
    if (self.contentSize.width > self.bounds.size.width) {
        self.scrollEnabled = NO;
    }
    
    if (self.bounds.size.width < self.contentSize.width ||
        self.bounds.size.height < self.contentSize.height) {
        CGFloat x = (self.contentSize.width - self.bounds.size.width) / 2;
        CGFloat y = (self.contentSize.height - self.bounds.size.height) / 2;
        self.contentOffset = CGPointMake(x, y);
    }
}

- (CGFloat)scaleWithImageSize:(CGSize)imageSize {
    CGSize boundsSize = self.bounds.size;
    // 计算最小缩放比例
    CGFloat xScale = boundsSize.width / imageSize.width;
    CGFloat yScale = boundsSize.height / imageSize.height;
    CGFloat scale;
    if (self.photoContentMode == YPPhotoContentModeScaleFill) {
        if (imageSize.width < imageSize.height) {
            scale = yScale;
        } else {
            scale = xScale;
        }
    } else if (self.photoContentMode == YPPhotoContentModeScaleFillHeight) {
        scale = yScale;
    } else {
        scale = MIN(xScale, yScale);
        scale = MIN(scale, 1);
    }
    return scale;
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

- (void)handleSingleTap:(UITapGestureRecognizer *)gesture {
    [[NSNotificationCenter defaultCenter] postNotificationName:YPPhotoViewCellSingleTappedNotification object:nil];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:YPPhotoViewCellLongPressedNotification object:nil];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint touchPoint = [recognizer locationInView:self.photoImageView];
    if (self.zoomScale != self.minimumZoomScale) {
        // 恢复初始缩放比例
        if (self.minimumZoomScale >= 1) {
            [self setZoomScale:1 animated:YES];
        } else {
            [self setZoomScale:self.minimumZoomScale animated:YES];
        }
    } else {
        // 放大以显示双击的位置
        CGFloat newZoomScale = (self.maximumZoomScale + self.minimumZoomScale) / 2;
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize) animated:YES];
    }
}

@end
