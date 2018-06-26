//
//  YPPhotoPageView.m
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/8/1.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import "YPPhotoPageView.h"
#import "YPPhotoViewCell.h"

static NSString * const kContentOffset = @"contentOffset";

@interface YPPhotoPageView () <UIScrollViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIScrollView *photoScrollView;
@property (nonatomic, assign) NSUInteger numberOfPhotos;

@property (nonatomic, strong) UIView *toolView;
@property (nonatomic, strong) UILabel *pageIndicatorLabel;
@property (nonatomic, strong) UIButton *moreButton;

@property (nonatomic, strong) NSMutableSet <YPPhotoViewCell *> *visibleCells;
@property (nonatomic, strong) NSMutableSet <YPPhotoViewCell *> *reusableCells;

@end

@implementation YPPhotoPageView

@synthesize delegate;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)_setup {
    _visibleCells = [[NSMutableSet alloc] init];
    _reusableCells = [[NSMutableSet alloc] init];
    
    CGRect frame = self.bounds;
    frame.origin.x -= YPPhotoPageViewPadding;
    frame.size.width += (2 * YPPhotoPageViewPadding);
    _photoScrollView = [[UIScrollView alloc] initWithFrame:CGRectIntegral(frame)];
    
    _photoScrollView.pagingEnabled = YES;
    _photoScrollView.showsHorizontalScrollIndicator = NO;
    _photoScrollView.showsVerticalScrollIndicator = NO;
    _photoScrollView.backgroundColor = [UIColor clearColor];
    _photoScrollView.delegate = self;
    _photoScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_photoScrollView];
    
    _toolView = [[UIView alloc] init];
    [self addSubview:_toolView];
    
    _pageIndicatorLabel = [[UILabel alloc] initWithFrame:self.toolView.bounds];
    _pageIndicatorLabel.font = [UIFont systemFontOfSize:14];
    _pageIndicatorLabel.textColor = [UIColor whiteColor];
    _pageIndicatorLabel.textAlignment = NSTextAlignmentCenter;
    _pageIndicatorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _pageIndicatorLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    _pageIndicatorLabel.shadowOffset = CGSizeMake(1, 1);
    [_toolView addSubview:self.pageIndicatorLabel];
    
    NSString * path = [[NSBundle mainBundle] pathForResource:@"YPPhotoBrowser" ofType:@"bundle"];
    NSString *imagePath = [path stringByAppendingPathComponent:@"button_more@2x"];
    UIImage *buttonImage = [UIImage imageWithContentsOfFile:imagePath];
    _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreButton setImage:buttonImage forState:UIControlStateNormal];
    [_moreButton addTarget:self action:@selector(moreButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_toolView addSubview:_moreButton];
    
    _pageIndicatorHidden = NO;
    _pageIndicatorLabel.hidden = YES;
    _moreButtonHidden = NO;
    _moreButton.hidden = YES;
    
    [self updateToolViewFrame];
    
    _displayingIndex = NSNotFound;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoViewCellSingleTapped)
                                                 name:YPPhotoViewCellSingleTappedNotification
                                               object:nil];
}

- (void)setDisplayingIndex:(NSUInteger)displayingIndex {
    NSUInteger maxIndex = self.numberOfPhotos - 1;
    if (displayingIndex > maxIndex) {
        _displayingIndex = maxIndex;
    } else {
        _displayingIndex = displayingIndex;
    }
    [self setContentOffsetToDisplayingIndex];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 更新photoScrollView的contentSize
    CGSize size = CGSizeMake(self.photoScrollView.bounds.size.width * self.numberOfPhotos,
                             self.photoScrollView.bounds.size.height);
    self.photoScrollView.contentSize = size;
    
    // 定位到当前的displayingIndex所在位置
    [self setContentOffsetToDisplayingIndex];
    
    // 更新visibleCells的frame和缩放比例
    for (YPPhotoViewCell *cell in self.visibleCells) {
        cell.frame = [self frameForCellAtIndex:cell.index];
        [cell.photoView setMaxMinZoomScalesForCurrentBounds];
    }
    
    [self updateToolViewFrame];
}

- (CGRect)frameForCellAtIndex:(NSUInteger)index {
    CGRect bounds = self.photoScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * YPPhotoPageViewPadding);
    pageFrame.origin.x = (bounds.size.width * index) + YPPhotoPageViewPadding;
    return CGRectIntegral(pageFrame);
}

- (void)layoutCells {
    CGRect bounds = self.photoScrollView.bounds;
    NSInteger firstIndex = (NSInteger)floorf((CGRectGetMinX(bounds) + YPPhotoPageViewPadding * 2) / CGRectGetWidth(bounds));
    NSInteger lastIndex  = (NSInteger)floorf((CGRectGetMaxX(bounds) - YPPhotoPageViewPadding * 2 - 1) / CGRectGetWidth(bounds));
    NSUInteger number = self.numberOfPhotos;
    if (firstIndex < 0) firstIndex = 0;
    if (firstIndex > number - 1) firstIndex = number - 1;
    if (lastIndex < 0) lastIndex = 0;
    if (lastIndex > number - 1) lastIndex = number - 1;
    
    // 将不需要的cell放入重用池
    for (YPPhotoViewCell *cell in self.visibleCells) {
        if (cell.index < firstIndex || cell.index > lastIndex) {
            [self.reusableCells addObject:cell];
            [cell removeFromSuperview];
            if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:didEndDisplayingCell:forPhotoAtIndex:)]) {
                [self.delegate photoPageView:self didEndDisplayingCell:cell forPhotoAtIndex:cell.index];
            }
            [cell prepareForReuse];
            NSLog(@"Removed page at index %lu, count:%lu", (unsigned long)cell.index, (unsigned long)self.subviews.count);
        }
    }
    
    [self.visibleCells minusSet:self.reusableCells];
    
    while (self.reusableCells.count > 2) {
        // 只保留2个重用cell
        [self.reusableCells removeObject:[self.reusableCells anyObject]];
    }
    
    // 配置需要显示的cell
    for (NSUInteger index = firstIndex; index <= lastIndex; index++) {
        if (![self isCellDisplayingForIndex:index]) {
            
            // 如果需要显示的cell未被显示出来，通过delegate获取cell
            YPPhotoViewCell *cell = [self.dataSource photoPageView:self cellForPhotoAtIndex:index];
            
            [self.visibleCells addObject:cell];
            cell.frame = [self frameForCellAtIndex:index];
            cell.index = index;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:willDisplayCell:forPhotoAtIndex:)]) {
                [self.delegate photoPageView:self willDisplayCell:cell forPhotoAtIndex:index];
            }
            [self.photoScrollView addSubview:cell];
        }
    }
}

/**
 *  重新加载photos
 */
- (void)reloadPhotos {
    self.numberOfPhotos = [self.dataSource numberOfPhotos:self];
    
    // 清除正在显示的cell
    for (YPPhotoViewCell *cell in self.visibleCells) {
        [cell removeFromSuperview];
        [cell prepareForReuse];
        [self.reusableCells addObject:cell];
    }
    [self.visibleCells removeAllObjects];
    
    self.photoScrollView.contentSize = CGSizeMake(self.photoScrollView.bounds.size.width * self.numberOfPhotos, self.photoScrollView.bounds.size.height);
    
    if (self.numberOfPhotos == 0) {
        // 图片数量为0
        _displayingIndex = NSNotFound;
        [self updatePageIndicator];
        return;
    }
    // 如果新的图片数量大于当前的displayingIndex，将其定位到最后一张
    if (self.displayingIndex > self.numberOfPhotos - 1) {
        _displayingIndex = self.numberOfPhotos - 1;
    }
    [self setContentOffsetToDisplayingIndex];
    [self updateSubviews];
    [self updateToolViewFrame];
}

- (YPPhotoViewCell *)dequeueReusableCell {
    YPPhotoViewCell *cell = [self.reusableCells anyObject];
    if (cell) {
        [self.reusableCells removeObject:cell];
    }
    return cell;
}

/**
 *  是否正在显示该index指向的cell
 */
- (BOOL)isCellDisplayingForIndex:(NSUInteger)index {
    for (YPPhotoViewCell *cell in self.visibleCells) {
        if (cell.index == index) {
            return YES;
        }
    }
    return NO;
}

- (YPPhotoViewCell *)displayingCell {
    for (YPPhotoViewCell *cell in self.visibleCells) {
        if (self.displayingIndex == cell.index) {
            return cell;
        }
    }
    return nil;
}

// 定位到当前显示的图片
- (void)setContentOffsetToDisplayingIndex {
    CGRect cellFrame = [self frameForCellAtIndex:self.displayingIndex];
    [self.photoScrollView setContentOffset:CGPointMake(cellFrame.origin.x - YPPhotoPageViewPadding, 0)];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Tool View

- (void)setPageIndicatorHidden:(BOOL)hidden {
    [self setPageIndicatorHidden:hidden animated:NO];
}

- (void)setPageIndicatorHidden:(BOOL)hidden animated:(BOOL)animated {
    _pageIndicatorHidden = hidden;
    self.pageIndicatorLabel.hidden = hidden;
    [self updatePageIndicator];
    if (animated) {
        self.pageIndicatorLabel.alpha = 0.0f;
        [UIView animateWithDuration:0.3f
                         animations:^{
                             self.pageIndicatorLabel.alpha = 1.0f;
                         }];
    }
}

- (void)updatePageIndicator {
    if (!self.pageIndicatorHidden) {
        NSInteger index = self.numberOfPhotos == 0 ? 0 : self.displayingIndex + 1;
        NSString *text = [NSString stringWithFormat:@"%lu / %lu", index, (unsigned long)self.numberOfPhotos];
        self.pageIndicatorLabel.text = text;
    }
}

- (void)setMoreButtonHidden:(BOOL)hidden {
    [self setMoreButtonHidden:hidden animated:NO];
}

- (void)setMoreButtonHidden:(BOOL)hidden animated:(BOOL)animated {
    _moreButtonHidden = hidden;
    self.moreButton.hidden = hidden;
    if (animated) {
        self.moreButton.alpha = 0.0f;
        [UIView animateWithDuration:0.3f animations:^{
            self.moreButton.alpha = 1.0f;
        }];
    }
}

- (void)updateToolViewFrame {
    if (self.captionHidden) {
        // 如果photo没有caption，则将tool view显示在页面底部
        _toolView.frame = CGRectMake(0, self.bounds.size.height - 60, self.bounds.size.width, 60);
    } else {
        // 如果photo有caption，则将tool view显示在页面顶部
        _toolView.frame = CGRectMake(0, 0, self.bounds.size.width, 60);
    }
    CGFloat sideLength = self.toolView.frame.size.height;
    _moreButton.frame = CGRectMake(self.toolView.frame.size.width - sideLength, 0, sideLength, sideLength);
}

- (void)moreButtonClicked:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageViewDidClickMoreButton:)]) {
        [self.delegate photoPageViewDidClickMoreButton:self];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging) {
        return;
    }
    if (self.numberOfPhotos == 0) {
        return;
    }
    [self updateSubviews];
}

- (void)updateSubviews {
    [self layoutCells];
    
    // 计算当前应显示的index
    CGRect visibleBounds = self.photoScrollView.bounds;
    NSInteger index = (NSInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
    if (index > self.numberOfPhotos - 1) index = self.numberOfPhotos - 1;
    
    // 如果计算出的index与_displayingIndex不等，则加载新的cell
    if (index != _displayingIndex) {
        _displayingIndex = index;
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:displayingCell:forPhotoAtIndex:)]) {
            [self.delegate photoPageView:self displayingCell:self.displayingCell forPhotoAtIndex:index];
        }
        [self updatePageIndicator];
    }
}

#pragma mark - Handle notifications

/**
 *  cell被单击
 */
- (void)photoViewCellSingleTapped {
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:didClickCellAtIndex:)]) {
        [self.delegate photoPageView:self didClickCellAtIndex:self.displayingIndex];
    }
}

@end
