//
//  XFViewController.m
//  LaunchImageMagic
//
//  Created by luoqisheng on 11/25/2019.
//  Copyright (c) 2019 luoqisheng. All rights reserved.
//

#import "XFViewController.h"
#import <LaunchImageMagic/XFLaunchImageManager.h>

@interface XFViewController ()

@end

@implementation XFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    UIStoryboard *launchScreen = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil];
    UIViewController *vc = [launchScreen instantiateInitialViewController];
    UIImageView *(^findImageView)(void) = ^() {
           UIImageView *target = nil;
           for (UIView *view in vc.view.subviews) {
               if ([view isKindOfClass:UIImageView.class]) {
                   target = (UIImageView *)view;
                   break;
               }
           }

           return target;
    };
    UIImageView *find = findImageView();

    int random = arc4random() % 3;
    find.image = [UIImage imageNamed:[NSString stringWithFormat:@"launch_image_%d",random]];
    UIImage *launchImage = [XFLaunchImageManager imageWithVC:vc];
    [[XFLaunchImageManager shared] onNextLaunchImage:launchImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
