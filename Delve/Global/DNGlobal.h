//
//  DNGlobal.h
//  Delve
//
//  Created by Letsgomo Labs on 06/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>





@interface DNGlobal : NSObject

+(DNGlobal *)sharedDNGlobal;

-(void)setBaseURL:(NSString*)url;
-(void)setCookie:(NSString*)cookie;
//To Be Removed
-(void)setDefaultCookie;

@property (nonatomic , strong) NSString *gCSRF_Token;
@property (nonatomic) NSInteger gRandomNumberForFeed;
@property (nonatomic) NSInteger gRandomNumberForConversation;

@property( strong, nonatomic) NSString *gCookieInPostApi;
@property (strong,nonatomic) NSString* gCookie;
@property (strong,nonatomic) NSString* baseURL;
@property (assign) BOOL gIsTappedOnProfileName; // used to check if we have tapped on a user's name
@property (strong , nonatomic) NSDictionary *userOrganizations;//for logged in user organisation
@property (strong,nonatomic) NSDictionary *gRandomUserDictionary;//for going from comments
@property (strong , nonatomic) NSDictionary *gUserInfoDictionary;//for logged in user

@property (strong , nonatomic) NSDictionary *gSwitchOrgDictionary;// switch org

@property (strong , nonatomic)  NSString *switchedUserOrganization;// name of the switched org
@property (strong , nonatomic)  NSString *switchedUserOrganizationID;// name of the switched org

// to check if we are showing current loggin in user's profile
@property (assign , nonatomic)  BOOL isOnMyProfile;


/***************************************************************************
 DESCRIPTION:   REMOVES THE DUPLICATE ENTERIES FROM A MUTABLE ARRAY
 (EVEN IF ONLY ONE VALUE IN THE DICTIONARY IS DUPLICATED)
 PARAMETERS:    A MUTABLE ARRAY WITH DUPLICATE VALUES
 RETURN VALUE:  AN ARRAY CONTAINING THE UNIQUE VALUES
 ***************************************************************************/
+(NSMutableArray *)removeDuplicateDelvesFromClipsArray:(NSMutableArray *)clipsArray;

/***************************************************************************
 DESCRIPTION:   Dynamic size of the label
 ***************************************************************************/

+(UILabel *)adjustSizeOfLabel:(UILabel *)lbl;


#pragma mark - navigation bar methods
+ (void)customizeNavigationBarOnViewController:(UIViewController *)viewController andWithDropdownHeading:(NSString *)rightLabelString;
+ (void)hideCustomTabBarOnViewController:(UIViewController *)viewController;// hide custom tabbar
+ (void)showCustomTabBarOnViewController:(UIViewController *)viewController;// show custom tabbar

// image scaling method
+(UIImage*)imageWithImage:(UIImage*)sourceImage scaledToWidth: (float) i_width;

#pragma mark - create delve and comments string
+(NSMutableString *)createDelvesAndCommentString:(NSArray *)clipsArray : (NSArray *)commentsArray;
//+(NSString *)createDelvesAndCommentsStringForConversation:(NSArray *)clipsArray : (NSArray *)commentsArray;

@end
