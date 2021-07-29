//
//  YPPhotoPageView.h
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/8/1.
//  Copyright © 2016年 com.yp. All rights reserved.
//
//  此类的作用于UITableView类似

#import <UIKit/UIKit.h>
#import "YPPhotoProtocol.h"

static const CGFloat YPPhotoPageViewPadding = 10.0f;

@class YPPhotoPageView;
@class YPPhotoViewCell;

@protocol YPPhotoPageViewDataSource <NSObject>

@required
- (NSUInteger)numberOfPhotos:(YPPhotoPageView *)pageView;
- (YPPhotoViewCell *)photoPageView:(YPPhotoPageView *)pageView cellForPhotoAtIndex:(NSUInteger)index;
@end

@protocol YPPhotoPageViewDelegate <NSObject>

@optional
- (void)photoPageView:(YPPhotoPageView *)pageView displayingCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;

- (void)photoPageView:(YPPhotoPageView *)pageView preloadImageAtIndex:(NSUInteger)index;
- (void)photoPageView:(YPPhotoPageView *)pageView releaseImageAtIndex:(NSUInteger)index;

- (void)photoPageView:(YPPhotoPageView *)pageView didClickCellAtIndex:(NSUInteger)index;
- (void)photoPageView:(YPPhotoPageView *)pageView didLongPressAtIndex:(NSUInteger)index;
- (void)photoPageViewDidClickMoreButton:(YPPhotoPageView *)pageView;

@end

@interface YPPhotoPageView : UIView

@property (nonatomic, assign) BOOL pageIndicatorHidden;
@property (nonatomic, assign) BOOL moreButtonHidden;
@property (nonatomic, assign) BOOL captionHidden;

@property (nonatomic, assign) NSUInteger displayingIndex;

@property (nonatomic, weak) id<YPPhotoPageViewDataSource> dataSource;
@property (nonatomic, weak) id<YPPhotoPageViewDelegate> delegate;

- (void)registerClass:(Class)cellClass;
- (void)registerNib:(UINib *)nib;

- (void)reloadPhotos;

- (YPPhotoViewCell *)dequeueReusableCell;

- (YPPhotoViewCell *)displayingCell;

- (BOOL)isCellDisplayingForIndex:(NSUInteger)index;

- (void)setMoreButtonHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setPageIndicatorHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)setDisplayingIndex:(NSUInteger)displayingIndex animated:(BOOL)animated;

- (void)deleteCellAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end
