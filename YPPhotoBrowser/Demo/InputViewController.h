//
//  InputViewController.h
//  YPPhotoBrowser
//
//  Created by 喻平 on 2017/6/13.
//  Copyright © 2017年 com.yp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InputViewController : UIViewController

@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) void (^completion)(NSString *text);

@end
