//
//  RumexCustomTabBar.m
//
//
//  Created by Rakesh
//  Copyright 2010
//
#import "DNCustomTabBar.h"

#import "DNGlobal.h"

#define kTabbarOffsety_5 518.0
#define kTabbarOffsety_4 430.0
#define kTabbarItemWidth 80.0
#define kTabbarItemheight 50.0


@implementation DNCustomTabBar
{
    BOOL isNewTabbarHidden;
}

@synthesize tabBarItemFeed, tabBarItemConversation, tabBarItemOrganisation, tabBarItemProfile;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	[self hideTabBar];
	[self addCustomElements];
    
}

- (void)hideTabBar
{
	for(UIView *view in self.view.subviews)
	{
		if([view isKindOfClass:[UITabBar class]])
		{
			view.hidden = YES;
			break;
		}
	}
}

-(BOOL)isNewTabbarHidden
{
    return isNewTabbarHidden;
}

- (void)hideNewTabBar 
{
    self.tabBarItemFeed.hidden = 1;
    self.tabBarItemConversation.hidden = 1;
    self.tabBarItemOrganisation.hidden = 1;
    self.tabBarItemProfile.hidden = 1;
    
    isNewTabbarHidden = YES;
    self.tabBar.backgroundColor = [UIColor clearColor];

}

- (void)showNewTabBar
{
    self.tabBarItemFeed.hidden = 0;
    self.tabBarItemConversation.hidden = 0;
    self.tabBarItemOrganisation.hidden = 0;
    self.tabBarItemProfile.hidden = 0;
    
    isNewTabbarHidden = NO;
}

-(void)addCustomElements
{
	// Initialise our two images
	UIImage *btnImage = [UIImage imageNamed:@"newspaper.png"];
	UIImage *btnImageSelected = [UIImage imageNamed:@"newspaper_selected.png"];
	
	self.tabBarItemFeed = [UIButton buttonWithType:UIButtonTypeCustom]; //Setup the button
    CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
    
    if (iOSDeviceScreenSize.height == 480)
    {
        tabBarItemFeed.frame = CGRectMake(0, kTabbarOffsety_4, kTabbarItemWidth, kTabbarItemheight); // Set the frame (size and position) of the button)
    }
    else
    {
        tabBarItemFeed.frame = CGRectMake(0, kTabbarOffsety_5, kTabbarItemWidth, kTabbarItemheight);
    }
	[tabBarItemFeed setBackgroundImage:btnImage forState:UIControlStateNormal]; // Set the image for the normal state of the button
	[tabBarItemFeed setBackgroundImage:btnImageSelected forState:UIControlStateSelected]; // Set the image for the selected state of the button
	[tabBarItemFeed setTag:0]; // Assign the button a "tag" so when our "click" event is called we know which button was pressed.
	[tabBarItemFeed setSelected:true]; // Set this button as selected (we will select the others to false as we only want Tab 1 to be selected initially
	
	// Now we repeat the process for the other buttons
	btnImage = [UIImage imageNamed:@"comments.png"];
	btnImageSelected = [UIImage imageNamed:@"comments_selected.png"];
	self.tabBarItemConversation = [UIButton buttonWithType:UIButtonTypeCustom];
    if (iOSDeviceScreenSize.height == 480)
    {
        tabBarItemConversation.frame = CGRectMake(80, kTabbarOffsety_4, kTabbarItemWidth, kTabbarItemheight);
    }
    else
    {
        tabBarItemConversation.frame = CGRectMake(80, kTabbarOffsety_5, kTabbarItemWidth, kTabbarItemheight);
    }

	
	[tabBarItemConversation setBackgroundImage:btnImage forState:UIControlStateNormal];
	[tabBarItemConversation setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[tabBarItemConversation setTag:1];
	
	btnImage = [UIImage imageNamed:@"organisation.png"];
	btnImageSelected = [UIImage imageNamed:@"organisation_selected.png"];
	self.tabBarItemOrganisation = [UIButton buttonWithType:UIButtonTypeCustom];
    if(iOSDeviceScreenSize.height == 480)
    {
        tabBarItemOrganisation.frame = CGRectMake(160, kTabbarOffsety_4, kTabbarItemWidth, kTabbarItemheight);
    }
    else
    {
        tabBarItemOrganisation.frame = CGRectMake(160, kTabbarOffsety_5, kTabbarItemWidth, kTabbarItemheight);
    }
	
	[tabBarItemOrganisation setBackgroundImage:btnImage forState:UIControlStateNormal];
	[tabBarItemOrganisation setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[tabBarItemOrganisation setTag:2];
	
	btnImage = [UIImage imageNamed:@"profile.png"];
	btnImageSelected = [UIImage imageNamed:@"profile_selected.png"];
	self.tabBarItemProfile = [UIButton buttonWithType:UIButtonTypeCustom];
    if(iOSDeviceScreenSize.height == 480)
    {
        tabBarItemProfile.frame = CGRectMake(240, kTabbarOffsety_4, kTabbarItemWidth, kTabbarItemheight);
    }
    else
    {
        tabBarItemProfile.frame = CGRectMake(240, kTabbarOffsety_5, kTabbarItemWidth, kTabbarItemheight);
    }
	
	[tabBarItemProfile setBackgroundImage:btnImage forState:UIControlStateNormal];
	[tabBarItemProfile setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[tabBarItemProfile setTag:3];
	
	// Add my new buttons to the view
	[self.view addSubview:tabBarItemFeed];
	[self.view addSubview:tabBarItemConversation];
	[self.view addSubview:tabBarItemOrganisation];
	[self.view addSubview:tabBarItemProfile];
	
	// Setup event handlers so that the buttonClicked method will respond to the touch up inside event.
	[tabBarItemFeed addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[tabBarItemConversation addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[tabBarItemOrganisation addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[tabBarItemProfile addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonClicked:(id)sender
{
	int tagNum = [sender tag];
	[self selectTab:tagNum];
}

// When tabs are selected in our customized tabbar 
- (void)selectTab:(int)tabID
{
    // if tab 4 is selected and on root view (means watching current user profile)
    if(tabID != 3 )
    {
        //  change the varible used to show user's profile
        [DNGlobal sharedDNGlobal].isOnMyProfile = NO;
    }
    else
    {
        // else also check if on tab 4 there is no other profile is opened up
        if([[[self childViewControllers] objectAtIndex:tabID] childViewControllers].count == 1)
        {
            [DNGlobal sharedDNGlobal].isOnMyProfile = YES;
        }
    }
    
    // if the tab is already selected only then pop all contrllers , not on a simple switch
    if(self.selectedIndex == tabID)
    {
        // if tab 4 is selected and on root view (means watching current user profile)
        if(tabID == 3 )
        {
            // NSLog(@"on my profile now-----");
            // also change the varible used to show user's profile
            [DNGlobal sharedDNGlobal].isOnMyProfile = YES;
        }
        
        // accessing child navigation controller of the selected tab
        // NSLog(@"controllers : %@", [[[self childViewControllers] objectAtIndex:tabID] childViewControllers]);
        [[[self childViewControllers] objectAtIndex:tabID] popToRootViewControllerAnimated:YES];
    }
    
	switch(tabID)
	{
		case 0:
			[tabBarItemFeed setSelected:true];
			[tabBarItemConversation setSelected:false];
			[tabBarItemOrganisation setSelected:false];
			[tabBarItemProfile setSelected:false];
			break;
		case 1:
			[tabBarItemFeed setSelected:false];
			[tabBarItemConversation setSelected:true];
			[tabBarItemOrganisation setSelected:false];
			[tabBarItemProfile setSelected:false];
			break;
		case 2:
			[tabBarItemFeed setSelected:false];
			[tabBarItemConversation setSelected:false];
			[tabBarItemOrganisation setSelected:true];
			[tabBarItemProfile setSelected:false];
			break;
		case 3:
			[tabBarItemFeed setSelected:false];
			[tabBarItemConversation setSelected:false];
			[tabBarItemOrganisation setSelected:false];
			[tabBarItemProfile setSelected:true];
			break;
	}
    
	self.selectedIndex = tabID; // to choose

}

@end
