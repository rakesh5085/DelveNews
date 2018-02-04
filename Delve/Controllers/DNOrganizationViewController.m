//
//  DNOrganizationViewController.m
//  Delve
//
//  Created by Letsgomo Labs on 19/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNOrganizationViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "DNGlobal.h"
#import "DNOrganizationModal.h"
#import "DNOrganizationObject.h"
#import "DNTodaysDelvedModel.h"
#import "DNArticleViewController.h"
#import "Constants.h"
#import "UIImage+animatedGIF.h"

#import "DNProfileViewController.h"


// to use for below ios 5.0
#import <CoreText/CoreText.h>

#define kHeaderLabelTopOffsetY 10
#define kHeaderImageViewOffsetX 10
#define kHeaderImageViewOffsetY 37
#define kHeaderLabelsOffsetX 70
#define kHeaderDesigLabelOffsetY 45
#define kHeaderNameLabelOffsetY 65

#define kDropDownTag 101
#define kDropDownTableHeight 132.0f
#define kRowHeight 44.0


@interface DNOrganizationViewController ()
{
    NSURLConnection *articleConnection;
    NSMutableData *articlesData;
    NSMutableArray *organizationArray;
    NSDictionary *dictOrganization;
    NSMutableArray *todaysDelvesArray;
    
    //To refresh the feeds
    UIRefreshControl *refreshControl;
    
    // to check when to show spinner
    BOOL isFirstTimeLoadingFeeds;
    BOOL isEndedLoadingFeeds;
    
    // link click on the user name
    NSString * urlForId;
    
    // Switch organization parameters
    NSURLConnection *connectionSwitchOrg;
    NSMutableData *dataSwitchOrganization;
    BOOL isOrganizationSwitched;
    NSInteger selectedOrganizationID;
    
    // this string will hold the current organization name
    NSString *defaultOrganizationName;
    
    // for delve and comments instant update
    int sectionNumberOfArticle, rowNumberOfarticle;

}
// String to hold whether user or organisation
// As required in Api
@property (strong, nonatomic) NSString *typeString;
@property (nonatomic, retain) UITableView *tableViewDropDown;

// core text view to link profile names
@property (nonatomic) FTCoreTextView *coreTextView;

@end

@implementation DNOrganizationViewController

@synthesize tableViewDropDown = _tableViewDropDown;
@synthesize spinnerView = _spinnerView;
@synthesize tableViewOrganization = _tableViewOrganization;
@synthesize alphaMaskView = _alphaMaskView;
@synthesize typeString = _typeString;
@synthesize spinnerImageView;

@synthesize coreTextView = _coreTextView;

@synthesize isOrganizationSwitched = _isOrganizationSwitched;

#pragma mark - view cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    dictOrganization =[[NSDictionary alloc] initWithDictionary:[DNGlobal sharedDNGlobal].userOrganizations];
    // NSLog(@" dict Organization : %@", dictOrganization);
    
    
    // Drop down list for oraganizations list from api/organization
    _tableViewDropDown = [[UITableView alloc] initWithFrame:
                          CGRectMake(0, -kRowHeight*[[dictOrganization objectForKey:@"organizations"] count], self.view.frame.size.width,
                                     kRowHeight*[[dictOrganization objectForKey:@"organization"] count])
                                                      style:UITableViewStylePlain];
    _tableViewDropDown.dataSource = self;
    _tableViewDropDown.delegate = self;
    _tableViewDropDown.tag = kDropDownTag;
    _tableViewDropDown.hidden = YES;
    [_tableViewDropDown setBackgroundColor:[UIColor whiteColor]];
    [_tableViewDropDown setBounces:NO];
    [self.view addSubview:_tableViewDropDown];
        
    //Add gesture Recognizer to maskView so clicking it will animate back the _tableViewDropDown
    UITapGestureRecognizer *gestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showHideDropdownList)];
    [_alphaMaskView addGestureRecognizer:gestureRecognizer];
    
    //refresh feeds data
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshArticlesInCurrentOrganization:) forControlEvents:UIControlEventValueChanged];
    [_tableViewOrganization addSubview:refreshControl];
    
    isFirstTimeLoadingFeeds = YES;
    // set the end refreshing parameter initialy to no as feeds would get load in view didload
    isEndedLoadingFeeds = NO;
    
    // ******************** selected org id would be set to 0 initially 
    selectedOrganizationID = 0;
    
    // Method to call getUserArticlesInCurrentOrganization api
    [self getUserArticlesInCurrentOrganization];
    
    // notification when organization is switched
    _isOrganizationSwitched = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(organizationSwitchedNotification:) name:kPOSTNOTIFICATION_SWITCH_ORG object:nil];
    //refresh feeds notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFeedsNotificationReceived:) name:kPOSTNOTIFICATION_REFRESH_FEEDS object:nil];
    //Delve or comment on article notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delveOrCommentNotificationReceived:) name:kPOSTNOTIFICATION_DELVE_OR_COMMENT object:nil];
    // user logged out
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedoutNotificationReceived:) name:kPOSTNOTIFICATION_USER_LOGGEDOUT object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    NSString * activeOrganizationID = [[dictOrganization objectForKey:@"active_organization"] stringValue];
    defaultOrganizationName = @"Switch Organization";
    
    if([DNGlobal sharedDNGlobal].switchedUserOrganization && [DNGlobal sharedDNGlobal].switchedUserOrganization.length>0)
    {
        defaultOrganizationName = [DNGlobal sharedDNGlobal].switchedUserOrganization;
    }
    else
    {
        for(NSDictionary *orgDict in [dictOrganization objectForKey:@"organizations"])
        {
            if([activeOrganizationID isEqualToString:[[orgDict objectForKey:@"id"] stringValue]] )
            {
                defaultOrganizationName = [orgDict objectForKey:@"name"];
                break;
            }
        }
    }
    
    if(_isOrganizationSwitched)// if organization switched then load feed for it
    {
        isEndedLoadingFeeds = NO;
        
        // now change the feeds according to switched organization
        isFirstTimeLoadingFeeds = YES; // consider fetching first time as we need to show globe spinner too
        
        [self getUserArticlesInCurrentOrganization];
        _isOrganizationSwitched = NO;// only call this api one time (if user keeps switching between tabs)
    }
    
    [_tableViewDropDown reloadData]; // reload organization data
    [DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:defaultOrganizationName];
}

-(void)viewWillDisappear:(BOOL)animated
{
    // if drop down displayed disappear it again
    if(!_tableViewDropDown.hidden)
        [self showHideDropdownList];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - refresh the profile table view
-(void)refreshArticlesInCurrentOrganization:(UIRefreshControl *)refreshControl1
{
    if(isEndedLoadingFeeds)
    {
        isFirstTimeLoadingFeeds = NO;
        isEndedLoadingFeeds = NO;
        [self getUserArticlesInCurrentOrganization];
    }
    else
    {
        // NSLog(@"data already being fetched from server");
        [refreshControl1 endRefreshing];
    }
}

#pragma mark - show dropdown list

- (void)showHideDropdownList
{
    if(_tableViewDropDown.hidden)
    {
        _tableViewDropDown.hidden=NO;
        _alphaMaskView.hidden = NO;
        [UIView animateWithDuration:0.3f
                              delay:0.0
                            options: 0
                         animations:^{
                             
                             int maxHeight = kRowHeight*[[dictOrganization objectForKey:@"organizations"] count];
                             
                             if (( kRowHeight*[[dictOrganization objectForKey:@"organizations"] count] ) > 240)
                                 maxHeight = 240;
                             
                             _tableViewDropDown.frame = CGRectMake(0, 0, self.view.frame.size.width, maxHeight);
                         }
                         completion:^(BOOL finished){
                             
                         }];
        
    }
    else
    {
        [UIView animateWithDuration:0.3f
                              delay:0.0
                            options: 0
                         animations:^{
                             _tableViewDropDown.frame = CGRectMake(0, -kRowHeight*2, self.view.frame.size.width, kRowHeight*2);
                         }
                         completion:^(BOOL finished){
                             _tableViewDropDown.hidden=YES;
                             _alphaMaskView.hidden = YES;
                         }];
    }
}

//Method to show activityindicator on view
-(void)showIndicator
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"delve_globe" withExtension:@"gif"];
    self.spinnerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 200, 40, 40)];
    self.spinnerImageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    [self.view addSubview:self.spinnerImageView];
}

#pragma mark - get the users articles in current organization
/*************************
 API TO CALL --- /api/userarticleclip/
 PARAMETERS --- active_organization' , type , id , begin_date , end_date
 *************************/
-(void)getUserArticlesInCurrentOrganization
{
    DNGlobal *sharedInstance = [DNGlobal sharedDNGlobal];
    //Fetching active organisation from global userorganisation.
    NSString *userActiveOrg=[sharedInstance.userOrganizations objectForKey:@"active_organization"];
    //Here Basically we are passing typeString as organisation
    _typeString = @"organization";
    
    // pass the organization id if user has not selected manually any other organization
    NSString *org_id = [[NSString alloc] init];
    if(selectedOrganizationID == 0)
        org_id = userActiveOrg;
    else
        org_id = [NSString stringWithFormat:@"%d", selectedOrganizationID];
    
    // *************** Add begin date parameter **
    NSString * beginDate =  [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    
    // Creating Dictionary for extra data which should be passed with URL
    NSDictionary *activeOrgDict;
    if(!_isOrganizationSwitched)
    {
        activeOrgDict = [NSDictionary dictionaryWithObjectsAndKeys:userActiveOrg,@"active_organization",_typeString,@"type",
                         org_id,@"id",beginDate, @"begin_date", nil];
    }
    else
    {
        activeOrgDict = [NSDictionary dictionaryWithObjectsAndKeys:userActiveOrg,@"active_organization",_typeString,@"type",org_id,@"id"
                         ,beginDate, @"begin_date",
                         [[DNGlobal sharedDNGlobal].gSwitchOrgDictionary objectForKey:@"internal_organizations"],@"internal_organizations",[[DNGlobal sharedDNGlobal].gSwitchOrgDictionary objectForKey:@"preference_organizations"],@"preference_organizations",nil];
    }
    
    // Making data with jsonobject
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:activeOrgDict options:kNilOptions error:nil];
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *idAndActiveOrgString=[NSString stringWithFormat:@"%@/api/userarticleclip/?settings=%@",kAPI_Host_Name,jsonString];
    // NSLog(@"idfinalstr-=%@",idAndActiveOrgString);
    
    NSURL *url = [NSURL URLWithString:idAndActiveOrgString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //Add cookie object here passing globally saved cookie
    [request addValue:sharedInstance.gCookie forHTTPHeaderField:@"Cookie"];
    
    // cancel a connection if already present
    if(articleConnection)
    {
        [articleConnection cancel];
        articleConnection = nil;
    }
    
    articleConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (articleConnection)
    {
        // Create the NSMutableData to hold the received data.
        articlesData = [[NSMutableData data] init];
        
        isEndedLoadingFeeds = NO;
        if(self.spinnerImageView!=nil)
        {
            [self.spinnerImageView removeFromSuperview];
            self.spinnerImageView = nil;
        }
        
        if(isFirstTimeLoadingFeeds)
            //Showing indicatorview
            [self showIndicator];
    }
    else
    {
        // Inform the user that the connection failed.
        // NSLog(@"CONNECTION CREATION FAILED FOR CONVERSATION ARTICLES LIST: ====>>>>>>");
    }
}


#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if(connection == articleConnection)
    {
        [articlesData setLength:0];
    }
    else
    {
        [dataSwitchOrganization setLength:0];
    }
    isEndedLoadingFeeds = NO;
    // NSLog(@"PROFILE didReceiveResponse");
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    if(connection == articleConnection)
    {
        [articlesData appendData:data];
    }
    else
    {
        [dataSwitchOrganization appendData:data];
    }
    isEndedLoadingFeeds = NO;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(self.spinnerImageView!=nil)
    {
        [self.spinnerImageView removeFromSuperview];
        self.spinnerImageView = nil;
    }
    
    if(connection == articleConnection)
    {
        //Initialising todaysdelvesarray
        
        organizationArray = [[NSMutableArray alloc] init];
        
        // Today's date for matching with today's delved/Shared stories only
        NSDate *currentDate = [[NSDate alloc] init];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *localDateString = [dateFormatter stringFromDate:currentDate];
        
        NSString* responseString= [[NSString alloc] initWithData:articlesData encoding:NSUTF8StringEncoding];
        // NSLog(@"Response in organisationviewcontroller: %@",responseString);
        
        NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
        
        //First checking the response status.
        NSString *responseStatus = [responseJSON objectForKey:@"success"];
        if([responseStatus boolValue])
        {
            // we will have array of all users belwo , each user will have clips (0 or more )
            NSArray *clipList= [responseJSON objectForKey:@"clip_list"];
            
            // we only have to display those users in the table view which has more 1 or more clips (atleast one clip)
            // ***** itterating thru each user's data (in an organixation )
            for(NSDictionary* orgDict in clipList)
            {
                // ACCESSING clips of a user
                NSArray *tempClipArray = [orgDict objectForKey:@"clips"];
                
                // Only save clips if USER has atleast one clip
                if(tempClipArray != nil && tempClipArray.count > 0)
                {
                    // This array will store today's delved/shared array for this USER
                    todaysDelvesArray = [[NSMutableArray alloc] init];
                    
                    DNOrganizationModal *objOrgModal = [[DNOrganizationModal alloc] init];
                    objOrgModal.clips = [[NSMutableArray alloc] init];
                
                    // Now traverse through each clip of the user
                    for(NSDictionary *clipDictionary in tempClipArray)
                    {
                        // First of all accessing date of a clip
                        NSString *tempDateStr = [clipDictionary objectForKey:@"date"];
                        
                        // If the date is equal to current date (i.e. today's date) then start saving this clip
                        if([tempDateStr isEqualToString:localDateString])
                        {
                            DNTodaysDelvedModel *objTodaysDelved = [[DNTodaysDelvedModel alloc] init];
                            // if clips available then add it, so that it can be used to display delves
                            objTodaysDelved.clipsOfArticleArray = [NSMutableArray arrayWithArray: [clipDictionary objectForKey:@"clips"]];
                            
                            // remove duplicate delves from clips array
                            objTodaysDelved.clipsOfArticleArray = [DNGlobal removeDuplicateDelvesFromClipsArray:objTodaysDelved.clipsOfArticleArray];

                            // add comments too
                            if([clipDictionary objectForKey:@"comments"] != nil)
                            {
                                if(!objTodaysDelved.commentsOfArticleArray)
                                    objTodaysDelved.commentsOfArticleArray = [[NSMutableArray alloc] init];
                                objTodaysDelved.commentsOfArticleArray = [NSMutableArray arrayWithArray:[clipDictionary objectForKey:@"comments"]];
                            }
                            // also add comments from discussions array
                            NSDictionary *discussion= [clipDictionary objectForKey:@"discussions"];
                            if(discussion )
                            {
                                if(!objTodaysDelved.commentsOfArticleArray)
                                    objTodaysDelved.commentsOfArticleArray = [[NSMutableArray alloc] init];
                                [objTodaysDelved.commentsOfArticleArray addObject:discussion];
                            }
                            
                            NSDictionary *articleDictionary = [clipDictionary objectForKey:@"article"];
                            if(articleDictionary!=nil)
                            {
                                NSString *tempTitle = [articleDictionary objectForKey:@"title"];
                                if(tempTitle!=nil)
                                {
                                    objTodaysDelved.titleOfArticle = tempTitle;
                                }
                                NSString *tempLink = [articleDictionary objectForKey:@"link"];
                                if(tempLink!=nil)
                                {
                                    objTodaysDelved.linkOfArticle = tempLink;
                                }
                                NSString *tempId = [articleDictionary objectForKey:@"id"];
                                if(tempId!=nil)
                                {
                                    objTodaysDelved.idOfArticle = tempId;
                                }
                                
                                //Adding object to todaysdelvedarray
                                [todaysDelvesArray addObject:objTodaysDelved];
                            }
                        }
                    }
                    // Now its time to save user's clips
//                    [objOrgModal.clips addObject:[NSArray arrayWithArray:todaysDelvesArray]];
                    
                    objOrgModal.clips = [NSMutableArray arrayWithArray:todaysDelvesArray];
                    
                    // NSLog(@"count of objOrgModal.clips=%d",[objOrgModal.clips count]);
                    
                    // save this user's info also
                    NSString *tempName = [orgDict objectForKey:@"name"];
                    if(tempName!=nil)
                    {
                        objOrgModal.nameOfUser = tempName;
                    }
                    NSString *tempImgUrl = [orgDict objectForKey:@"image37"];
                    if(tempImgUrl != nil)
                    {
                        objOrgModal.imageUrlString = [NSString stringWithFormat:@"http:%@",tempImgUrl];
                    }
                    NSString *tempId = [orgDict objectForKey:@"id"];
                    if(tempId != nil)
                    {
                        objOrgModal.userId = tempId;
                    }
                    NSString *tempPosition = [orgDict objectForKey:@"position"];
                    if(tempPosition != nil)
                    {
                        objOrgModal.positionString = tempPosition;
                    }
                    NSString *tempEmail = [orgDict objectForKey:@"email"];
                    {
                        objOrgModal.emailString = tempEmail;
                    }
                    
                    if(objOrgModal.clips.count > 0)
                    {
                        //Now add this object of DNOrganizationModal in array if the count of clips is greater than 0 :)
                        [organizationArray addObject:objOrgModal];
                    }
                }
            }
                  // NSLog(@"Complete-> organisations array : %d", organizationArray.count);
            
            if(_isOrganizationSwitched) // if this data is due to  organization switch turn it off then 
                _isOrganizationSwitched = NO;
            
            [_tableViewOrganization reloadData];
        }
        else
        {
            UIAlertView *responseAlert= [[UIAlertView alloc] initWithTitle:@"Delve" message:@"No response from server" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [responseAlert show];
        }
    }
    else if ([connection isEqual:connectionSwitchOrg]) // ajax/switch_org call
    {
            NSString* responseString= [[NSString alloc] initWithData:dataSwitchOrganization encoding:NSUTF8StringEncoding];
            //// NSLog(@"Response: %@",responseString);
            
            NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData:
                                         [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
            
            // NSLog(@"-------- >>> repsonse of switch org: %@", responseJSON);
            
            if([responseJSON objectForKey:@"success"])
            {
                [DNGlobal sharedDNGlobal].gSwitchOrgDictionary = [[NSDictionary alloc] initWithDictionary:[responseJSON objectForKey:@"suggested_organization_values"]];
                
                // send notification in all tabs (to all registered notifications ) that an organization has been switched
                // sent the parameter ‘suggested_organization_values’ to all tabs
                NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"organization",@"fromController", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:kPOSTNOTIFICATION_SWITCH_ORG object:nil userInfo:userInfo];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve"
                                                                message:@"Organization switch failed, try again"
                                                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }            
    }
    
    isEndedLoadingFeeds = YES;
    [refreshControl endRefreshing];
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error in connection, Please try again"
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    if(self.spinnerImageView!=nil)
    {
        [self.spinnerImageView removeFromSuperview];
        self.spinnerImageView = nil;
    }
    isEndedLoadingFeeds = YES;
    [refreshControl endRefreshing];
}

#pragma mark - core text delegates

- (NSArray *)coreTextStyle
{
    NSMutableArray *result = [NSMutableArray array];
    
	FTCoreTextStyle *defaultStyle = [FTCoreTextStyle new];
	defaultStyle.name = FTCoreTextTagDefault;	//thought the default name is already set to FTCoreTextTagDefault
	defaultStyle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0];
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
//	boldStyle.name = @"bold";
    boldStyle.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
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
    [DNGlobal sharedDNGlobal].gIsTappedOnProfileName = TRUE;
    NSString *str = [urlForId stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    // NSLog(@"str= %@",str);
    NSString *loggedInUserId;;
    //Fetching id of current loggedinuser
    loggedInUserId = [NSString stringWithFormat:@"%@",[[DNGlobal sharedDNGlobal].gUserInfoDictionary objectForKey:@"id"]];
    
    if([loggedInUserId isEqualToString:str])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Trying to open existing profile" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        // programmatically creating the story board instance
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        DNProfileViewController *objProfileController = (DNProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"profileViewController"];
        
        NSString *str = [urlForId stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        objProfileController.gIdForSelf = str;
        
        [self.navigationController pushViewController:objProfileController animated:YES];
    }
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView.tag == kDropDownTag)
    {
        return 1;
    }
    if([organizationArray count] == 0)
        return 1;
    return [organizationArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView.tag == kDropDownTag)
    {
        return [[dictOrganization objectForKey:@"organizations"] count];
    }
    if([organizationArray count] == 0) // if no records are there , no rows should be there
        return 0;
    
    DNOrganizationModal *one_org = (DNOrganizationModal *)[organizationArray objectAtIndex:section];
    // NSLog(@"clips in one org: %@", one_org.clips);
    
    NSArray *arr_clips = [NSArray arrayWithArray:one_org.clips];
    
    return arr_clips.count; // number of clips we have saved on parsing of response
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if(tableView.tag == kDropDownTag) // drop down table configration 
    {
        static NSString *CellIdentifier = @"dropdownCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] ;
        }
        
        // NSLog(@"text in cel : %@", [[[dictOrganization objectForKey:@"organizations"] objectAtIndex:indexPath.row] objectForKey:@"name"]);
        
        cell.textLabel.text =[NSString stringWithFormat:@"%@       ",[[[dictOrganization objectForKey:@"organizations"] objectAtIndex:indexPath.row] objectForKey:@"name"]];
        cell.textLabel.textAlignment= NSTextAlignmentRight;
        [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15]];
    }
    else  // organization feed table configration 
    {
            static NSString *CellIdentifierFull = @"OrganizationCellFull";
            if(SYSTEM_VERSION_GREATER_THAN(@"6.0"))
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierFull forIndexPath:indexPath];
            else
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierFull ];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:CellIdentifierFull] ;

            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // NSLog(@"before crash : ");
            DNOrganizationModal *obj = (DNOrganizationModal *)[organizationArray objectAtIndex:indexPath.section];
            NSMutableArray *arr = [NSMutableArray arrayWithArray:obj.clips]; // clips of one user (user's name etc will be in section header)
            DNTodaysDelvedModel *objtoday = (DNTodaysDelvedModel *)[arr objectAtIndex:indexPath.row];
            
            ((UILabel*)[cell.contentView viewWithTag:150]).font = [UIFont fontWithName:@"Bitter-Regular" size:18];
            ((UILabel*)[cell.contentView viewWithTag:150]).text = objtoday.titleOfArticle;
            
            NSString * strDelvesAndComments = [DNGlobal createDelvesAndCommentString:objtoday.clipsOfArticleArray :objtoday.commentsOfArticleArray];
            
            // core text view for profile linking and styles
            _coreTextView = (FTCoreTextView *)[cell viewWithTag:151];
            // set text
            [_coreTextView setText:strDelvesAndComments];
            // set styles
            [_coreTextView addStyles:[self coreTextStyle]];
            // set delegate
            [_coreTextView setDelegate:self];
            
            [_coreTextView fitToSuggestedHeight];
            
            //make  Background of cell square
            UIView *bg = [[UIView alloc] initWithFrame:cell.bounds];
            bg.backgroundColor = [UIColor colorWithRed:0.980 green:0.988 blue:0.984 alpha:1];
            bg.layer.borderColor = [UIColor colorWithRed:0.827 green:0.827 blue:0.835 alpha:1].CGColor;
            bg.layer.borderWidth = kCellBorderWidth;
            //bg.layer.cornerRadius= kCellBorderRadius;
            cell.backgroundView = bg;
            
            // to make cell selection square and not round (which is by default)
            UIView *bg_selected = [[UIView alloc] initWithFrame:cell.bounds];
            bg_selected.backgroundColor = [UIColor lightGrayColor];
            bg_selected.layer.borderColor = [UIColor colorWithRed:0.827 green:0.827 blue:0.835 alpha:1].CGColor;
            bg_selected.layer.borderWidth = kCellBorderWidth;
            cell.selectedBackgroundView = bg_selected;
        
    }
    return cell;
}
-(UILabel *)adjustSizeOfLabel:(UILabel *)lbl
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
-(UIView *)createHeaderView:(DNOrganizationModal *)objOrganization withSection: (int )section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kHeaderWidth, 94)];
    
    // FOR FIRST SECTION ADD A LABEL TO THE HEADER VIEW  
    if(section == 0 && isEndedLoadingFeeds)
    {
        UILabel *label_topTitle = [[UILabel alloc] initWithFrame:CGRectMake(kHeaderImageViewOffsetX, 10, 300, 20)];
        label_topTitle.text = [NSString stringWithFormat:@"TODAY'S SHARES FROM (%@)", defaultOrganizationName];
        label_topTitle.font  = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0];
        label_topTitle.numberOfLines = 0;
        label_topTitle = [self adjustSizeOfLabel:label_topTitle];
        label_topTitle.textColor = [UIColor colorWithRed:171/255.0 green:171/255.0 blue:171/255.0 alpha:1.0];
        label_topTitle.backgroundColor = [UIColor clearColor];
        [headerView addSubview:label_topTitle];
    }
    
    // *********** Downloading image and setting it to imageView
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(kHeaderImageViewOffsetX, kHeaderImageViewOffsetY, kImagePersonWidth, kImagePersonHeight)];
    if (objOrganization.userImageData)
    {
        imgView.image = [UIImage imageWithData:objOrganization.userImageData];
    }
    else
    {
        imgView.image = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            UIImage *tempImage;
            if(objOrganization.imageUrlString != nil) // if feedimage string is not nil
            {
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:objOrganization.imageUrlString]];
                tempImage = [UIImage imageWithData:imageData];
            }
            // create thumb resized image
            UIImage *image_thumb = [DNGlobal imageWithImage:tempImage scaledToWidth:100];
            objOrganization.userImageData = (NSMutableData *)UIImageJPEGRepresentation(image_thumb, 1);
            dispatch_async(dispatch_get_main_queue(), ^{
                //Setting the image on imageview
                imgView.image = tempImage;
                
            });
        });
    }

    UILabel *label_desig = [[UILabel alloc] initWithFrame:CGRectMake(kHeaderLabelsOffsetX, kHeaderDesigLabelOffsetY, kLableWidth, kLableHeight)];
    label_desig.text = objOrganization.positionString;
    label_desig.font  = [UIFont italicSystemFontOfSize:12.0];
    label_desig.backgroundColor = [UIColor clearColor];
    
    UILabel *label_name = [[UILabel alloc] initWithFrame:CGRectMake(kHeaderLabelsOffsetX, kHeaderNameLabelOffsetY, kLableWidth, kLableHeight)];
    label_name.text = objOrganization.nameOfUser;
    label_name.backgroundColor = [UIColor clearColor];
    label_name.textColor = [UIColor colorWithRed:0/255.0 green:74/255.0 blue:142/255.0 alpha:1.0]; // 0,74,142
    label_name.font = [UIFont boldSystemFontOfSize:16.0];
    
    [headerView addSubview:imgView];
    [headerView addSubview:label_desig];
    [headerView addSubview:label_name];
    
    return headerView;
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(tableView.tag == kDropDownTag)
    {
        return nil;
    }
    
    if(organizationArray.count == 0)
    {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kHeaderWidth, 94)];
        
        if(section == 0  && isEndedLoadingFeeds)
        {
            UILabel *label_topTitle = [[UILabel alloc] initWithFrame:CGRectMake(kHeaderImageViewOffsetX, 10, 300, 20)];
            label_topTitle.text = [NSString stringWithFormat:@" NO SHARES TODAY FROM (%@)", defaultOrganizationName];
            label_topTitle.font  = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0];
            label_topTitle.numberOfLines = 0;
            label_topTitle = [self adjustSizeOfLabel:label_topTitle];
            label_topTitle.textAlignment = NSTextAlignmentCenter;
            label_topTitle.textColor = [UIColor colorWithRed:171/255.0 green:171/255.0 blue:171/255.0 alpha:1.0];
            label_topTitle.backgroundColor = [UIColor clearColor];
            [headerView addSubview:label_topTitle];
        }
        
        return headerView;
    }

    // Fetching the section and sending the corresponding object to make headerview
    DNOrganizationModal *objOrgModal = (DNOrganizationModal *)[organizationArray objectAtIndex:section];
    return [self createHeaderView:objOrgModal withSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(tableView.tag == kDropDownTag)
    {
        return 0;
    }

    return kHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag != kDropDownTag)
    {
        
        if([organizationArray count ] == 0)
        {
            return 0;
        }
        
        // NSLog(@"before crash 2 : ");
        DNOrganizationModal *obj = (DNOrganizationModal *)[organizationArray objectAtIndex:indexPath.section];
        NSMutableArray *arr = [NSMutableArray arrayWithArray:obj.clips];
        DNTodaysDelvedModel *objtoday = (DNTodaysDelvedModel *)[arr objectAtIndex:indexPath.row];
        
        NSAttributedString * strDelvesAndComments = [[NSAttributedString alloc] initWithString:[DNGlobal createDelvesAndCommentString:objtoday.clipsOfArticleArray :objtoday.commentsOfArticleArray] ];
        
        CGSize size_temp;
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
        {
            // crash on ios 5.0
            CGRect rect = [strDelvesAndComments boundingRectWithSize:CGSizeMake(270.0, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) context:nil];
            size_temp = rect.size;
            
        }
        else
        {       
            // works same as above code .. need to apply if else too with this
            CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)strDelvesAndComments);
            CGSize targetSize = CGSizeMake(270, CGFLOAT_MAX);
            CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [strDelvesAndComments length]), NULL, targetSize, NULL);
            size_temp = fitSize;
        }
        
        
        return [self getHeightOfSharedAndCommentedCoreText:strDelvesAndComments]+30;
    }
    return 44.0;
}

-(float)getHeightOfSharedAndCommentedCoreText:(NSAttributedString *)strDelvesAndComments
{
    NSString *strTemp = [NSString stringWithFormat:@"%@", strDelvesAndComments];

    strTemp = [[strTemp componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet] ] componentsJoinedByString:@""];

    strTemp = [strTemp stringByReplacingOccurrencesOfString:@"<_link>" withString:@""];
    strTemp = [strTemp stringByReplacingOccurrencesOfString:@"</_link>" withString:@""];

    //        // NSLog(@"strTemp : %@ length : %d",strTemp, strDelvesAndComments.length);
    CGSize size_temp;

    size_temp = [strTemp sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:13.0]
                    constrainedToSize:CGSizeMake(280.0, CGFLOAT_MAX)
                        lineBreakMode:NSLineBreakByCharWrapping];

    // NSLog(@"height of string : %f", size_temp.height);
        
        return size_temp.height;
}


#pragma mark - prepare for segue
// Method to perform segue.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"goFromOrganization"])
    {
        NSIndexPath *indexPath = [_tableViewOrganization indexPathForSelectedRow];
        DNOrganizationModal *obj = (DNOrganizationModal *)[organizationArray objectAtIndex:indexPath.section];
        NSMutableArray *arr = [NSMutableArray arrayWithArray:obj.clips];
        DNTodaysDelvedModel *objtoday = (DNTodaysDelvedModel *)[arr objectAtIndex:indexPath.row];
        
        DNArticleViewController *articleViewController = segue.destinationViewController;
        articleViewController.openedArticleId= objtoday.idOfArticle;
        [articleViewController openLinkInWebview:objtoday.linkOfArticle];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag == kDropDownTag)
    {
        if(!_tableViewDropDown.hidden)
            [self showHideDropdownList];
        
        // API call to switch organization
        selectedOrganizationID = [[[[dictOrganization objectForKey:@"organizations"] objectAtIndex:indexPath.row] objectForKey:@"id"] floatValue];
        // NSLog(@"id of selected organization in cel : %@",[NSNumber numberWithFloat: selectedOrganizationID]);
        
        NSString *org_name = [[[dictOrganization objectForKey:@"organizations"] objectAtIndex:indexPath.row] objectForKey:@"name"];
        if(selectedOrganizationID && (![org_name isEqualToString:[DNGlobal sharedDNGlobal].switchedUserOrganization]))
        {
            NSDictionary *requestDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: selectedOrganizationID] forKey:@"organization_id"];
            // Making data with jsonobject
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:kNilOptions error:nil];
            
            NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAPI_Host_Name,@"/ajax/switch_org/"]]
                                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                   timeoutInterval:60];
            
            // Set the request's content type to application/x-www-form-urlencoded
            [postRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            // Designate the request a POST request and specify its body data
            [postRequest setHTTPMethod:@"POST"];
            [postRequest setValue:[NSString stringWithFormat:@"%d", [jsonData length]] forHTTPHeaderField:@"Content-Length"];
            [postRequest setHTTPBody:jsonData];
            [postRequest addValue:[DNGlobal sharedDNGlobal].gCSRF_Token forHTTPHeaderField:@"X-CSRFToken"];
            [postRequest addValue:[NSString stringWithFormat:@"csrftoken=%@;sessionid=%@",[DNGlobal sharedDNGlobal].gCSRF_Token,
                                   [DNGlobal sharedDNGlobal].gCookieInPostApi] forHTTPHeaderField:@"Cookie"];
            //Set to NO so that each time cookie will be generated
            [postRequest setHTTPShouldHandleCookies:NO];

            // *******************************************************************************************************************************
             // ******** end refreshing controller so that UI remains undisturbed
            // *******************************************************************************************************************************
            
            [refreshControl endRefreshing];
            
            // also disable connection
            if(articleConnection)
            {
                [articleConnection cancel];
                articleConnection = nil;
            }
            // *******************************************************************************************************************************
            // cancel a connection if already present
            if(connectionSwitchOrg)
            {
                [connectionSwitchOrg cancel];
                connectionSwitchOrg = nil;
            }
            // hit login api with the specified request
            connectionSwitchOrg = [[NSURLConnection alloc] initWithRequest:postRequest delegate:self];
            
            if(connectionSwitchOrg) // connection for switched org
            {
                dataSwitchOrganization = [[NSMutableData alloc] init];
                if(self.spinnerImageView!=nil)
                {
                    [self.spinnerImageView removeFromSuperview];
                    self.spinnerImageView = nil;
                }
                [self showIndicator];
            }
        }
        [DNGlobal sharedDNGlobal].switchedUserOrganization = [[[dictOrganization objectForKey:@"organizations"] objectAtIndex:indexPath.row] objectForKey:@"name"];
        [DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:org_name];
        
        defaultOrganizationName = [DNGlobal sharedDNGlobal].switchedUserOrganization;
            
        [_tableViewOrganization reloadData];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - post notification when org switched

-(void)organizationSwitchedNotification: (NSNotification *)notification
{
    _isOrganizationSwitched = YES;
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_SWITCH_ORG])
    {
        // NSLog(@"notification receieved in ORGANIzation view controller ---- ");
        if([[notification.userInfo objectForKey:@"fromController"] isEqualToString:@"organization"])
        {
            isEndedLoadingFeeds = NO;
            // now change the feeds according to switched organization
            isFirstTimeLoadingFeeds = YES; // consider fetching first time as we need to show globe spinner too            
            [self getUserArticlesInCurrentOrganization];
            
            _isOrganizationSwitched = NO;// set to no to prevent calling in viewWillApear: wen tabs switched
        }
    }
}
-(void)refreshFeedsNotificationReceived: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_REFRESH_FEEDS])
    {
        // NSLog(@"refresh feeds called ---  in  Organization VC: ");
        
        // refresh feeds
        isFirstTimeLoadingFeeds = YES; // consider fetching first time as we need to show globe spinner too
        isEndedLoadingFeeds = NO;
        [self getUserArticlesInCurrentOrganization];
    }
}
-(void)delveOrCommentNotificationReceived: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_DELVE_OR_COMMENT])
    {
        // NSLog(@"Delve/Comment notification called ---  in Tab 2  Conversation VC: ");
        // NSLog(@"user info is : %@", notification.userInfo);
        
        for (DNOrganizationModal *objOrg in organizationArray)
        {
            NSArray *anOrg = [NSArray arrayWithArray:objOrg.clips];
                                    
            for (DNTodaysDelvedModel *aFeed in anOrg)
            {
                if([[NSString stringWithFormat:@"%@", aFeed.idOfArticle] isEqualToString:[NSString stringWithFormat:@"%@",[notification.userInfo objectForKey:@"delvedArticleId"]]])
                {

                    
                    aFeed.clipsOfArticleArray = [NSMutableArray arrayWithArray:[notification.userInfo  objectForKey:@"clips"]];
                    aFeed.commentsOfArticleArray =  [NSMutableArray arrayWithArray: [notification.userInfo  objectForKey:@"comments"]];
                    
                    if(aFeed.clipsOfArticleArray.count == 0)
                        aFeed.clipsOfArticleArray = nil;
                }
            }
        }
        
        // now relaod that
        [_tableViewOrganization reloadData];
    }
}
// user logged out .. cancel any pending connections
-(void)userLoggedoutNotificationReceived: (NSNotification *)notification
{
    // NSLog(@"user logged out ----");
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_USER_LOGGEDOUT])
    {
        // cancel a connection if already present
        // cancel a connection if already present
        if(connectionSwitchOrg)
        {
            [connectionSwitchOrg cancel];
            connectionSwitchOrg = nil;
        }
        if(articleConnection)
        {
            [articleConnection cancel];
            articleConnection = nil;
        }
    }
}


@end
