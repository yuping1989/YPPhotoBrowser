//
//  YPPhotoBrowser.m
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/7/27.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import "YPPhotoBrowser.h"
#import "YPPhotoViewCell.h"
#import "YPPhotoPageView.h"
#import <objc/runtime.h>

NSString * const YPPhotoViewCellIdentifier = @"YPPhotoViewCell";

static const int browser_key;

@interface YPPhotoBrowser () <UIActionSheetDelegate> {
    BOOL _isVCBasedStatusBarAppearance;
    BOOL _isCaptionViewHidden;
    BOOL _isStatusBarHiddenBefore;
}

@property (nonatomic, strong) UIImageView *animationImageView;

@property (nonatomic, copy) NSArray *photos;
@property (nonatomic, assign) BOOL statusBarHidden;

@end

@implementation YPPhotoBrowser

#pragma mark - Init

- (instancetype)initWithPhotos:(NSArray *)photos {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(photoLoadingDidEnd:)
                                                     name:YPPhotoLoadingDidEndNotification
                                                   object:nil];
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:photos.count];
        for (id photo in photos) {
            if ([photo isKindOfClass:[YPPhoto class]]) {
                [array addObject:photo];
            } else {
                NSString *string = photo;
                YPPhoto *photoObj = [[YPPhoto alloc] init];
                if ([string isKindOfClass:[NSString class]]) {
                    if ([string hasPrefix:@"http"]) {
                        photoObj.imageURL = [NSURL URLWithString:string];
                    } else if ([string containsString:@"/"]) {
                        photoObj.localPath = string;
                    } else {
                        photoObj.imageName = string;
                    }
                } else if ([photo isKindOfClass:[NSURL class]]) {
                    photoObj.imageURL = photo;
                } else if ([photo isKindOfClass:[UIImage class]]) {
                    photoObj.image = photo;
                }
                [array addObject:photoObj];
            }
        }
        self.photos = array;
        _animationStyle = YPPhotoBrowserAnimationNone;
        _transitionAnimationImageContentMode = UIViewContentModeScaleAspectFill;
        _animationDuration = 0.3f;
        _displayingIndex = 0;
        _captionHidden = YES;
        
        NSNumber *isVCBasedStatusBarAppearanceNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
        if (isVCBasedStatusBarAppearanceNum) {
            _isVCBasedStatusBarAppearance = isVCBasedStatusBarAppearanceNum.boolValue;
        } else {
            _isVCBasedStatusBarAppearance = YES;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    
    self.photoPageView = [[YPPhotoPageView alloc] initWithFrame:self.view.bounds];
    self.photoPageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.photoPageView.dataSource = self;
    self.photoPageView.delegate = self;
    [self.view addSubview:self.photoPageView];

    self.photoPageView.displayingIndex = self.displayingIndex;
    self.photoPageView.moreButtonHidden = self.moreButtonHidden;
    self.photoPageView.pageIndicatorHidden = self.pageIndicatorHidden;
    self.photoPageView.captionHidden = self.captionHidden;
    
    // 当转场模式为YPPhotoBrowserAnimationTransition时，需等到转场动画完成后，再调用以下代码
    if (self.animationStyle != YPPhotoBrowserAnimationTransition) {
        self.photoPageView.pageIndicatorHidden = self.pageIndicatorHidden;
        self.photoPageView.moreButtonHidden = self.moreButtonHidden;
        [self.photoPageView reloadPhotos];
    }
    
    _isCaptionViewHidden = NO;
    
    [self setupNavigationItem];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _isStatusBarHiddenBefore = [[UIApplication sharedApplication] isStatusBarHidden];
    if (!self.navigationController) {
        self.statusBarHidden = YES;
    } else {
        _statusBarHidden = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.statusBarHidden = _isStatusBarHiddenBefore;
}

- (void)setupNavigationItem {
    if ([self.navigationController.viewControllers firstObject] == self) {
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonClicked)];
        // Set appearance
        self.navigationItem.rightBarButtonItem = closeItem;
    } else {
        UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
        if (!previousViewController.title) {
            UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            previousViewController.navigationItem.backBarButtonItem = newBackButton;
        }
    }
}

- (void)closeButtonClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setDisplayingIndex:(NSUInteger)displayingIndex {
    _displayingIndex = displayingIndex;
    self.photoPageView.displayingIndex = displayingIndex;
}

- (void)setPageIndicatorHidden:(BOOL)hidden {
    _pageIndicatorHidden = hidden;
    self.photoPageView.pageIndicatorHidden = hidden;
}

- (void)setMoreButtonHidden:(BOOL)hidden {
    _moreButtonHidden = hidden;
    self.photoPageView.moreButtonHidden = hidden;
}

- (void)setCaptionHidden:(BOOL)hidden {
    _captionHidden = hidden;
    self.photoPageView.captionHidden = hidden;
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    NSLog(@"statusBarHidden--->%d %d", statusBarHidden, _statusBarHidden);
    if (_statusBarHidden == statusBarHidden) {
        return;
    }
    
    _statusBarHidden = statusBarHidden;
    if (_isVCBasedStatusBarAppearance) {
        [UIView animateWithDuration:0.2f animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:statusBarHidden withAnimation:UIStatusBarAnimationSlide];
#pragma clang diagnostic pop
    }
}

- (BOOL)prefersStatusBarHidden {
    NSLog(@"prefersStatusBarHidden");
    return self.statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

#pragma mark - Show

- (void)show {
    objc_setAssociatedObject([UIApplication sharedApplication], &browser_key, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIWindow *window = [[UIApplication sharedApplication].windows firstObject];
    [window addSubview:self.view];
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    if (self.animationStyle == YPPhotoBrowserAnimationTransition) {
        YPPhoto *photo = self.photos[self.displayingIndex];
        UIImage *image = [photo displayImage];
        if (!image) {
            image = [photo thumbnailImage];
        }
        self.animationImageView = [[UIImageView alloc] initWithImage:image];
        self.animationImageView.contentMode = self.transitionAnimationImageContentMode;
        self.animationImageView.frame = photo.originFrame;
        self.animationImageView.clipsToBounds = YES;
        [self.view addSubview:self.animationImageView];
        self.view.backgroundColor = [UIColor clearColor];
        [UIView animateWithDuration:self.animationDuration
                         animations:^{
                             self.view.backgroundColor = [UIColor blackColor];
                             self.animationImageView.frame = [self centerFrameForSize:self.animationImageView.image.size];
                             statusBar.alpha = 0;
                         } completion:^(BOOL finished) {
                             self.animationImageView.hidden = YES;
                             [self.photoPageView reloadPhotos];
                             
                             [self.photoPageView setPageIndicatorHidden:self.pageIndicatorHidden animated:YES];
                             [self.photoPageView setMoreButtonHidden:self.moreButtonHidden animated:YES];
                         }];
    } else if (self.animationStyle == YPPhotoBrowserAnimationFade) {
        self.view.alpha = 0.0f;
        [UIView animateWithDuration:self.animationDuration
                         animations:^{
                             statusBar.alpha = 0;
                             self.view.alpha = 1.0f;
                         }];
    }
}

- (void)hide {
    YPPhoto *photo = self.photos[self.photoPageView.displayingIndex];
    void (^completion)(BOOL finished) = ^ (BOOL finished) {
        [self.view removeFromSuperview];
        objc_setAssociatedObject([UIApplication sharedApplication], &browser_key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    };
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    if (self.animationStyle == YPPhotoBrowserAnimationTransition) {
        if (!CGRectEqualToRect(photo.originFrame, CGRectZero)) {
            YPPhotoViewCell *cell = [self.photoPageView displayingCell];
            CGRect frame = [cell.photoView.photoImageView convertRect:cell.photoView.photoImageView.bounds toView:nil];
            self.animationImageView.frame = frame;
            UIImage *image = [photo displayImage];
            if (!image) {
                image = [photo thumbnailImage];
            }
            self.animationImageView.image = image;
            self.animationImageView.hidden = NO;
            self.photoPageView.hidden = YES;
            
            [UIView animateWithDuration:self.animationDuration
                             animations:^{
                                 self.animationImageView.frame = photo.originFrame;
                                 self.view.backgroundColor = [UIColor clearColor];
                                 statusBar.alpha = 1;
                             }
                             completion:completion];
        } else {
            [UIView animateWithDuration:self.animationDuration
                             animations:^{
                                 self.view.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
                                 self.view.alpha = 0;
                                 statusBar.alpha = 1;
                             }
                             completion:completion];
        }
    } else if (self.animationStyle == YPPhotoBrowserAnimationFade) {
        [UIView animateWithDuration:self.animationDuration
                         animations:^{
                             self.view.alpha = 0;
                             statusBar.alpha = 1;
                         }
                         completion:completion];
    } else {
        completion(YES);
    }
}

- (CGRect)centerFrameForSize:(CGSize)size {
    CGSize boundsSize = self.view.bounds.size;
    
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    CGFloat xScale = boundsSize.width / size.width;
    CGFloat yScale = boundsSize.height / size.height;
    if (xScale < 1.0f || yScale < 1.0f) {
        CGFloat minScale = MIN(xScale, yScale);
        width = size.width * minScale;
        height = size.height * minScale;
    }
    CGFloat x = floorf((boundsSize.width - width) / 2.0);
    CGFloat y = floorf((boundsSize.height - height) / 2.0);
    return CGRectMake(x, y, width, height);
}


#pragma mark - Notification
/**
 *  图片下载完成，开始加载相邻的图片
 */
- (void)photoLoadingDidEnd:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *data = (NSDictionary *)notification.object;
        id<YPPhoto> photo = data[@"photo"];
        NSInteger index = [self.photos indexOfObject:photo];
        if ([self.photoPageView isCellDisplayingForIndex:index]) {
            [self loadAdjacentPhotosForIndex:index];
        }
    });
}

/**
 *  加载相邻的photos
 */
- (void)loadAdjacentPhotosForIndex:(NSUInteger)index {
    if (index > 0) {
        if (![self.photoPageView isCellDisplayingForIndex:index - 1]) {
            YPPhoto *photo = self.photos[index - 1];
            [photo startDownloadImageAndNotify];
        }
    }
    if (index < self.photos.count - 1) {
        if (![self.photoPageView isCellDisplayingForIndex:index + 1]) {
            YPPhoto *photo = self.photos[index + 1];
            [photo startDownloadImageAndNotify];
        }
    }
}

#pragma mark - YPPhotoPageViewDataSource

- (NSUInteger)numberOfPhotos:(YPPhotoPageView *)pageView {
    return self.photos.count;
}

- (YPPhotoViewCell *)photoPageView:(YPPhotoPageView *)pageView cellForPhotoAtIndex:(NSUInteger)index {
    YPPhotoViewCell *cell = [self.photoPageView dequeueReusableCell];
    if (!cell) {
        cell = [[YPPhotoViewCell alloc] initWithFrame:self.view.bounds];
    }
    YPPhoto *photo = self.photos[index];
    cell.photo = photo;
    if (!self.captionHidden) {
        if (photo.attributedCaption) {
            cell.attributedCaption = photo.attributedCaption;
            cell.captionViewHidden = _isCaptionViewHidden;
        } else if (photo.caption) {
            cell.caption = photo.caption;
            cell.captionViewHidden = _isCaptionViewHidden;
        }
    }
    return cell;
}

#pragma mark - YPPhotoPageViewDelegate
- (void)photoPageView:(YPPhotoPageView *)pageView didClickCellAtIndex:(NSUInteger)index {
    if (self.navigationController) {
        [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];

        self.statusBarHidden = self.navigationController.navigationBarHidden;
        
        YPPhotoViewCell *cell = [self.photoPageView displayingCell];
        _isCaptionViewHidden = !_isCaptionViewHidden;
        [cell setCaptionViewHidden:_isCaptionViewHidden animated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self hide];
    }
}

// 显示某个页面时的回调
- (void)photoPageView:(YPPhotoPageView *)pageView didDisplayCellAtIndex:(NSUInteger)index {
    if (self.navigationController) {
        self.title = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)index, (unsigned long)self.photos.count];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)photoPageViewDidClickMoreButton:(YPPhotoPageView *)pageView {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存到相册", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        YPPhoto *displayingPhoto = self.photos[self.displayingIndex];
        [displayingPhoto saveImageToAlbumWithCompletionBlock:nil];
    }
}
#pragma clang diagnostic pop

@end
