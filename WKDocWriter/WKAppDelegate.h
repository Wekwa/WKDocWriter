//
//  WKAppDelegate.h
//  WKDocWriter
//
//  Created by Wyatt Kaufman on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WKViewController;

@interface WKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) WKViewController *viewController;

@end
