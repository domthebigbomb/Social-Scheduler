//
//  FacebookFriendsViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/7/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "FacebookFriendsViewController.h"
#import <YAJL/YAJL.h>
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
    BOOL showSchedule;
    int scheduleIndex;
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

    internetReachability = [Reachability reachabilityForInternetConnection];
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    getListOfFriendsURLString = @"friends_with_app";
    fbLoginURLString = @"access?access_token=";
    getFriendsInCourseURLString = @"friends?";
    
    [self refreshFriends];
    
    [_scheduleScrollView addSubview:_scheduleImageView];
    [_scheduleScrollView setDelegate: self];
}

-(void)viewDidAppear:(BOOL)animated{
    BOOL refreshFriends = [[NSUserDefaults standardUserDefaults] boolForKey:@"refreshFriends"];
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

    if(refreshFriends){
        [self refreshFriends];
        
    }
}

-(void)refreshFriends{
    network = [internetReachability currentReachabilityStatus];
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
                id JSON = [data yajl_JSON];
                NSLog(@"Login Response: %@", response);
                NSLog(@"Login Error: %@", connectionError);
                NSLog(@"Login JSON: %@",[JSON yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"  "]);
                NSDictionary *loginData = [[NSDictionary alloc] initWithDictionary:[JSON valueForKey:@"data"]];
                BOOL shareEnabled = [[loginData valueForKey:@"share"] boolValue];
                NSLog(@"Sharing Enabled: %hhd",shareEnabled);
                
                if(!shareEnabled){
                    [_sharingEnabledLabel setText:@"No"];
                    [_sharingSwitch setOn:NO];
                }
                
                NSURLRequest *request = [NSURLRequest requestWithURL:getContactURL];
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                    [contactData appendData:data];
                    id JSON = [data yajl_JSON];
                    contacts = [[NSMutableArray alloc] initWithArray:[JSON valueForKey:@"data"]];
                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                    [contacts sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
                    NSLog(@"Sorted Contacts: %@",[contacts description]);
                    
                    NSArray *courses = [userSchedule allKeys];
                    for(NSString *course in courses){
                        NSURLRequest *getCourseFriendsRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@term=%@&course=%@",socialSchedulerURLString,getFriendsInCourseURLString,termCode,course]]];
                        [NSURLConnection sendAsynchronousRequest:getCourseFriendsRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                            id courseFriendsJSON = [data yajl_JSON];
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
                                id JSON = [data yajl_JSON];
                                NSArray *contactCourses = [[NSArray alloc] initWithArray:[JSON valueForKey:@"data"]];
                                [contactSchedules setObject:contactCourses forKey:fbid];
                            }
                            
                            NSLog(@"%@",[jsonDict description]);
                            NSLog(@"Contact Response: %@", response);
                            NSLog(@"Contact Error: %@", connectionError);
                            
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_activityIndicator stopAnimating];
                                [_closeScheduleButton setHidden:NO];
                                [_greyedBackgroundView setHidden:YES];
                                [[self contactTableView] setHidden:NO];
                                [[self contactTableView] reloadData];
                            });
                            
                        }];
                    }
                }];
            }];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshFriends"];
        }else{
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Please login to facebook to access this feature" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [_alertMsg show];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"ContactCell";
    
    ContactCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    int rowNumber = indexPath.row;
    NSDictionary *contactInfo = [contacts objectAtIndex:rowNumber];
    NSString *name = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"name"]];
    NSString *fbid = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"fbid"]];
    NSString *share = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"share"]];
    NSArray *contactPicFbids = [contactPics allKeys];
    
    [cell.contactPic setImage:[UIImage imageNamed:@"fb_default.jpg"]];
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

- (IBAction)showSchedule:(UIButton *)sender {
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
