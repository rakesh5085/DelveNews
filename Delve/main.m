//
//  main.m
//  Delve
//
//  Created by Letsgomo Labs on 29/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DNTimerUIApllication.h"
#import "DNAppDelegate.h"


/*
 
 Main.m changed due to new version of xcode (and use of story board)
 after xcode 4.2
 */
int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, NSStringFromClass([DNTimerUIApllication class]), NSStringFromClass([DNAppDelegate class]));
    }
}
