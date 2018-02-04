//
//  DNAppDelegate.m
//  Delve
//
//  Created by Letsgomo Labs on 29/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "DNAppDelegate.h"
#import "DNGlobal.h"
#import "DNTimerUIApllication.h"

#import "Crittercism.h"

@implementation DNAppDelegate

@synthesize idleTimer = _idleTimer;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // on launch of application keep 'isLoggedOutLastTime' bool to no 
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        // app already launched
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // This is the first launch ever
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedOutLastTime"];
    }
    
    // crittercism
//    [Crittercism enableWithAppID:@"5256c3c24002051ac7000006"];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //setting false to comingfromcomments
    DNGlobal *sharedInstance = [DNGlobal sharedDNGlobal];
    sharedInstance.gIsTappedOnProfileName = FALSE;
    
    // check for idle time
    NSDate *sleepTime = [_idleTimer fireDate];
    [[NSUserDefaults standardUserDefaults]setValue:sleepTime forKey:@"sleptTime"];
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
//    // NSLog(@"===================> applicationWillEnterForeground called");
    NSDate *sleepDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"sleptTime"];
    NSDate *currentDate = [NSDate date];
    NSTimeInterval interval = [currentDate timeIntervalSinceDate:sleepDate];
    
    NSString *timeoutInterval = [[NSUserDefaults standardUserDefaults]valueForKey:@"timeoutInterval"];
    int idleTimeout;// = 0;
    if (timeoutInterval == nil)
    {
        idleTimeout = 15*60;
        [[NSUserDefaults standardUserDefaults] setValue:@"15" forKey:@"timeoutInterval"];
    }
    else
    {
        idleTimeout = [timeoutInterval integerValue]*60;
    }
    
    if(interval>idleTimeout)
    {
       [(DNTimerUIApllication *)[UIApplication sharedApplication] resetIdleTimer];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
