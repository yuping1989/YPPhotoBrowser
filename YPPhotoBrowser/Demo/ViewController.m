//
//  ViewController.m
//  YPPhotoBrowser
//
//  Created by 喻平 on 16/7/27.
//  Copyright © 2016年 com.yp. All rights reserved.
//

#import "ViewController.h"
#import "DemoCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "YPPhotoBrowser.h"
#import "InputViewController.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        NSArray *thumbs = @[@"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1607/31/c0/24943421_1469960308512_200x300.jpg",
                            @"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1608/11/c0/25449432_1470929066363_200x150.jpg",
                            @"http://www.sinaimg.cn/dy/slidenews/1_t160/2016_30/63957_715785_462226.jpg",
                            @"http://www.sinaimg.cn/dy/slidenews/1_t160/2016_30/63957_715773_106423.jpg",
                            @"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1405/19/c0/34375654_1400463601188_200x150.jpg",
                            @"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1607/16/c1/24266961_1468663628034_320x480.jpg",
                            @"http://img1.imgtn.bdimg.com/it/u=351588642789563137&fm=21&gp=0.jpg"
                            ];
        NSArray *images = @[@"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1607/31/c0/24943421_1469960308512_320x480.jpg",
                            @"http://imgrt.pconline.com.cn/images/upload/upc/tx/wallpaper/1608/11/c0/spcgroup/25449432_1470929066363_2560x1600.jpg",
                            @"http://www.sinaimg.cn/dy/slidenews/1_img/2016_30/63957_715785_462226.jpg",
                            @"http://www.sinaimg.cn/dy/slidenews/1_img/2016_30/63957_715773_106423.jpg",
                            @"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1405/19/c0/34375654_1400463601188.jpg",
                            @"http://imgrt.pconline.com.cn/images/upload/upc/tx/wallpaper/1607/16/c1/spcgroup/24266961_1468663628034_1080x1920.jpg",
                            @"http://image85.360doc.com/DownloadImg/2015/05/2315/53888693_30.jp"];
        NSArray *descrptions = @[@"恢弘的建筑",
                                 @"红色的枫叶",
                                 @"水面上的自行车",
                                 @"晚霞中劳作回家的人",
                                 @"冰冻的河流",
                                 @"桃花，即桃树盛开的花朵，属蔷薇科植物。叶椭圆状披针形，核果近球形，主要分果桃和花桃两大类。桃花原产于中国中部、北部，现已在世界温带国家及地区广泛种植，其繁殖以嫁接为主。桃花可制成桃花丸、桃花茶等食品。其具有很高的观赏价值，是文学创作的常用素材。此外，桃花中元素有疏通经络、滋润皮肤的药用价值。其花语及代表意义为：爱情的俘虏。每年3~6月份，各地会以桃花为媒，举办不同的桃花节盛会。",
                                 @""];
        
        self.dataSource = [NSMutableArray array];
        for (int i = 0; i < images.count; i++) {
            YPPhoto *photo = [[YPPhoto alloc] init];
            photo.imageURL = [NSURL URLWithString:images[i]];
            photo.thumbnailURL = [NSURL URLWithString:thumbs[i]];
            NSString *caption = [NSString stringWithFormat:@"%d/%lu %@", i + 1, (unsigned long)images.count, descrptions[i]];
            
            NSMutableAttributedString *attrCaption = [[NSMutableAttributedString alloc] initWithString:caption];
            [attrCaption addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, caption.length)];
            [attrCaption addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20] range:NSMakeRange(0, 3)];
            [attrCaption addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 3)];
            photo.attributedCaption = attrCaption;
            
            
            photo.caption = descrptions[i];
            
            [self.dataSource addObject:photo];
        }
        [self.tableView reloadData];
    }];
    
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Trasition1", @"Trasition2", @"Fade", @"Push", @"Present"]];
    self.navigationItem.titleView = self.segmentedControl;
    [self.segmentedControl setSelectedSegmentIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DemoCell";
    DemoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    YPPhoto *photo = self.dataSource[indexPath.row];
    [cell.imageButton sd_setImageWithURL:photo.thumbnailURL forState:UIControlStateNormal];
    [cell.imageButton addTarget:self action:@selector(imageButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    cell.imageButton.tag = indexPath.row;
    
    cell.textView.text = photo.caption;
    NSLog(@"cellForRowAtIndexPath-->%d", indexPath.row);
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSLog(@"willDisplayCell-->%d", indexPath.row);
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSLog(@"didEndDisplayingCell-->%d", indexPath.row);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    YPPhoto *photo = self.dataSource[indexPath.row];
    InputViewController *vc = [[InputViewController alloc] initWithNibName:@"InputViewController" bundle:nil];
    vc.text = photo.caption;
    vc.completion = ^(NSString *text) {
        
        NSString *caption = [NSString stringWithFormat:@"%zd/%zd %@", indexPath.row + 1, 7, text];
        NSMutableAttributedString *attrCaption = [[NSMutableAttributedString alloc] initWithString:caption];
        [attrCaption addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, caption.length)];
        [attrCaption addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20] range:NSMakeRange(0, 3)];
        [attrCaption addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 3)];
        photo.attributedCaption = attrCaption;
        
        photo.caption = text;
        [self.tableView reloadData];
    };
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navController animated:YES completion:nil];
}


- (void)imageButtonClicked:(UIButton *)button {
    YPPhotoBrowser *browser = [[YPPhotoBrowser alloc] initWithPhotos:self.dataSource];
    browser.displayingIndex = button.tag;
//    browser.moreButtonHidden = YES;
//    browser.pageIndicatorHidden = YES;
    browser.captionHidden = NO;
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0: {
            for (YPPhoto *photo in self.dataSource) {
                photo.originFrame = CGRectZero;
            }
            YPPhoto *photo = self.dataSource[button.tag];
            
            [photo convertOriginFrameByView:button];
            
            browser.animationStyle = YPPhotoBrowserAnimationTransition;
            [browser show];
        }
            break;
        case 1:
            for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
                DemoCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                YPPhoto *photo = self.dataSource[indexPath.row];
                [photo convertOriginFrameByView:cell.imageButton];
            }
            
            browser.animationStyle = YPPhotoBrowserAnimationTransition;
            [browser show];
            break;
        case 2:
            browser.animationStyle = YPPhotoBrowserAnimationFade;
            [browser show];
            break;
        case 3:
            browser.pageIndicatorHidden = NO;
            browser.moreButtonHidden = NO;
            [self.navigationController pushViewController:browser animated:YES];
            break;
        case 4:
            browser.pageIndicatorHidden = NO;
            browser.moreButtonHidden = NO;
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:browser] animated:YES completion:nil];
            break;
        default:
            break;
    }
}

@end
