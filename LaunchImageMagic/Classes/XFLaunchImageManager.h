//
//  XFLaunchImageManager.h
//  LaunchImageMagic
//
//  Created by Luo Qisheng on 2019/11/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, Orientation) {
    Portrait,
    Landscape,
};

NS_ASSUME_NONNULL_BEGIN

@interface XFLaunchImageManager : NSObject

+ (instancetype)shared;
- (void)onNextLaunchImage:(UIImage *)launchImage;
- (void)onNextLaunchImage:(UIImage *)launchImage forOrientation:(Orientation)orientation;

///  Helper Methods
+ (UIImage *)imageWithView:(UIView *)view;
+ (UIImage *)imageWithLaunchScreen:(UIStoryboard *)launchScreen;
+ (UIImage *)imageWithVC:(UIViewController *)viewController;
@end

NS_ASSUME_NONNULL_END
