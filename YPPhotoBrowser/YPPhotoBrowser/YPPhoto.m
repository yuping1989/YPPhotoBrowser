//
//  YPPhoto.m
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/7/27.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import "YPPhoto.h"
#import <SDWebImage/SDWebImageOperation.h>
#import <SDWebImage/SDWebImageManager.h>

@interface YPPhoto () {
    id <SDWebImageOperation> _webImageOperation;
}

@property (nonatomic, copy) void (^savePhotoComletionBlock)(NSError *error);

@end

@implementation YPPhoto
@synthesize caption;
@synthesize attributedCaption;

#pragma mark - YPPhotoProtocol
- (UIImage *)displayImage {
    if (self.imageURL) {
        return [self imageFromCache];
    } else if (self.localPath) {
        return [UIImage imageWithContentsOfFile:self.localPath];
    } else if (self.imageName) {
        return [UIImage imageNamed:self.imageName];
    } else if (self.image) {
        return self.image;
    }
    return nil;
}

- (UIImage *)thumbnailImage {
    return [self scaledImageByScreenScale:[[SDImageCache sharedImageCache] imageFromCacheForKey:self.thumbnailURL.absoluteString]];
}

- (void)dealloc {
    if (_webImageOperation) {
        [_webImageOperation cancel];
        _webImageOperation = nil;
    }
}


- (void)startDownloadImageAndNotify {
    SDWebImageManager *manager = [SDWebImageManager sharedManager];

    _webImageOperation = [manager loadImageWithURL:self.imageURL
                                           options:0
                                          progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                                              if (expectedSize > 0) {
                                                  CGFloat progress = receivedSize / (CGFloat)expectedSize;
                                                  NSDictionary *data = @{@"photo" : self, @"progress" : @(progress)};
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:YPPhotoProgressNotification object:data];
                                              }
                                          }
                                         completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                                             if (finished) {
                                                 _webImageOperation = nil;
                                                 
                                                 NSDictionary *data = @{@"photo" : self, @"result" : @(image ? YES : NO)};
                                                 [[NSNotificationCenter defaultCenter] postNotificationName:YPPhotoLoadingDidEndNotification object:data];
                                             }
                                         }];
}

- (UIImage *)imageFromCache {
    return [self scaledImageByScreenScale:[[SDImageCache sharedImageCache] imageFromCacheForKey:self.imageURL.absoluteString]];
}

- (UIImage *)scaledImageByScreenScale:(UIImage *)image {
    if (!image) {
        return nil;
    }
    return [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
}

- (void)saveImageToAlbumWithCompletionBlock:(void (^)(NSError *error))completion {
    self.savePhotoComletionBlock = completion;
    UIImage *image = [self imageFromCache];
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    } else {
        [self showAlertViewWithTitle:@"图片正在下载或下载失败"];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (self.savePhotoComletionBlock) {
        self.savePhotoComletionBlock(error);
        return;
    }
    
    NSString *msg = nil ;
    if (error) {
        msg = @"图片保存失败";
    } else {
        msg = @"图片保存成功";
    }
    [self showAlertViewWithTitle:msg];
}



- (void)showAlertViewWithTitle:(NSString *)title {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    [alert show];
#pragma clang diagnostic pop
    
}

- (void)convertOriginFrameByView:(UIView *)view {
    self.originFrame = [view convertRect:view.bounds toView:nil];
}

@end
