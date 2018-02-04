//
//  DNConversationViewController.h
//  Delve
//
//  Created by Atul Khatri on 13/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DNConversationCell.h"

#import "MNMBottomPullToRefreshManager.h"

#import "FTCoreTextView.h"

@interface DNConversationViewController : UIViewController
<UITableViewDelegate,UITableViewDataSource, NSURLConnectionDelegate, UIScrollViewDelegate, MNMBottomPullToRefreshManagerClient, FTCoreTextViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *conversationTableView;

@property (strong,nonatomic) NSMutableArray* converstaionCellsArray;
@property (nonatomic , retain) NSURLConnection *conversationConnection;
@property (strong ,nonatomic) UIActivityIndicatorView *spinnerView;
@property (strong , nonatomic) UIImageView *spinnerImageView;
@property (weak, nonatomic) IBOutlet UIView *alphaMaskView;// mask view for drop down table apearance


@property (assign , nonatomic)   BOOL isOrganizationSwitched;

@end
