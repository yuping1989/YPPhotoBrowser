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

// 重置cell
- (void)prepareForReuse;

@end
