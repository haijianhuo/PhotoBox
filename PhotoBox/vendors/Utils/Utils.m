//
//  Utils.m
//  PhotoBox
//
//  Created by Haijian Huo on 3/30/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

#import "Utils.h"
#import "Reachability.h"
#import "ProgressHUD.h"

@implementation Utils

+ (BOOL)isInternetReachableWithPopup
{
    if (![self isInternetReachable])
    {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [ProgressHUD showError:@"Internet not reachable!"];
        });
        
        return NO;
    }
    return YES;
}

+ (BOOL)isInternetReachable
{
    
    BOOL ret = ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable);
    
    return ret;
}


+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NYAlertViewController *alertViewController = [[NYAlertViewController alloc] initWithNibName:nil bundle:nil];
        alertViewController.title = title;
        alertViewController.message = message;
        alertViewController.backgroundTapDismissalGestureEnabled = YES;
        alertViewController.swipeDismissalGestureEnabled = YES;
        alertViewController.transitionStyle = NYAlertViewControllerTransitionStyleFade;
        
        NSString *actionTitle = @"OK";
        UIAlertActionStyle actionStyle = UIAlertActionStyleCancel;
        
        UIViewController *controller = [self topViewController];
        
        [alertViewController addAction:[NYAlertAction actionWithTitle:actionTitle style:actionStyle handler:^(NYAlertAction *action) {
            [controller dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [controller presentViewController:alertViewController animated:YES completion:nil];
    });
}

+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message completion:(void (^)(void))completion
{
    NYAlertViewController *alertViewController = [[NYAlertViewController alloc] initWithNibName:nil bundle:nil];
    alertViewController.title = title;
    alertViewController.message = message;
    alertViewController.backgroundTapDismissalGestureEnabled = YES;
    alertViewController.swipeDismissalGestureEnabled = YES;
    alertViewController.transitionStyle = NYAlertViewControllerTransitionStyleFade;
    
    UIViewController *controller = [self topViewController];
    
    [alertViewController addAction:[NYAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(NYAlertAction *action) {
        [controller dismissViewControllerAnimated:YES completion:nil];
        if (completion)
            completion();
    }]];
    
    [controller presentViewController:alertViewController animated:YES completion:nil];
    
}

+ (NYAlertViewController*)alertViewControllerWithTitle:(NSString*)title message:(NSString*)message tapDismiss:(BOOL)tapDismiss
{
    NYAlertViewController *alertViewController = [[NYAlertViewController alloc] initWithNibName:nil bundle:nil];
    alertViewController.title = title;
    alertViewController.message = message;
    alertViewController.backgroundTapDismissalGestureEnabled = tapDismiss;
    alertViewController.swipeDismissalGestureEnabled = YES;
    alertViewController.transitionStyle = NYAlertViewControllerTransitionStyleFade;
    
    return alertViewController;
}

+ (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController
{
    if ([rootViewController isKindOfClass:NSClassFromString(@"UIApplicationRotationFollowingController")])
        return nil;
    
    if ([rootViewController isKindOfClass:[UITabBarController class]])
    {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    }
    else if ([rootViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    }
    else if (rootViewController.presentedViewController)
    {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    }
    else
    {
        return rootViewController;
    }
}

@end
