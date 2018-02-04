//
//  DNConversationViewController.m
//  Delve
//
//  Created by Atul Khatri on 13/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNConversationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "DNGlobal.h"
#import "DNArticleViewController.h"
#import "UIImage+animatedGIF.h"
#import "Constants.h"
#import "DNProfileViewController.h"

#import "MNMBottomPullToRefreshManager.h"


#define kHeaderLabelOffsetX 16
#define kHeaderLabelOffsetY 16
#define kHeaderLabelHeight 49
#define kHeaderViewHeight 54

#define kCellHeight 85.0f

@interface DNConversationViewController()
{
    NSDictionary *dictOrganization; // dict for organizations of logged in user
    NSMutableData *conversationData; // received data from conversation feed api , store in here
    BOOL   isRefreshing;
    
    /*Refer API Doc: Set ‘offset’ to the number of clips that have already been displayed and the server will return more clips starting from that number.
     So, for instance, if you have already displayed 20 clips and want to get the next batch, set offset:20 in the JSON.
     */
    int offsetForFetchMore;
    
    NSMutableArray *conversationFeedArray;
    UIRefreshControl *refreshControl;// refresh control to refresh the whole view and changes the view id , (fetch more is diffrent and view id remains same)
    NSInteger generatedRandomNumber;// use to generate the random view id
    
    // to check when to show spinner
    BOOL isFirstTimeLoadingFeeds;
    BOOL isEndedLoadingFeeds;
    
    /**
     * Pull to refresh manager
     */
    MNMBottomPullToRefreshManager *pullToRefreshManager_;
    BOOL isFetchingInProgress; // a bool for fetch operation in progress or not
    
    // link click on the user name
    NSString * urlForId;
    
    // Switch organization parameters
    NSURLConnection *connectionSwitchOrg;
    NSMutableData *dataSwitchOrganization;
    NSString *defaultOrganizationName;
    NSInteger selectedOrganizationID; // store the selected org Id
    
}

// String to hold whether user or organisation
// As required in Api
@property (strong, nonatomic) NSString *typeString;
@property (nonatomic, retain) UITableView *tableViewDropDown;

@end

@implementation DNConversationViewController


@synthesize tableViewDropDown = _tableViewDropDown;
@synthesize converstaionCellsArray = _conversationCellsArray;
@synthesize conversationConnection = _conversationConnection;
@synthesize conversationTableView = _conversationTableView;
@synthesize spinnerView= _spinnerView;
@synthesize spinnerImageView;
@synthesize alphaMaskView = _alphaMaskView;

@synthesize isOrganizationSwitched = _isOrganizationSwitched;

@synthesize typeString = _typeString;



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
    
    // Drop down list for oraganizations list from api/organization
    dictOrganization =[[NSDictionary alloc] initWithDictionary:[DNGlobal sharedDNGlobal].userOrganizations];
    _tableViewDropDown = [[UITableView alloc] initWithFrame:
                          CGRectMake(0, -kRowHeight*[[dictOrganization objectForKey:@"organizations"] count], self.view.frame.size.width,
                                     kRowHeight*[[dictOrganization objectForKey:@"organizations"] count])
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
    
    // Conversation cells array initialization
    _conversationCellsArray = [[NSMutableArray alloc] init];
    
    ////************* Method to fetch data
    isRefreshing = YES;
    offsetForFetchMore = 0; // initialy set it to 0
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshConversationFeeds:) forControlEvents:UIControlEventValueChanged];
    [_conversationTableView addSubview:refreshControl];
    
    isFirstTimeLoadingFeeds = YES; // to show globe spinner
    ////************* set the end refreshing parameter initialy to no as feeds would get load in view didload
    isEndedLoadingFeeds = NO;
    
    //************* pull to refresh from bottom or say fetch more 
    pullToRefreshManager_ = [[MNMBottomPullToRefreshManager alloc] initWithPullToRefreshViewHeight:60.0f tableView:_conversationTableView withClient:self];
    isFetchingInProgress = NO; // set it to no initially , we are not fetching
    
    //************* //************* set intial value of selected org to 0
    selectedOrganizationID = 0;
    
    [self getConversationArticles]; // to get articles for conversation
    
    ////************* notification when organization is switched
    _isOrganizationSwitched = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(organizationSwitchedNotification:) name:kPOSTNOTIFICATION_SWITCH_ORG object:nil];
    //refresh feeds notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFeedsNotificationReceived:) name:kPOSTNOTIFICATION_REFRESH_FEEDS object:nil];
    //Delve or comment on article notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delveOrCommentNotificationReceived:) name:kPOSTNOTIFICATION_DELVE_OR_COMMENT object:nil];
    // user logged out
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedoutNotificationReceived:) name:kPOSTNOTIFICATION_USER_LOGGEDOUT object:nil];
    
}

-(void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        isRefreshing = YES; // must be set to true according to API clarification
        
        [self getConversationArticles];
        _isOrganizationSwitched = NO;// only call this api one time (if user keeps switching between tabs)
    }
    
    [_tableViewDropDown reloadData]; // reload organization data
    
    [DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:defaultOrganizationName];
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

-(NSInteger )generateRandomNumber
{
    NSInteger minValue = 0;
    NSInteger maxValue = 10000000;
    NSInteger randomNumber = arc4random() % (maxValue - minValue)+minValue;
    return randomNumber;
}
#pragma mark - Globe spinner
//Method to show activityindicator on view
-(void)showIndicator
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"delve_globe" withExtension:@"gif"];
    self.spinnerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 200, 40, 40)];
    self.spinnerImageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    self.spinnerImageView.hidden = NO;
    [self.view addSubview:self.spinnerImageView];
    [self.view bringSubviewToFront:self.spinnerImageView];
    
    // also disable the tableview interaction 
    [_conversationTableView setUserInteractionEnabled:NO];
}

-(void)removeGlobeSpinner
{
    if(self.spinnerImageView!=nil)
    {
        [self.spinnerImageView removeFromSuperview];
        self.spinnerImageView = nil;
    }
    
    // enable interaction with table view again
    [_conversationTableView setUserInteractionEnabled:YES];
}

#pragma mark - pull to refresh

- (void)refreshConversationFeeds:(UIRefreshControl *)refreshControl1
{
    if(isEndedLoadingFeeds && !isFetchingInProgress)
    {
        isRefreshing = YES;
        offsetForFetchMore = 0;
        isFirstTimeLoadingFeeds = NO;
        isEndedLoadingFeeds = NO;
        [self getConversationArticles];
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
        isFirstTimeLoadingFeeds = NO;
        isEndedLoadingFeeds = NO;
        [self getConversationArticles];
        
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
    if(isEndedLoadingFeeds && !refreshControl.isRefreshing)
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

#pragma mark - hit conversation article api
// Fetch and render articles from /api/article/
-(void)getConversationArticles
{
    DNGlobal *sharedInstance=[DNGlobal sharedDNGlobal];
    //Fetching active organisation from global userorganisation.
    NSString *userActiveOrg = [sharedInstance.userOrganizations objectForKey:@"active_organization"];
    
    // pass the organization id if user has not selected manually any other organization
    NSString *org_id = [[NSString alloc] init];
    if(selectedOrganizationID == 0)
        org_id = userActiveOrg;
    else
        org_id = [NSString stringWithFormat:@"%d", selectedOrganizationID];
        
    //Here Basically we are passing typeString as organisation
    _typeString = @"organization";
    NSString *str_group_by = @"none";
    
    NSMutableDictionary *activeOrgDict;
    if(isRefreshing) // pulling table view to refresh data
    {
        // Creating Dictionary for extra data which should be passed with URL
        activeOrgDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:userActiveOrg,@"active_organization",_typeString, @"type",
                         org_id,@"id",@"most_recent",@"order_by",str_group_by, @"group_by",[NSNumber numberWithInt:offsetForFetchMore],@"offset", nil];
    }
    else // fetching more data scrolling tableview to bottom
    {
        activeOrgDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:userActiveOrg,@"active_organization",_typeString,
                         @"type",org_id,@"id", [NSNumber numberWithInt:offsetForFetchMore],@"offset",@"most_recent",@"order_by",str_group_by, @"group_by", nil];
    }
    
    if(_isOrganizationSwitched)
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
    
    //********************* Create connection for conversation feeds **************************
    _conversationConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(_conversationConnection)
    {

        // Create the NSMutableData to hold the received data.
        conversationData = [[NSMutableData data] init];
        
        if(isFirstTimeLoadingFeeds)
        {
            // remove spinner if there are any
            [self removeGlobeSpinner];
            [self showIndicator];
            
        }
        
    }
    else
    {
        // Inform the user that the connection failed.
        // NSLog(@"CONNECTION CREATION FAILED FOR CONVERSATION ARTICLES LIST: ====>>>>>>");
    }
}

#pragma mark - show dropdown list for conversation
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
                             _tableViewDropDown.frame = CGRectMake(0, -kRowHeight*[[dictOrganization objectForKey:@"organizations"] count], self.view.frame.size.width, kRowHeight*[[dictOrganization objectForKey:@"organizations"] count]);
                         }
                         completion:^(BOOL finished){
                             _tableViewDropDown.hidden=YES;
                             _alphaMaskView.hidden = YES;
                         }];
    }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if([connection isEqual:_conversationConnection])
    {
        [conversationData setLength:0];
    }
    else
    {
        [dataSwitchOrganization setLength:0];
    }
    isEndedLoadingFeeds = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if([connection isEqual:_conversationConnection])
    {
        [conversationData appendData:data];
    }
    else
    {
        [dataSwitchOrganization appendData:data];
    }
    isEndedLoadingFeeds = NO;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // enable intercation on view
    if(isFirstTimeLoadingFeeds)
    {        
        [_conversationTableView setUserInteractionEnabled:YES];
    }
    [self removeGlobeSpinner];
    // The request is complete and data has been received
    if(connection== _conversationConnection)
    {
        NSString* responseString= [[NSString alloc] initWithData:conversationData encoding:NSUTF8StringEncoding];
        
        NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];

        NSArray *clipList= [responseJSON objectForKey:@"clip_list"];
        // NSLog(@"number of objects in ARTICLE LIST: %@",clipList );
        
        // if in refresh or first time load (also considers switch org)
        if(isRefreshing)
        {
            offsetForFetchMore = clipList.count; // assign the offset parameter for next time fetch
        }
        else
            offsetForFetchMore += clipList.count; // increase (update) the offset parameter for fetch more logic
        
        if(responseJSON != (id)[NSNull null])
        {
            //array to hold the feeds retrieved from api
            conversationFeedArray = [[NSMutableArray alloc] init];
         // ***************************************
         //Changing API and therefore changing parsing technique also
            for (NSDictionary *dict in clipList)
            {
                if([ dict objectForKey:@"clips"])// if object is has some clips
                {
                    DNConversationCell* conversationObject = [[DNConversationCell alloc] init];
                    
                    // if clips available then add it, so that it can be used to display delves
                    conversationObject.personsCliped = [NSMutableArray arrayWithArray: [dict objectForKey:@"clips"]];
                    conversationObject.personsCliped = [DNGlobal removeDuplicateDelvesFromClipsArray:conversationObject.personsCliped];
                    
                    // add comments too
                    if([dict objectForKey:@"comments"] != nil)
                    {
                        if(!conversationObject.personsCommented)
                            conversationObject.personsCommented = [[NSMutableArray alloc] init];
                        conversationObject.personsCommented = [NSMutableArray arrayWithArray:[dict objectForKey:@"comments"]];
                    }
                    // also add comments from discussions array
                    NSDictionary *discussion= [dict objectForKey:@"discussions"];
                    if(discussion )
                    {
                        if(!conversationObject.personsCommented)
                            conversationObject.personsCommented = [[NSMutableArray alloc] init];
                        [conversationObject.personsCommented addObject:discussion];
                    }
                    
                    NSDictionary *articleDictionary = [dict objectForKey:@"article"];
                    if(articleDictionary!=nil)
                    {
                        NSDictionary* publication= [dict objectForKey:@"publication"];
                        conversationObject.publicationSourceIconURL = [NSString stringWithFormat:@"http:%@", [publication objectForKey:@"image_url"] ];
                        conversationObject.publicationSourceName = [publication objectForKey:@"name"];
                        
                        NSString *tempTitle = [articleDictionary objectForKey:@"title"];
                        if(tempTitle!=nil)
                            conversationObject.heading = tempTitle;
                        NSString *tempLink = [articleDictionary objectForKey:@"link"];
                        if(tempLink!=nil)
                            conversationObject.articleLink = tempLink;
                        NSString *tempId = [articleDictionary objectForKey:@"id"];
                        if(tempId!=nil)
                            conversationObject.articleId = tempId;
                        // also you can fetch imager of the article if needed
                        // ****** leave the thumb type images 
                        if([[articleDictionary objectForKey:@"image_type"] isEqualToString:@"full"])
                        {
                            NSString *imageUrl = [articleDictionary objectForKey:@"image"];
                            if(imageUrl!=nil)
                                conversationObject.imageURL = imageUrl;
                        }
                        else
                        {
                            conversationObject.imageURL = nil;
                        }
                    }
                    [conversationFeedArray addObject:conversationObject];
                }
            }
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve"
                                                            message:@"No Response, Please try again"
                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
        if(!isRefreshing)
        {
            [_conversationCellsArray addObjectsFromArray:conversationFeedArray];
        }
        else
        {
            // if the feed list view has been aksed to refresh then reinitialize the array
            _conversationCellsArray = [[NSMutableArray alloc] initWithArray:conversationFeedArray];
        }
        // NSLog(@"conversation cells count: %d",_conversationCellsArray.count);
    }
    else if ([connection isEqual:connectionSwitchOrg]) // ajax/switch_org call
    {
        NSString* responseString= [[NSString alloc] initWithData:dataSwitchOrganization encoding:NSUTF8StringEncoding];
        //// NSLog(@"Response: %@",responseString);
        
        NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData:
                                     [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
        
        // NSLog(@"-------- >>> repsonse of switch org: %@", responseJSON);
        if([responseJSON objectForKey:@"success"] )
        {
            [DNGlobal sharedDNGlobal].gSwitchOrgDictionary = [[NSDictionary alloc] initWithDictionary:[responseJSON objectForKey:@"suggested_organization_values"]];
            // send notification in all tabs (to all registered notifications ) that an organization has been switched
            // sent the parameter ‘suggested_organization_values’ to all tabs
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"conversation",@"fromController",
                                       [NSNumber numberWithFloat:selectedOrganizationID], @"selected_org_id", nil];
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
    
    // NSLog(@"Conversation  connectionDidFinishLoading");
    //Removing the spinnerView after parsing the response data successfully
    
    // *******************************************************************************************************************************
    /*
     UI FIX : for fetch more + refresh
     Description : always first reload table and then call [refreshControl endRefreshing]  &   [pullToRefreshManager_ tableViewReloadFinished];
     else fetch abd refresh control symbol will appear over the table or may be in the middle of table
     // ORDER is also important first call endRefreshing & then tableviewReloadfinished.
     */
    // *******************************************************************************************************************************
    [_conversationTableView reloadData];
    [refreshControl endRefreshing];// data loaded stop refresh control
    [pullToRefreshManager_ tableViewReloadFinished];
    // *******************************************************************************************************************************

    
    isEndedLoadingFeeds = YES;
    isFetchingInProgress = NO;
    if(_isOrganizationSwitched)
        _isOrganizationSwitched = NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // enable intercation on view
    if(isFirstTimeLoadingFeeds) // means if globe is displaying
    {
        [_conversationTableView setUserInteractionEnabled:YES];
    }
    [self removeGlobeSpinner];
    [pullToRefreshManager_ tableViewReloadFinished];
    [refreshControl endRefreshing];// data loaded stop refresh control
    // NSLog(@" ERROR OCCURED %@",error);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Error fetching feeds, Please try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    

    
    isEndedLoadingFeeds = YES;
    isFetchingInProgress = NO;
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
    if([tableView isEqual:_tableViewDropDown])
        return 1;
    return [_conversationCellsArray count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag == kDropDownTag)
    {
        return 44;
    }
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(tableView.tag != kDropDownTag)
    {
        if(_conversationCellsArray.count > 0)
        {
            
                DNConversationCell* conversation_cellObject= (DNConversationCell *)[_conversationCellsArray objectAtIndex:section];
                if((conversation_cellObject.personsCliped && conversation_cellObject.personsCliped.count>0 )||
                   (conversation_cellObject.personsCommented && conversation_cellObject.personsCommented.count>0 ))
                {

                    NSString *delvesAndComments = [DNGlobal createDelvesAndCommentString:conversation_cellObject.personsCliped :conversation_cellObject.personsCommented];
                    
                    CGSize stringSize = [delvesAndComments sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:13.0]
                                                      constrainedToSize:CGSizeMake(270, 9999)
                                                          lineBreakMode:UILineBreakModeWordWrap];
                    if(stringSize.height<30)
                        return 30;
                    return stringSize.height;
                    
                }
        }
    }
    
    return 0.0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
{
    if(tableView.tag != kDropDownTag && section ==0)
    {
        return kHeaderHeight-50;
    }
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
{
    if(section ==0)
    {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kHeaderWidth, kHeaderHeight-50)];
        UILabel *label_topTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 20)];
        label_topTitle.text = [NSString stringWithFormat:@"MOST RECENT ACTIVITY (%@)", defaultOrganizationName];
        label_topTitle.font  = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0];
        label_topTitle.numberOfLines = 0;
        label_topTitle = [DNGlobal  adjustSizeOfLabel:label_topTitle];
        label_topTitle.textColor = [UIColor colorWithRed:171/255.0 green:171/255.0 blue:171/255.0 alpha:1.0];
        label_topTitle.backgroundColor = [UIColor clearColor];
        [headerView addSubview:label_topTitle];
        
        return headerView;
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if(_conversationCellsArray.count > 0)
    {
        DNConversationCell* conversation_cellObject= (DNConversationCell *)[_conversationCellsArray objectAtIndex:section];
        if(tableView.tag != kDropDownTag)
        {
            if((conversation_cellObject.personsCliped && conversation_cellObject.personsCliped.count>0 )||
               (conversation_cellObject.personsCommented && conversation_cellObject.personsCommented.count>0 ))
            {
                NSString *delvesAndComments = [DNGlobal createDelvesAndCommentString:conversation_cellObject.personsCliped :conversation_cellObject.personsCommented];
                
                UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kHeaderWidth, kHeaderHeight)];
                FTCoreTextView *_coreTextView = [[FTCoreTextView alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width-30, kHeaderViewHeight-20)];
                
                // set text
                [_coreTextView setText:delvesAndComments];
                // set styles
                [_coreTextView addStyles:[self coreTextStyle]];
                // set delegate
                [_coreTextView setDelegate:self];
                
//                [_coreTextView fitToSuggestedHeight];
                
                [headerView addSubview:_coreTextView];
                
                
                return headerView;
            }
            else
                return nil;
        }
    }
    return nil;
    
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([tableView isEqual:_tableViewDropDown])
        return [[dictOrganization objectForKey:@"organizations"] count];
    // NSLog(@"section=%d",section);
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if([tableView isEqual:_tableViewDropDown])
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
    else
    {
        
        NSString *identifier = @"ConversationCell";
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        //  [cell.textLabel setFont:[UIFont fontWithName:@"Bitter-Bold" size:18]];
        ((UILabel*)[cell.contentView viewWithTag:102]).font=[UIFont fontWithName:@"Bitter-Regular" size:18];
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
        
        cell.tag = indexPath.section;
        
        // Configure the cell of conversation..
        DNConversationCell* conversation_cellObject= (DNConversationCell *)[_conversationCellsArray objectAtIndex:indexPath.section];
        
        UILabel *heading = (UILabel *)[cell viewWithTag:102];
        heading.text= conversation_cellObject.heading;
        heading.font=[UIFont fontWithName:@"Bitter-Regular" size:18];
        
        UILabel *lbl_publication_name = (UILabel *)[cell viewWithTag:104];
        lbl_publication_name.text = conversation_cellObject.publicationSourceName;
        
        //Downloading image and setting it to imageView
        if (conversation_cellObject.mainImageData)
        {
            ((UIImageView *)[cell viewWithTag:101]).image = [UIImage imageWithData:conversation_cellObject.mainImageData];
        }
        else
        {
            ((UIImageView *)[cell viewWithTag:101]).image = nil;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *tempImage;
                if(conversation_cellObject.imageURL != nil) // if feedimage string is not nil
                {
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:conversation_cellObject.imageURL]];
                    tempImage = [UIImage imageWithData:imageData];
                }
                else
                {
                    tempImage = [UIImage imageNamed:@"placeholder_tab2.png"];
                }
                // create thumb resized image
                UIImage *image_thumb = [DNGlobal imageWithImage:tempImage scaledToWidth:200];
                conversation_cellObject.mainImageData= UIImageJPEGRepresentation(image_thumb, 1);
                dispatch_async(dispatch_get_main_queue(), ^{
                    // now fill the image data into the ceversation cell object to retain it
                    UITableViewCell *cell_local = [tableView cellForRowAtIndexPath:indexPath];
                    ((UIImageView *)[cell_local viewWithTag:101]).image = [UIImage imageWithData:conversation_cellObject.mainImageData];
                    [cell_local setNeedsLayout];
                });
            });
        }
        
        if (conversation_cellObject.iconImageData)
        {
            ((UIImageView *)[cell viewWithTag:103]).image = [UIImage imageWithData:conversation_cellObject.iconImageData];
        }
        else
        {
            ((UIImageView *)[cell viewWithTag:103]).image = nil;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:conversation_cellObject.publicationSourceIconURL]];
                conversation_cellObject.iconImageData= imageData;
                //if(imageData)
                dispatch_async(dispatch_get_main_queue(), ^{
                    {
                        UITableViewCell *cell_local = [tableView cellForRowAtIndexPath:indexPath];
                        ((UIImageView *)[cell_local viewWithTag:103]).image = [UIImage imageWithData:imageData];
                    }
                });
            });
        }
    }
    
    return cell;
}

#pragma mark - prepare for segue
// Method to perform segue.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"openInWebview"])
    {
        NSIndexPath *indexPath = [_conversationTableView indexPathForSelectedRow];
        DNConversationCell* cell= (DNConversationCell *)[_conversationCellsArray objectAtIndex:indexPath.section];
        DNArticleViewController *articleViewController = segue.destinationViewController;
        articleViewController.openedArticleId= cell.articleId;
        [articleViewController openLinkInWebview:cell.articleLink];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag == kDropDownTag)
    {
        if(!_tableViewDropDown.hidden)
            [self showHideDropdownList];
        
        NSString *org_name = [[[dictOrganization objectForKey:@"organizations"] objectAtIndex:indexPath.row] objectForKey:@"name"];
        // only switch if org is diff from switched org 
        if(![org_name isEqualToString:[DNGlobal sharedDNGlobal].switchedUserOrganization])
        {            
            // API call to switch organization
            // first fetch the selected org ID
            selectedOrganizationID = [[[[dictOrganization objectForKey:@"organizations"] objectAtIndex:indexPath.row] objectForKey:@"id"] floatValue];
            if(selectedOrganizationID)
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
                 // ******** end refreshing controller and fetch more controller so that UI remains undisturbed
                // *******************************************************************************************************************************
                
                [refreshControl endRefreshing];
                [pullToRefreshManager_ tableViewReloadFinished];
                
                // also disable connection
                if(_conversationConnection)
                {
                    [_conversationConnection cancel];
                    _conversationConnection = nil;
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
                    [self removeGlobeSpinner];
                    [self showIndicator]; // Show spinner
                    
                    isFirstTimeLoadingFeeds = YES; // assume that it is loading feeds first time
                    offsetForFetchMore = 0;
                    isRefreshing = YES;
                }
            }
        }
        [DNGlobal sharedDNGlobal].switchedUserOrganization = [[[dictOrganization objectForKey:@"organizations"] objectAtIndex:indexPath.row] objectForKey:@"name"];
        defaultOrganizationName = [DNGlobal sharedDNGlobal].switchedUserOrganization;
        [DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:org_name];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - post notification when org switched

-(void)organizationSwitchedNotification: (NSNotification *)notification
{
    _isOrganizationSwitched = YES; // organization is switched
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_SWITCH_ORG])
    {
        // NSLog(@"notification receieved in Conversation view controller ---- ");
        
        if([[notification.userInfo objectForKey:@"fromController"] isEqualToString:@"conversation"])
        {
            isEndedLoadingFeeds = NO;
            // now change the feeds according to switched organization
            isFirstTimeLoadingFeeds = YES; // consider fetching first time as we need to show globe spinner too
            isRefreshing = YES; // must be set to true according to API clarification
            
            [self getConversationArticles];
            _isOrganizationSwitched = NO;// set to no to prevent calling in viewWillApear: wen tabs switched
        }
    }
}
-(void)refreshFeedsNotificationReceived: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_REFRESH_FEEDS])
    {
        // NSLog(@"refresh feeds called ---  in  Conversation VC: ");
        
        // refresh feeds after idle timeout ****************
        isFirstTimeLoadingFeeds = YES; // consider loading feeds first time , it will show globe spinner
        isEndedLoadingFeeds = NO;
        isRefreshing = YES;
        offsetForFetchMore = 0;
        [self getConversationArticles];
        
    }
}
-(void)delveOrCommentNotificationReceived: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_DELVE_OR_COMMENT])
    {
        // NSLog(@"Delve/Comment notification called ---  in Tab 2  Conversation VC: ");
        // NSLog(@"user info is : %@", notification.userInfo);
                
        // now change the article (if its delved or commented), loop through the whole saved response
        for(DNConversationCell *aFeed in conversationFeedArray) // looping through articles
        {
            if([[NSString stringWithFormat:@"%@", aFeed.articleId] isEqualToString:[NSString stringWithFormat:@"%@",[notification.userInfo objectForKey:@"delvedArticleId"]]])
            {
                // NSLog(@"article matched ..TAb 2.. now change it");
                aFeed.personsCliped = [notification.userInfo  objectForKey:@"clips"];
                aFeed.personsCommented = [notification.userInfo  objectForKey:@"comments"];
                break;
            }
        }
        
        // now relaod that
        [_conversationTableView reloadData];
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
        if(_conversationConnection)
        {
            [_conversationConnection cancel];
            _conversationConnection = nil;
        }
    }
}



@end
