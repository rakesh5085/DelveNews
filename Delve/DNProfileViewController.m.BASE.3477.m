//
//  DNProfileViewController.m
//  Delve
//
//  Created by Atul Khatri on 13/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNProfileViewController.h"
#define kHeaderLabelOffsetX 20
#define kHeaderLabelOffsetY 10
#define kHeaderLabelHeight 20
#define kBorderWidth 1.0f
#define kDropDownTag 101


@interface DNProfileViewController ()
{
    NSArray *arrayList;
}
    @property (nonatomic, retain) UITableView *tableViewDropDown;
@end

@implementation DNProfileViewController

@synthesize profileImage;
@synthesize tableViewDropDown = _tableViewDropDown;
@synthesize userName;
@synthesize articleConnection;
@synthesize articleData;
@synthesize articleCells;
@synthesize profileTableView;


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
    
    profileImage.layer.cornerRadius=5.0;
    profileImage.clipsToBounds=YES;
    
    arrayList = [[NSArray alloc] initWithObjects:@"Most recent",@"Most delved",@"Last week",@"One month ago",@"Most commented",@"Most controversial", nil];
    
    // Create dropdown
    _tableViewDropDown = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2) style:UITableViewStylePlain];
    _tableViewDropDown.dataSource = self;
    _tableViewDropDown.delegate = self;
    _tableViewDropDown.tag = kDropDownTag;
    _tableViewDropDown.hidden = YES;
    [self.view addSubview:_tableViewDropDown];
      
    [self getDelvedArticles];
    //[self getUserInfo];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    
    [self setUserName:[defaults objectForKey:@"userName"] andImage:[defaults objectForKey:@"userImage"]];
    
}


-(void)setUserName:(NSString*)name andImage:(NSData*)userImageData{
    [profileImage setImage:[UIImage imageWithData:userImageData]];
    [userName setText:name];
}

-(void)getDelvedArticles{
    
        
    //NSURL *url = [NSURL URLWithString:@"http://proto.delvenews.com/api/userarticleclip/"];
    //NSURL *url = [NSURL URLWithString:@"http://proto.delvenews.com/api/userarticleclip/?settings=%7B%22active_organization%22%3A3843%2C%22begin_date%22%3A1376245800%2C%22end_date%22%3A0%2C%22id%22%3A5252%7D"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAPI_Host_Name,@"/api/userarticleclip/?settings=%7B%22active_organization%22%3A3843%2C%22type%22%3A%22user%22%2C%22id%22%3A5252%2C%22begin_date%22%3A0%2C%22end_date%22%3A0%7D"]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString *cookie=@"sessionid=plvbxc16svd0vhj8t6awrxqdxqsvuazd; expires=Mon, 26-Aug-2013 12:08:58 GMT; httponly; Max-Age=1209600; Path=/";
    //Add cookie object here:
    [request addValue:cookie forHTTPHeaderField:@"Cookie"];
    
    articleConnection= [[NSURLConnection alloc] initWithRequest:request delegate:self];

    
}

-(void)viewWillAppear:(BOOL)animated
{
    //[DNGlobal customizeNavigationBarOnViewController:self andWithDropdownHeading:@"Most Recent"];
    [self customizeNavigationBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - helper for navigation bar

-(void)customizeNavigationBar
{
    self.navigationController.navigationBarHidden = NO;
    
    // Remove any subviews already present
    for(UIView *view in [self.navigationController.navigationBar subviews])
    {
        if(view.tag == 101 || view.tag == 102 || view.tag == 103 || view.tag == 104)
            [view removeFromSuperview];
    }
    
    // create a donw arrow image leaving right space of 10px
    UIImageView *imageViewDelveLogo = [[UIImageView alloc] initWithFrame:CGRectMake(10,10,96,24)];
    imageViewDelveLogo.image = [UIImage imageNamed:@"delve_logo.png"];
    imageViewDelveLogo.tag = 101;
    [self.navigationController.navigationBar addSubview:imageViewDelveLogo];
    
    // add the right side label
    UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake(150,10,130,24)];
    navLabel.tag = 102;
    navLabel.text = @"Most Recent";
    navLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    navLabel.textColor = [UIColor whiteColor];
    navLabel.backgroundColor = [UIColor clearColor];
    navLabel.textAlignment = NSTextAlignmentRight;
    [self.navigationController.navigationBar addSubview:navLabel];
    
    // create a down arrow image leaving right space of 10px
    UIImageView *imageViewDownArrow = [[UIImageView alloc] initWithFrame:CGRectMake(290,20,8,4)];
    imageViewDownArrow.image = [UIImage imageNamed:@"down_arrow.png"];
    imageViewDownArrow.tag = 103;
    [self.navigationController.navigationBar addSubview:imageViewDownArrow];
    
    UIButton *buttonDropdown = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonDropdown.frame = CGRectMake(160,5,140,34);
    buttonDropdown.tag = 105;
    [buttonDropdown addTarget:self action:@selector(showDropdownList:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController.navigationBar addSubview:buttonDropdown];
}

- (void)showDropdownList:(id)sender
{
    NSLog(@"showDropdownList called");

    if(_tableViewDropDown.hidden)
    {
        _tableViewDropDown.hidden=NO;
    }
    else
    {
        _tableViewDropDown.hidden=YES;
    }
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if(tableView.tag == kDropDownTag)
        return 1;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(tableView.tag == kDropDownTag)
    {
        return 0.0;
    }
    return 36.0;
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
        return [articleCells count];
    }
    
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
        }
        
        [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15]];
        cell.textLabel.text = [arrayList objectAtIndex:indexPath.row];
    }
    else
    {
        
        NSString *CellIdentifier = nil;

        DNProfileCell* articleCell= [articleCells objectAtIndex:indexPath.row];
        if (articleCell.articleComments.count >0)
        {
            CellIdentifier=@"ProfileCellWithComment";
        }
        else
        {
            CellIdentifier=@"ProfileCellWithoutComment";
        }        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if(cell== nil)
        {
            if(articleCell.articleComments.count>0)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            else
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            }
        }
        [cell.textLabel setFont:[UIFont fontWithName:@"Bitter-Regular" size:18]];
        cell.textLabel.text= articleCell.articleTitle;
        
        if (articleCell.articleComments.count>0)
        {
            int articleCount= articleCell.articleComments.count;
            if(articleCount ==1)
            {
                NSLog(@"Reached if");
                cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ commented",[articleCell.articleComments objectAtIndex:0]];
            }
            else
            {
                NSLog(@"Reached else");

                cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ and %i other commented",[articleCell.articleComments objectAtIndex:0],articleCount-1];
            }
        }
    }
    UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height)];
    bg.backgroundColor = [UIColor whiteColor];
    bg.layer.borderColor = [UIColor colorWithRed:0.901 green:0.901 blue:0.909 alpha:1].CGColor;
    bg.layer.borderWidth = kBorderWidth;
    cell.backgroundView = bg;
    cell.layer.cornerRadius=10.0f;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag == kDropDownTag)
    {
        return 44;
    }
    else
    {
        if(((DNProfileCell*)[articleCells objectAtIndex:0]).articleComments.count > 0)
        {
            return 60;
        }
        else
        {
            return 44;
        }
    }
}
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(tableView.tag != kDropDownTag)
    {        
        UIView *headerView= [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 36)];
        UILabel *headerLabel=[[UILabel alloc] initWithFrame:CGRectMake(kHeaderLabelOffsetX, kHeaderLabelOffsetY, tableView.frame.size.width, kHeaderLabelHeight)];
        
        // UILabel *headerLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 20)];
        [headerLabel setBackgroundColor:[UIColor colorWithRed:0.929 green:0.929 blue:0.929 alpha:1]];
        [headerLabel setText:@"Today"];
        
        headerLabel.font =   [UIFont fontWithName:@"HelveticaNeue-Bold" size:15]; // BOLD
        headerLabel.textColor=[UIColor colorWithRed:0.549 green:0.549 blue:0.549 alpha:1];
        [headerView addSubview:headerLabel];
        return headerView;
    }
    else
    {
        
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}


#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
//    _responseData = [[NSMutableData alloc] init];
    if(connection == articleConnection)
    {
        articleData= [[NSMutableData alloc]init];
        articleCells= [[NSMutableArray alloc] init];
    }
    NSLog(@"PROFILE didReceiveResponse");
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
//    [_responseData appendData:data];
    
     if(connection == articleConnection)
    {
        [articleData appendData:data];
    }
    NSLog(@"USER ARTICLE RESPONSE");

}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    if(connection == articleConnection)
    {

        NSString* responseString= [[NSString alloc] initWithData:articleData encoding:NSUTF8StringEncoding];
        //NSLog(@"Response: %@",responseString);
        
        NSDictionary *responseJSON =[NSJSONSerialization JSONObjectWithData: [responseString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:nil];
        //NSLog(@"Dictionary Response: %@",responseJSON);
        
        NSArray *clipList= [responseJSON objectForKey:@"clip_list"];
        //NSLog(@"ARTICLE LIST: %@",articleList);
        
        for(NSDictionary* dict in clipList)
        {
            NSDictionary* articleDict= [dict objectForKey:@"article"]; //For title , ID & link
            NSArray* clipDict= [dict objectForKey:@"clips"]; //For comments 
            NSString* date= [NSString stringWithFormat:@"%@",[dict objectForKey:@"date"]]; //For date of article posted
            
            if(![date isEqualToString:@"0"])
            {
                //Save it to articleCells Array
                DNProfileCell* profileArticleCell= [[DNProfileCell alloc] init];
                
                profileArticleCell.articleTitle=[articleDict objectForKey:@"title"];
                profileArticleCell.articleLink= [articleDict objectForKey:@"link"];
                profileArticleCell.articleID= [articleDict objectForKey:@"id"];
                profileArticleCell.articleDate= date;
                NSLog(@"ARTICLE DATE: %@",date);
                //Extract feed Delves
                for(NSDictionary* clip in clipDict)
                {
                    NSString* user_name= [clip objectForKey:@"user_name"];
                    NSLog(@"ARTICLE COMMENT :%@",user_name);
                    if(user_name.length >0)
                    {
                        [profileArticleCell.articleComments addObject:user_name];
                    }
                }
                [articleCells addObject:profileArticleCell];
            }
        }
        
        [self.profileTableView reloadData];
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}

@end
