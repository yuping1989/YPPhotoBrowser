//
//  InputViewController.m
//  YPPhotoBrowser
//
//  Created by 喻平 on 2017/6/13.
//  Copyright © 2017年 com.yp. All rights reserved.
//

#import "InputViewController.h"

@interface InputViewController ()

@property (nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation InputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"编辑";
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.textView.text = self.text;
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancelItem;
    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = doneItem;
    
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.textView.layer.borderWidth = 0.5f;
    self.textView.layer.cornerRadius = 5;
}

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)done {
    if (self.completion) {
        self.completion(self.textView.text);
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
