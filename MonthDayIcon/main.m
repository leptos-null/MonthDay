//
//  main.m
//  MonthDayIcon
//
//  Created by Leptos on 12/21/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "AppDelegate/AppDelegate.h"

int main(int argc, char *argv[]) {
    NSString *appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
