//
//  Utils.h
//  PhotoBox
//
//  Created by Haijian Huo on 3/30/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NYAlertViewController.h"

@interface Utils : NSObject

+ (BOOL)isInternetReachableWithPopup;
+ (BOOL)isInternetReachable;

+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message;
+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message completion:(void (^)(void))completion;
+ (NYAlertViewController*)alertViewControllerWithTitle:(NSString*)title message:(NSString*)message tapDismiss:(BOOL)tapDismiss;


@end
