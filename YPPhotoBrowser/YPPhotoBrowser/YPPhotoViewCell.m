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
    
    _captionOpened = YES;
    _captionFont = [UIFont systemFontOfSize:16];
    _captionViewHidden = NO;
    _maxHeightOfCaptionWhenOpened = self.bounds.size.height / 4;
    _maxHeightOfCaptionWhenClosed = self.bounds.size.height / 10;
    
    _animationDuration = 0.3f;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSLog(@"layoutSubviews");
    // 当非点击事件触发时，重新计算高度，比如设备旋转
    if (!_updateCaptionViewFrameByTapped) {
        [self calculateAndUpdateCaptionViewFrame];
    }
}

- (void)prepareForReuse {
    self.index = NSNotFound;
    self.photo = nil;
    self.photoView.progressView.hidden = YES;
    self.photoView.progressView.progress = 0;
    self.photoView.progressView.progressLabel.text = @"0%";
    self.captionOpened = YES;
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
    UIImage *image = [self.photo displayImage];
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
            [self.photoView.progressView setProgress:progress animated:YES];
            NSString *progrssStr = [NSString stringWithFormat:@"%ld%%", (long)(progress * 100)];
            self.photoView.progressView.progressLabel.text = progrssStr;
            NSLog(@"progress--->%@", progrssStr);
        }
    });
}

#pragma mark - Caption view

- (UILabel *)captionLabel {
    if (!_captionLabel) {
        _captionLabel = [[UILabel alloc] init];
        _captionLabel.numberOfLines = 0;
        _captionLabel.textColor = [UIColor whiteColor];
        _captionLabel.font = self.captionFont;
        
        self.captionView = [[UIView alloc] init];
        self.captionView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
        self.captionView.clipsToBounds = YES;
        self.captionLabelScrollView = [[UIScrollView alloc] init];
        self.captionLabelScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        
        [self.captionLabelScrollView addSubview:_captionLabel];
        [self.captionView addSubview:self.captionLabelScrollView];
        [self addSubview:self.captionView];
        
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captionViewTapped)];
        [self.captionLabelScrollView addGestureRecognizer:recognizer];
        
        self.captionView.alpha = 0.0f;
        [UIView animateWithDuration:0.3f animations:^{
            self.captionView.alpha = 1.0f;
        }];
    }
    return _captionLabel;
}

- (void)setCaption:(NSString *)caption {
    _caption = [caption copy];
    
    self.captionLabel.text = caption;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setAttributedCaption:(NSAttributedString *)attributedCaption {
    _attributedCaption = attributedCaption;
    
    self.captionLabel.attributedText = attributedCaption;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

/**
 *  计算captionView的高度
 */
- (void)calculateAndUpdateCaptionViewFrame {
    if (!self.caption && !self.attributedCaption) {
        self.captionView.frame = CGRectZero;
        return;
    }
    CGFloat width = self.bounds.size.width - YPPhotoViewCellCaptionViewPadding * 2;
    if (self.attributedCaption) {
        self.captionHeight = [self.attributedCaption boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                         context:nil].size.height;
    } else if (self.caption) {
        self.captionHeight = [self.caption boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                    attributes:@{NSFontAttributeName : self.captionLabel.font}
                                       context:nil].size.height;
    }
    
    CGFloat padding = YPPhotoViewCellCaptionViewPadding;
    self.captionLabelScrollView.contentSize = CGSizeMake(self.bounds.size.width, self.captionHeight);
    self.captionLabel.frame = CGRectMake(padding, 0, self.bounds.size.width - padding * 2, self.captionHeight);
    
    [self updateCaptionViewFrame];
}

- (void)updateCaptionViewFrame {
    CGFloat padding = YPPhotoViewCellCaptionViewPadding;
    CGFloat textHeight;
    if (self.captionOpened) {
        textHeight = MIN(self.maxHeightOfCaptionWhenOpened - 2 * padding , self.captionHeight);
    } else {
        textHeight = MIN(self.maxHeightOfCaptionWhenClosed - 2 * padding, self.captionHeight);
    }
    
    CGSize boundsSize = self.bounds.size;
    CGFloat captionViewHeight = MIN(self.maxHeightOfCaptionWhenOpened, textHeight) + 2 * padding;
    
    self.captionLabelScrollView.frame = CGRectMake(0, padding, boundsSize.width, captionViewHeight - 2 * padding);
    CGFloat captionViewY;
    if (self.captionViewHidden) {
        captionViewY = boundsSize.height;
    } else {
        captionViewY = boundsSize.height - captionViewHeight;
    }
    self.captionView.frame = CGRectMake(0, captionViewY, boundsSize.width, captionViewHeight);
    NSLog(@"caption--->%@ %d", NSStringFromCGRect(self.captionView.frame), _captionViewHidden);
}

- (void)setCaptionColor:(UIColor *)captionColor {
    _captionColor = captionColor;
    self.captionLabel.textColor = captionColor;
}

- (void)setCaptionFont:(UIFont *)captionFont {
    _captionFont = captionFont;
    self.captionLabel.font = captionFont;
    
    [self calculateAndUpdateCaptionViewFrame];
}

- (void)captionViewTapped {
    if (self.captionHeight < self.maxHeightOfCaptionWhenClosed) {
        return;
    }
    _captionOpened = !_captionOpened;
    
    [UIView animateWithDuration:self.animationDuration animations:^{
        _updateCaptionViewFrameByTapped = YES;
        [self updateCaptionViewFrame];
    } completion:^(BOOL finished) {
        _updateCaptionViewFrameByTapped = NO;
    }];
}

- (void)setCaptionViewHidden:(BOOL)captionViewHidden {
    [self setCaptionViewHidden:captionViewHidden animated:NO];
}

- (void)setCaptionViewHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_captionViewHidden == hidden) {
        return;
    }
    _captionViewHidden = hidden;
    CGRect frame = self.captionView.frame;
    frame.origin.y = hidden ? self.bounds.size.height : self.bounds.size.height - frame.size.height;
    if (animated) {
        [UIView animateWithDuration:self.animationDuration animations:^{
            _updateCaptionViewFrameByTapped = YES;
            self.captionView.frame = frame;
            NSLog(@"caption view--->%@ hidden-->%d", NSStringFromCGRect(self.captionView.frame), _captionViewHidden);
        } completion:^(BOOL finished) {
            _updateCaptionViewFrameByTapped = NO;
        }];
    } else {
        _updateCaptionViewFrameByTapped = YES;
        self.captionView.frame = frame;
        _updateCaptionViewFrameByTapped = NO;
        NSLog(@"caption view--->%@ hidden-->%d", NSStringFromCGRect(self.captionView.frame), _captionViewHidden);
    }
}

@end
