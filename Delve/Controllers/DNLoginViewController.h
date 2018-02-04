//
//  DNLoginViewController.h
//  Delve
//
//  Created by Letsgomo Labs on 29/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DNGlobal;
@interface DNLoginViewController : UIViewController<UITextFieldDelegate, NSURLConnectionDelegate>
{
    DNGlobal *sharedInstance;
}

@property (nonatomic, retain) IBOutlet UITextField *textFieldEmail;
@property (nonatomic, retain) IBOutlet UITextField *textFieldPassword;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,strong) NSURLConnection* loginConnection;
@property (nonatomic,strong) NSURLConnection* userDataConnection;
@property (nonatomic , retain) NSArray *cookiesArray;
@property (nonatomic, strong) UIImageView *spinnerImageView;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
//Class method to create global cookie
+(NSString *)globalCookieFromParameters:(NSString *)name withValue:(NSString *)value withExpiryDate:(NSString *)expires withSession:(BOOL)sessionOnly withDomain:(NSString *)domain withPath:(NSString *)path andIsSecure:(BOOL)secure;
-(IBAction)LoginTapped:(id)sender;

@end
