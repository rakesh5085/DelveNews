//
//  DNArticleViewController.h
//  Delve
//
//  Created by Atul Khatri on 31/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuartzCore/QuartzCore.h"
#import "FTCoreTextView.h"

@class DNGlobal;

@interface DNArticleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIWebViewDelegate,FTCoreTextViewDelegate>
{
    DNGlobal *sharedInstance;
    NSString *urlForId;
}

@property (nonatomic, strong) IBOutlet UIImageView *imageViewLoggedInUser;// logged in user image
@property (nonatomic, strong) IBOutlet UILabel *labelLoggedInUserName; // logged in user name 

@property (weak, nonatomic) IBOutlet UIWebView *articleWebView;
@property (retain, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UIView *postCommentView;
@property (weak, nonatomic) IBOutlet UIButton *justCommentButton;
@property (weak, nonatomic) IBOutlet UIButton *delveAndCommentButton;
@property (weak, nonatomic) IBOutlet UITextField *commentTextView; // to commment on the article


@property (strong, nonatomic) UIView *commentListView;
@property (strong,nonatomic) UIButton *delveButton;
@property (strong,nonatomic) UIButton *invisibleButton; // on tap of it you would see the comment table view 
@property (strong,nonatomic) UIButton *footerNotificationButton;
@property (strong, nonatomic) UIButton *commentListNotificationButton;
@property (strong, nonatomic) UIView* footerView; // footer view to hold delve button and number of comments button 
@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) NSString *openedArticleId;
@property (strong,nonatomic) NSURLConnection* commentsConnection;
@property (strong,nonatomic) NSMutableData* commentsResponseData;
@property (strong, nonatomic) NSMutableArray *commentsAndClipsArray;
@property (strong, nonatomic) NSString *gUserId;
@property (strong , nonatomic) NSString *gUserName;                             //used for
@property (nonatomic, assign) BOOL isDelve;

@property (nonatomic) FTCoreTextView *coreTextView;
@property (strong , nonatomic) UIImageView *spinnerImageView;
-(void)openLinkInWebview:(NSString*)link;
//Method to delve an article
-(void)delveAnArticle:(NSString *)articleId;

//Method to comment on article
-(void)commentOnArticle:(NSString *)articleId andCommentText:(NSString *)commentText;

@end
