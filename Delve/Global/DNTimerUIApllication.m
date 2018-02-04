//
//  DNTimerUIApllication.m
//  Delve
//
//  Created by Letsgomo Labs on 30/09/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNTimerUIApllication.h"



@implementation DNTimerUIApllication

@synthesize idleTimer = _idleTimer;


#pragma mark - idle timer methods
//Idle Timer Methods
- (void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];
    
    if (!_idleTimer)
    {
        [self resetIdleTimer];
    }

    // Only want to reset the timer on a Began touch or an Ended touch, to reduce the number of timer resets.
    NSSet *allTouches = [event allTouches];
    if ([allTouches count] > 0)
    {
        // allTouches count only ever seems to be 1, so anyObject works here.
        UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
        if (phase == UITouchPhaseBegan || phase == UITouchPhaseEnded)
            [self resetIdleTimer];
    }
}

- (void)resetIdleTimer
{
    if (_idleTimer) {
        [_idleTimer invalidate];
    }
    int idleTimeout = kApplicationTimeoutInMinutes * 30;
    _idleTimer = [NSTimer scheduledTimerWithTimeInterval:idleTimeout target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
}

- (void)idleTimerExceeded
{
    // NSLog(@"idle time exceeded");
    [self resetIdleTimer];
    
    // now refresh each page , simply by posting notification 
    [[NSNotificationCenter defaultCenter] postNotificationName:kPOSTNOTIFICATION_REFRESH_FEEDS object:nil userInfo:nil];
}


@end
