//
//  DNProfileViewController.m
//  Delve
//
//  Created by Atul Khatri on 13/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNProfileViewController.h"
#import "DNTodaysDelvedModel.h" // to store and retrieve all articles on profile page
#import "UIImage+animatedGIF.h"
#import "Constants.h"

#import "DNGlobal.h"

#import "DNCustomTabBar.h"

#import "MNMBottomPullToRefreshManager.h"

#import <CoreText/CoreText.h>


#define kHeaderLabelOffsetX 20
#define kHeaderLabelOffsetY 10
#define kHeaderLabelHeight 20
#define kBorderWidth 1.0f
#define kDropDownTag 101
#define kDropDownTableHeight 132.0f

#define kRowHeight 44.0


@interface DNProfileViewController ()
{
    NSArray *arrayList;
    NSMutableData *userData;
    
    NSURLConnection *logoutConnection;
    NSMutableData *logoutDataReceived;
    
    //To refresh the feeds
    UIRefreshControl *refreshControl;
    
    /*Refer API Doc: Set ‘offset’ to the number of clips that have already been displayed and the server will return more clips starting from that number.
     So, for instance, if you have already displayed 20 clips and want to get the next batch, set offset:20 in the JSON.
     */
    int offsetForFetchMore;
    BOOL isRefreshing;
    
    // to check when to show spinner
    BOOL isFirstTimeLoadingFeeds;
    BOOL isEndedLoadingFeeds;
    
    // Pull to refresh manager
    MNMBottomPullToRefreshManager *pullToRefreshManager_;
    BOOL isFetchingInProgress; // a bool for fetch operation in progress or not
    
    // temporary dictionary to hold sections
    NSMutableDictionary *tempDictSections;
    
    // Sorting of articles
    NSString *orderBy;
    
    // Array to hold most delved or comments feeds
    NSMutableArray *tempArrayClipsAndComments, *arrayCilpsAndComments;
    // link click on the user name
    NSString * urlForId;
    
    // to check if we are showing current loggin in user's profile
    BOOL isOnMyProfile;
    
}
// String to hold whether user or organisation
// As required in Api
@property (strong, nonatomic) NSString *typeString;
@property (nonatomic, retain) UITableView *tableViewDropDown;

// core text view to link profile names
@property (nonatomic) FTCoreTextView *coreTextView;

@end

@implementation DNProfileViewController

@synthesize profileImage;
@synthesize tableViewDropDown = _tableViewDropDown;
@synthesize userName;
@synthesize articleConnection;
@synthesize articleData;
@synthesize profileTableView;
@synthesize maskView;
@synthesize spinnerView = _spinnerView;
@synthesize typeString = _typeString;
@synthesize sections = _sections;
@synthesize sortedDateKeysArray = _sortedDateKeysArray;
@synthesize gIdForSelf;
@synthesize userDataConnection;
@synthesize spinnerImageView;

@synthesize coreTextView = _coreTextView;

@synthesize isOrganizationSwitched = _isOrganizationSwitched;

#pragma mark - view cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
	// Do any additional setup after loading the view.
    [super viewDidLoad];

    // Hide the back button on navigation bar using the tabbar controller
    ((DNCustomTabBar *)([self.navigationController.childViewControllers objectAtIndex:[self.navigationController.childViewControllers count]-1])).navigationItem.hidesBackButton = YES;
    
    DNGlobal *objGlobal = [DNGlobal sharedDNGlobal];
    
    profileImage.layer.cornerRadius=5.0;
    profileImage.clipsToBounds=YES;

    if(objGlobal.gIsTappedOnProfileName && !objGlobal.isOnMyProfile)
    {
        arrayList = [[NSArray alloc] initWithObjects:@"Most Recent",@"Most Commented",@"Most Shared", nil];
    }
    else
    {
        arrayList = [[NSArray alloc] initWithObjects:@"Most Recent",@"Most Commented",@"Most Shared",@"Log Out", nil];
    }
    
    
    // Create dropdown list 
    _tableViewDropDown = [[UITableView alloc] initWithFrame:
                          CGRectMake(0, -kRowHeight*[arrayList count], self.view.frame.size.width, kRowHeight*[arrayList count])
                        style:UITableViewStylePlain];
    
    _tableViewDropDown.tag = kDropDownTag;
    _tableViewDropDown.hidden = YES;
    _tableViewDropDown.dataSource = self;
    _tableViewDropDown.delegate = self;
    [_tableViewDropDown setBackgroundColor:[UIColor whiteColor]];
    [_tableViewDropDown setBounces:NO];
    [self.view addSubview:_tableViewDropDown];
    
    //Add gesture Recognizer to maskView so clicking it will animate back the _tableViewDropDown
    UITapGestureRecognizer *gestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showHideDropdownList)];
    [maskView addGestureRecognizer:gestureRecognizer];
    
    if(objGlobal.gIsTappedOnProfileName && ![DNGlobal sharedDNGlobal].isOnMyProfile)
    {
       //here i need one api
        [self getUserInfo];
    }
    else
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [self setUserName:[defaults objectForKey:@"userName"] andImage:[defaults objectForKey:@"userImage"]];
    }
    
    isFirstTimeLoadingFeeds = YES;
    // set the end refreshing parameter initialy to no as feeds would get load in view didload
    isEndedLoadingFeeds = NO;
    
    offsetForFetchMore = 0;
    isRefreshing = YES; // consider both the refreshing and first time load the same activity , so that this bool can be used or first time articles load call

    //refresh feeds data 
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshArticlesForLoggedInUser:) forControlEvents:UIControlEventValueChanged];
    [self.profileTableView addSubview:refreshControl];
    
    // fetch more from bottom 
    pullToRefreshManager_ = [[MNMBottomPullToRefreshManager alloc] initWithPullToRefreshViewHeight:60.0f tableView:self.profileTableView withClient:self];
    isFetchingInProgress = NO;
    
    // to hold section dict of articles temporarly
    tempDictSections = [[NSMutableDictionary alloc] init];
    _sections = [[NSMutableDictionary alloc] init];
    
    // sort by parameter
    orderBy = @"most_recent"; // ‘most_recent’, ‘most_comments’, or ‘most_clips’, => order_by parameter
    
    // Method to call getDelvedArticlesOfLoggedInUser api.
    [self getDelvedArticlesOfLoggedInUser];
    
    // register for the notification of switch org
    _isOrganizationSwitched = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(organizationSwitchNotification:) name:kPOSTNOTIFICATION_SWITCH_ORG object:nil];
    
    // register for refresh feeds notification 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFeedsNotificationReceived:) name:kPOSTNOTIFICATION_REFRESH_FEEDS object:nil];
    //Delve or comment on article notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delveOrCommentNotificationReceived:) name:kPOSTNOTIFICATION_DELVE_OR_COMMENT object:nil];
    // user logged out
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedoutNotificationReceived:) name:kPOSTNOTIFICATION_USER_LOGGEDOUT object:nil];
}
-(void)viewWillAppear:(BOOL)animated
{
    DNGlobal *objGlobal = [DNGlobal sharedDNGlobal];
    if(objGlobal.gIsTappedOnProfileName && !objGlobal.isOnMyProfile)
    {
        arrayList = [[NSArray alloc] initWithObjects:@"Most Recent",@"Most Commented",@"Most Shared", nil];
    }
    else
    {
        arrayList = [[NSArray alloc] initWithObjects:@"Most Recent",@"Most Commented",@"Most Shared",@"Log Out", nil];
    }
    
    NSString *orderString;
    if([orderBy isEqualToString:@"most_recent"])
        orderString = [arrayList objectAtIndex:0];
    if([orderBy isEqualToString:@"most_comments"])
        orderString = [arrayList objectAtIndex:1];
    if([orderBy isEqualToString:@"most_clips"])
        orderString = [arrayList objectAtIndex:2];
    [DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:orderString];
    
    [_tableViewDropDown reloadData]; // reload organization data
    
    // ********* switching organization  **************
    // ony switch if current profile is being shown
    
    if(_isOrganizationSwitched && objGlobal.isOnMyProfile)// if organization switched then load feed for it
    {
        isEndedLoadingFeeds = NO;
        // now change the feeds according to switched organization
        isFirstTimeLoadingFeeds = YES; // consider fetching first time as we need to show globe spinner too
        isRefreshing = YES; // must be set to true according to API clarification
        
        [self getDelvedArticlesOfLoggedInUser];
        _isOrganizationSwitched = NO;// only call this api one time (if user keeps switching between tabs)
    }
}
-(void)goToBack:(UIButton *)sender
{
    // NSLog(@"controllers : %@", [self.navigationController childViewControllers]);
    // check if we are on tab 4 and also when tapped on back button it will take us to tab 4 root view  (profile view of loggedin user)
    if(([self.navigationController childViewControllers].count == 2) &&
       [[[self.navigationController childViewControllers] objectAtIndex:0] isKindOfClass:[DNProfileViewController class]])
    {
        // NSLog(@"we are on profile view");
        [DNGlobal sharedDNGlobal].isOnMyProfile = YES;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    // if drop down is displayed, disappear it again
    if(!_tableViewDropDown.hidden)
        [self showHideDropdownList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - get deleved articles for currently logged in user
-(void)getDelvedArticlesOfLoggedInUser
{
    DNGlobal *sharedInstance=[DNGlobal sharedDNGlobal];
    NSString *loggedInUserId;
    //checking if gIsTappedOnProfileName then
    if(sharedInstance.gIsTappedOnProfileName && !sharedInstance.isOnMyProfile)
    {
        loggedInUserId = gIdForSelf;
    }
    else
    {
        //Fetching id of current loggedinuser 
        loggedInUserId = [sharedInstance.gUserInfoDictionary objectForKey:@"id"];
    }
    //Fetching active organisation from global userorganisation.
    NSString *userActiveOrg=[sharedInstance.userOrganizations objectForKey:@"active_organization"];
    //Here Basically we are passing typeString as 'user'
    _typeString = @"user";
    
    NSString *str_group_by = @"none";
    
    NSMutableDictionary *activeOrgDict;
    if(isRefreshing) // pulling table view to refresh data
    {
        // Creating Dictionary for extra data which should be passed with URL
        activeOrgDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:userActiveOrg,@"active_organization",_typeString,@"type",loggedInUserId,@"id",orderBy,@"order_by",str_group_by, @"group_by", nil];
    }
    else // fetching more data scrolling tableview to bottom
    {
        activeOrgDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:userActiveOrg,@"active_organization",_typeString,
                         @"type",loggedInUserId,@"id",[NSNumber numberWithInt:offsetForFetchMore],@"offset",orderBy,@"order_by",str_group_by, @"group_by", nil];
    }
        
    if(_isOrganizationSwitched) // if organization is switched
    {
        NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys: [[DNGlobal sharedDNGlobal].gSwitchOrgDictionary objectForKey:@"internal_organizations"],@"internal_organizations",[[DNGlobal sharedDNGlobal].gSwitchOrgDictionary objectForKey:@"preference_organizations"],@"preference_organizations",nil];
        
        [activeOrgDict setValuesForKeysWithDictionary:dict];
    }
    
    // Making data with jsonobject
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:activeOrgDict options:kNilOptions error:nil];
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *idAndActiveOrgString=[NSString stringWithFormat:@"%@/api/userarticleclip/?settings=%@",kAPI_Host_Name,jsonString];
    // NSLog(@"idfinalstr-=%@",idAndActiveOrgString);
    NSURL *url = [NSURL URLWithString:idAndActiveOrgString]; // url
    
    // Create request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //Add cookie object here passing globally saved cookie
    [request addValue:sharedInstance.gCookie forHTTPHeaderField:@"Cookie"];
    
    articleConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(articleConnection)
    {
        isEndedLoadingFeeds = NO;
        if(isFirstTimeLoadingFeeds)
        {
            [self removeGlobeSpinner];
            [self showIndicator];
        }
    }
    else
    {
        // NSLog(@"connection creation problem");
    }
}

#pragma mark - refresh the profile table view
-(void)refreshArticlesForLoggedInUser:(UIRefreshControl *)refreshControl1
{
    if(isEndedLoadingFeeds && !isFetchingInProgress)
    {
        isRefreshing = YES;
        offsetForFetchMore = 0;
        isEndedLoadingFeeds = NO;
        isFirstTimeLoadingFeeds = NO;
        [self getDelvedArticlesOfLoggedInUser];
    }
    else
    {
        // NSLog(@"data already being fetched from server");
        [refreshControl1 endRefreshing];
    }
}
#pragma  mark - fetch more - scroll to bottom
- (void)fetchMoreFeeds
{
    if(isEndedLoadingFeeds)
    {
        // NSLog(@"fetching more feeds");
        isRefreshing = NO;
        isEndedLoadingFeeds = NO;
        isFirstTimeLoadingFeeds = NO;
        [self getDelvedArticlesOfLoggedInUser];
        
        // NSLog(@"offsetForFetchMore : %d", offsetForFetchMore);
    }
    else
    {
        [pullToRefreshManager_ tableViewReloadFinished];
    }
}

- (void)viewDidLayoutSubviews
{
    
    [super viewDidLayoutSubviews];
    
    [pullToRefreshManager_ relocatePullToRefreshView];
}


#pragma mark -
#pragma mark MNMBottomPullToRefreshManagerClient

/**
 * This is the same delegate method as UIScrollView but required in MNMBottomPullToRefreshClient protocol
 * to warn about its implementation. Here you have to call [MNMBottomPullToRefreshManager tableViewReleased]
 *
 * Tells the delegate when dragging ended in the scroll view.
 *
 * @param scrollView: The scroll-view object that finished scrolling the content view.
 * @param decelerate: YES if the scrolling movement will continue, but decelerate, after a touch-up gesture during a dragging operation.
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(isEndedLoadingFeeds && !refreshControl.isRefreshing && !isRefreshing)
        [pullToRefreshManager_ tableViewReleased];
}

/**
 * Tells client that refresh has been triggered
 * After reloading is completed must call [MNMBottomPullToRefreshManager tableViewReloadFinished]
 *
 * @param manager PTR manager
 */
- (void)bottomPullToRefreshTriggered:(MNMBottomPullToRefreshManager *)manager
{    
    isFetchingInProgress = YES;
    [self performSelector:@selector(fetchMoreFeeds) withObject:nil afterDelay:1.0f];
}

#pragma mark - scroll view delegates
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    /**
     * required in MNMBottomPullToRefreshManagerClient protocol
     * to warn about its implementation. Here you have to call [MNMBottomPullToRefreshManager tableViewScrolled]
     *
     * Tells the delegate when the user scrolls the content view within the receiver.
     *
     * @param scrollView: The scroll-view object in which the scrolling occurred.
     */
    [pullToRefreshManager_ tableViewScrolled];
}

#pragma mark - get the user info for header
-(void)getUserInfo
{
    DNGlobal *sharedInstance =[DNGlobal sharedDNGlobal];
    
    NSString *url_string = [NSString stringWithFormat:@"%@/api/user/%@", kAPI_Host_Name,gIdForSelf];
    
    NSURL *url= [NSURL URLWithString:url_string];
    // NSLog(@"url - %@", url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //Add cookie object here and passing globally saved cookie
    [request addValue:sharedInstance.gCookie forHTTPHeaderField:@"Cookie"];
    
    // Create url connection and fire request
    userDataConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //[self showIndicator];       
}

#pragma mark - prepare for seague

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"openInWebview"])
    {
        if([orderBy isEqualToString:@"most_recent"])
        {
            NSIndexPath *indexPath = [self.profileTableView indexPathForSelectedRow];
            NSInteger sectionOfSelectedRow = indexPath.section;
            NSString *keySectionDateHeadingString = [_sortedDateKeysArray objectAtIndex:sectionOfSelectedRow];
            NSArray *articlesArray = [_sections objectForKey:keySectionDateHeadingString];
            
            DNTodaysDelvedModel *objTodaysDelved= (DNTodaysDelvedModel *)[articlesArray objectAtIndex:indexPath.row];
            DNArticleViewController *articleViewController = segue.destinationViewController;
            // NSLog(@"LINK TO OPEN : %@",objTodaysDelved.linkOfArticle);
            
            articleViewController.openedArticleId= objTodaysDelved.idOfArticle;
            [articleViewController openLinkInWebview:objTodaysDelved.linkOfArticle];
        }
        else
        {
            NSIndexPath *indexPath = [self.profileTableView indexPathForSelectedRow];
            
            DNTodaysDelvedModel *objTodaysDelved= (DNTodaysDelvedModel *)[arrayCilpsAndComments objectAtIndex:indexPath.row];
            DNArticleViewController *articleViewController = segue.destinationViewController;
            // NSLog(@"LINK TO OPEN : %@",objTodaysDelved.linkOfArticle);
            
            articleViewController.openedArticleId= objTodaysDelved.idOfArticle;
            [articleViewController openLinkInWebview:objTodaysDelved.linkOfArticle];
        }
    }
}

-(void)setUserName:(NSString*)name andImage:(NSData*)userImageData
{
    [profileImage setImage:[UIImage imageWithData:userImageData]];
    [userName setText:name];
}



- (void)showHideDropdownList
{

    if(_tableViewDropDown.hidden)
    {
        _tableViewDropDown.hidden=NO;
        maskView.hidden=NO;
        [UIView animateWithDuration:0.3f
                              delay:0.0
                            options: 0
                         animations:^{
                             _tableViewDropDown.frame = CGRectMake(0, 0, self.view.frame.size.width, kRowHeight*[arrayList count]);
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
                             _tableViewDropDown.frame = CGRectMake(0, -kRowHeight*[arrayList count], self.view.frame.size.width, kRowHeight*[arrayList count]);
                         }
                         completion:^(BOOL finished){
                             _tableViewDropDown.hidden=YES;
                             maskView.hidden=YES;
                         }];


    }
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
    italicStyle.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:15.0];
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


// Adjust the size of a label
-(UILabel *)adjustSizeOfLabel:(UILabel *)lbl
{
    CGSize maximumLabelSize = CGSizeMake(270,FLT_MAX);//270 is the height of coreTextView in storyboard
    
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


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView.tag == kDropDownTag)
        return 1;
    else
    {
        if([orderBy isEqualToString:@"most_recent"])
            return [_sortedDateKeysArray count]; // will hold the array of dates (section dates that are displayed in profile table as today , yestersday ... etc)
        else
            return 1;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(tableView.tag == kDropDownTag)
    {
        return 0.0;
    }
    else
    {
        if([orderBy isEqualToString:@"most_recent"])
            return 36.0;
    }
    return 0.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(tableView.tag == kDropDownTag)
    {
        return [arrayList count];
    }
    else
    {
         if([orderBy isEqualToString:@"most_recent"])
         {
            NSString *str = [_sortedDateKeysArray objectAtIndex:section];
            NSArray *arr = [_sections objectForKey:str];
            
            return [arr count];
         }
        else
        {
            return [arrayCilpsAndComments count];
        }
    }
}
// to set height of each row
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag != kDropDownTag)
    {
        NSAttributedString * strDelvesAndComments;
        if([orderBy isEqualToString:@"most_recent"])
        {
            NSString *str = [_sortedDateKeysArray objectAtIndex:indexPath.section];
            
            NSArray *arr = [_sections objectForKey:str];
            DNTodaysDelvedModel *objTodayDelve = (DNTodaysDelvedModel *)[arr objectAtIndex:indexPath.row];
            
            strDelvesAndComments = [[NSAttributedString alloc] initWithString:[DNGlobal createDelvesAndCommentString:objTodayDelve.clipsOfArticleArray :objTodayDelve.commentsOfArticleArray]];
        }
        else
        {
            DNTodaysDelvedModel *objTodayDelve = (DNTodaysDelvedModel *)[arrayCilpsAndComments objectAtIndex:indexPath.row];
            
            strDelvesAndComments = [[NSAttributedString alloc] initWithString:[DNGlobal createDelvesAndCommentString:objTodayDelve.clipsOfArticleArray :objTodayDelve.commentsOfArticleArray]];
        }
        
        return [self getHeightOfSharedAndCommentedCoreText:strDelvesAndComments]+30;

    }
    return 44.0;
}

-(float)getHeightOfSharedAndCommentedCoreText : (NSAttributedString *)strDelvesAndComments
{
    
    NSString *strTemp = [NSString stringWithFormat:@"%@", strDelvesAndComments];
    
    strTemp = [[strTemp componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet] ] componentsJoinedByString:@""];
    
    strTemp = [strTemp stringByReplacingOccurrencesOfString:@"<_link>" withString:@""];
    strTemp = [strTemp stringByReplacingOccurrencesOfString:@"</_link>" withString:@""];
    
//    NSLog(@"strTemp : %@ length : %d",strTemp, strDelvesAndComments.length);
    CGSize size_temp;
    
    size_temp = [strTemp sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:13.0]
                    constrainedToSize:CGSizeMake(280.0, CGFLOAT_MAX)
                        lineBreakMode:NSLineBreakByCharWrapping];
    
//     NSLog(@"height of string : %f", size_temp.height);
    
    return size_temp.height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(tableView.tag == kDropDownTag)
    {
        static NSString *CellIdentifier = @"dropdownCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:CellIdentifier] ;
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
            [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15]];
            cell.textLabel.textAlignment= NSTextAlignmentRight;
        }
        cell.textLabel.text =[NSString stringWithFormat:@"%@       ",[arrayList objectAtIndex:indexPath.row]];
    }
    else
    {
        NSString *CellIdentifier = nil;
        CellIdentifier=@"ProfileCellWithComment"; //  // ProfileCellWithoutComment
        if(SYSTEM_VERSION_GREATER_THAN(@"6.0"))
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        else
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:CellIdentifier] ;
        }
        if([orderBy isEqualToString:@"most_recent"])
        {
            NSString *str = [_sortedDateKeysArray objectAtIndex:indexPath.section];
            
            NSArray *arr = [_sections objectForKey:str];
            DNTodaysDelvedModel *objTodayDelve = (DNTodaysDelvedModel *)[arr objectAtIndex:indexPath.row];
            
            ((UILabel *)[cell viewWithTag:101]).text = objTodayDelve.titleOfArticle;
            ((UILabel *)[cell viewWithTag:101]).font = [UIFont fontWithName:@"Bitter-Regular" size:20];
            
            NSString * strDelvesAndComments = [DNGlobal createDelvesAndCommentString:objTodayDelve.clipsOfArticleArray :objTodayDelve.commentsOfArticleArray];            
            
            // core text view for profile linking and styles
            _coreTextView = (FTCoreTextView *)[cell viewWithTag:102];
            // set text
            [_coreTextView setText:strDelvesAndComments];
            // set styles
            [_coreTextView addStyles:[self coreTextStyle]];
            // set delegate
            [_coreTextView setDelegate:self];
            
            [_coreTextView fitToSuggestedHeight];
            
        }
        else
        {
            DNTodaysDelvedModel *objTodayDelve = (DNTodaysDelvedModel *)[arrayCilpsAndComments objectAtIndex:indexPath.row];
            ((UILabel *)[cell viewWithTag:101]).text = objTodayDelve.titleOfArticle;
            ((UILabel *)[cell viewWithTag:101]).font = [UIFont fontWithName:@"Bitter-Regular" size:20];
            
            NSString * strDelvesAndComments = [DNGlobal createDelvesAndCommentString:objTodayDelve.clipsOfArticleArray :objTodayDelve.commentsOfArticleArray];
            
            // core text view for profile linking and styles
            _coreTextView = (FTCoreTextView *)[cell viewWithTag:102];
            // set text
            [_coreTextView setText:strDelvesAndComments];
            // set styles
            [_coreTextView addStyles:[self coreTextStyle]];
            // set delegate
            [_coreTextView setDelegate:self];
            
            [_coreTextView fitToSuggestedHeight];
        }
        
        UIView *bg = [[UIView alloc] initWithFrame:cell.bounds];
        bg.backgroundColor = [UIColor colorWithRed:0.980 green:0.988 blue:0.984 alpha:1];
        bg.layer.borderColor = [UIColor colorWithRed:0.827 green:0.827 blue:0.835 alpha:1].CGColor;
        bg.layer.borderWidth = kCellBorderWidth;
//        bg.layer.cornerRadius= kCellBorderRadius;
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

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(tableView.tag != kDropDownTag)
    {
        // Only show title if most recent articles are to be shown
        if([orderBy isEqualToString:@"most_recent"])
        {
            UIView *headerView= [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 36)];
            UILabel *headerLabel=[[UILabel alloc] initWithFrame:CGRectMake(kHeaderLabelOffsetX, kHeaderLabelOffsetY, tableView.frame.size.width, kHeaderLabelHeight)];
            headerLabel.backgroundColor = [UIColor clearColor];
            NSString *headerDate = [_sortedDateKeysArray objectAtIndex:section];
            
            // get today's date string and compare it
            NSDate *currentDate = [[NSDate alloc] init];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd"];// @"yyyy-MM-dd"
            
            // ******* now compare this date with today's (current) date and yesterday's date
            NSString *localDateString = [dateFormatter stringFromDate:currentDate];
            if([localDateString isEqualToString:headerDate])
                headerDate = @"Today";
            
            // get yesterday's date string and compare it 
            NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
            [componentsToSubtract setDay:-1];
            NSDate *yesterdayDate = [[NSCalendar currentCalendar] dateByAddingComponents:componentsToSubtract toDate:[NSDate date] options:0];
            NSString *yesterdayDateString = [dateFormatter stringFromDate:yesterdayDate];
            if([yesterdayDateString isEqualToString:headerDate])
                headerDate = @"Yesterday";
            
            // if date string is not equal to both yesterday or today string
            if(![headerDate isEqualToString:@"Today"] && ![headerDate isEqualToString:@"Yesterday"])
            {
                NSDate *date_temp = [dateFormatter dateFromString:headerDate];
                
                // now convert this date into default device date format
                NSDateFormatter *dateFormatter_temp = [[NSDateFormatter alloc ] init];
                [dateFormatter_temp setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter_temp setTimeStyle:NSDateFormatterNoStyle];
                
                headerDate = [dateFormatter_temp stringFromDate:date_temp];
                
                
            }
            
            [headerLabel setText:headerDate]; // apply in label now
            
            // apply all this into the header view
            headerLabel.font =   [UIFont fontWithName:@"HelveticaNeue-Bold" size:15]; // BOLD
            headerLabel.textColor=[UIColor colorWithRed:0.549 green:0.549 blue:0.549 alpha:1];
            [headerView addSubview:headerLabel];
            return headerView;
        }
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag == kDropDownTag)
    {
        if(indexPath.row == 3)
        {
            NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAPI_Host_Name,@"/ajax/logout/"]]
                                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                   timeoutInterval:60];
            [postRequest setHTTPMethod:@"POST"];
            [postRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

            [postRequest addValue:[DNGlobal sharedDNGlobal].gCSRF_Token forHTTPHeaderField:@"X-CSRFToken"];
            //Add cookie object here passing globally saved cookie

            // Creating a cookie which contains csrf token + cookie.
            [postRequest addValue:[NSString stringWithFormat:@"csrftoken=%@;sessionid=%@",[DNGlobal sharedDNGlobal].gCSRF_Token,[DNGlobal sharedDNGlobal].gCookieInPostApi] forHTTPHeaderField:@"Cookie"];
            
            // NSLog(@"header of request : %@ ", postRequest.allHTTPHeaderFields);
            // NSLog(@"cookie session id : %@ ", [DNGlobal sharedDNGlobal].gCookieInPostApi);
            
            //Set to NO so that each time cookie will be generated
            [postRequest setHTTPShouldHandleCookies:NO];
            // hit login api with the specified request
            logoutConnection = [[NSURLConnection alloc] initWithRequest:postRequest delegate:self];
            
            //Start spinner
            if(logoutConnection)
            {
                logoutDataReceived = [[NSMutableData alloc] init];
                [self showIndicator];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedOutLastTime"];
                [[NSNotificationCenter defaultCenter] postNotificationName:kPOSTNOTIFICATION_USER_LOGGEDOUT object:nil userInfo:nil];
            }
            else
            {
                // NSLog(@"logout connection creation error");
            }
            

        }
        else // @"Most Recent",@"Most Commented",@"Most Delved",@"Log Out", nil];
        {
            /* Tom: To sort by other fields, we have added a parameter called order_by, which can be set to ‘most_recent’, ‘most_comments’, or ‘most_clips’, which sort by recency, comments, and Delves, respectively. */
            if(indexPath.row == 0)
                orderBy = @"most_recent";
            else if(indexPath.row == 1)
                orderBy = @"most_comments";
            else if(indexPath.row == 2)
                orderBy = @"most_clips";
            
            // *******************************************************************************************************************************
             // ******** end refreshing controller and fetch more controller so that UI remains undisturbed
            // *******************************************************************************************************************************
            
            [refreshControl endRefreshing];
            [pullToRefreshManager_ tableViewReloadFinished];
            
            // also disable connection
            if(articleConnection)
            {
                [articleConnection cancel];
                articleConnection = nil;
            }
            // *******************************************************************************************************************************
            
            isRefreshing = YES;
            isFirstTimeLoadingFeeds = YES; // we need new feeds for most_comments and most_delved and consider it if we are loading them first time
            
            // reload the table so that data of changed sorting parameter displays again , if you dont do this there will be crash
            // As tables types are diffrent in case of 'most_recent' & 'most_comments/most_clips' parameters
            [self.profileTableView reloadData];
            
            // call api again for sorted articles
            [self getDelvedArticlesOfLoggedInUser];
            
            [DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:[arrayList objectAtIndex:indexPath.row]];
            
            // if drop down is displayed, disappear it again

        }
        if(!_tableViewDropDown.hidden)
            [self showHideDropdownList];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

#pragma mark - post notification for org switch
-(void)organizationSwitchNotification: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_SWITCH_ORG])
    {
        // NSLog(@"notification receieved in  profile VC : %@ ---- ", notification.userInfo);
        
        _isOrganizationSwitched = YES;
    }
}

-(void)refreshFeedsNotificationReceived: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_REFRESH_FEEDS])
    {
        // NSLog(@"refresh feeds in --  Profile VC: ");
        
        // refresh feeds after idle timeout
        offsetForFetchMore = 0;
        isEndedLoadingFeeds = NO;
        isFirstTimeLoadingFeeds = YES; // consider loading feeds first time , that will enable globe spinner too
        [self getDelvedArticlesOfLoggedInUser];
    }
}

-(void)delveOrCommentNotificationReceived: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_DELVE_OR_COMMENT])
    {
        // NSLog(@"Delve/Comment notification called ---  in Tab 4: ");
//        // NSLog(@"user info is : %@", notification.userInfo);
        
        if([orderBy isEqualToString:@"most_recent"])
        {
            for (NSString *key in _sortedDateKeysArray)
            {
                NSArray *arr = [_sections objectForKey:key];
                // now change the article (if its delved or commented), loop through the whole saved response
                for(DNTodaysDelvedModel *aFeed in arr) // looping through articles
                {
                    if([[NSString stringWithFormat:@"%@", aFeed.idOfArticle] isEqualToString:[NSString stringWithFormat:@"%@",[notification.userInfo objectForKey:@"delvedArticleId"]]])
                    {
                        // NSLog(@"article matched ..TAb 4.. now change it");
                        aFeed.clipsOfArticleArray = [notification.userInfo  objectForKey:@"clips"];
                        aFeed.commentsOfArticleArray = [notification.userInfo  objectForKey:@"comments"];
                        break;
                    }
                }
            }
        }
        else
        {
            for(DNTodaysDelvedModel *aFeed in arrayCilpsAndComments) // looping through articles
            {
                if([[NSString stringWithFormat:@"%@", aFeed.idOfArticle] isEqualToString:[NSString stringWithFormat:@"%@",[notification.userInfo objectForKey:@"delvedArticleId"]]])
                {
                    // NSLog(@"article matched ..TAb 4.. now change it");
                    aFeed.clipsOfArticleArray = [notification.userInfo  objectForKey:@"clips"];
                    aFeed.commentsOfArticleArray = [notification.userInfo  objectForKey:@"comments"];
                    break;
                }
            }
        }
        
        // now relaod that
        [self.profileTableView reloadData];
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
        if(articleConnection)
        {
            [articleConnection cancel];
            articleConnection = nil;
        }
        if(userDataConnection)
        {
            [userDataConnection cancel];
            userDataConnection = nil;
        }
    }
}



#pragma mark - show indicator

//Method to show activityindicator on view
-(void)showIndicator
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"delve_globe" withExtension:@"gif"];
    self.spinnerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 200, 40, 40)];
    self.spinnerImageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    [self.view addSubview:self.spinnerImageView];

    // also disable interaction
    [self.profileTableView setUserInteractionEnabled:NO];

}
-(void)removeGlobeSpinner
{
    if(self.spinnerImageView!=nil)
    {
        [self.spinnerImageView removeFromSuperview];
        self.spinnerImageView = nil;
    }
    
    [self.profileTableView setUserInteractionEnabled:YES];
}

#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    _responseData = [[NSMutableData alloc] init];
    if(connection == articleConnection)
    {
        articleData= [[NSMutableData alloc]init];
    }
    else if(connection == userDataConnection)
    {
        userData= [[NSMutableData alloc] init];
    }
    else if([connection isEqual:logoutConnection])
    {
        [logoutDataReceived setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
//    [_responseData appendData:data];
    
     if(connection == articleConnection)
    {
        [articleData appendData:data];
    }
     else if(connection == userDataConnection)
     {
         [userData appendData:data];
     }
     else if([connection isEqual:logoutConnection])
     {
         [logoutDataReceived appendData:data];
     }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    if(!self.profileTableView.userInteractionEnabled)
    {
        [self.profileTableView setUserInteractionEnabled:YES];
    }
    if(connection == articleConnection)
    {
        NSString* responseString = [[NSString alloc] initWithData:articleData encoding:NSUTF8StringEncoding];
        NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding]
                                                                    options: NSJSONReadingMutableContainers error:nil];
        
//        // NSLog(@"response : %@", responseJSON);
        
        if(responseJSON != (id)[NSNull null])
        {            
            NSArray *clipList= [responseJSON objectForKey:@"clip_list"];
            
            
            // initialize it so that each time it holds the new data
            tempDictSections = [[NSMutableDictionary alloc] init]; // temprary dictionary to hold data for _sections dict .. IMP
            tempArrayClipsAndComments = [[NSMutableArray alloc] init];// temporary array to hold data for most clips and delved articles
            
            
            if(isRefreshing)
            {
                _sortedDateKeysArray = [[NSMutableArray alloc] init];
                offsetForFetchMore = clipList.count; // assign the offset parameter for next time fetch
            }
            else
                offsetForFetchMore += clipList.count; // increase (update) the offset parameter for fetch more logic

            if([orderBy isEqualToString:@"most_recent"])
            {
                // re- initialize dateKeys array of table (sections heading) when refreshing
                // first create an array of date keys 
                for(NSDictionary* dict in clipList)
                {
                    
                    if((dict != (id)[NSNull null]) && [dict objectForKey:@"clips"]) // clips must be present
                    {
                        NSString *dateStr = [dict objectForKey:@"date"];
                        if(![[tempDictSections allKeys] containsObject:dateStr])
                        {
                            NSMutableArray *arr = [[NSMutableArray alloc] init];
                            [tempDictSections setValue:arr forKey:dateStr]; // an empty array for all keys (keys are dates)
                            [_sortedDateKeysArray addObject:dateStr]; // an array of date keys
                        }
                    }
                }
                // remove duplicate keys and maintain order
                NSMutableArray *uniqueItems = [NSMutableArray array];
                for (id item in _sortedDateKeysArray)
                    if (![uniqueItems containsObject:item])
                        [uniqueItems addObject:item];
                _sortedDateKeysArray = [NSMutableArray arrayWithArray:uniqueItems];
                
                // fetch articles by date
                for (NSDictionary *dict in clipList)
                {
                    DNTodaysDelvedModel *objTodaysDelved = [[DNTodaysDelvedModel alloc] init];
                    if((dict != (id)[NSNull null]) && [dict objectForKey:@"clips"]) // don't add any object if clips array in json is nil or 0
                    {
                        // ********** if clips available then add it, so that it can be used to display delves
                        objTodaysDelved.clipsOfArticleArray = [NSMutableArray arrayWithArray: [dict objectForKey:@"clips"]];
                        objTodaysDelved.clipsOfArticleArray = [DNGlobal removeDuplicateDelvesFromClipsArray:objTodaysDelved.clipsOfArticleArray];
                        
                        // add comments array too 
                        if([dict objectForKey:@"comments"] != nil)
                        {
                            if(!objTodaysDelved.commentsOfArticleArray)
                                objTodaysDelved.commentsOfArticleArray = [[NSMutableArray alloc] init];
                            objTodaysDelved.commentsOfArticleArray = [NSMutableArray arrayWithArray:[dict objectForKey:@"comments"]];
                        }
                        // also add comments from discussions array
                        NSDictionary *discussion= [dict objectForKey:@"discussions"];
                        if(discussion )
                        {
                            if(!objTodaysDelved.commentsOfArticleArray)
                                objTodaysDelved.commentsOfArticleArray = [[NSMutableArray alloc] init];
                            [objTodaysDelved.commentsOfArticleArray addObject:discussion];
                        }
                        
                        NSDictionary *articleDictionary = [dict objectForKey:@"article"]; // now add article array items needed
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
                        }
                        [[tempDictSections objectForKey:[dict objectForKey:@"date"]] addObject:objTodaysDelved];
                    }
                }
                
                // now add enteries according to fetch more or refresh parameter
                if(!isRefreshing) // fetch more
                {
                    [_sections addEntriesFromDictionary:tempDictSections];
                }
                else // refresh (on first time load isRefreshing will be yes)
                {
                    if(!_sections)
                    {
                        _sections = [[NSMutableDictionary alloc] init];
                    }
                    else
                    {
                        [_sections removeAllObjects];
                    }
                    [_sections addEntriesFromDictionary:tempDictSections];
                }
            }
            else // for most_delve , most_comments
            {
                for (NSDictionary *dict in clipList)
                {
                    if((dict != (id)[NSNull null]) && [ dict objectForKey:@"clips"])// if object is has some clips
                    {
                        DNTodaysDelvedModel *objTodaysDelved = [[DNTodaysDelvedModel alloc] init];

                        // if clips available then add it, so that it can be used to display delves
                        objTodaysDelved.clipsOfArticleArray = [NSMutableArray arrayWithArray: [dict objectForKey:@"clips"]];
                        objTodaysDelved.clipsOfArticleArray = [DNGlobal removeDuplicateDelvesFromClipsArray:objTodaysDelved.clipsOfArticleArray];
                        
                        // add comments too
                        if([dict objectForKey:@"comments"] != nil)
                        {
                            if(!objTodaysDelved.commentsOfArticleArray)
                                objTodaysDelved.commentsOfArticleArray = [[NSMutableArray alloc] init]; 
                            objTodaysDelved.commentsOfArticleArray = [NSMutableArray arrayWithArray:[dict objectForKey:@"comments"]];
                        }
                        // also add comments from discussions array
                        NSDictionary *discussion= [dict objectForKey:@"discussions"];
                        if(discussion )
                        {
                                if(!objTodaysDelved.commentsOfArticleArray)
                                    objTodaysDelved.commentsOfArticleArray = [[NSMutableArray alloc] init];
                                [objTodaysDelved.commentsOfArticleArray addObject:discussion];
                        }
                        
                        NSDictionary *articleDictionary = [dict objectForKey:@"article"];
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
                            // also you can fetch imager of the article if needed
                        }
                        [tempArrayClipsAndComments addObject:objTodaysDelved];
                    }
                }

                // now add enteries according to fetch more or refresh parameter
                if(!isRefreshing) // fetch more
                {
                    [arrayCilpsAndComments addObjectsFromArray:tempArrayClipsAndComments];
                }
                else // refresh (on first time load isRefreshing will be yes)
                {
                    // if the feed list view has been aksed to refresh then reinitialize the array
                    if(!arrayCilpsAndComments)
                    {
                        arrayCilpsAndComments = [[NSMutableArray alloc] init];
                    }
                    else
                    {
                        [arrayCilpsAndComments removeAllObjects];
                    }
                    [arrayCilpsAndComments addObjectsFromArray:tempArrayClipsAndComments];
                }
            }
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"No Response, Please try again"
                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
        if(_isOrganizationSwitched)// if organization switched causes feed load then next time must be normal load
        {
            _isOrganizationSwitched = NO;
        }
    
        
        
        [self removeGlobeSpinner];
        
        
        // *******************************************************************************************************************************
        /*
         UI FIX : for fetch more + refresh 
         Description : always first reload table and then call [refreshControl endRefreshing]  &   [pullToRefreshManager_ tableViewReloadFinished];
         else fetch abd refresh control symbol will appear over the table or may be in the middle of table
         */
        // *******************************************************************************************************************************
        [self.profileTableView reloadData];

        [refreshControl endRefreshing];
        [pullToRefreshManager_ tableViewReloadFinished];
        // *******************************************************************************************************************************

        isEndedLoadingFeeds = YES;
        isFetchingInProgress = NO;
        isRefreshing = NO;
    }
    else if(connection == userDataConnection)// Fetching response of userData api after login
    {
        // NSLog(@"USER DATA didReceiveData");
        
        NSError *requestError;
         NSLog(@"Response: %@",[[NSString alloc] initWithData:userData encoding:NSUTF8StringEncoding]);
        
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:userData
                              options:kNilOptions
                              error:&requestError];
        if(json != (id)[NSNull null])
        {
            
            //Downloading image and setting it to imageView
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *ImageURL =[NSString stringWithFormat:@"http:%@",[json objectForKey:@"image"]];
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:ImageURL]];
                NSString* userNameForProfile= [json objectForKey:@"name"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    self.profileImage.image = [UIImage imageWithData:imageData];
                    self.userName.text = userNameForProfile;
                    
                });
            });
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"No Response, Please try again"
                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    else if([connection isEqual:logoutConnection])
    {
        // NSLog(@"logout data received : ");
        NSError *requestError;
//        // NSLog(@"Response: %@",[[NSString alloc] initWithData:logoutDataReceived encoding:NSUTF8StringEncoding]);
        
        NSString *responseString = [[NSString alloc] initWithData:logoutDataReceived encoding:NSUTF8StringEncoding];
        
        if(responseString.length != 0)
        {
            NSDictionary* json = [NSJSONSerialization
                                  JSONObjectWithData:logoutDataReceived
                                  options:kNilOptions
                                  error:&requestError];
            // NSLog(@"json of logout: %@", json);
            [[[self parentViewController] parentViewController].navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

    
    if(!self.profileTableView.userInteractionEnabled)
    {
        [self.profileTableView setUserInteractionEnabled:YES];
    }

    // NSLog(@"didFailWithError --------");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error in connection, Please try again"
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [self removeGlobeSpinner];

//    if(refreshControl.isRefreshing)
        [refreshControl endRefreshing];
    [pullToRefreshManager_ tableViewReloadFinished];
    
    isEndedLoadingFeeds = YES;
    isFetchingInProgress = NO;
    isRefreshing = NO;
}


@end
