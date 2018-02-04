//
//  DNTimerUIApllication.h
//  Delve
//
//  Created by Letsgomo Labs on 30/09/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "Constants.h"

//the length of time before your application "times out". This number actually represents seconds, so we'll have to multiple it by 60 in the .m file
#define kApplicationTimeoutInMinutes 15


@interface DNTimerUIApllication : UIApplication

@property (nonatomic, retain) NSTimer *idleTimer;

-(void)resetIdleTimer;

@end
