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
#import <SDWebImage/SDImageCache.h>
#import "YPPhotoUtil.h"
#import <Photos/PHPhotoLibrary.h>
#import <Photos/PHAssetCreationRequest.h>
#import <YPUIKit/YPToastView.h>

@interface YPPhoto () {
    id <SDWebImageOperation> _webImageOperation;
}

@property (nonatomic, copy) void (^savePhotoComletionBlock)(NSError *error);

@end

@implementation YPPhoto
@synthesize caption;
@synthesize attributedCaption;

#pragma mark - YPPhotoProtocol
- (id)displayImage {
    if (self.image) {
        return self.image;
    } else if (self.imageURL) {
        return [self scaledImageByScreenScale:[[SDImageCache sharedImageCache] imageFromCacheForKey:self.imageURL.absoluteString]];
    } else if (self.localPath) {
        if ([YPPhotoUtil isGifWithPath:self.localPath]) {
            return [FLAnimatedImage animatedImageWithGIFData:[NSData dataWithContentsOfFile:self.localPath]];
        } else {
            return [self scaledImageByScreenScale:[UIImage imageWithContentsOfFile:self.localPath]];
        }
    } else if (self.imageName) {
        return [UIImage imageNamed:self.imageName];
    }
    return nil;
}

- (void)preloadImage {
    if (self.image) {
        return;
    }
    [self async:^{
        if (self.imageURL) {
            self.image = [self scaledImageByScreenScale:[[SDImageCache sharedImageCache] imageFromCacheForKey:self.imageURL.absoluteString]];
        } else if (self.localPath) {
            if ([YPPhotoUtil isGifWithPath:self.localPath]) {
                self.image = [FLAnimatedImage animatedImageWithGIFData:[NSData dataWithContentsOfFile:self.localPath]];
            } else {
                self.image = [self scaledImageByScreenScale:[UIImage imageWithContentsOfFile:self.localPath]];
            }
        } else if (self.imageName) {
            self.image = [UIImage imageNamed:self.imageName];
        }
    }];
}

- (void)resetImage {
    if (self.imageURL || self.localPath || self.imageName) {
        self.image = nil;
    }
}

- (void)async:(void (^)(void))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

/*
- (void)loadDisplayImageWithCompletion:(void (^)(UIImage *))completion {
    if (!completion) {
        return;
    }
    if (self.imageURL) {
        [[SDImageCache sharedImageCache] queryCacheOperationForKey:self.imageURL.absoluteString done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
            if (image) {
                image = [self scaledImageByScreenScale:image];
                completion(image);
            } else {
                completion(nil);
            }
        }];
    } else if (self.localPath) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];
            if (image) {
                image = [self scaledImageByScreenScale:image];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(image);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil);
                });
            }
        });
    } else if (self.imageName) {
        completion([UIImage imageNamed:self.imageName]);
    } else if (self.image) {
        completion(self.image);
    }
}
*/
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
    id image = [self displayImage];
    if (image) {
        if ([image isKindOfClass:[UIImage class]]) {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        } else if ([image isKindOfClass:[FLAnimatedImage class]]) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:[image data] options:nil];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.savePhotoComletionBlock) {
                        self.savePhotoComletionBlock(error);
                        return;
                    }
                    [self showAlertViewWithTitle:error ? @"图片保存失败" : @"图片保存成功"];
                });
            }];
        }
        
    } else {
        [self showAlertViewWithTitle:@"图片正在下载或下载失败"];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (self.savePhotoComletionBlock) {
        self.savePhotoComletionBlock(error);
        return;
    }
    if (error) {
        YPErrorToast(@"图片保存失败");
    } else {
        YPSuccessToast(@"图片保存成功");
    }
}



- (void)showAlertViewWithTitle:(NSString *)title {
    YPTextToast(title);
}

- (void)convertOriginFrameByView:(UIView *)view {
    self.originFrame = [view convertRect:view.bounds toView:nil];
}

@end
