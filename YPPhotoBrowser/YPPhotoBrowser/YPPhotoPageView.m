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

@property (nonatomic, strong) NSMutableSet<YPPhotoViewCell *> *visibleCells;
@property (nonatomic, strong) NSMutableSet<YPPhotoViewCell *> *reusableCells;

@property (nonatomic, assign) Class cellClass;
@property (nonatomic, strong) UINib *cellNib;

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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    NSString *imagePath = [path stringByAppendingPathComponent:@"yp_button_more@2x"];
    UIImage *buttonImage = [UIImage imageWithContentsOfFile:imagePath];
    _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreButton setImage:buttonImage forState:UIControlStateNormal];
    [_moreButton addTarget:self action:@selector(moreButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_toolView addSubview:_moreButton];
    
    _pageIndicatorHidden = NO;
    _pageIndicatorLabel.hidden = YES;
    _moreButtonHidden = NO;
    _moreButton.hidden = YES;
    _captionHidden = YES;
    
    [self updateToolViewFrame];
    
    _displayingIndex = 0;
    _numberOfPhotos = NSNotFound;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoViewCellSingleTapped) name:YPPhotoViewCellSingleTappedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoViewCellLongPressed) name:YPPhotoViewCellLongPressedNotification object:nil];
}

- (void)registerClass:(Class)cellClass {
    self.cellClass = cellClass;
}

- (void)registerNib:(UINib *)nib {
    self.cellNib = nib;
}

- (void)setDisplayingIndex:(NSUInteger)displayingIndex {
    [self setDisplayingIndex:displayingIndex animated:NO];
}

- (void)setDisplayingIndex:(NSUInteger)displayingIndex animated:(BOOL)animated {
    NSUInteger maxIndex = self.numberOfPhotos - 1;
    if (displayingIndex > maxIndex) {
        _displayingIndex = maxIndex;
    } else {
        _displayingIndex = displayingIndex;
    }
    if (self.numberOfPhotos != NSNotFound) {
        [self moveContentOffsetToIndex:_displayingIndex animated:animated completed:nil];
    }
}

- (void)deleteCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    NSUInteger targetIndex;
    if (index == self.numberOfPhotos - 1) {
        targetIndex = self.displayingIndex - 1;
    } else {
        targetIndex = self.displayingIndex + 1;
    }
    [self moveContentOffsetToIndex:targetIndex animated:animated completed:^{
        [self reloadPhotos];
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 更新photoScrollView的contentSize
    CGSize size = CGSizeMake(self.photoScrollView.bounds.size.width * self.numberOfPhotos,
                             self.photoScrollView.bounds.size.height);
    self.photoScrollView.contentSize = size;
    
    // 定位到当前的displayingIndex所在位置
    CGRect cellFrame = [self frameForCellAtIndex:self.displayingIndex];
    [self.photoScrollView setContentOffset:CGPointMake(cellFrame.origin.x - YPPhotoPageViewPadding, 0)];
    
    // 更新visibleCells的frame和缩放比例
    for (YPPhotoViewCell *cell in self.visibleCells) {
        cell.frame = [self frameForCellAtIndex:cell.index];
        [cell.photoView updateZoomScaleForCurrentBounds];
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

/**
 *  重新加载photos
 */
- (void)reloadPhotos {
    self.numberOfPhotos = [self.dataSource numberOfPhotos:self];
    
    // 将cell移入重用池
    for (YPPhotoViewCell *cell in self.visibleCells) {
        [cell removeFromSuperview];
        [cell prepareForReuse];
        [self.reusableCells addObject:cell];
    }
    [self.visibleCells removeAllObjects];
    
    self.photoScrollView.contentSize = CGSizeMake(self.photoScrollView.bounds.size.width * self.numberOfPhotos, self.photoScrollView.bounds.size.height);
    
    if (self.numberOfPhotos == 0) {
        // 图片数量为0
        _displayingIndex = 0;
        [self updatePageIndicator];
        return;
    }
    // 如果新的图片数量大于当前的displayingIndex，将其定位到最后一张
    if (self.displayingIndex > self.numberOfPhotos - 1) {
        _displayingIndex = self.numberOfPhotos - 1;
    }
    
    // 加载cell
    [self loadVisibleCells];
    
    // 移动到显示的cell的位置
    [self moveContentOffsetToIndex:_displayingIndex animated:NO completed:nil];
    
    [self updateToolViewFrame];
}

- (YPPhotoViewCell *)dequeueReusableCell {
    if (self.reusableCells.count == 0) {
        if (self.cellClass) {
            return [[self.cellClass alloc] initWithFrame:self.bounds];
        } else if (self.cellNib) {
            YPPhotoViewCell *cell = [[self.cellNib instantiateWithOwner:nil options:nil] firstObject];
            cell.frame = self.bounds;
            return cell;
        }
    }
    YPPhotoViewCell *cell = [self.reusableCells anyObject];
    if (cell) {
        cell.frame = self.bounds;
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
    return [self visibleCellForIndex:self.displayingIndex];
}

- (YPPhotoViewCell *)visibleCellForIndex:(NSUInteger)index {
    for (YPPhotoViewCell *cell in self.visibleCells) {
        if (index == cell.index) {
            return cell;
        }
    }
    return nil;
}

// 定位到当前显示的图片
- (void)moveContentOffsetToIndex:(NSUInteger)index
                        animated:(BOOL)animated
                       completed:(void (^)(void))completed {
    CGRect cellFrame = [self frameForCellAtIndex:index];
    if (animated) {
        [UIView animateWithDuration:0.25f animations:^{
            [self.photoScrollView setContentOffset:CGPointMake(cellFrame.origin.x - YPPhotoPageViewPadding, 0)];
        } completion:^(BOOL finished) {
            [self preloadAndReleaseImage];
            if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:displayingCell:forPhotoAtIndex:)]) {
                [self.delegate photoPageView:self displayingCell:[self visibleCellForIndex:index] forPhotoAtIndex:index];
            }
            [self updatePageIndicator];
            if (completed) {
                completed();
            }
        }];
    } else {
        [self.photoScrollView setContentOffset:CGPointMake(cellFrame.origin.x - YPPhotoPageViewPadding, 0)];
        [self preloadAndReleaseImage];
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:displayingCell:forPhotoAtIndex:)]) {
            [self.delegate photoPageView:self displayingCell:self.displayingCell forPhotoAtIndex:index];
        }
        [self updatePageIndicator];
        if (completed) {
            completed();
        }
    }
}

- (void)loadVisibleCells {
    NSInteger firstIndex = self.displayingIndex - 1;
    NSInteger lastIndex = self.displayingIndex + 1;
    if (firstIndex < 0) {
        firstIndex = 0;
    }
    if (lastIndex >= self.numberOfPhotos) {
        lastIndex = self.numberOfPhotos - 1;
    }
    
    // 配置需要显示的cell
    for (NSInteger index = firstIndex; index <= lastIndex; index++) {
        if (![self isCellDisplayingForIndex:index]) {
            YPPhotoViewCell *cell = [self.dataSource photoPageView:self cellForPhotoAtIndex:index];
            [self.visibleCells addObject:cell];
            cell.frame = [self frameForCellAtIndex:index];
            cell.index = index;
            [self.photoScrollView addSubview:cell];
        }
    }
    
    for (YPPhotoViewCell *cell in self.visibleCells) {
        // 重置Cell的缩放倍数
        if (cell.index != self.displayingIndex) {
            [cell.photoView updateZoomScaleForCurrentBounds];
        }
        // 将不必要的cell移到重用池
        if (cell.index < firstIndex || cell.index > lastIndex) {
            [cell prepareForReuse];
            [self.reusableCells addObject:cell];
            [cell removeFromSuperview];
        }
    }
    [self.visibleCells minusSet:self.reusableCells];
    while (self.reusableCells.count > 2) {
        // 只保留2个重用cell
        [self.reusableCells removeObject:[self.reusableCells anyObject]];
    }
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
    
    // 配置需要显示的cell
    for (NSUInteger index = firstIndex; index <= lastIndex; index++) {
        if (![self isCellDisplayingForIndex:index]) {
            YPPhotoViewCell *cell = [self.dataSource photoPageView:self cellForPhotoAtIndex:index];
            [self.visibleCells addObject:cell];
            cell.frame = [self frameForCellAtIndex:index];
            cell.index = index;
            [self.photoScrollView addSubview:cell];
        }
    }
}

- (void)preloadAndReleaseImage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:preloadImageAtIndex:)]) {
        NSInteger preIndex = self.displayingIndex - 1;
        if (preIndex > 0 && preIndex < self.numberOfPhotos - 1) {
            [self.delegate photoPageView:self preloadImageAtIndex:preIndex];
        }
        NSInteger nextIndex = self.displayingIndex + 1;
        if (nextIndex > 0 && nextIndex < self.numberOfPhotos - 1) {
            [self.delegate photoPageView:self preloadImageAtIndex:nextIndex];
        }
        
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:releaseImageAtIndex:)]) {
        NSInteger preIndex = self.displayingIndex - 2;
        if (preIndex > 0 && preIndex < self.numberOfPhotos - 1) {
            [self.delegate photoPageView:self releaseImageAtIndex:preIndex];
        }
        NSInteger nextIndex = self.displayingIndex + 2;
        if (nextIndex > 0 && nextIndex < self.numberOfPhotos - 1) {
            [self.delegate photoPageView:self releaseImageAtIndex:nextIndex];
        }
    }
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
    if (self.pageIndicatorHidden) {
        return;
    }
    if (self.numberOfPhotos == NSNotFound) {
        return;
    }
    NSInteger index = self.numberOfPhotos == 0 ? 0 : self.displayingIndex + 1;
    NSString *text = [NSString stringWithFormat:@"%lu / %lu",  (unsigned long)index, (unsigned long)self.numberOfPhotos];
    self.pageIndicatorLabel.text = text;
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadVisibleCells];
    [self preloadAndReleaseImage];
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

/**
 *  cell被长按
 */
- (void)photoViewCellLongPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoPageView:didLongPressAtIndex:)]) {
        [self.delegate photoPageView:self didLongPressAtIndex:self.displayingIndex];
    }
}

@end
