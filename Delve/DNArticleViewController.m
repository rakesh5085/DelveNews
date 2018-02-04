//
//  DNArticleViewController.m
//  Delve
//
//  Created by Atul Khatri on 31/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNArticleViewController.h"
#import "DNGlobal.h"
#import "DNCommentModal.h"
#import <QuartzCore/QuartzCore.h>
#import "DNProfileViewController.h"
#import "UIImage+animatedGIF.h"

#import "DNCustomTabBar.h"

//DelveIt button offset, width and height
#define kDelveButtonOffsetY 10.0
#define kDelveButtonOffsetX 17.0
#define kDelveButtonWidth 213.0
#define kDelveButtonHeight 38.0

//Blue Grey Line below Notification button
#define kLineOffsetY 44.0
#define kLineHeight 3.0

//Notification button offset, width & height
#define kNotifButtonsOffsetX 244.0
#define kNotifButtonsWidth 76.0
#define kNotifButtonsHeight 47.0

//Notification button Text offset so text remains in center
#define kNotificationButtonLeftOffset 5.0
#define kNotificationButtonBottomOffset -2.0

//Footer view top margin
#define kFooterTopMargin 10.0

//PostCommentView offset, animation state offset & height
#define kPostCommentViewOffsetY 461.0
#define kPostCommentViewOffsetY_iphone4 371.0
#define kPostCommentViewAfterAnimOffsetY 204.0
#define kPostCommentViewAfterAnimOffsetY_iphone4 125.0
#define kPostCommentViewHeight 104.0

//CommentList offset, height and animation state offset
#define kCommentListOffsetY 480.0
#define kCommentListViewHeight 410.0
#define kCommentListViewHeight_iphone4 260.0
#define kCommentListAfterAnimOffsetY 80.0
#define kCommentListAfterAnimOffsetY_iphone4 70.0

//Device screenWidth
#define kScreenWidth 320.0

//Comments Table View's height
#define kCommentTableViewHeight 335.0
#define kCommentTableViewHeight_iphone4 260.0


//FooterView at bottom height & offset
#define kFooterViewHeight 53.0
#define kFooterViewOffsetY 471.0 // footer view contains delve btn and comments button
#define kFooterViewOffsetY_iphone4 385.0

//TextView and Button's Border Width
#define kBorderWidth 1.0f

//CommentTextView's radius of corners
#define kCommentTextViewCornerRadius 3.0f

//CommentListView Animation duration
#define kCommentListViewAnimationDuration 0.5

//PostCommentView Animation duration
#define kPostCommentViewAnimationDuration 0.2

//FooterView's show/hide delay
#define kFooterViewShowHideDelay 0.2

//
#define FONT_SIZE 12.0f
#define CELL_CONTENT_WIDTH 232.0f
#define CELL_CONTENT_MARGIN 5.0f

@implementation DNArticleViewController
{
    // To delve
    NSURLConnection *connectionToDelveArticle;          // connnetion to delve an article
    NSMutableData *dataToDelveArticle;                  // Data for delving an article
    // To Comment
    NSURLConnection *connectionToCommentArticle;        // connection to comment on article
    NSMutableData *dataOfCommentedArticle;              // Data for commenting an article
    // To undelve
    NSURLConnection *connectionToUndelveArticle;
    NSMutableData *dataToUndelveArticle;
    NSArray *clipsArray; // to hold clips of the article
    NSDictionary *loggedinUserClipDictionary; // clip of the logged in user
    
    // delves and comments istant update
    NSArray *tempClipsArray; // temporary clips array to hold the value of clips for the article
    BOOL isArcticleModified; // weather article delved/undelved/ commented
        
}


@synthesize articleWebView;
@synthesize commentTableView;
@synthesize postCommentView;
@synthesize justCommentButton;
@synthesize delveAndCommentButton;
@synthesize commentTextView;
@synthesize commentListView;
@synthesize delveButton;
@synthesize footerView;
@synthesize footerNotificationButton;
@synthesize commentListNotificationButton;
@synthesize maskView;
@synthesize invisibleButton; //For hiding the commentListView
@synthesize spinner;
@synthesize openedArticleId;
@synthesize commentsConnection;
@synthesize commentsResponseData;
@synthesize commentsAndClipsArray;
@synthesize gUserName; //local to this class
@synthesize gUserId;   // local to this class
@synthesize isDelve;
@synthesize coreTextView;
@synthesize imageViewLoggedInUser = _imageViewLoggedInUser;
@synthesize labelLoggedInUserName = _labelLoggedInUserName;
@synthesize spinnerImageView;

#pragma mark - core text delegates

- (NSArray *)coreTextStyle
{
    NSMutableArray *result = [NSMutableArray array];
    
	FTCoreTextStyle *defaultStyle = [FTCoreTextStyle new];
	defaultStyle.name = FTCoreTextTagDefault;	//thought the default name is already set to FTCoreTextTagDefault
	defaultStyle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
	defaultStyle.textAlignment = FTCoreTextAlignementLeft;
	[result addObject:defaultStyle];
	
	
	FTCoreTextStyle *titleStyle = [FTCoreTextStyle styleWithName:@"title"]; // using fast method
	titleStyle.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:40.f];
	titleStyle.paragraphInset = UIEdgeInsetsMake(0, 0, 25, 0);
	titleStyle.textAlignment = FTCoreTextAlignementLeft;
	[result addObject:titleStyle];
	
	FTCoreTextStyle *imageStyle = [FTCoreTextStyle new];
	imageStyle.paragraphInset = UIEdgeInsetsMake(0,0,0,0);
	imageStyle.name = FTCoreTextTagImage;
	imageStyle.textAlignment = FTCoreTextAlignementLeft;
	[result addObject:imageStyle];
	
	FTCoreTextStyle *firstLetterStyle = [FTCoreTextStyle new];
	firstLetterStyle.name = @"firstLetter";
	firstLetterStyle.font = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:30.f];
	[result addObject:firstLetterStyle];
	
	FTCoreTextStyle *linkStyle = [defaultStyle copy]; // for link text styling
	linkStyle.name = FTCoreTextTagLink;
	linkStyle.color = [UIColor colorWithRed:0.0 green:74/255.0 blue:142/255.0 alpha:1];
	[result addObject:linkStyle];
	
	FTCoreTextStyle *subtitleStyle = [FTCoreTextStyle styleWithName:@"subtitle"];
	subtitleStyle.font = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:25.f];
	subtitleStyle.color = [UIColor brownColor];
	subtitleStyle.paragraphInset = UIEdgeInsetsMake(10, 0, 10, 0);
	[result addObject:subtitleStyle];
    
    FTCoreTextStyle *italicStyle = [defaultStyle copy];
	italicStyle.name = @"italic";
	//italicStyle.underlined = YES;
    italicStyle.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:15.0 ];
    italicStyle.color = [UIColor colorWithRed:171/255.0 green:171/255.0 blue:171/255.0 alpha:1.0];
	[result addObject:italicStyle];
    
    FTCoreTextStyle *boldStyle = [defaultStyle copy];
	boldStyle.name = @"bold";
    boldStyle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0];
	[result addObject:boldStyle];
    
    FTCoreTextStyle *coloredStyle = [defaultStyle copy];
    [coloredStyle setName:@"colored"];
    [coloredStyle setColor:[UIColor redColor]];
	[result addObject:coloredStyle];
    
    return  result;
}

- (void)coreTextView:(FTCoreTextView *)acoreTextView receivedTouchOnData:(NSDictionary *)data
{
    NSURL *url = [data objectForKey:FTCoreTextDataURL];
    urlForId = [url absoluteString];
    if (!urlForId) return;
    // NSLog(@"url = %@",urlForId);
    sharedInstance.gIsTappedOnProfileName = TRUE;
    NSString *str = [urlForId stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    // NSLog(@"str= %@",str);
    
    NSString *loggedInUserId;
    //Fetching id of current loggedinuser
    loggedInUserId = [NSString stringWithFormat:@"%@",[sharedInstance.gUserInfoDictionary objectForKey:@"id"]];
    
    if([loggedInUserId isEqualToString:str])
    {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Trying to open existing profile" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        [DNGlobal sharedDNGlobal].gIsTappedOnProfileName = YES;
        // change the profile user is watching currently
        [DNGlobal sharedDNGlobal].isOnMyProfile = NO;
        
        // programmatically creating the story board instance
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        DNProfileViewController *objProfileController = (DNProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"profileViewController"];
        
        NSString *str = [urlForId stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        objProfileController.gIdForSelf = str;
        
        [self.navigationController pushViewController:objProfileController animated:YES];
    }
}

//#pragma  mark - prepare for segue
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.identifier isEqualToString:@"comingFromComments"])
//    {
//        NSString *str = [urlForId stringByReplacingOccurrencesOfString:@"http://" withString:@""];
//        // NSLog(@"str= %@",str);
//        DNProfileViewController *objProfileController = segue.destinationViewController;
//        objProfileController.gIdForSelf = str;
//    }
//}
#pragma mark - view cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    clipsArray = [[NSArray alloc] init];
    loggedinUserClipDictionary = [[NSDictionary alloc]init];
    
    //Delve button appearance initialization
    delveButton= [[UIButton alloc]initWithFrame:CGRectMake(kDelveButtonOffsetX, kDelveButtonOffsetY, kDelveButtonWidth, kDelveButtonHeight)];
    [delveButton setImage:[UIImage imageNamed:@"delveit.png"] forState:UIControlStateNormal];// normal
    [delveButton setImage:[UIImage imageNamed:@"delved.png"] forState:UIControlStateSelected];// ticked
    [delveButton addTarget:self action:@selector(delveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    //Invisible Button to hide postCommentView
    invisibleButton= [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth-kNotifButtonsWidth, kNotifButtonsHeight)];
    [invisibleButton addTarget:self action:@selector(animateDown) forControlEvents:UIControlEventTouchUpInside];
    
    //Add gesture Recognizer to maskView so clicking it will animate down the commentListView
    UITapGestureRecognizer *gestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(animateDown)];
    [maskView addGestureRecognizer:gestureRecognizer];
    
    //Blue line to make outline to commentListView
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, kLineOffsetY, kNotifButtonsOffsetX, kLineHeight)];
    lineView.backgroundColor = [UIColor colorWithRed:0.0 green:0.211 blue:0.498 alpha:1];
    
    //Notification image to be used on footerNotificationButton & commentsListNotificationButton
    UIImage* notificationImage= [UIImage imageNamed:@"notification_blue_grey76x47.png"];
    
    //Initializing commentsListNotificationButton appearance
    commentListNotificationButton= [[UIButton alloc]initWithFrame:CGRectMake(kNotifButtonsOffsetX, 0, kNotifButtonsWidth, kNotifButtonsHeight)];
    [commentListNotificationButton addTarget:self action:@selector(animateDown) forControlEvents:UIControlEventTouchUpInside];
    [commentListNotificationButton setBackgroundColor:[UIColor whiteColor]];
    commentListNotificationButton.contentEdgeInsets = UIEdgeInsetsMake(0, kNotificationButtonLeftOffset, kNotificationButtonBottomOffset, 0);
    commentListNotificationButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [commentListNotificationButton setBackgroundImage:notificationImage forState:UIControlStateNormal];
    [commentListNotificationButton setTitle:@"0" forState:UIControlStateNormal];
    [commentListNotificationButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    //Initializing footerNotificationButton appearance
    footerNotificationButton= [[UIButton alloc]initWithFrame:CGRectMake(kNotifButtonsOffsetX, kFooterTopMargin, kNotifButtonsWidth, kNotifButtonsHeight)];
    [footerNotificationButton addTarget:self action:@selector(animateUp) forControlEvents:UIControlEventTouchUpInside];
    [footerNotificationButton setBackgroundColor:[UIColor whiteColor]];
    footerNotificationButton.contentEdgeInsets = UIEdgeInsetsMake(0, kNotificationButtonLeftOffset, kNotificationButtonBottomOffset, 0);
    footerNotificationButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [footerNotificationButton setBackgroundImage:notificationImage forState:UIControlStateNormal];
    [footerNotificationButton setTitle:@"0" forState:UIControlStateNormal];
    [footerNotificationButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    //Initializing postCommentView
    CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
    
    if (iOSDeviceScreenSize.height == 480)
    {
        postCommentView.frame=CGRectMake(0, kPostCommentViewOffsetY_iphone4, kScreenWidth, kPostCommentViewHeight); 
    }
    else
    {
        postCommentView.frame=CGRectMake(0, kPostCommentViewOffsetY, kScreenWidth, kPostCommentViewHeight); //Align it to view's bottom with buttons below the screen
    }
    postCommentView.layer.borderWidth = kBorderWidth;
    postCommentView.layer.borderColor = [UIColor colorWithRed:0.705 green:0.705 blue:0.705 alpha:1].CGColor;
    postCommentView.hidden=YES;
    
    //Initializing commentTextView
    commentTextView.delegate=self;
    commentTextView.layer.borderWidth= kBorderWidth;
    commentTextView.layer.borderColor = [UIColor colorWithRed:0.823 green:0.827 blue:0.835 alpha:1].CGColor;
    commentTextView.layer.cornerRadius= kCommentTextViewCornerRadius;
    [commentTextView setBackgroundColor:[UIColor whiteColor]];
    
    //Initializing justCommentButton
    [justCommentButton setImage:[UIImage imageNamed:@"comment1.png"] forState:UIControlStateNormal];
    [justCommentButton setImage:[UIImage imageNamed:@"comment_active.png"] forState:UIControlStateHighlighted];
    [justCommentButton addTarget:self action:@selector(commentButtonPressed) forControlEvents:UIControlEventTouchUpInside];
   
    //Initializing delveAndCommentButton
    [delveAndCommentButton setImage:[UIImage imageNamed:@"delveandcomment"] forState:UIControlStateNormal];
    [delveAndCommentButton setImage:[UIImage imageNamed:@"delveandcomment_selected"] forState:UIControlStateHighlighted];
    [delveAndCommentButton addTarget:self action:@selector(delveAndCommentButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    
    //Initializing dataSource & delegate of commenTableView
    if (iOSDeviceScreenSize.height == 480)
        commentTableView.frame= CGRectMake(0, kNotifButtonsHeight, kScreenWidth, kCommentTableViewHeight_iphone4); //set Offset Y to NotifButton's Height so that it comes under it
    else
        commentTableView.frame= CGRectMake(0, kNotifButtonsHeight, kScreenWidth, kCommentTableViewHeight); //set Offset Y to NotifButton's Height so that it comes under it
    commentTableView.hidden=NO;
    commentTableView.backgroundColor = [UIColor whiteColor];
    commentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [commentTableView setDataSource:self];
    [commentTableView setDelegate:self];
    
    //Initializing commentListView
    if (iOSDeviceScreenSize.height == 480)
        commentListView= [[UIView alloc] initWithFrame:CGRectMake(0, kCommentListOffsetY, kScreenWidth, kCommentListViewHeight_iphone4)];
    else
        commentListView= [[UIView alloc] initWithFrame:CGRectMake(0, kCommentListOffsetY, kScreenWidth, kCommentListViewHeight)];
    [commentListView addSubview:invisibleButton];
    [commentListView addSubview:commentListNotificationButton];
    [commentListView addSubview:lineView];
    [commentListView addSubview:commentTableView];
    commentListView.hidden=YES;
    
    //Initializing footerView
    if (iOSDeviceScreenSize.height == 480)
        footerView= [[UIView alloc] initWithFrame:CGRectMake(0, kFooterViewOffsetY_iphone4, kScreenWidth, kFooterViewHeight)];
    else
        footerView= [[UIView alloc] initWithFrame:CGRectMake(0, kFooterViewOffsetY, kScreenWidth, kFooterViewHeight)];
    [footerView setBackgroundColor:[UIColor colorWithRed:0.945 green:0.945 blue:0.945 alpha:1]];
    [footerView addSubview:delveButton];
    [footerView addSubview:footerNotificationButton];
    
    [self.view addSubview:footerView];
    [self.view addSubview:commentListView];
    [self.view addSubview:postCommentView];
    
    
    //Register notification for keyboard dismiss event
    NSNotificationCenter *keyboardNotification = [NSNotificationCenter defaultCenter];        
    [keyboardNotification addObserver:self selector:@selector(hidePostCommentView) name:
     UIKeyboardWillHideNotification object:nil];

    //setting webview delegate to self for capturing states
    articleWebView.delegate=self;
    
    //Creating global instance of Dnglobal
    sharedInstance=[DNGlobal sharedDNGlobal];
    
    //Method to fetch comments and discussion
    [self getArticleDetails:self.openedArticleId];

    //set user name and image
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self setUserName:[defaults objectForKey:@"userName"] andImage:[defaults objectForKey:@"userImage"]];
    
    //Delve or comment on article notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delveOrCommentNotificationReceived:) name:kPOSTNOTIFICATION_DELVE_OR_COMMENT object:nil];
}
-(void)viewWillAppear:(BOOL)animated
{
    isArcticleModified = NO;
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    [DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:nil];
    
    // NSLog(@" super class -- %@", [self.navigationController parentViewController]);
    
    [DNGlobal hideCustomTabBarOnViewController:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [DNGlobal showCustomTabBarOnViewController:self];
}

-(void)setUserName:(NSString*)name andImage:(NSData*)userImageData
{
    UIImage *image_thumb = [DNGlobal imageWithImage:[UIImage imageWithData:userImageData] scaledToWidth:47];
    
    [_imageViewLoggedInUser setImage:image_thumb];
    [_labelLoggedInUserName setText:name];
}

-(void)goToBack:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)openLinkInWebview:(NSString *)link
{
    // NSLog(@"ARTICLE Inside openLinkInWebview");
    // NSLog(@"LINK: %@",link);
    dispatch_after
    ( dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_current_queue(),
                   ^{
        [articleWebView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:link]]];
    });
}

#pragma mark - delve or comment notification 
// delve /Comment article notification received method
-(void)delveOrCommentNotificationReceived: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_DELVE_OR_COMMENT])
    {
        // NSLog(@"Delve/Comment notification called ---  in  Article VC: ");
//        // NSLog(@"user info is : %@", notification.userInfo);
    }
}
/*
 "article_id" - The ID of the article that this comment is on
 "active_organization" - The numeric ID of the user’s current organization
 "unmute"- which is always true 
 */

#pragma  mark - delve an article
// Method to undelve article
-(void)undelveAnArticle:(NSString *)articleId
{
    isArcticleModified = YES; // article is to be modified
    
    // NSLog(@"clips array is : %@", loggedinUserClipDictionary);
    // article has been delved
    NSString *urlString = [NSString stringWithFormat:@"%@/api/userarticleclip/%@",kAPI_Host_Name,[NSNumber numberWithInteger:[[loggedinUserClipDictionary objectForKey:@"id"] integerValue]]];
    // NSLog(@"idfinalstr ( undelve )-=%@",urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    // NSLog(@"url= %@",url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url  cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    [request setHTTPMethod:@"DELETE"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    [request addValue:sharedInstance.gCSRF_Token forHTTPHeaderField:@"X-CSRFToken"];
    [request addValue:[NSString stringWithFormat:@"csrftoken=%@;sessionid=%@",sharedInstance.gCSRF_Token,sharedInstance.gCookieInPostApi] forHTTPHeaderField:@"Cookie"];
    
    connectionToUndelveArticle= [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if(connectionToUndelveArticle)
    {
        dataToUndelveArticle = [[NSMutableData alloc] init];
        // remove any spinner present
        [self removeGlobleSpinner]; // remove any spinner already if there are
        [self showIndicator]; // show the spinner now
        [self.delveButton setEnabled:NO]; // disable the button so that user can not tap it again
    }
}

// Method to delve an article
-(void)delveAnArticle:(NSString *)articleId
{
    isArcticleModified = YES; // article is to be modified
    
    //Fetching active organisation from global userorganisation.
    NSString *userActiveOrg=[sharedInstance.userOrganizations objectForKey:@"active_organization"];
    
    //    // NSLog(@"article id, active org : %@, %@ ", articleId, userActiveOrg);
    NSDictionary *dictToPost = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:[articleId integerValue]],@"article_id",[NSNumber numberWithInteger:[userActiveOrg integerValue]],@"active_organization",[NSNumber numberWithBool:TRUE],@"unmute", nil];
    NSDictionary *settingsDictionary = [ NSDictionary dictionaryWithObject:dictToPost forKey:@"settings"];
    // Making data with jsonobject
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:settingsDictionary options:kNilOptions error:nil];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/userarticleclip/",kAPI_Host_Name];
    // NSLog(@"idfinalstr (delving)-=%@",urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [jsonData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonData];
    [request addValue:sharedInstance.gCSRF_Token forHTTPHeaderField:@"X-CSRFToken"];
    [request addValue:[NSString stringWithFormat:@"csrftoken=%@;sessionid=%@",sharedInstance.gCSRF_Token,sharedInstance.gCookieInPostApi] forHTTPHeaderField:@"Cookie"];
    
    connectionToDelveArticle= [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if(connectionToDelveArticle)
    {
        dataToDelveArticle = [[NSMutableData alloc] init];
        [self removeGlobleSpinner]; // first remove any globe spinner if already there
        [self showIndicator]; // show the globe spinner
        
        [self.delveButton setEnabled:NO]; // disable the delve button , so user cant tap it again immidiatly
    }
    else
    {
        // NSLog(@"error in connection of delving--");
    }
}

/*
 "article_id" - The ID of the article that this comment is on
 "active_organization" - The numeric ID of the user’s current organization
 "text" - The text of the comment
 "notify_user_ids" - An array of the numeric IDs of users who are @mentioned in this comment-- here empty array
 
 */

//Method to comment on article
-(void)commentOnArticle:(NSString *)articleId andCommentText:(NSString *)commentText
{
    isArcticleModified = YES; // article is to be modified
    
    //Fetching active organisation from global userorganisation.
    NSString *userActiveOrg=[sharedInstance.userOrganizations objectForKey:@"active_organization"];
    
    // NSLog(@"article id, active org : %@, %@ ", articleId, userActiveOrg);
    NSArray *arr_userIds = [[NSArray alloc] init];
    
    NSDictionary *dictToPost = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:[articleId integerValue]],@"article_id",[NSNumber numberWithInteger:[userActiveOrg integerValue]],@"active_organization",commentText,@"text",arr_userIds, @"notify_user_ids", nil];
    //NSDictionary *settingsDictionary = [ NSDictionary dictionaryWithObject:dictToPost forKey:@"settings"];
    // Making data with jsonobject
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictToPost options:kNilOptions error:nil];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/comment/",kAPI_Host_Name];
    // NSLog(@"idfinalstr-=%@",urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    // NSLog(@"url= %@",url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [jsonData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonData];
    [request addValue:sharedInstance.gCSRF_Token forHTTPHeaderField:@"X-CSRFToken"];
    
    //Add cookie object here passing globally saved cookie
    // Creating a cookie which contains csrf token + cookie.
    [request addValue:[NSString stringWithFormat:@"csrftoken=%@;sessionid=%@",sharedInstance.gCSRF_Token,sharedInstance.gCookieInPostApi] forHTTPHeaderField:@"Cookie"];
    
    connectionToCommentArticle= [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(connectionToCommentArticle)
    {
        dataOfCommentedArticle = [[NSMutableData alloc] init];
        [self removeGlobleSpinner];
        [self showIndicator];
    }
}

#pragma mark- webview delegate methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [spinner stopAnimating];
    
}
- (void)webViewDidStartLoad:(UIWebView *)webView{
    
    [spinner startAnimating];

}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [spinner stopAnimating];
}

-(void)delveButtonPressed
{
    // NSLog(@"Delve Button pressed");

    // First check what is the status of article whether it is delved or not. 
    if([self.delveButton isSelected])
    {
        [self undelveAnArticle:self.openedArticleId];
    }
    else
    {
        [self delveAnArticle:self.openedArticleId];
    }

}

#pragma mark - jsut comment Pressed
-(void)commentButtonPressed // "just comment" button pressed
{
    // NSLog(@"commentButtonPressed start pressed");
    
    NSString *trimmedString = [self.commentTextView.text stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    
    if(trimmedString.length > 0)
    {
        // First we will call to comment
        [self commentOnArticle:self.openedArticleId andCommentText:self.commentTextView.text];
    }
    else
    {
        UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Please enter a comment" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [delveAlert show];
    }
    
    //Resigning the textview and making it blank
    [self.commentTextView resignFirstResponder];
    self.commentTextView.text = @"";
    
    // After that we will hide hidePostCommentView
    [self hidePostCommentView];
    // NSLog(@"commentButtonPressed end pressed");
}

-(void)delveAndCommentButtonPressed
{
    if(![self.delveButton isSelected])
    {
        [self delveAnArticle:self.openedArticleId];
    }
    else
    {
        UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Article is already Shared" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [delveAlert show];
    }
        
    [self commentButtonPressed];
}

-(void)animateDown
{
    // NSLog(@"animateDown");

    //Dismiss keyboard when notificationbutton Clicked
    [commentTextView resignFirstResponder];
    
    //Animated down the postCommentView
    [UIView animateWithDuration:kCommentListViewAnimationDuration
                          delay:0
                        options: 0
                     animations:^{
                         
                         //Initializing postCommentView
                         CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
                         if (iOSDeviceScreenSize.height == 480)
                             commentListView.frame = CGRectMake(0, kCommentListOffsetY, kScreenWidth, kCommentListViewHeight_iphone4);
                         else
                             commentListView.frame = CGRectMake(0, kCommentListOffsetY, kScreenWidth, kCommentListViewHeight);
                     }
                     completion:^(BOOL finished){
                         commentListView.hidden=YES;
                         //Hide maskView from webview
                         maskView.hidden=YES;
                     }];
    [self performSelector:@selector(showFooterView) withObject:nil afterDelay:kFooterViewShowHideDelay];
    
}

-(void)showFooterView{
    footerView.hidden=NO;
    postCommentView.hidden=YES;
}

-(void)animateUp
{
    // NSLog(@"animateUp");
    //show mask over webview
    maskView.hidden=NO;
    commentListView.hidden=NO;
    
    [UIView animateWithDuration:kCommentListViewAnimationDuration
                          delay:0
                        options: 0
                     animations:^{
                         CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
                         if (iOSDeviceScreenSize.height == 480)
                             commentListView.frame = CGRectMake(0, kCommentListAfterAnimOffsetY_iphone4, kScreenWidth, kCommentListViewHeight_iphone4);
                         else
                             commentListView.frame = CGRectMake(0, kCommentListAfterAnimOffsetY, kScreenWidth, kCommentListViewHeight);
                     }
                     completion:^(BOOL finished){
                         
                     }];
    [self performSelector:@selector(hideFooterView) withObject:nil afterDelay:kFooterViewShowHideDelay];
}


-(void)hideFooterView{
    footerView.hidden=YES;
    postCommentView.hidden=NO;
    
}

-(void)showPostCommentView
{
    // NSLog(@"showCommentView");
    
    [UIView animateWithDuration:kPostCommentViewAnimationDuration
                          delay:0.0
                        options: 0
                     animations:^{
                         CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
                         
                         if (iOSDeviceScreenSize.height == 480)
                             postCommentView.frame = CGRectMake(0, kPostCommentViewAfterAnimOffsetY_iphone4, kScreenWidth, kPostCommentViewHeight);
                         else
                             postCommentView.frame = CGRectMake(0, kPostCommentViewAfterAnimOffsetY, kScreenWidth, kPostCommentViewHeight);
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

-(void)hidePostCommentView
{
    // NSLog(@"hideCommentView");
    
    [UIView animateWithDuration:kPostCommentViewAnimationDuration
                          delay:0.0
                        options: 0
                     animations:^{
                         CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
                         
                         if (iOSDeviceScreenSize.height == 480)
                             postCommentView.frame = CGRectMake(0, kPostCommentViewOffsetY_iphone4, kScreenWidth, kPostCommentViewHeight);
                         else
                             postCommentView.frame = CGRectMake(0, kPostCommentViewOffsetY, kScreenWidth, kPostCommentViewHeight);
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

#pragma mark - textview delegates
// TextField Delegate Methods
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    
    // NSLog(@"textFieldShouldReturn");

    [textField resignFirstResponder];
    [self hidePostCommentView];
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // NSLog(@"textFieldShouldBeginEditing");

    [self showPostCommentView];
    return YES;
}


#pragma mark - table view methods

//Since i have to distinguish on basis of commented and responded to so need one global variable to store 42 or 62.

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    
    DNCommentModal *objCommentModal = (DNCommentModal *)[commentsAndClipsArray objectAtIndex:indexPath.row];
    
    NSString *text = objCommentModal.commentString;
    
    CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), 20000.0f);
    
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height;
//    if(indexPath.row == 0)
//    {
//        height = MAX(size.height + 42 + CELL_CONTENT_MARGIN , 100);
//    }
//    else
//    {
        height = MAX(size.height + 56  , 100);
    //}
    
    
    return height + (CELL_CONTENT_MARGIN * 2);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
       
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commentCell" forIndexPath:indexPath];
     if(cell == nil )
     {
         cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"commentCell"] ;
     }
    UIImageView *imageOfUser = (UIImageView *)[cell viewWithTag:996];

    
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType  = UITableViewCellAccessoryNone;


    
    coreTextView = (FTCoreTextView *)[cell viewWithTag:998];
    DNCommentModal *objCommentModal = (DNCommentModal *)[commentsAndClipsArray objectAtIndex:indexPath.row];
//    if(indexPath.row == [commentsAndClipsArray count]-1)
//    {
        NSString *str= [NSString stringWithFormat:@"<_link>%@|%@</_link> <italic>commented:</italic>",objCommentModal.idOfUser,objCommentModal.userName];
        // NSLog(@"str = %@",str);
        // set text
        [coreTextView setText:str];
//    }
//    else
//    {
//        NSString *str= [NSString stringWithFormat:@"<_link>%@|%@</_link> <italic>responded to</italic> <_link>%@|%@</_link>",objCommentModal.idOfUser,objCommentModal.userName,gUserId,gUserName];
//        // NSLog(@"str = %@",str);
//        // set text
//        [coreTextView setText:str];
//    }
    
    // set styles
    [coreTextView addStyles:[self coreTextStyle]];
    // set delegate
    [coreTextView setDelegate:self];
	
	[coreTextView fitToSuggestedHeight];
    
    // **************  set time - how much time ago comment was commeted
     UILabel *commentTimeLabel = (UILabel *)[cell viewWithTag:997];
    [commentTimeLabel setFont:[UIFont italicSystemFontOfSize:FONT_SIZE-1]];
    
    NSString *dayString = @"day", *hourString = @"hour", *min_string=@"minute";
    if((int)objCommentModal.secondsCommentedBefore/(60*60*60) > 1)
        dayString = @"days";
    if((int)objCommentModal.secondsCommentedBefore/(60*60) > 1)
        hourString = @"hours";
    if((int)objCommentModal.secondsCommentedBefore/(60) > 1)
        min_string = @"minutes";
    
     NSInteger num_seconds = objCommentModal.secondsCommentedBefore;
    
    int days, hours, minutes;
    
    days = num_seconds / (60 * 60 * 24);
    num_seconds -= days * (60 * 60 * 24);
    hours = num_seconds / (60 * 60);
    num_seconds -= hours * (60 * 60);
    minutes = num_seconds / 60;

    if((NSInteger)objCommentModal.secondsCommentedBefore/(60*60) > 24) // for days and hrs
    {
//         int days = floor(num_seconds/(60*60*60));
//        int hours = (round(num_seconds - days * 60*60*60))/(60*60);
        
        commentTimeLabel.text = [NSString stringWithFormat: @"%d %@ %d %@ ago",
                                days, dayString , hours, hourString];
    }
    else // for hrs and mins
    {
        if((NSInteger)num_seconds/(60) < 60.0) // for mins
        {
            if(num_seconds < 60.0)
                commentTimeLabel.text = [NSString stringWithFormat: @"0 %@ ago", min_string];
            else
                commentTimeLabel.text = [NSString stringWithFormat: @"%d %@ ago", (int)(num_seconds/(60)), min_string];
        }
        else
            commentTimeLabel.text = [NSString stringWithFormat: @"%d %@ ago", (int)(num_seconds/(60*60)), hourString];
    }
    // **************  set time - how much time ago comment was commeted ********************
    
    imageOfUser.image = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:objCommentModal.userImageUrl]];
        UIImage *tempImage = [UIImage imageWithData:imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageOfUser.image= tempImage;
        });
    });
    
    // Comment String : user comment will be shown in this part  *************
    UILabel *commentLabel = (UILabel *)[cell viewWithTag:999];
    [commentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    //[commentLabel setMinimumFontSize:FONT_SIZE];
    [commentLabel setNumberOfLines:0];
    [commentLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    commentLabel.text = objCommentModal.commentString;
    
    commentLabel = [self adjustSizeOfLabel:commentLabel];
    
    return cell;
     
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // NSLog(@"commentsAndClipsArray count=%d",[commentsAndClipsArray count]);
    
    return [commentsAndClipsArray count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NSLog(@"Row seleced is: %d",indexPath.row);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

#pragma mark - adjust size of label in comment table
// Adjust the size of a label
-(UILabel *)adjustSizeOfLabel:(UILabel *)lbl
{
    CGSize maximumLabelSize = CGSizeMake(240,FLT_MAX);
    
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

#pragma mark - GET the details of the article ***
//Method to fetch comments and discussion
-(void)getArticleDetails:(NSString *)articleId
{
    //Fetching active organisation from global userorganisation.
    NSString *userActiveOrg = [sharedInstance.userOrganizations objectForKey:@"active_organization"];
    
    // Creating Dictionary for extra data which should be passed with URL
    NSDictionary *activeOrgDict = [NSDictionary dictionaryWithObject:userActiveOrg forKey:@"active_organization"];
    
    // Making data with jsonobject
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:activeOrgDict options:kNilOptions error:nil];
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
     
    NSString *idAndActiveOrgString=[NSString stringWithFormat:@"%@/api/article/%@?settings=%@",kAPI_Host_Name, articleId,jsonString];
    // NSLog(@"idfinalstr to get comments =   %@",idAndActiveOrgString);
        
    NSURL *url = [NSURL URLWithString:idAndActiveOrgString];
        
    // NSLog(@"url= %@",url);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //Add cookie object here passing globally saved cookie
    [request addValue:sharedInstance.gCookie forHTTPHeaderField:@"Cookie"];
    
    commentsConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];

    // remove any globe spinner if present
    [self removeGlobleSpinner];

    // now add
    NSURL *delve_globeURL = [[NSBundle mainBundle] URLForResource:@"delve_globe" withExtension:@"gif"];
    self.spinnerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 200, 40, 40)];
    self.spinnerImageView.image = [UIImage animatedImageWithAnimatedGIFURL:delve_globeURL];
    [self.commentTableView addSubview:self.spinnerImageView];    
}

//Method to show activityindicator on view
-(void)showIndicator
{
     // NSLog(@"Adding globe spinner-- ");
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"delve_globe" withExtension:@"gif"];
    self.spinnerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 200, 40, 40)];
    self.spinnerImageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    [self.view addSubview:self.spinnerImageView];
   
}
#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
    if(connection == commentsConnection)
    {
        commentsResponseData= [[NSMutableData alloc]init];
        commentsAndClipsArray= [[NSMutableArray alloc] init];
    }
    else if(connection == connectionToDelveArticle)
    {
        [dataToDelveArticle setLength:0];
    }
    else if(connection == connectionToCommentArticle)
    {
        [dataOfCommentedArticle setLength:0];
    }
    else if (connection == connectionToUndelveArticle)
    {
        [dataToUndelveArticle setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
       
    if(connection == commentsConnection)
    {
        [commentsResponseData appendData:data];
    }
    else if(connection == connectionToDelveArticle)
    {
        [dataToDelveArticle appendData:data];
    }
    else if (connection == connectionToCommentArticle)
    {
        [dataOfCommentedArticle appendData:data];
    }
    else if (connection == connectionToUndelveArticle)
    {
        [dataToUndelveArticle appendData:data];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    // remove the Spinner now
    [self removeGlobleSpinner];
    
    if(connection == commentsConnection)
    {
        NSString* responseString= [[NSString alloc] initWithData:commentsResponseData encoding:NSUTF8StringEncoding];
//        // NSLog(@"Response: %@",responseString);
        
        NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
        // NSLog(@"Dictionary Response: %@",responseJSON);
                
        // Now fetching the comments
        NSArray *comments = [responseJSON objectForKey:@"comments"];
        for(NSDictionary *commmentDict in comments)
        {
            //Creating object of DNCommentModal.
            DNCommentModal *objCommentModal = [[DNCommentModal alloc] init];
            if([commmentDict objectForKey:@"timestamp"]!=nil)
            {
                NSTimeInterval seconds = [[NSDate date] timeIntervalSince1970] -  [[commmentDict objectForKey:@"timestamp"] floatValue];
                //// NSLog(@"commented before %d hours", (int)seconds/(60*60));
                objCommentModal.secondsCommentedBefore = seconds;
            }
            NSString *comments = [commmentDict objectForKey:@"text"];
            if(comments!=nil)
            {
                objCommentModal.commentString = comments;
            }
            NSDictionary *writerDict=[commmentDict objectForKey:@"writer"];
            NSString *nameOfCommentUser = [writerDict objectForKey:@"name"];
            if(nameOfCommentUser!=nil)
            {
                objCommentModal.userName = nameOfCommentUser;
            }
            NSString *tempIdOfUser = [writerDict objectForKey:@"id"];
            if(tempIdOfUser!=nil)
            {
                objCommentModal.idOfUser = tempIdOfUser;
            }
            NSString *imageUrlOfCommentUser = [writerDict objectForKey:@"image37"];
            if(imageUrlOfCommentUser!=nil)
            {
                objCommentModal.userImageUrl = [NSString stringWithFormat:@"http:%@", imageUrlOfCommentUser];
            }
            // Adding the object to the commentsAndClipsArray:
            [commentsAndClipsArray addObject:objCommentModal];
        }
        
        // logic for very last index the array contains the discussion and after that all comments are added.

        // first comment of every article will cosidered to be 'Discussions'
        NSArray *discussion= [responseJSON objectForKey:@"discussions"];
        //// NSLog(@"ARTICLE LIST: %@",discussion);
        
        //// NSLog(@"ARTICLE LIST: %@",sharedInstance.gRandomUserDictionary);
        for(NSDictionary* dict in discussion)
        {
            //Creating object of DNCommentModal.
            DNCommentModal *objCommentModal = [[DNCommentModal alloc] init];
            NSString *discussion = [dict objectForKey:@"brief"];
            if(discussion!=nil)
            {
                objCommentModal.commentString=discussion;
            }
            NSString *nameOfUser = [dict objectForKey:@"user_name"];
            if(nameOfUser!=nil)
            {
                gUserName=nameOfUser;
                objCommentModal.userName = nameOfUser;
            }
            NSString *tempIdOfUser = [dict objectForKey:@"user_id"];
            if(tempIdOfUser!=nil)
            {
                gUserId = tempIdOfUser;
                objCommentModal.idOfUser = tempIdOfUser;
            }
            NSString *imageUrlOfUser = [dict objectForKey:@"user_image_url"];
            if(imageUrlOfUser!=nil)
            {
                objCommentModal.userImageUrl = [NSString stringWithFormat:@"http:%@", imageUrlOfUser];
            }
            // Adding the object to the commentsAndClipsArray:
            [commentsAndClipsArray addObject:objCommentModal];
        }
        
        commentsAndClipsArray = (NSMutableArray *)[[commentsAndClipsArray reverseObjectEnumerator] allObjects];

        // First checking if the loginned user's name is in clips or not , if available then allready delved it otherwise not Shared.
        clipsArray = [responseJSON objectForKey:@"clips"];
        tempClipsArray = [[NSArray alloc] initWithArray:clipsArray];
        
        // NSLog(@"clips array : %@", [responseJSON objectForKey:@"clips"]);
        
        for(NSDictionary *clipDict in clipsArray)
        {
            NSString *username = [clipDict objectForKey:@"user_name"]; // user name from clips 
            
            NSString *loggedInUserName = [sharedInstance.gUserInfoDictionary objectForKey:@"name"]; // logged in user name

            if([username isEqualToString:loggedInUserName])
            {
                loggedinUserClipDictionary = clipDict;
                [self.delveButton setSelected:YES];
                break;
            }
        }
        if(isArcticleModified)
        {
            // NSLog(@"-------- notification posted --------");
            // send notification in all tabs (to all registered notifications ) that an article has been delved
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:self.openedArticleId,@"delvedArticleId",
                                      tempClipsArray, @"clips",
                                      commentsAndClipsArray, @"comments",
                                      nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kPOSTNOTIFICATION_DELVE_OR_COMMENT object:nil userInfo:userInfo];
        }
        
        //Adding count of comment
        [commentListNotificationButton setTitle:[NSString stringWithFormat:@"%d",[commentsAndClipsArray count]] forState:UIControlStateNormal];
        [footerNotificationButton setTitle:[NSString stringWithFormat:@"%d",[commentsAndClipsArray count]] forState:UIControlStateNormal];
        
        // relaod comments table view
        [self.commentTableView reloadData];
    }
    else if(connection == connectionToDelveArticle) 
    {
        NSString* responseString= [[NSString alloc] initWithData:dataToDelveArticle encoding:NSUTF8StringEncoding];
        // NSLog(@"Response: %@",responseString);
        
        NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
        
        [self.delveButton setEnabled:YES]; // in any case , enable the button again
        if(responseJSON != (id)[NSNull null])
        {
            NSString *statusString = [responseJSON objectForKey:@"status"];
            if([statusString isEqualToString:@"Clip created"])
            {
                // Changing the button view to delve it
                [self.delveButton setSelected:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Article is Shared" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [delveAlert show];
                });
                
                //get article details again to get the clips array 
                [self getArticleDetails:self.openedArticleId];
            }
            else
            if([statusString isEqualToString:@"Returning a clip that already existed. This is strange."])
            {
                UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Article is already Shared" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [delveAlert show];
            }
        }
    }
    else if(connection == connectionToCommentArticle)
    {
         NSString* responseString= [[NSString alloc] initWithData:dataOfCommentedArticle encoding:NSUTF8StringEncoding];
         NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
        // NSLog(@"responseJSON connectionToCommentArticle : %@", responseJSON);
        
        if((responseJSON != (id)[NSNull null] ) && [responseJSON objectForKey:@"success"])
        {
            // NSLog(@"comment posted");
            //now Calling the getArticleDetails method to get the comments
            [self getArticleDetails:self.openedArticleId];
        }
        else
        {
            UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Comment could not be posted, try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [delveAlert show];
        }
    }
    else if (connection == connectionToUndelveArticle) // here check the response please
    {
        NSString* responseString= [[NSString alloc] initWithData:dataToUndelveArticle encoding:NSUTF8StringEncoding];
        NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
        // NSLog(@"responseJSON : %@", responseJSON);
        
        [self.delveButton setEnabled:YES]; // in any case , enable the button again
        
        if((responseJSON != (id)[NSNull null] ) && [responseJSON objectForKey:@"success"])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Article unshared" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [delveAlert show];
            });
            // NSLog(@"Article unshared");
            
            //get article details again to get the clips array (modified one)
            [self getArticleDetails:self.openedArticleId];
            
            [self.delveButton setSelected:NO]; // for undelve
        }
        else
        {
            UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Could not unshare article, Please try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [delveAlert show];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self removeGlobleSpinner];
    
    if(!self.delveButton.isEnabled)
        [self.delveButton setEnabled:YES];
    
    // NSLog(@"Error ---- : %@, userinfo : %@", error.description,error.userInfo);
    
    UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:[error.userInfo objectForKey:@"NSLocalizedDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [delveAlert show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - remove globe spinner
-(void)removeGlobleSpinner
{
    // NSLog(@"removing globe spinner-- ");
    // remove globe spinner
    if(self.spinnerImageView!=nil)
    {
        [self.spinnerImageView removeFromSuperview];
        self.spinnerImageView = nil;
    }
}

@end
