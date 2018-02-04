//
//  DNLoginViewController.m
//  Delve
//
//  Created by Letsgomo Labs on 29/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNLoginViewController.h"
#import "DNGlobal.h"
#import "UIImage+animatedGIF.h"

@implementation NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
    return YES;
}
@end

@interface DNLoginViewController ()
{
    NSMutableData *loginData;
    NSMutableData *userData;
    NSURLConnection *userOrganizationConnection;
    NSMutableData *organizationData;

}

@end

@implementation DNLoginViewController

@synthesize textFieldEmail = _textFieldEmail;
@synthesize textFieldPassword = _textFieldPassword;
@synthesize cookiesArray = _cookiesArray;
@synthesize userDataConnection;
@synthesize loginConnection;
@synthesize spinnerImageView;
@synthesize loginButton;

#pragma mark - View cycle methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.navigationItem.hidesBackButton = YES;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    
    BOOL isloggedOutLastTime = [[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedOutLastTime"];
    
    // NSLog(@"last time logged out : %d", isloggedOutLastTime);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //To add padding in Email Password textViews
    UIView *paddingViewForEmail = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _textFieldEmail.leftView = paddingViewForEmail;
    _textFieldEmail.leftViewMode = UITextFieldViewModeAlways;
    
    UIView *paddingViewForPassword = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _textFieldPassword.leftView= paddingViewForPassword;
    _textFieldPassword.leftViewMode= UITextFieldViewModeAlways;
    
    _textFieldEmail.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"user_id"];
    _textFieldPassword.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"password"];
    
    _textFieldEmail.delegate = self;
    _textFieldPassword.delegate = self;
    
    // Creating a single Instance of DNGlobal
    sharedInstance = [DNGlobal sharedDNGlobal];
    
    BOOL isloggedOutLastTime = [[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedOutLastTime"];
    if(!isloggedOutLastTime) // go to the tab bar controller straight if not logged out from the app previously
    {
        // Creating a single Instance of DNGlobal
        sharedInstance = [DNGlobal sharedDNGlobal];
        sharedInstance.gCookie = [[NSUserDefaults standardUserDefaults] valueForKey:@"gCookie"];
        sharedInstance.gCookieInPostApi = [[NSUserDefaults standardUserDefaults] valueForKey:@"gCookieInPostApi"];
        sharedInstance.gCSRF_Token = [[NSUserDefaults standardUserDefaults] valueForKey:@"gCSRF_Token"];

        // hide the loggin button and disable interaction , show the spinner
        self.loginButton.hidden = YES;
        [self.view setUserInteractionEnabled:NO];
        [self showIndicator];

        [self getUserInfo];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Method returning cookie string
+(NSString *)globalCookieFromParameters:(NSString *)name withValue:(NSString *)value withExpiryDate:(NSString *)expires withSession:(BOOL)sessionOnly withDomain:(NSString *)domain withPath:(NSString *)path andIsSecure:(BOOL)secure;{
    NSString *gCookie = [NSString stringWithFormat:@"%@=%@;%@;%d;%@;%@;%d",name,value,expires,sessionOnly,domain,path,secure];
    // NSLog(@"cookie string=%@",gCookie);
    return gCookie;
}
#pragma mark - Login button tapped
-(IBAction)LoginTapped:(id)sender
{
    // NSLog(@"Login api calling: ");
    
    [self.view endEditing:YES];
    
    if(_textFieldEmail.text.length > 0 && _textFieldPassword.text.length>0)
    {
    
        // Creating request string
        NSMutableString *myRequestString = [NSMutableString stringWithString:@"email="];
        [myRequestString appendString:_textFieldEmail.text];
        [myRequestString appendString:@"&password="];
        [myRequestString appendString:_textFieldPassword.text];
        [myRequestString appendString:@"&submit_login="];
        [myRequestString appendString:@"true"];
        
        // In body data for the 'application/x-www-form-urlencoded' content type, form fields are separated by an ampersand. Note the absence of a
        // leading ampersand.
        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAPI_Host_Name,@"/ajax/login/"]]
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:60];
        
        // Set the request's content type to application/x-www-form-urlencoded
        [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        // Designate the request a POST request and specify its body data
        [postRequest setHTTPMethod:@"POST"];
        [postRequest setHTTPBody:[NSData dataWithBytes:[myRequestString UTF8String] length:[myRequestString length]]];
        
        //Set to NO so that each time cookie will be generated
        [postRequest setHTTPShouldHandleCookies:NO];
        // hit login api with the specified request
        loginConnection = [[NSURLConnection alloc] initWithRequest:postRequest delegate:self];
        
        if(loginConnection)
        {
            // hide the loggin button and disable interaction , show the spinner
            self.loginButton.hidden = YES;
            [self showIndicator];
            [self.view setUserInteractionEnabled:NO];
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Please fill all fields" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

-(void)showIndicator
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"delve_globe" withExtension:@"gif"];
    
    //self.urlImageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
    
    if (iOSDeviceScreenSize.height == 480)
        self.spinnerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 250, 40, 40)];
    else
        self.spinnerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 305, 40, 40)];
    self.spinnerImageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    [self.view addSubview:self.spinnerImageView];
    
}

#pragma mark - get user information api
-(void)getUserInfo
{
    NSURL *url= [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAPI_Host_Name,@"/api/user/"]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //Add cookie object here and passing globally saved cookie
    [request addValue:sharedInstance.gCookie forHTTPHeaderField:@"Cookie"];
    
    // Create url connection and fire request
    userDataConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
}

-(void)getuserOraganizationsList
{
    NSURL *url= [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAPI_Host_Name,@"/api/organization/"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
           
    //Add cookie object here and passing globally saved cookie
    [request addValue:sharedInstance.gCookie forHTTPHeaderField:@"Cookie"];
    
    // Create url connection and fire request
    userOrganizationConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(userOrganizationConnection)
    {
        organizationData = [[NSMutableData alloc] init];
    }
    else
    {
        // NSLog(@"could not create connection");
    }
}

#pragma mark - connection delegate methods
// NSURLConnection Delegates
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{    
    if(connection== loginConnection)
    {
        if ([challenge previousFailureCount] == 0)
        {
            // NSLog(@"received authentication challenge");
            NSURLCredential *newCredential = [NSURLCredential credentialWithUser:_textFieldEmail.text
                                                                        password:_textFieldPassword.text
                                                                     persistence:NSURLCredentialPersistenceForSession];
            // NSLog(@"credential created");
            [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
            // NSLog(@"responded to authentication challenge");
        }
        else {
            // NSLog(@"previous authentication failure");
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if(connection == loginConnection)
    {
        loginData = [[NSMutableData alloc] init];        
        self.cookiesArray = [[NSArray alloc] init];        
        //[loginData setLength:0];
        
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        
        // Check the status code and respond appropriately.
        switch ([httpResponse statusCode])
        {
            case 200:
            {
                // Got a response so extract any cookies.  The array will be empty if there are none.
                NSDictionary *theHeaders = [httpResponse allHeaderFields];
                NSArray      *theCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:theHeaders forURL:[response URL]];
                
                // Save any cookies
                if ([theCookies count] > 0)
                {
                    self.cookiesArray = theCookies;
                    
                    for (NSHTTPCookie *cookie in theCookies)
                    {
                        //converting the expiry date to string
                        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
                        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
                        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
                        
                        NSString *expireString = [dateFormatter stringFromDate:cookie.expiresDate];
                        
                        //Method to return cookie parameters in single string
                        NSString *cookieStr=[DNLoginViewController globalCookieFromParameters:cookie.name withValue:cookie.value withExpiryDate:expireString withSession:cookie.isSessionOnly withDomain:cookie.domain withPath:cookie.path andIsSecure:cookie.isSecure];
                        //Assigning globalcookie with cookieStr
                        sharedInstance.gCookie=cookieStr;
                        
                        // Saving gCookieInPostApi with value 
                        sharedInstance.gCookieInPostApi = cookie.value;
                       
                    }

                }
                break;
            }
            default:
                break;
        }
    }
    else if(connection == userDataConnection)
    {
        userData= [[NSMutableData alloc] init];
    }
    else if(connection == userOrganizationConnection)
    {
        [organizationData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(connection == loginConnection)
    {
        [loginData appendData:data];
    }
    else if(connection == userDataConnection)
    {
        [userData appendData:data];
    }
    else if(connection == userOrganizationConnection)
    {
        [organizationData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // enable user interaction in any case
    [self.view setUserInteractionEnabled:YES];
    
    NSDictionary* jsonLogin;
    
    if(connection == loginConnection)// Fetching Response of login api
    {
        // NSLog(@"LOGIN didReceiveData");

//        NSString *responseStringLogin = [[NSString alloc] initWithData:loginData encoding:NSUTF8StringEncoding];
        // NSLog(@"response string: %@", responseStringLogin);
        //// NSLog(@"cookies  %@", self.cookiesArray);
        NSError *requestError;
         jsonLogin = [NSJSONSerialization
                              JSONObjectWithData:loginData
                              options:kNilOptions
                              error:&requestError];
        
        // if login is successful then only let user into app
        if(([[jsonLogin objectForKey:@"success"] boolValue] ||
            ![[jsonLogin objectForKey:@"status"] isEqualToString:@"Sorry, authentication failed"])
           && !requestError)
        {
            NSString *tempCSRFToken = [jsonLogin objectForKey:@"csrf_token"];
            // NSLog(@"tempcsrftokenn=%@",tempCSRFToken);
            if(tempCSRFToken!=nil)
            {
                sharedInstance.gCSRF_Token = tempCSRFToken;
                //Calling user API
                [self getUserInfo];
                
            }
        }
        else // else Let user login again
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:[jsonLogin objectForKey:@"status"] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            
            //Stop spinner
            //[_spinner stopAnimating];
            if(self.spinnerImageView!=nil)
            {
                [self.spinnerImageView removeFromSuperview];
                self.spinnerImageView = nil;
            }
            //unhiding spinner button.
            self.loginButton.hidden = NO;
            
        }
    }
    else if(connection == userDataConnection)   // Fetching response of userData api after login
    {
        // NSLog(@"USER DATA didReceiveData");

        NSError *requestError;
        // NSLog(@"Response: %@",[[NSString alloc] initWithData:userData encoding:NSUTF8StringEncoding]);
        
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:userData
                              options:kNilOptions
                              error:&requestError];
        // NSLog(@"Name: %@",[json objectForKey:@"name"]);
        
        if([json objectForKey:@"name"] != nil  && ((NSString *)[json objectForKey:@"name"]).length>0)
        {
            //Saving the userInfo Dictionary globally
            sharedInstance.gUserInfoDictionary=json;
            
            // NSLog(@"Name: %@",[json objectForKey:@"name"]);
            // NSLog(@"Image URL: %@",[json objectForKey:@"image"]);
            
            //Downloading image and setting it to imageView
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *ImageURL =[NSString stringWithFormat:@"http:%@",[json objectForKey:@"image"]];
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:ImageURL]];
                NSString* userName= [json objectForKey:@"name"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //Store UserName and Image to userDefaults
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:userName forKey:@"userName"];
                    [defaults setObject:imageData forKey:@"userImage"];
                    
                });
            });
            
            [self getuserOraganizationsList];
        }
        else // else Let user login again
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Oops! could not log you in!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            
            // ****** remove spinner , show login button, enable view interaction
            if(self.spinnerImageView!=nil)
            {
                [self.spinnerImageView removeFromSuperview];
                self.spinnerImageView = nil;
            }
            //unhiding spinner button.
            self.loginButton.hidden = NO;
        }
        
    }
    else if(connection == userOrganizationConnection) // Fetching response of user's organisation api
    {
        // NSLog(@"ORG  DATA received ");

        NSError *requestError;

        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:organizationData
                              options:kNilOptions
                              error:&requestError];
        // NSLog(@"Response org data : %@",json);
        
        sharedInstance.userOrganizations = [[NSDictionary alloc] initWithDictionary: json];
        
        // first check if we have received succuss response while autologin
        if(([json objectForKey:@"success"] && [[json objectForKey:@"organizations"] count]>0) &&([sharedInstance.gCSRF_Token length]>0))
        {
            // now we have succesfully logged in ; save the credentials and a flag 
            [[NSUserDefaults standardUserDefaults] setValue:_textFieldEmail.text forKey:@"user_id"];
            [[NSUserDefaults standardUserDefaults] setValue:_textFieldPassword.text forKey:@"password"];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLoggedOutLastTime"];
            
            // also store global shared cokkie data in user defaults
            [[NSUserDefaults standardUserDefaults] setValue:sharedInstance.gCookie forKey:@"gCookie"];
            [[NSUserDefaults standardUserDefaults] setValue:sharedInstance.gCookieInPostApi forKey:@"gCookieInPostApi"];
            [[NSUserDefaults standardUserDefaults] setValue:sharedInstance.gCSRF_Token forKey:@"gCSRF_Token"];
            
            // Performing segue
            [self performSegueWithIdentifier:@"loginSuccess" sender:self];

        }
        else // else Let user login again
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:@"Oops! could not log you in!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
        }
        
        // ****** remove spinner , show login button, enable view interaction
        if(self.spinnerImageView!=nil)
        {
            [self.spinnerImageView removeFromSuperview];
            self.spinnerImageView = nil;
        }
        //unhiding spinner button.
        self.loginButton.hidden = NO;
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // ****** remove spinner , show login button, enable view interaction
    //Stoping the activity indicator
    if(self.spinnerImageView!=nil)
    {
        [self.spinnerImageView removeFromSuperview];
        self.spinnerImageView = nil;
    }
    //unhiding spinner button.
    self.loginButton.hidden = NO;
    [self.view setUserInteractionEnabled:YES];
    
    if(connection == loginConnection)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:[NSString stringWithFormat:@"ERROR! %@", [error.userInfo objectForKey:@"NSLocalizedDescription"]] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
    else if(connection == userDataConnection)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:[NSString stringWithFormat:@"Error fetching user data: %@", [error.userInfo objectForKey:@"NSLocalizedDescription"]] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
    else if(connection == userOrganizationConnection)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delve" message:[NSString stringWithFormat:@"Error fetching user's organization data: %@", [error.userInfo objectForKey:@"NSLocalizedDescription"]] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
    
    // NSLog(@"LOGIN ERROR OCCURED %@",[error.userInfo objectForKey:@"NSLocalizedDescription"]);
}


#pragma mark - Textfield delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [_textFieldEmail resignFirstResponder];
//    [_textFieldPassword resignFirstResponder];
    [self.view endEditing:YES];
    return YES;
}
- (void)viewDidUnload {
    [self setLoginButton:nil];
    [super viewDidUnload];
}
@end
