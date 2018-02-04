//
//  RumexCustomTabBar.h
//  
//
//  Created by Rakesh 
//  Copyright 2010 
//

#import <UIKit/UIKit.h>

@interface DNCustomTabBar : UITabBarController <UITabBarControllerDelegate, UITabBarDelegate>
{
	UIButton *tabBarItemFeed;
	UIButton *tabBarItemConversation;
	UIButton *tabBarItemOrganisation;
	UIButton *tabBarItemProfile;
}

@property (nonatomic, retain) UIButton *tabBarItemFeed;
@property (nonatomic, retain) UIButton *tabBarItemConversation;
@property (nonatomic, retain) UIButton *tabBarItemOrganisation;
@property (nonatomic, retain) UIButton *tabBarItemProfile;

-(void) hideTabBar;
-(void) addCustomElements;
-(void) selectTab:(int)tabID;

-(void) hideNewTabBar;
-(void) showNewTabBar;

-(BOOL) isNewTabbarHidden;

@end
