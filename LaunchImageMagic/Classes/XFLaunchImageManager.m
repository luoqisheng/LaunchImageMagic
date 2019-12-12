//
//  XFLaunchImageManager.m
//  LaunchImageMagic
//
//  Created by Luo Qisheng on 2019/11/25.
//

#import "XFLaunchImageManager.h"

@implementation XFLaunchImageManager

+ (instancetype)shared {
    static XFLaunchImageManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [XFLaunchImageManager new];
    });
    return shared;
}

- (void)onNextLaunchImage:(UIImage *)launchImage {
    [self onNextLaunchImage:launchImage forOrientation:Portrait];
}

- (void)onNextLaunchImage:(UIImage *)launchImage forOrientation:(Orientation)orientation {

    CGSize imageSize = launchImage.size;
    BOOL validImage = ([self isPortraitImageSize:imageSize] && orientation == Portrait)
    || ([self isLandscapeImageSize:imageSize] && orientation == Landscape);
    if (!validImage) {
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        NSString *o = @"Portrait";
        NSString *r = [NSString stringWithFormat:@"%f:%f", screenSize.width, screenSize.height];
        if (orientation == Landscape) {
            o = @"Landscape";
            r = [NSString stringWithFormat:@"%f:%f", screenSize.height, screenSize.width];
        }

        NSString *reason = [NSString stringWithFormat:@"The aspect ratio of the launch image for %@ should be %@", o, r];
        @throw [NSException exceptionWithName:@"invalid launch image"
                                       reason:reason
                                     userInfo:nil];
    }


    NSString *destDir = [self launchImageDirPath];
    if (!destDir.length) {
        return;
    }
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:destDir];
    NSString *entry;
    while ((entry = enumerator.nextObject) != nil) {
        NSString *filePath = [destDir stringByAppendingPathComponent:entry];
        NSURL *url = [NSURL fileURLWithPath:filePath];
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
        if (source) {
            NSDictionary *options = @{ (NSString *)kCGImageSourceShouldCache: @(NO) };
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, 0, (__bridge CFDictionaryRef)options);
            if (properties) {
                NSNumber *width = [(__bridge NSDictionary *)properties objectForKey:(NSString *)kCGImagePropertyPixelWidth];
                NSNumber *height = [(__bridge NSDictionary *)properties objectForKey:(NSString *)kCGImagePropertyPixelHeight];

                CGSize imageSize = CGSizeMake(width.floatValue, height.floatValue);
                if ([self isPortraitImageSize:imageSize] && orientation == Portrait) {
                    [self saveImage:launchImage intoURL:url];
                } else if ([self isLandscapeImageSize:imageSize] && orientation == Landscape) {
                    [self saveImage:launchImage intoURL:url];
                }
                CFRelease(properties);
            } else {
                // 文件损坏
                NSError *error;
                [NSFileManager.defaultManager removeItemAtURL:url error:&error];
            }

            CFRelease(source);
        }
    }
}

- (BOOL)isPortraitImageSize:(CGSize)imageSize {

    if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        return NO;
    }

    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGFloat widthRadio = imageSize.width / screenSize.width;
    CGFloat heightRadio = imageSize.height / screenSize.height;
    return widthRadio == heightRadio;
}

- (BOOL)isLandscapeImageSize:(CGSize)imageSize {

    if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        return NO;
    }

    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGFloat widthRadio = imageSize.width / screenSize.height;
    CGFloat heightRadio = imageSize.height / screenSize.width;
    return widthRadio == heightRadio;
}

- (BOOL)saveImage:(UIImage *)image intoURL:(NSURL *)url {
    if (![url isFileURL]) {
        return NO;
    }

    float compression = 1.0; // Lossless compression if available.
    CFStringRef keys[2];
    CFTypeRef   values[2];
    CFDictionaryRef options = NULL;
    keys[0] = kCGImagePropertyHasAlpha;
    values[0] = kCFBooleanTrue;
    keys[1] = kCGImageDestinationLossyCompressionQuality;
    values[1] = CFNumberCreate(NULL, kCFNumberFloatType, &compression);
    options = CFDictionaryCreate(NULL, (const void **)keys, (const void **)values, 2,
                          &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)@"public.png", 1, NULL);
    CGImageDestinationAddImage(dest, image.CGImage, options);
    BOOL success = CGImageDestinationFinalize(dest);

    // 清理资源
    CFRelease(values[1]);
    CFRelease(options);
    CFRelease(dest);

    return success;
}

- (NSString *)launchImageDirPath {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    NSString *pathComponent = [NSString stringWithFormat:@"SplashBoard/Snapshots/%@ - {DEFAULT GROUP}/", NSBundle.mainBundle.bundleIdentifier];
    return [dir stringByAppendingPathComponent:pathComponent];
}

+ (UIImage *)imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (UIImage *)imageWithLaunchScreen:(UIStoryboard *)launchScreen {

    if (!launchScreen) {
        return nil;
    }

    UIViewController *vc = [launchScreen instantiateInitialViewController];
    return [self imageWithVC:vc];
}

+ (UIImage *)imageWithVC:(UIViewController *)viewController {

    if (!viewController) {
        return nil;
    }

    // 用不可见的window渲染，来处理不同系统上的布局问题
    UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    window.rootViewController = viewController;
    window.windowLevel = UIWindowLevelNormal - 1;
    [window makeKeyAndVisible];
    UIImage *image = [self imageWithView:window];
    return image;
}

@end
