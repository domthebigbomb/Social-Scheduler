//
//  FacebookFriendsViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/7/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "FacebookFriendsViewController.h"
#import "Reachability.h"
#import "ContactCell.h"
#import "ContactScheduleCell.h"

@interface FacebookFriendsViewController ()
- (IBAction)showSchedule:(UIButton *)sender;
- (IBAction)hideSchedule:(UIButton *)sender;
- (IBAction)toggleSharing:(UISwitch *)sender;

@property (strong,nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UIAlertView *alertMsg;
@property (weak, nonatomic) IBOutlet UILabel *sharingEnabledLabel;
@property (weak, nonatomic) IBOutlet UISwitch *sharingSwitch;
@property (weak,nonatomic) IBOutlet UIToolbar *sharingToolbar;

@end

@implementation FacebookFriendsViewController{
    NSString *socialSchedulerURLString;
    NSString *getListOfFriendsURLString;
    NSString *fbLoginURLString;
    NSString *scheduleSharingURLString;
    NSMutableData *contactData;
    NSDictionary *jsonDict;
    NSMutableDictionary *userSchedule;
    NSMutableDictionary *contactSchedules;
    NSMutableArray *contacts;
    NSMutableDictionary *contactPics;
    NSString *getFriendsInCourseURLString;
    NSMutableArray *contactWithMutualClasses;
    UIImage *contactScheduleImage;
    NSString *scheduleFbid;
    NSString *termCode;
    Reachability *internetReachability;
    NetworkStatus network;
    FBLoginView *loginView;
    BOOL showSchedule;
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

    _sharingToolbar.layer.masksToBounds = NO;
    _sharingToolbar.layer.shadowOffset = CGSizeMake(0, 2);
    _sharingToolbar.layer.shadowRadius = 5;
    _sharingToolbar.layer.shadowOpacity = 0.5;
    
    internetReachability = [Reachability reachabilityForInternetConnection];
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    getListOfFriendsURLString = @"friends_with_app";
    fbLoginURLString = @"access?access_token=";
    getFriendsInCourseURLString = @"friends?";
    
    CGRect loginFrame = CGRectFromString([NSString stringWithFormat: @"{{50,%f},{200,46}}",_refreshButton.frame.origin.y + 150]);
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        loginFrame = CGRectFromString(@"{{225, 547},{321,66}}");
    }
    
    loginView = [[FBLoginView alloc] initWithFrame:loginFrame];
    [loginView setReadPermissions:@[@"basic_info",@"email",@"user_likes"]];
    [loginView setDefaultAudience:FBSessionDefaultAudienceFriends];
    [loginView setPublishPermissions:@[@"publish_actions" ]];
    [loginView setHidden: YES];
    [loginView setDelegate:self];
    [_closeScheduleButton setHidden:YES];
    [_greyedBackgroundView addSubview:loginView];
    
    [_refreshButton setHidden:YES];
    _refreshButton.layer.cornerRadius = 3.0f;
    
    
    /*
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshFriends"]){
        [self refreshFriends];
    }
    */
    //[self refreshFriends];
    [_scheduleScrollView addSubview:_scheduleImageView];
    [_scheduleScrollView setDelegate: self];
}

-(void)viewDidAppear:(BOOL)animated{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshFriends"]){
        [self refreshFriends];
    }else if([contacts count] == 0){
        [self refreshFriends];
    }
}

-(void)refreshFriends{
    [_activityIndicator startAnimating];
    [_greyedBackgroundView setHidden: NO];
    [_refreshButton setHidden:YES];
    [_closeScheduleButton setHidden:YES];
    
    NSString *courseString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Courses"];
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
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
    
    network = [internetReachability currentReachabilityStatus];
    [loginView setHidden:YES];
    
    if([[FBSession activeSession] accessTokenData] == nil){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Please login to facebook to access this feature" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [_alertMsg show];
        [_activityIndicator stopAnimating];
        [_refreshButton setHidden:NO];
        [loginView setHidden:NO];
    }
    
    if(network == NotReachable){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else{
        if([[FBSession activeSession] accessTokenData] != nil){
            NSString *getContactString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,getListOfFriendsURLString];
            NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
            NSURL *getContactURL = [NSURL URLWithString:getContactString];
            NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
            NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
            
            [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
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
                    NSError *error;
                    NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
                    contacts = [[NSMutableArray alloc] initWithArray:[JSON valueForKey:@"data"]];
                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                    [contacts sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
                    NSLog(@"Sorted Contacts: %@",[contacts description]);
                    
                    NSArray *courses = [userSchedule allKeys];
                    //for(NSString *course in courses){
                    for(int i = 0; i < [courses count]; i++){
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
                            
                            // DEBUGGING PURPOSES
                            //[contacts removeAllObjects];
                            if(i == [courses count]-1){
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [_activityIndicator stopAnimating];
                                    [_closeScheduleButton setHidden:NO];
                                    [_greyedBackgroundView setHidden:YES];
                                    [[self contactTableView] setHidden:NO];
                                    [[self contactTableView] reloadData];
                                });
                            }
                            
                        }];
                    }
                }];
            }];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshFriends"];
        }
        
        /*
         else{
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Please login to facebook to access this feature" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [_alertMsg show];
        }
         */
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ([contacts count] == 0){
            return 1;
    }
    return [contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"ContactCell";
    
    
    if ([contacts count] == 0){
        cellIdentifier = @"NoFriends";
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        return cell;
    }
    
    ContactCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    NSInteger rowNumber = indexPath.row;
    NSDictionary *contactInfo = [contacts objectAtIndex:rowNumber];
    NSString *name = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"name"]];
    NSString *fbid = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"fbid"]];
    NSString *share = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"share"]];
    NSArray *contactPicFbids = [contactPics allKeys];
    
    [cell.contactPic setImage:[UIImage imageNamed:@"fb_default.jpg"]];
    network = [internetReachability currentReachabilityStatus];
    if(network != NotReachable){
        if(![contactPicFbids containsObject:fbid]){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&height=100&width=100",fbid]]]];
                [contactPics setObject:contactPic forKey:fbid];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ContactCell *updatedContact = (ContactCell *)[_contactTableView cellForRowAtIndexPath:indexPath];
                    if(updatedContact){
                        [cell.contactPic setImage: [contactPics objectForKey:fbid]];
                        [updatedContact setNeedsLayout];
                    }
                });
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
    }
    return cell;
}


-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _scheduleImageView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user{
    //[self refreshFriends];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    NSLog(@"Logged into Facebook");
}

- (IBAction)showSchedule:(UIButton *)sender {
    [_closeScheduleButton setHidden:NO];
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.contactTableView];
    NSIndexPath *indexPath = [self.contactTableView indexPathForRowAtPoint:buttonPosition];
    scheduleIndex = [indexPath row];
    ContactCell *contact = (ContactCell *) [[self contactTableView] cellForRowAtIndexPath:indexPath];
    UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.umdsocialscheduler.com/schedule_image?term=%@&fbid=%@",termCode, contact.fbid]]]];
    contactScheduleImage = contactPic;
    [_tapGesture setEnabled: YES];
    [_scheduleScrollView setZoomScale:1.0];
    [_scheduleImageView setImage:contactScheduleImage];
    [_greyedBackgroundView setHidden:NO];
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
    }
    NSURL *url = [NSURL URLWithString:[socialSchedulerURLString stringByAppendingString:toggleSharingString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSLog(@"Sharing Response: %@",[response description]);
        NSString *description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Sharing Data: %@", description);
    }];
}

@end
