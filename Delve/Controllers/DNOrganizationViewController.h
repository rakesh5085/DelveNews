//
//  DNOrganizationViewController.h
//  Delve
//
//  Created by Letsgomo Labs on 19/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Core text view to use with profile name linking and styling
#import "FTCoreTextView.h"

@interface DNOrganizationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FTCoreTextViewDelegate>

@property (strong ,nonatomic) UIActivityIndicatorView *spinnerView;

@property (strong , nonatomic) IBOutlet UITableView *tableViewOrganization;
@property (weak, nonatomic) IBOutlet UIView *alphaMaskView;
@property (strong , nonatomic) UIImageView *spinnerImageView;

// check for switch org
@property (assign , nonatomic)   BOOL isOrganizationSwitched;

@end
