//
//  DNFeedTableViewController.h
//  Delve
//
//  Created by Letsgomo Labs on 29/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DNFeedCell.h"

#import "MNMBottomPullToRefreshManager.h"

#import "FTCoreTextView.h"

@interface DNFeedTableViewController : UITableViewController <NSURLConnectionDelegate, UIScrollViewDelegate,
MNMBottomPullToRefreshManagerClient, FTCoreTextViewDelegate>

@property (strong, nonatomic) NSMutableArray* feedCells;
@property (strong,nonatomic) NSMutableData* feedData;
@property (strong,nonatomic) NSURLConnection* feedConnection;
@property (strong ,nonatomic) UIActivityIndicatorView *spinnerView;
@property (strong , nonatomic) UIImageView *spinnerImageView;

 @property (assign , nonatomic)   BOOL isOrganizationSwitched;

@end
