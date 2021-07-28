//
//  YPNewPhotoPageView.h
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/8/1.
//  Copyright © 2016年 com.yp. All rights reserved.
//
//  此类的作用于UITableView类似

#import <UIKit/UIKit.h>
#import "YPPhotoProtocol.h"

static const CGFloat YPNewPhotoPageViewPadding = 10.0f;

@class YPNewPhotoPageView;
@class YPPhotoViewCell;

@protocol YPNewPhotoPageViewDataSource <NSObject>

@required
- (NSUInteger)numberOfPhotos:(YPNewPhotoPageView *)pageView;
- (YPPhotoViewCell *)photoPageView:(YPNewPhotoPageView *)pageView cellForPhotoAtIndex:(NSUInteger)index;
@end

@protocol YPNewPhotoPageViewDelegate <NSObject>

@optional
- (void)photoPageView:(YPNewPhotoPageView *)pageView willDisplayCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoPageView:(YPNewPhotoPageView *)pageView displayingCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoPageView:(YPNewPhotoPageView *)pageView didEndDeceleratingOnCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;
- (void)photoPageView:(YPNewPhotoPageView *)pageView didEndDisplayingCell:(YPPhotoViewCell *)cell forPhotoAtIndex:(NSUInteger)index;

- (void)photoPageView:(YPNewPhotoPageView *)pageView didClickCellAtIndex:(NSUInteger)index;
- (void)photoPageView:(YPNewPhotoPageView *)pageView didLongPressAtIndex:(NSUInteger)index;
- (void)photoPageViewDidClickMoreButton:(YPNewPhotoPageView *)pageView;

@end

@interface YPNewPhotoPageView : UIView

@property (nonatomic, assign) BOOL pageIndicatorHidden;
@property (nonatomic, assign) BOOL moreButtonHidden;
@property (nonatomic, assign) BOOL captionHidden;

@property (nonatomic, assign) NSUInteger displayingIndex;

@property (nonatomic, weak) id<YPNewPhotoPageViewDataSource> dataSource;
@property (nonatomic, weak) id<YPNewPhotoPageViewDelegate> delegate;

- (void)reloadPhotos;

- (YPPhotoViewCell *)dequeueReusableCell;

- (YPPhotoViewCell *)displayingCell;

- (BOOL)isCellDisplayingForIndex:(NSUInteger)index;

- (void)setMoreButtonHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setPageIndicatorHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)setDisplayingIndex:(NSUInteger)displayingIndex animated:(BOOL)animated;

- (void)deleteCellAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end
