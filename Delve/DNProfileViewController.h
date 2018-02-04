//
//  DNProfileViewController.h
//  Delve
//
//  Created by Atul Khatri on 13/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "DNAppDelegate.h"
#import "DNGlobal.h"
#import "DNProfileCell.h"
#import "DNArticleViewController.h"

#import "MNMBottomPullToRefreshManager.h"

#import "FTCoreTextView.h"

@interface DNProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
NSURLConnectionDelegate, UIScrollViewDelegate, MNMBottomPullToRefreshManagerClient, FTCoreTextViewDelegate>

@property (nonatomic,strong) NSURLConnection* userDataConnection;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *userName;

@property (strong,nonatomic) NSURLConnection* articleConnection;
@property (strong,nonatomic) NSMutableData* articleData;

@property (strong, nonatomic) IBOutlet UITableView *profileTableView;
@property (weak, nonatomic) IBOutlet UIView *maskView; // maskview for dropdown table to show when dropdown is open
@property (strong ,nonatomic) UIActivityIndicatorView *spinnerView;
 
@property (nonatomic,strong) NSMutableDictionary *sections; // section dict fetched from /api/userarticleclip/ => to have date wise articles 
@property (nonatomic,strong) NSMutableArray *sortedDateKeysArray;  // Contains keys of section dictionary
@property (nonatomic , strong) NSString *gIdForSelf; //global for self.

@property (strong , nonatomic) UIImageView *spinnerImageView;

//-(void)getDelvedArticles:(NSString *)idOfUser;

// check for org switch 
@property (assign , nonatomic)   BOOL isOrganizationSwitched;
@end
