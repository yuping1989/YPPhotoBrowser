//
//  YPPhotoViewCell.m
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/7/27.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import "YPPhotoViewCell.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDImageCache.h>
#import "YPPhotoProgressView.h"

static CGFloat YPPhotoViewCellCaptionViewPadding = 10.0f;

@interface YPPhotoViewCell () <UIScrollViewDelegate> {
    // 此变量用于标记captionView的frame变化是否为点击事件触发
    BOOL _updateCaptionViewFrameByTapped;
}

// 这里没有使用UITextView，因为UITextView创建耗时较长
@property (nonatomic, strong, readwrite) UILabel *captionLabel;

// caption最外层View
@property (nonatomic, strong) UIView *captionView;

// 包裹captionLabel的UIScrollView，当文字高度过高时，可以滑动
@property (nonatomic, strong) UIScrollView *captionLabelScrollView;

// caption的高度
@property (nonatomic, assign) CGFloat captionHeight;

@end

@implementation YPPhotoViewCell

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoLoadingDidEnd:)
                                                 name:YPPhotoLoadingDidEndNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoLoadingProgress:)
                                                 name:YPPhotoProgressNotification
                                               object:nil];
    
    _photoView = [[YPPhotoZoomingView alloc] initWithFrame:self.bounds];
    _photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_photoView];
}

- (void)prepareForReuse {
    self.index = NSNotFound;
    self.photo = nil;
    self.photoView.progressView.hidden = YES;
    self.photoView.progressView.progress = 0;
    self.photoView.progressView.progressLabel.text = @"0%";
}

- (void)setPhoto:(id<YPPhoto>)photo {
    _photo = photo;
    if (_photo) {
        [self displayPhotoImageWithAnimated:NO];
    } else {
        [self.photoView displayImage:nil animatied:NO];
    }
}

/**
 *  显示photo的图像
 */
- (void)displayPhotoImageWithAnimated:(BOOL)animated {
    id image = [self.photo displayImage];
    if (image) {
        self.photoView.progressView.hidden = YES;
        [self.photoView displayImage:image animatied:animated];
    } else {
        UIImage *thumbnail = [self.photo thumbnailImage];
        if (thumbnail) {
            [self.photoView displayImage:thumbnail animatied:animated];
        }
        
        self.photoView.progressView.hidden = NO;
        [self.photo startDownloadImageAndNotify];
    }
}

#pragma mark - YPPhoto notification

/**
 *  接收图片下载完成的通知
 */
- (void)photoLoadingDidEnd:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        id<YPPhoto> photo = notification.object[@"photo"];
        if (photo == self.photo) {
            self.photoView.progressView.hidden = YES;
            if ([notification.object[@"result"] boolValue]) {
                [self displayPhotoImageWithAnimated:YES];
            } else {
                // 显示下载失败的图片
                NSString * path = [[NSBundle mainBundle] pathForResource:@"YPPhotoBrowser" ofType:@"bundle"];
                NSString *imagePath = [path stringByAppendingPathComponent:@"yp_image_failed@2x"];
                UIImage *failedImage = [UIImage imageWithContentsOfFile:imagePath];
                [self.photoView displayImage:failedImage animatied:NO];
            }
        }
    });
}

- (void)photoLoadingProgress:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        id<YPPhoto> photo = notification.object[@"photo"];
        if (photo == self.photo) {
            CGFloat progress = [notification.object[@"progress"] floatValue];
            self.photoView.progressView.progress = progress;
            NSString *progrssStr = [NSString stringWithFormat:@"%ld%%", (long)(progress * 100)];
            self.photoView.progressView.progressLabel.text = progrssStr;
        }
    });
}

@end
