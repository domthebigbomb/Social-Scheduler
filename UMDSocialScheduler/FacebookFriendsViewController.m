//
//  FacebookFriendsViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/7/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "FacebookFriendsViewController.h"
#import "ContactCell.h"
#import "ContactScheduleCell.h"
#import "ScheduleTheaterViewController.h"
#import  <QuartzCore/QuartzCore.h>
#import "AFNetworking.h"

@interface FacebookFriendsViewController ()
- (IBAction)showSchedule:(UIButton *)sender;
- (IBAction)hideSchedule:(UIButton *)sender;
- (IBAction)toggleSharing:(UISwitch *)sender;
@property (strong,nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UIAlertView *alertMsg;
@property (weak, nonatomic) IBOutlet UILabel *sharingEnabledLabel;
@property (weak, nonatomic) IBOutlet UISwitch *sharingSwitch;
@property (weak,nonatomic) IBOutlet UIToolbar *sharingToolbar;
@property (weak,nonatomic) IBOutlet UIProgressView *progressBar;
@property (strong,nonatomic) UIRefreshControl *friendRefresher;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;

@property int numFinished;
@end

@implementation FacebookFriendsViewController{
    NSString *socialSchedulerURLString;
    NSString *getListOfFriendsURLString;
    NSString *fbLoginURLString;
    NSString *scheduleSharingURLString;
    NSMutableData *contactData;
    NSDictionary *jsonDict;
    NSDictionary *organizedContacts;
    NSMutableDictionary *userSchedule;
    NSMutableDictionary *contactSchedules;
    NSMutableDictionary *contactPics;
    NSMutableArray *contacts;
    NSMutableArray *contactWithMutualClasses;
    NSString *getFriendsInCourseURLString;
    UIImage *contactScheduleImage;
    NSString *scheduleFbid;
    NSString *termCode;
    AFNetworkReachabilityManager *reachability;
    AFHTTPRequestOperationManager *manager;
    //FBLoginView *loginView;
    BOOL showSchedule;
    BOOL isRefreshing;
    NSInteger scheduleIndex;
}

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
    [self contactTableView].dataSource = self;
    contactPics = [[NSMutableDictionary alloc] init];
    contactSchedules = [[NSMutableDictionary alloc] init];
    contactWithMutualClasses = [[NSMutableArray alloc] init];
    manager = [AFHTTPRequestOperationManager manager];
    isRefreshing = NO;
    
    _friendRefresher = [[UIRefreshControl alloc] init];
    [_friendRefresher addTarget:self action:@selector(refreshFriends) forControlEvents:UIControlEventValueChanged];
    [_contactTableView addSubview:_friendRefresher];
    
    _sharingToolbar.layer.masksToBounds = NO;
    _sharingToolbar.layer.shadowOffset = CGSizeMake(0, 2);
    _sharingToolbar.layer.shadowRadius = 5;
    _sharingToolbar.layer.shadowOpacity = 0.5;
    
    reachability = [AFNetworkReachabilityManager sharedManager];

    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    getListOfFriendsURLString = @"friends_with_app";
    fbLoginURLString = @"access?access_token=";
    getFriendsInCourseURLString = @"friends?";
    
    CGRect loginFrame = CGRectFromString([NSString stringWithFormat: @"{{50,%f},{200,46}}",_greyedBackgroundView.center.y]);
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        loginFrame = CGRectFromString(@"{{225, 547},{321,66}}");
    }
    
    //_loginView = [[FBLoginView alloc] initWithFrame:loginFrame];
    [_loginView setReadPermissions:@[@"public_profile",@"email",@"user_friends",@"user_likes"]];
    [_loginView setDefaultAudience:FBSessionDefaultAudienceFriends];
    [_loginView setPublishPermissions:@[@"publish_actions" ]];
    [_loginView setHidden: YES];
    [_loginView setDelegate:self];
    [_closeScheduleButton setHidden:YES];
    //[_greyedBackgroundView addSubview:loginView];
    
    if ([_contactTableView respondsToSelector:@selector(setSectionIndexColor:)]) {
        _contactTableView.sectionIndexColor = [UIColor redColor]; // some color
        _contactTableView.sectionIndexTrackingBackgroundColor = [UIColor clearColor]; // some other color
        _contactTableView.sectionIndexBackgroundColor = [UIColor clearColor];
    }
    
    /*
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshFriends"]){
        [self refreshFriends];
    }
    */
    //[self refreshFriends];
    [[UINavigationBar appearance] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];

}

-(void)viewDidAppear:(BOOL)animated{
    //[_activityIndicator stopAnimating];
    if([[FBSession activeSession] accessTokenData] == nil){
        [_progressBar setHidden: YES];
        [_activityIndicator stopAnimating];
        [_closeScheduleButton setHidden:YES];
        [_greyedBackgroundView setHidden:NO];
        [_loginView setHidden:NO];
    }else{
        if(!isRefreshing){
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshFriends"]){
                [self refreshFriends];
            }else if([contacts count] == 0){
                [self refreshFriends];
            }
        }
    }
}

-(void)refreshFriends{
    isRefreshing = YES;
    [_progressBar setProgress:0.0];
    [_activityIndicator startAnimating];
    [_progressBar setHidden: NO];
    [_greyedBackgroundView setHidden: NO];
    [_closeScheduleButton setHidden:YES];
    _numFinished = 0;
    NSString *courseString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Courses"];
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    if(courseString == nil || termCode == nil){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Session Expired" message:@"Please login to refresh class data" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [_alertMsg show];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        [_friendRefresher endRefreshing];
        return;
    }
    userSchedule = [[NSMutableDictionary alloc] init];
    NSUInteger index;
    while(![courseString isEqualToString:@""]){
        index =[courseString rangeOfString:@"|"].location;
        NSString *class = [courseString substringToIndex:index];
        courseString = [courseString substringFromIndex:index + 1];
        index =[courseString rangeOfString:@"/"].location;
        NSString *section = [courseString substringToIndex: index];
        courseString = [courseString substringFromIndex:index + 1];
        [userSchedule setObject:section forKey:class];
    }
    
    [_loginView setHidden:YES];
    
    if([[FBSession activeSession] accessTokenData] == nil){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Please login to facebook to access this feature" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [_alertMsg show];
        [_activityIndicator stopAnimating];
        [_loginView setHidden:NO];
        [_friendRefresher endRefreshing];
    }
    
    if(![reachability isReachable]){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
        [_friendRefresher endRefreshing];
    }else{
        if([[FBSession activeSession] accessTokenData] != nil){
            NSString *getContactString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,getListOfFriendsURLString];
            NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
            NSURL *getContactURL = [NSURL URLWithString:getContactString];
            NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
            NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
            
            [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                //[_progressBar setProgress:0.5 animated:YES];
                NSError *error;
                NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
                NSLog(@"Login Response: %@", response);
                NSLog(@"Login Error: %@", connectionError);
                NSLog(@"Login JSON: %@",[JSON description]);
                
                NSDictionary *loginData = [[NSDictionary alloc] initWithDictionary:[JSON valueForKey:@"data"]];
                BOOL shareEnabled = [[loginData valueForKey:@"share"] boolValue];
                NSLog(@"Sharing Enabled: %d",shareEnabled);
                
                if(!shareEnabled){
                    [_sharingEnabledLabel setText:@"No"];
                    [_sharingSwitch setOn:NO];
                }
                
                NSURLRequest *request = [NSURLRequest requestWithURL:getContactURL];
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                    [contactData appendData:data];
                    [_progressBar setProgress:0.1 animated:YES];
                    NSError *error;
                    NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error: &error];
                    if([[JSON valueForKey:@"success"] integerValue] == 1){
                        contacts = [[NSMutableArray alloc] initWithArray:[JSON valueForKey:@"data"]];
                        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                        [contacts sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
                        NSLog(@"Sorted Contacts: %@",[contacts description]);
                        
                        NSArray *courses = [userSchedule allKeys];
                        //for(NSString *course in courses){
                        for(int i = 0; i < [courses count]; i++){
                            NSLog(@"Progress: %f",[_progressBar progress]);
                            NSString *course = [courses objectAtIndex:i];
                            NSURLRequest *getCourseFriendsRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@term=%@&course=%@",socialSchedulerURLString,getFriendsInCourseURLString,termCode,course]]];
                            [NSURLConnection sendAsynchronousRequest:getCourseFriendsRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                NSError *error;
                                NSMutableDictionary *courseFriendsJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
                                NSArray *friends = [courseFriendsJSON objectForKey:@"data"];
                                for(NSDictionary *friend in friends){
                                    NSString *fbid = [friend objectForKey:@"fbid"];
                                    if(![contactWithMutualClasses containsObject:fbid]){
                                        [contactWithMutualClasses addObject:fbid];
                                    }
                                }
                                
                                //NSLog(@"Contact With Mutual Classes: %@",[contactWithMutualClasses description]);
                                
                                for(NSString *fbid in contactWithMutualClasses){
                                    NSURLRequest *scheduleRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.umdsocialscheduler.com/schedule?term=%@&fbid=%@",termCode,fbid]]];
                                    NSURLResponse *response;
                                    NSError *error;
                                    NSData *data = [NSURLConnection sendSynchronousRequest:scheduleRequest returningResponse:&response error:&error];
                                    NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
                                    NSArray *contactCourses = [[NSArray alloc] initWithArray:[JSON valueForKey:@"data"]];
                                    [contactSchedules setObject:contactCourses forKey:fbid];
                                }
                                
                                NSLog(@"%@",[jsonDict description]);
                                NSLog(@"Contact Response: %@", response);
                                NSLog(@"Contact Error: %@", connectionError);
                                
                                [_progressBar setProgress:[_progressBar progress] + (.9/[courses count]) animated:YES];
                                
                                NSLog(@"Progress: %f",[_progressBar progress]);
                                // DEBUGGING PURPOSES
                                //[contacts removeAllObjects];
                                _numFinished += 1;
                                if(_numFinished == [courses count]){
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        //[_progressBar setProgress:1.0 animated:YES];
                                        [_activityIndicator stopAnimating];
                                        [_closeScheduleButton setHidden:NO];
                                        [_greyedBackgroundView setHidden:YES];
                                        [_progressBar setHidden:YES];
                                        organizedContacts = [[NSDictionary alloc] initWithDictionary:[self organizeNamesFromList:contacts]];
                                        [[self contactTableView] setHidden:NO];
                                        [[self contactTableView] reloadData];
                                        isRefreshing = NO;
                                        [_friendRefresher endRefreshing];
                                    });
                                }
                                
                            }];
                        }
                    }else{
                        NSLog(@"Failed to authenticate facebook with umd social scheduiler");
                        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't connect facebook to UMD Social Scheduler service" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                        [_alertMsg show];
                        [_activityIndicator stopAnimating];
                        [_progressBar setHidden:YES];
                        isRefreshing = NO;
                    }
                }];
            }];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshFriends"];
        }
    }
}

-(NSMutableDictionary *)organizeNamesFromList:(NSArray *)list{
    NSMutableDictionary *organizedNames = [[NSMutableDictionary alloc] init];
    for(NSDictionary *contact in list){
        NSString *name = [contact objectForKey:@"name"];
        NSString *firstChar = [name substringToIndex:1];
        NSMutableArray *names = [organizedNames objectForKey:firstChar];
        if(names == nil){
            names = [[NSMutableArray alloc] init];
        }
        [names addObject:contact];
        [organizedNames setObject:names forKey:firstChar];
    }
    return organizedNames;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [[organizedContacts allKeys] count];
    // Try adding sections 
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *letters = [[organizedContacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSString *letter = [letters objectAtIndex:section];
    return [[organizedContacts objectForKey:letter] count];
    /* old logic
    if ([contacts count] == 0){
            return 1;
    }
    return [contacts count];
     */
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"ContactCell";
    
    
    if ([contacts count] == 0){
        cellIdentifier = @"NoFriends";
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        return cell;
    }
    
    ContactCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    NSArray *contactKeys = [[organizedContacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSString *letter = [contactKeys objectAtIndex:indexPath.section];
    NSInteger rowNumber = indexPath.row;
    NSDictionary *contactInfo = [[organizedContacts objectForKey:letter] objectAtIndex:rowNumber];
    // NSDictionary *contactInfo = [contacts objectAtIndex:rowNumber];
    NSString *name = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"name"]];
    NSString *fbid = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"fbid"]];
    NSString *share = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"share"]];
    NSArray *contactPicFbids = [contactPics allKeys];
    
    cell.contactPic.layer.cornerRadius = cell.contactPic.layer.frame.size.width/2;
    cell.contactPic.layer.borderColor = [self.view backgroundColor].CGColor;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        //[cell.cardView.layer setCornerRadius:4.0f];
        //[cell.cardShadow.layer setCornerRadius:4.0f];
        //cell.contactPic.layer.borderWidth = 2.0f;
    }else{
        [cell.cardView.layer setCornerRadius:2.0f];
        [cell.cardShadow.layer setCornerRadius:2.0f];
        //cell.contactPic.layer.borderWidth = 1.5f;
    }
    cell.imageShadow.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.imageShadow.layer.shadowOffset = CGSizeMake(1, 2);
    cell.imageShadow.layer.shadowOpacity = 0.5;
    cell.imageShadow.layer.shadowRadius = 3.0f;
    cell.imageShadow.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:cell.contactPic.frame cornerRadius:cell.contactPic.layer.frame.size.width/2].CGPath;
    cell.contactPic.layer.masksToBounds = YES;

    [cell.contactPic setImage:[UIImage imageNamed:@"fb_default.jpg"]];
    if([reachability isReachable]){
        if(![contactPicFbids containsObject:fbid]){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //Crashes here
                NSString *contactPicString;
                if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                    contactPicString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&height=160&width=160",fbid];
                }else{
                    CGRect screenRect = [[UIScreen mainScreen] bounds];
                    CGFloat screenHeight = screenRect.size.height;
                    NSNumber *fbDim;
                    int dim = cell.contactPic.frame.size.height;

                    if(screenHeight >= 736){
                        fbDim = [NSNumber numberWithInt:dim*3];
                    }else{
                        fbDim = [NSNumber numberWithInt:dim*2];
                    }
                    contactPicString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&height=%@&width=%@",fbid,fbDim,fbDim];
                }
                
                AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:contactPicString]]];
                [operation setResponseSerializer:[AFImageResponseSerializer serializer]];
                [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //UIImage *contactPic = [[UIImage alloc] initWithData:responseObject];
                    [contactPics setObject:responseObject forKey:fbid];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ContactCell *updatedContact = (ContactCell *)[_contactTableView cellForRowAtIndexPath:indexPath];
                        if(updatedContact){
                            [cell.contactPic setImage: [contactPics objectForKey:fbid]];
                            [updatedContact setNeedsLayout];
                        }
                    });
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Error grabbing fb contact pic: %@", [error localizedDescription]);
                }];
                [operation start];
                //UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:contactPicString]]];
                            });
        }else{
            [cell.contactPic setImage:[contactPics objectForKey:fbid]];
        }
    }else{
        /*
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"Please make sure you are connected to the internet" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [_alertMsg show];
         */
    }
    
    NSArray *contactSchedule = [[NSArray alloc] initWithArray:[contactSchedules objectForKey:fbid]];
    NSMutableArray *mutualClasses = [[NSMutableArray alloc] init];
    for(NSDictionary *class in contactSchedule){
        NSString *courseName = [class objectForKey:@"course_code"];
        if([[userSchedule allKeys] containsObject:courseName]){
            [mutualClasses addObject:courseName];
        }
    }
    [cell.numCoursesLabel setText:@"No Mutual Classes"];
    for(int i = 0; i< [mutualClasses count]; i++){
        //NSString *section = [class objectForKey:@"section"];
        if(i==0){
            [cell.numCoursesLabel setText: [mutualClasses firstObject]];
        }else{
            [cell.numCoursesLabel setText: [NSString stringWithFormat:@"%@, %@",[cell.numCoursesLabel text],[mutualClasses objectAtIndex:i]]];
        }
    }
    cell.fbid = fbid;
    [cell.nameLabel setText: name];
    [cell.showScheduleButton setEnabled: YES];
    [cell.showScheduleButton setHidden: NO];
    if([share isEqualToString:@"0"]){
        [cell.showScheduleButton setEnabled:NO];
        [cell.showScheduleButton setHidden:YES];
    }else{
        [cell.showScheduleButton setEnabled:YES];
        [cell.showScheduleButton setHidden:NO];
    }
    return cell;
}

-(void)viewDidLayoutSubviews
{
    if ([_contactTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [_contactTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([_contactTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [_contactTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self correctNavBarHeightForOrientation:toInterfaceOrientation];
}

- (void) correctNavBarHeightForOrientation:(UIInterfaceOrientation)orientation {
    // This is only needed in on the iPhone, since this is a universal app, check that first.
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone){
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            _navBar.frame = CGRectMake(self.navBar.frame.origin.x, self.navBar.frame.origin.y, self.navBar.frame.size.width, 32.0f);
        } else {
            _navBar.frame = CGRectMake(self.navBar.frame.origin.x, self.navBar.frame.origin.y, self.navBar.frame.size.width, 44.0f);
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)loginViewFetchedUserInfo:(FBLoginView *)fbloginView user:(id<FBGraphUser>)user{
    if(!isRefreshing){
        [_loginView setHidden:YES];
        [self refreshFriends];
    }
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    NSLog(@"Logged into Facebook");
}

-(IBAction)logout:(id)sender{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Schedule"];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showSchedule:(UIButton *)sender {
    ScheduleTheaterViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ScheduleTheater"];
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:_contactTableView];
    NSIndexPath *indexPath = [_contactTableView indexPathForRowAtPoint:buttonPosition];
    ContactCell *contact = (ContactCell *) [[self contactTableView] cellForRowAtIndexPath:indexPath];
    vc.fbid = contact.fbid;
    vc.studentName = contact.nameLabel.text;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self.tabBarController setModalPresentationStyle:UIModalPresentationCurrentContext];
    [self.tabBarController presentViewController:vc animated:NO completion:nil];
    [vc.view setAlpha:0];
    [UIView animateWithDuration:0.5 animations:^{
        [vc.view setAlpha:1];
    }];

}

- (IBAction)hideSchedule:(UIButton *)sender {
    [_greyedBackgroundView setHidden:YES];
}

- (IBAction)toggleSharing:(UISwitch *)sender {
    NSString *toggleSharingString;
    if([sender isOn]){
        [_sharingEnabledLabel setText:@"Yes"];
        toggleSharingString = @"enable_sharing";
    }else{
        [_sharingEnabledLabel setText:@"No"];
        toggleSharingString = @"disable_sharing";
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"By disabling sharing, your friends' wont be able to view your schedule!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [_alertMsg show];
    }
    NSURL *url = [NSURL URLWithString:[socialSchedulerURLString stringByAppendingString:toggleSharingString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        //NSLog(@"Sharing Response: %@",[response description]);
        NSString *description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Sharing Data: %@", description);
    }];
}

@end
