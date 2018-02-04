//
//  DNFeedTableViewController.m
//  Delve
//
//  Created by Letsgomo Labs on 29/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNFeedTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "DNCustomTabBar.h"
#import "DNGlobal.h"
#import "DNArticleViewController.h"
#import "UIImage+animatedGIF.h"
#import "Constants.h"

#import "DNProfileViewController.h"

#import "MNMBottomPullToRefreshManager.h"


#define kTableHeaderViewHeight 10
#define kBackgroundViewCornerRadius 0.5f
#define kBackgroundViewWidth 0.1f
#define kTableCellCornerRadius 2.0
#define kFeedCellHeightFull 216.0f
#define kFeedCellHeightNormal 170.0f

#define kHeaderLabelOffsetX 16
#define kHeaderLabelOffsetY 0
#define kHeaderLabelHeight 44
#define kHeaderViewHeight 44

@interface DNFeedTableViewController()
{
    BOOL isRefreshing; // parameter to be used in api call for view_refresh
    NSMutableArray *feedsArray;
    UIRefreshControl *refreshControl;// refresh control to refresh the whole view and changes the view id , (fetch more is diffrent and view id remains same)
    NSInteger generatedRandomNumber;// use to generate the random view id
    
    BOOL isFirstTimeLoadingFeeds;
    BOOL isEndedLoadingFeeds;
    /**
     * Pull to refresh manager
     */
    MNMBottomPullToRefreshManager *pullToRefreshManager_;
    BOOL isFetchingInProgress; // a bool for fetch operation in progress or not
    
    // link click on the user name
    NSString * urlForId;
}

// core text view to link profile names
@property (nonatomic) FTCoreTextView *coreTextView;


@end

@implementation DNFeedTableViewController
@synthesize feedCells;
@synthesize feedData;
@synthesize feedConnection;
@synthesize spinnerView;
@synthesize spinnerImageView;

@synthesize coreTextView = _coreTextView;

@synthesize isOrganizationSwitched = _isOrganizationSwitched;

#pragma mark - view cycle
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    feedCells= [[NSMutableArray alloc] init];

    // Hide the back button on navigation bar using the tabbar controller
    ((DNCustomTabBar *)([self.navigationController.childViewControllers objectAtIndex:[self.navigationController.childViewControllers count]-1])).navigationItem.hidesBackButton = YES;
    
    //Method to refresh feeds data
    isRefreshing = YES;
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshFeed:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:refreshControl];

    isFirstTimeLoadingFeeds = YES;
    // set the end refreshing parameter initialy to no as feeds would get load in view didload
    isEndedLoadingFeeds = NO;
    
    // bottom pull to refresh or fetch more feeds class 
    pullToRefreshManager_ = [[MNMBottomPullToRefreshManager alloc] initWithPullToRefreshViewHeight:60.0f tableView:self.tableView withClient:self];
    isFetchingInProgress = NO; // set it to no initially , we are not fetching 
    [self getFeedData];
    
    // register for the notification of switch org
    _isOrganizationSwitched = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(organizationSwitchNotification:) name:kPOSTNOTIFICATION_SWITCH_ORG object:nil];
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
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [pullToRefreshManager_ relocatePullToRefreshView];
}

-(void)viewWillAppear:(BOOL)animated
{
    if(_isOrganizationSwitched)// if organization switched then load feed for it
    {
        isEndedLoadingFeeds = NO;
        // now change the feeds according to switched organization
        isFirstTimeLoadingFeeds = YES; // consider fetching first time as we need to show globe spinner too
        isRefreshing = YES; // must be set to true according to API clarification
        
        [self getFeedData];
        _isOrganizationSwitched = NO;// only call this api one time (if user keeps switching between tabs)
    }
    
    // customize navigation bar
    [DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:@"Recommendations"];    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Method to show activityindicator on view
-(void)showIndicator
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"delve_globe" withExtension:@"gif"];
    self.spinnerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 200, 40, 40)];
    self.spinnerImageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    self.spinnerImageView.hidden = NO;
    [self.view addSubview:self.spinnerImageView];
}
-(NSInteger)generateRandomNumber
{
    //([max intValue] - [min intValue]) + [min intValue];
    NSInteger minValue = 0;
    NSInteger maxValue = 10000000;
    NSInteger randomNumber = arc4random() % (maxValue - minValue)+minValue;
    return randomNumber;
}

#pragma mark - pull to refresh

- (void)refreshFeed:(UIRefreshControl *)refreshControl1
{
    // NSLog(@" is ended: %d ", isEndedLoadingFeeds);
    
    if(isEndedLoadingFeeds && !isFetchingInProgress)
    {
        isRefreshing = YES;
        isFirstTimeLoadingFeeds = NO;
        isEndedLoadingFeeds = NO;
        
        [self getFeedData];
    }
    else
    {
        // NSLog(@"data already being fetched from server");
        [refreshControl1 endRefreshing];
        isRefreshing = NO;
    }
}

#pragma mark - fetch more - scroll to bottom
- (void)fetchMoreFeeds
{
     // NSLog(@" is ended: %d ", isEndedLoadingFeeds);
    if(isEndedLoadingFeeds)
    {
        // NSLog(@"fetching more feeds");
        isRefreshing = NO;
        isFirstTimeLoadingFeeds = NO;
        isEndedLoadingFeeds = NO;
        [self getFeedData];
    }
    else
    {
        [pullToRefreshManager_ tableViewReloadFinished];
    }
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

#pragma mark - get feed data

// Method to fetch api data
-(void)getFeedData
{
    DNGlobal *sharedInstance=[DNGlobal sharedDNGlobal];
    //Fetching active organisation from global userorganisation.
    NSString *userActiveOrg = [sharedInstance.userOrganizations objectForKey:@"active_organization"];
    //Function which give random number between range
    if(isRefreshing) // if view is refreshing then generate a new view ID
    {
        //Function which give random number between range
        generatedRandomNumber = [self generateRandomNumber];
    }
    //Saving this integer for fetching more items
    sharedInstance.gRandomNumberForFeed = generatedRandomNumber;
    // NSLog(@"checking =% d",generatedRandomNumber);
    
    NSString *randomString = [NSString stringWithFormat:@"%d",generatedRandomNumber];
    NSDictionary *datesDictionary = [[NSDictionary alloc] init];
    NSDictionary *filtersDictionary = [[NSDictionary alloc] init];
    NSMutableArray *tiersArray = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:15], nil];
    
    // isRefreshing will decide if the view being refreshed or just fetching more on the same view ID
    
    // Creating Dictionary for extra data which should be passed with URL
    NSDictionary *activeOrgDict ;
    
    if(!_isOrganizationSwitched)
    {
        activeOrgDict = [NSDictionary dictionaryWithObjectsAndKeys:userActiveOrg,@"active_organization",randomString,@"view_id'",[NSNumber numberWithBool:isRefreshing],@"view_refresh",@"true",@"mobile",@"2",@"version",datesDictionary,@"dates",filtersDictionary,@"filters",tiersArray,@"tiers", nil];
    }
    else
    {
        
        activeOrgDict = [NSDictionary dictionaryWithObjectsAndKeys:userActiveOrg,@"active_organization",randomString,@"view_id'",[NSNumber numberWithBool:isRefreshing],@"view_refresh",@"true",@"mobile",@"2",@"version",datesDictionary,@"dates",filtersDictionary,@"filters",tiersArray,@"tiers",[[DNGlobal sharedDNGlobal].gSwitchOrgDictionary objectForKey:@"internal_organizations"],@"internal_organizations",[[DNGlobal sharedDNGlobal].gSwitchOrgDictionary objectForKey:@"preference_organizations"],@"preference_organizations", nil];
    }
    
    // Making data with jsonobject
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:activeOrgDict options:kNilOptions error:nil];
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *idAndJsonString=[NSString stringWithFormat:@"%@/api/article?settings=%@",kAPI_Host_Name,jsonString];
    // NSLog(@"idfinalstr-=%@",idAndJsonString);
    
    NSURL *url = [NSURL URLWithString:idAndJsonString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //Add cookie object here and passing global cookie
    [request addValue:sharedInstance.gCookie forHTTPHeaderField:@"Cookie"];
    
    feedConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (feedConnection)
    {
        // to hold the feeds retrieved from api
        feedsArray = [[NSMutableArray alloc] init];

        if(isFirstTimeLoadingFeeds)
            [self showIndicator];
    }
    else
    {
        // Inform the user that the connection failed.
        // NSLog(@"CONNECTION CREATION FAILED FOR CONVERSATION ARTICLES LIST: ====>>>>>>");
        isEndedLoadingFeeds = YES;
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
    if (!urlForId)
        return;
    
    // NSLog(@"url = %@",urlForId);
    
    NSString *str = [urlForId stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    // NSLog(@"str= %@",str);
    
    NSString *loggedInUserId;
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
    return feedCells.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DNFeedCell *feedCell = [feedCells objectAtIndex:indexPath.section];
    if((feedCell.feedDelves && feedCell.feedDelves.count>0 )|| (feedCell.feedComments && feedCell.feedComments.count>0))
    {            
        NSString * strDelvesAndComments = [DNGlobal createDelvesAndCommentString:feedCell.feedDelves :feedCell.feedComments];
        
        CGSize stringSize = [strDelvesAndComments sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:13.0]
                                             constrainedToSize:CGSizeMake(270, 9999)
                                                 lineBreakMode:UILineBreakModeWordWrap];
        if(stringSize.height< 30)
            return 30+kFeedCellHeightNormal;
        else
            return stringSize.height+kFeedCellHeightNormal;
            
    }
    return kFeedCellHeightNormal;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Initialising feedCell `attributes with fetched data
    DNFeedCell* feedCell= (DNFeedCell *)[feedCells objectAtIndex:indexPath.section];

    UITableViewCell *cell ;//= [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if((feedCell.feedDelves && feedCell.feedDelves.count>0 )|| (feedCell.feedComments && feedCell.feedComments.count>0))
    {
        if(SYSTEM_VERSION_GREATER_THAN(@"6.0"))
            cell = [tableView dequeueReusableCellWithIdentifier:@"feedCellFull" forIndexPath:indexPath];
        else
            cell = [tableView dequeueReusableCellWithIdentifier:@"feedCellFull"];

        if (!cell)
            cell = (UITableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"feedCellFull"];
        
        // delve and comments
        NSString * strDelvesAndComments = [DNGlobal createDelvesAndCommentString:feedCell.feedDelves :feedCell.feedComments];
        
        // core text view for profile linking and styles
        _coreTextView = (FTCoreTextView *)[cell viewWithTag:1501];
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
        if(SYSTEM_VERSION_GREATER_THAN(@"6.0"))
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"feedCellNormal" forIndexPath:indexPath];
        else
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"feedCellNormal"];
        if (!cell)
            cell = (UITableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"feedCellNormal"];
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    ((UIImageView*)[cell.contentView viewWithTag:100]).layer.cornerRadius = kTableCellCornerRadius;
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
    
    UILabel *feedTitleLbl = (UILabel *)[cell viewWithTag:120];
//    feedTitleLbl.frame = CGRectMake(5, 0, 270, 57);
    // NSLog(@"y of the title : %f", ((UILabel *)[cell viewWithTag:120]).frame.origin.y);
    feedTitleLbl.text= feedCell.feedTitle;
    feedTitleLbl.font=[UIFont fontWithName:@"Bitter-Regular" size:22];
    
    UILabel *feedSource = (UILabel *)[cell viewWithTag:110];
    feedSource.text = feedCell.feedSource;
    
    if (feedCell.feedImageData)//Checking feedImageData availabilty if present then prevent downloading
    {
        ((UIImageView *)[cell viewWithTag:100]).image = [UIImage imageWithData:feedCell.feedImageData];
    }
    else //Downloading image and setting it to imageView
    {
        //Setting imageview to nil to prevent caching of image ; Important
        ((UIImageView *)[cell viewWithTag:100]).image = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            UIImage *tempImage;
            if(feedCell.feedImage != nil) // if feedimage string is not nil
            {
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:feedCell.feedImage]];
                tempImage = [UIImage imageWithData:imageData];
            } 
            else // apply the placeholder image else 
            {
                tempImage = [UIImage imageNamed:@"placeholder_tab1.png"];
            }

            // create thumb image of width 300*2 (maintaining aspect ratio)
            UIImage *image_thumb = [DNGlobal imageWithImage:tempImage scaledToWidth:600];
            dispatch_async(dispatch_get_main_queue(), ^{
                UITableViewCell *cell_local=nil;
                
                cell_local = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
                feedCell.feedImageData= UIImageJPEGRepresentation(image_thumb, 1);
                ((UIImageView *)[cell_local viewWithTag:100]).image = [UIImage imageWithData:feedCell.feedImageData];
                [cell_local setNeedsLayout];
            });
        });
    }
    return cell;
}

#pragma mark - prepare for segue

// Method to perform segue.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // push any seauge with the following view controller
    if ([segue.identifier isEqualToString:@"goFromFeed"] || [segue.identifier isEqualToString:@"goFromFeedFullCell"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        DNFeedCell* cell= (DNFeedCell *)[feedCells objectAtIndex:indexPath.section];
        
        DNArticleViewController *articleViewController = segue.destinationViewController;
        articleViewController.openedArticleId= cell.feedId;// important to pass on 
        [articleViewController openLinkInWebview:cell.feedLink];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - post notification for org switch
-(void)organizationSwitchNotification: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_SWITCH_ORG])
    {
        // NSLog(@"notification receieved in Feed view controller : %@ ---- ", notification.userInfo);
        _isOrganizationSwitched = YES;
    }
}
-(void)refreshFeedsNotificationReceived:(NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_REFRESH_FEEDS])
    {
        // NSLog(@"refresh feeds called ---  in  Tab 1 Feeds VC: ");
        
        // refresh feeds after idle timeout  **************
        isFirstTimeLoadingFeeds = YES; // consider loading of feeds first time  ,that will dispaly globe spinner too
        isEndedLoadingFeeds = NO;
        
        [self getFeedData];
    }
}
// an article has been shared or commented 

-(void)delveOrCommentNotificationReceived: (NSNotification *)notification
{
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_DELVE_OR_COMMENT])
    {
        // NSLog(@"Delve/Comment notification called ---  in Tab 1  Feed VC: ");
        // NSLog(@"user info is : %@", notification.userInfo);
        
        // now change the article (if its delved or commented), loop through the whole saved response
        for(DNFeedCell *aFeed in feedCells) // looping through articles
        {
            if([[NSString stringWithFormat:@"%@", aFeed.feedId] isEqualToString:[NSString stringWithFormat:@"%@",[notification.userInfo objectForKey:@"delvedArticleId"]]])
            {
                // NSLog(@"article matched .... now change it");
                aFeed.feedDelves = [notification.userInfo  objectForKey:@"clips"];
                aFeed.feedComments = [notification.userInfo  objectForKey:@"comments"];
                break;
            }
        }
        
        // now relaod that
        [self.tableView reloadData];
    }
}

// user logged out .. cancel any pending connections
-(void)userLoggedoutNotificationReceived: (NSNotification *)notification
{
    // NSLog(@"user logged out ----");
    if([[notification name] isEqualToString:kPOSTNOTIFICATION_USER_LOGGEDOUT])
    {
        // cancel a connection if already present
        if(feedConnection)
        {
            [feedConnection cancel];
            feedConnection = nil;
        }
    }
}


#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
    isEndedLoadingFeeds = NO;
    feedData = [[NSMutableData alloc] init];
    // NSLog(@"FEED didReceiveResponse");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    isEndedLoadingFeeds = NO;
    [feedData appendData:data];
    //    // NSLog(@"FEED didReceiveData");
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString* responseString= [[NSString alloc] initWithData:feedData encoding:NSUTF8StringEncoding];
    //// NSLog(@"Response: %@",responseString);
    
    NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
//    // NSLog(@"Dictionary Response: %@",responseJSON);
    
    if(responseJSON != (id)[NSNull null])
    {
        
        NSArray *articleList= [responseJSON objectForKey:@"article_list"];
        // NSLog(@"ARTICLE LIST: %@",articleList);
        
        for(NSDictionary* dict in articleList)
        {
            
            NSDictionary* imageDict = [dict objectForKey:@"image"];
            NSDictionary* publication= [dict objectForKey:@"publication"];
            NSString * title= [dict objectForKey:@"title"];        
            NSMutableArray *clips = [NSMutableArray arrayWithArray:[dict objectForKey:@"clips"]];
            
            // remove duplicate delves from clips array
            clips = [DNGlobal removeDuplicateDelvesFromClipsArray:clips];
            
            NSArray *comments= [dict objectForKey:@"comments"];
            
            //Save it to feedCells Array
            DNFeedCell* feedCell= [[DNFeedCell alloc] init];
            if(![[[dict objectForKey:@"image"] objectForKey:@"type"] isEqualToString:@"thumb"])
                feedCell.feedImage=[imageDict objectForKey:@"url"];
            else
                feedCell.feedImage = nil;
            feedCell.feedSource=[publication objectForKey:@"name"];
            feedCell.feedTitle=[[NSString alloc ] initWithString: title];
            feedCell.feedId = [dict objectForKey:@"id"];
            feedCell.feedLink = [dict objectForKey:@"link"];
            
            //Extract feed Delves and store it
            for(NSDictionary* clip in clips)
            {
                NSString* user_name= [clip objectForKey:@"user_name"];
                if(user_name && (user_name.length >0))
                {
                    if(!feedCell.feedDelves)
                        feedCell.feedDelves = [[NSMutableArray alloc] init];
                    [feedCell.feedDelves addObject:clip];
                }
            }
            //Extract feed commenters and store it
            for(NSDictionary* comment in comments)
            {
                NSDictionary* writer= [comment objectForKey:@"writer"];
                if([[writer objectForKey:@"name"] length]>0)
                {
                    if(!feedCell.feedComments)
                        feedCell.feedComments = [[NSMutableArray alloc] init];
                    [feedCell.feedComments addObject:writer];
                }
            }
            NSArray *discussion= [dict objectForKey:@"discussions"];
            if(discussion && discussion.count>0)
            {
                for(NSDictionary* dict in discussion)
                {
                    if(!feedCell.feedComments)
                        feedCell.feedComments = [[NSMutableArray alloc] init];
                    [feedCell.feedComments addObject:dict];
                }
            }
            
            [feedsArray addObject:feedCell];
        }
        if(!isRefreshing) // if fetching more feeds then add to the bottom of the 
        {
            [feedCells addObjectsFromArray:feedsArray];
        }
        else
        {
            // if the feed list view has been aksed to refresh then reinitialize the array with new feed
            feedCells = [[NSMutableArray alloc] initWithArray:feedsArray];
        }
    }
    else{
        UIAlertView *delveAlert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"No Response. Please try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [delveAlert show];
    }
    
    [self.tableView reloadData];
    if(!isRefreshing)
        [pullToRefreshManager_ tableViewReloadFinished];
    
    if(_isOrganizationSwitched)// if organization switched causes feed load then next time must be normal load
    {
        _isOrganizationSwitched = NO;
    }
    // NSLog(@"FEED connectionDidFinishLoading");
    // NSLog(@"feedCells count: %i",feedCells.count);

    //Removing the spinnerView after parsing the response data successfully
    if(self.spinnerImageView!=nil)
    {
        [self.spinnerImageView removeFromSuperview];
        self.spinnerImageView = nil;
    }
    if(refreshControl.isRefreshing)
    {
        // NSLog(@"ended refreshing ------- ");
        [refreshControl endRefreshing];
    }
    isRefreshing = NO;
    isEndedLoadingFeeds = YES;
    isFetchingInProgress = NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // The request has failed for some reason!
    // Check the error var
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error in connection, Please try again"
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];

    //Removing the spinnerView after parsing the response data successfully
    
    if(self.spinnerImageView!=nil)
    {
        [self.spinnerImageView removeFromSuperview];
        self.spinnerImageView = nil;
    }
    if(refreshControl.isRefreshing)
    {
        // NSLog(@"ended refreshing ------- ");
        [refreshControl endRefreshing];
    }

    // NSLog(@"FEED ERROR OCCURED %@",error);
    [pullToRefreshManager_ tableViewReloadFinished];
    isEndedLoadingFeeds = YES;
    isFetchingInProgress = NO;
    isRefreshing = NO;
}


@end
