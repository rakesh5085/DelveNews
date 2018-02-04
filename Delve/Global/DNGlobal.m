//
//  DNGlobal.m
//  Delve
//
//  Created by Letsgomo Labs on 06/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNGlobal.h"

#import "DNFeedTableViewController.h"

#import "DNProfileViewController.h"

#import "DNCustomTabBar.h"



@implementation DNGlobal
@synthesize baseURL;
@synthesize gCookie;
@synthesize userOrganizations;
@synthesize gUserInfoDictionary;
@synthesize gRandomNumberForFeed,gRandomNumberForConversation;
@synthesize gCSRF_Token;
@synthesize gCookieInPostApi;
@synthesize gIsTappedOnProfileName;
@synthesize gRandomUserDictionary;

@synthesize gSwitchOrgDictionary;

@synthesize switchedUserOrganization;

@synthesize switchedUserOrganizationID;

@synthesize isOnMyProfile;

#pragma mark - Navigation bar methods
// customize navigation bar methods
+ (void)customizeNavigationBarOnViewController:(UIViewController *)viewController andWithDropdownHeading:(NSString *)rightLabelString
{
    viewController.navigationController.navigationBarHidden = NO;
    // Remove any subviews already present
    for (UIView *view in [viewController.navigationController.navigationBar subviews])
    {
        if(view.tag == 101 || view.tag == 102 || view.tag == 103 || view.tag == 104 || view.tag == 105)
            [view removeFromSuperview];
    }
    
    // change the background of bar
    if ([viewController.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)] )
    {
        UIImage *image = [UIImage imageNamed:@"navBar.png"];
        [viewController.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
    
//    // NSLog(@"is tapped on profile name : %d", [DNGlobal sharedDNGlobal].gIsTappedOnProfileName);
//    // NSLog(@"controllers : %@", [[viewController parentViewController] childViewControllers]);

    // show back button if navigation controller has more than 1 child
    // [viewController parentViewController] means navigation controller
    if([[viewController parentViewController] childViewControllers].count > 1)
    {
        UIButton *buttonBack = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonBack.frame = CGRectMake(0,0,80,44);
        buttonBack.tag = 104;
        [buttonBack setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
        [buttonBack setImage:[UIImage imageNamed:@"back_highlighted.png"] forState:UIControlStateHighlighted];
        [buttonBack addTarget:viewController action:@selector(goToBack:) forControlEvents:UIControlEventTouchUpInside];
        [viewController.navigationController.navigationBar addSubview:buttonBack];
    }
    else
    {
        // create a delve logo image
        UIImageView *imageViewDelveLogo = [[UIImageView alloc] initWithFrame:CGRectMake(10,10,96,24)];
        imageViewDelveLogo.image = [UIImage imageNamed:@"logo.png"];
        imageViewDelveLogo.tag = 101;
        [viewController.navigationController.navigationBar addSubview:imageViewDelveLogo];
    }
    
    if(![viewController isKindOfClass:[DNFeedTableViewController class]] && ![viewController isKindOfClass:[DNArticleViewController class]])
    {
        // add the right side label
        UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake(150,10,130,24)];
        navLabel.tag = 102;
        navLabel.text = rightLabelString;
        navLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
        navLabel.textAlignment = NSTextAlignmentRight;
        navLabel.textColor = [UIColor whiteColor];
        navLabel.backgroundColor = [UIColor clearColor];
        [viewController.navigationController.navigationBar addSubview:navLabel];
        
        // create a down arrow image leaving right space of 10px
        UIImageView *imageViewDownArrow = [[UIImageView alloc] initWithFrame:CGRectMake(290,20,8,4)];
        imageViewDownArrow.image = [UIImage imageNamed:@"down_arrow.png"];
        imageViewDownArrow.tag = 103;
        [viewController.navigationController.navigationBar addSubview:imageViewDownArrow];
        
        UIButton *buttonDropdown = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonDropdown.frame = CGRectMake(160,5,140,34);
        buttonDropdown.tag = 105;
        [buttonDropdown addTarget:viewController action:@selector(showHideDropdownList) forControlEvents:UIControlEventTouchUpInside];
        [viewController.navigationController.navigationBar addSubview:buttonDropdown];
    }
}

+ (void)hideCustomTabBarOnViewController:(UIViewController *)viewController
{
    // hide tab bar on web view
    [((DNCustomTabBar *)[viewController.navigationController parentViewController]) hideNewTabBar];
    
    // set the size of the viewcurrent view's size to super view + height of tabbar 
    CGRect frame = viewController.tabBarController.view.superview.frame;
    CGFloat offset = viewController.tabBarController.tabBar.frame.size.height;
    frame.size.height += offset;
    viewController.tabBarController.view.frame = frame;
}

+ (void)showCustomTabBarOnViewController:(UIViewController *)viewController
{
    // hide tab bar on web view
    [((DNCustomTabBar *)[viewController.navigationController parentViewController]) showNewTabBar];
    
    // set the size of the viewcurrent view's size to super view 
    CGRect frame = viewController.tabBarController.view.superview.frame;
    viewController.tabBarController.view.frame = frame;
}

#pragma mark - Create Delve and Comments string
+(NSMutableString *)createDelvesAndCommentString:(NSArray *)clipsArray : (NSArray *)commentsArray
{
    NSMutableString *str_delvesAndComment = [[NSMutableString alloc] init];
    NSString *otherString, *commentString;
    
    if(clipsArray || commentsArray)
    {
        if(clipsArray && ([clipsArray count] > 3)) // Delved by Thomas, Andrew, Sandeep & 2 others | 4 Comments
        {
            // organize "others and comments " string
            if(([clipsArray count]-3) == 1)
                otherString = @"other";
            else if(([clipsArray count]-3) > 1)
                otherString = @"others";
            
            [str_delvesAndComment appendFormat:@"Shared by "];
            for (int i =0; i<[clipsArray count]-1; i++) // dont add ',' to last element
            {
                if(i<2) // it shd be < 2
                    [str_delvesAndComment appendFormat:@"<_link>%@|%@</_link>, ",[[clipsArray objectAtIndex:i] objectForKey:@"user_id"], [[clipsArray objectAtIndex:i] objectForKey:@"user_name"]];
                else if(i == 2) // for the last user name do not put ',' at last
                    [str_delvesAndComment appendFormat:@"<_link>%@|%@</_link> & ",[[clipsArray objectAtIndex:i] objectForKey:@"user_id"], [[clipsArray objectAtIndex:i] objectForKey:@"user_name"]];
            }
            // finally add "# Other" string  to it.. # is the number of other ppl
            [str_delvesAndComment appendString:[NSString stringWithFormat:@"%d %@ ", [clipsArray count]-3, otherString]];
        }
        else // Delved by Thomas & Andrew | 1 Comment or Delved by Thomas, Andrew & Sandeep | 2 Comments
        {
            if(clipsArray && ([clipsArray count] > 0)) // > 0 but <= 3
            {
                [str_delvesAndComment appendFormat:@"Shared by "];
                if([clipsArray count]==1)
                    [str_delvesAndComment appendString:[NSString stringWithFormat:@"<_link>%@|%@</_link> ",[[clipsArray objectAtIndex:0] objectForKey:@"user_id"], [[clipsArray objectAtIndex:0] objectForKey:@"user_name"]]];
                else if([clipsArray count]==2)
                    [str_delvesAndComment appendString:[NSString stringWithFormat:@"<_link>%@|%@</_link> & <_link>%@|%@</_link> ",
                        [[clipsArray objectAtIndex:0] objectForKey:@"user_id"], [[clipsArray objectAtIndex:0] objectForKey:@"user_name"],
                        [[clipsArray objectAtIndex:1] objectForKey:@"user_id"], [[clipsArray objectAtIndex:1] objectForKey:@"user_name"]]];
                else if([clipsArray count]==3)
                    [str_delvesAndComment appendString:[NSString stringWithFormat:@"<_link>%@|%@</_link>, <_link>%@|%@</_link> & <_link>%@|%@</_link> ",
                        [[clipsArray objectAtIndex:0] objectForKey:@"user_id"],[[clipsArray objectAtIndex:0] objectForKey:@"user_name"],
                         [[clipsArray objectAtIndex:1] objectForKey:@"user_id"], [[clipsArray objectAtIndex:1] objectForKey:@"user_name"],
                           [[clipsArray objectAtIndex:2] objectForKey:@"user_id"], [[clipsArray objectAtIndex:2] objectForKey:@"user_name"]]];
            }
        }
        
        // now for comments
        if(commentsArray && ([commentsArray count] > 0))
        {
            if([commentsArray count] > 1)
                commentString = @"Comments";
            else
                commentString = @"Comment";
            // finally for "| 4 Comments" string logic
            if(!clipsArray || clipsArray.count == 0 )
                [str_delvesAndComment appendString:[NSString stringWithFormat:@"%d %@ ", commentsArray.count, commentString]];
            else
                [str_delvesAndComment appendString:[NSString stringWithFormat:@"| %d %@ ", commentsArray.count, commentString]];
        }
    }

    return str_delvesAndComment;
}


#pragma mark - remove duplicates from mutable array of dictionaries
/***************************************************************************
 DESCRIPTION:   REMOVES THE DUPLICATE ENTERIES FROM A MUTABLE ARRAY
 (EVEN IF ONLY ONE VALUE IN THE DICTIONARY IS DUPLICATED)
 PARAMETERS:    A MUTABLE ARRAY WITH DUPLICATE VALUES
 RETURN VALUE:  AN ARRAY CONTAINING THE UNIQUE VALUES
 ***************************************************************************/
+(NSMutableArray *)removeDuplicateDelvesFromClipsArray:(NSMutableArray *)clipsArray
{
    // first sort the array
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"user_name" ascending:YES
                                                            selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject: sorter];
    [clipsArray sortUsingDescriptors:sortDescriptors];
    
    // and now removes duplicate clipped entries
    NSString *lastDelvedBy = nil;
    NSMutableArray *resultClipArray = [NSMutableArray array];
    
    for(NSDictionary *d in clipsArray)
    {
        NSString *user_name = [d objectForKey:@"user_name"];
        if (![user_name isEqualToString:lastDelvedBy])
        {
            [resultClipArray addObject:d];
            lastDelvedBy = user_name;
        }
    }
    return resultClipArray;
}

#pragma mark - helper uiimage methods
// image resizing method
+(UIImage*)imageWithImage:(UIImage*)sourceImage scaledToWidth: (float) i_width
{
    // To Resize the image maintaining the aspect ratio
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - for dynamic size of Label

+ (UILabel *)adjustSizeOfLabel:(UILabel *)lbl
{
    CGSize maximumLabelSize = CGSizeMake(300,FLT_MAX);
    
    CGSize expectedLabelSize = [lbl.text sizeWithFont:lbl.font
                                    constrainedToSize:maximumLabelSize
                                        lineBreakMode:lbl.lineBreakMode];
    
    //adjust the label the the new height/width.
    CGRect newFrame = lbl.frame;
    newFrame.size.height = expectedLabelSize.height;
    newFrame.size.width = expectedLabelSize.width;
    lbl.frame = newFrame;
    
    return lbl;
}

#pragma mark - shared instance GNGlobal

+(DNGlobal*)sharedDNGlobal
{
    static dispatch_once_t onceToken;
    static DNGlobal *dnGlobal = nil;
    dispatch_once(&onceToken, ^{
        dnGlobal = [[DNGlobal alloc] init];
        // NSLog(@"Creating a shared object");
    });
    
    return dnGlobal;

}

//SET Default baseURL
-(void)setBaseURL:(NSString *)url{
    self.baseURL= url;
}

-(void)setCookie:(NSString *)newCookie{
    self.cookie= newCookie;
}

-(void)setDefaultCookie{
    self.cookie= @"xyz";
}



@end
