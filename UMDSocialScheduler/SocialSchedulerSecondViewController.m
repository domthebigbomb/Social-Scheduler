
//
//  SocialSchedulerSecondViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/5/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "SocialSchedulerSecondViewController.h"
#import "CourseCell.h"
#import "FBLoginCell.h"
#import "Reachability.h"
#import "ClassContactCell.h"
#import "CourseDetailViewController.h"

@interface SocialSchedulerSecondViewController ()
@property (strong,nonatomic) NSMutableDictionary *courses;
@property (weak, nonatomic) IBOutlet UITableView *courseTableView;
@property (weak, nonatomic) IBOutlet UILabel *cellMsgLabel;
@property (strong,nonatomic) NSArray *courseKeys;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) UIAlertView *alertMsg;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation SocialSchedulerSecondViewController{
    NSString *socialSchedulerURLString;
    NSString *classesWithContactURLString;
    NSString *fbLoginURLString;
    NSString *courseString;
    NSString *courseDetails;
    NSString *termCode;
    NSArray *bldgCodes;
    NSMutableArray *insertIndexPaths;
    NSMutableDictionary *contactPics;
    Reachability *internetReachability;
    NetworkStatus network;
    NSInteger selectedIndex;
    NSInteger courseIndex;
    BOOL loggedIntoFB;
    BOOL showContact;
    BOOL isUpdating;
    BOOL isAnimating;
}

-(void)refreshFacebookToken{
    if([FBSession activeSession].state == FBSessionStateCreatedTokenLoaded){
        //[FBSession open]
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_cellMsgLabel setAlpha:0.0];
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    classesWithContactURLString = @"friends?";
    fbLoginURLString = @"access?access_token=";
    internetReachability = [Reachability reachabilityForInternetConnection];
    network = [internetReachability currentReachabilityStatus];
    loggedIntoFB = YES;
    if(network == NotReachable){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"No internet connection" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
        [_alertMsg show];
    }else{
        NSURL *bldgURL = [NSURL URLWithString:@"http://www.kimonolabs.com/api/cqwtzoos?apikey=437387afa6c3bf7f0367e782c707b51d"];
        NSData *data = [NSData dataWithContentsOfURL:bldgURL];
        NSError *error;
        bldgCodes = [[NSArray alloc] initWithArray:[[[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] objectForKey:@"results"] objectForKey:@"BuildingCodes"]];
    }
    
    insertIndexPaths = [[NSMutableArray alloc] init];
    contactPics = [[NSMutableDictionary alloc] init];
    //[self refreshClasses];
}

-(void)viewDidAppear:(BOOL)animated{
    network = [internetReachability currentReachabilityStatus];
    isUpdating = NO;
    isAnimating = NO;
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    if(network == NotReachable){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else if([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshClasses"]){
        [self refreshClasses];
    }else if([_courseKeys count] == 0){
        [self refreshClasses];
    }
}

-(void)refreshClasses{
    NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
    [_activityIndicator startAnimating];
    NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
    NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
    [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSError *err;
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
        NSLog(@"Attempt to submit token: %@",[responseData description]);
        if(responseData == nil){
            loggedIntoFB = NO;
            [_courseTableView reloadData];
        }
    }];
    courseString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Courses"];
    courseDetails = [[NSUserDefaults standardUserDefaults] stringForKey:@"CourseDetails"];
    
    if(courseString == nil){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Session Expired" message:@"Please login again to refresh class data" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [_alertMsg show];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // Parse Course String to get classes
    _courses = [[NSMutableDictionary alloc] init];
    NSUInteger index;
    while(![courseString isEqualToString:@""]){
        index =[courseString rangeOfString:@"|"].location;
        NSString *class = [courseString substringToIndex:index];
        courseString = [courseString substringFromIndex:index + 1];
        index =[courseString rangeOfString:@"/"].location;
        NSString *section = [courseString substringToIndex: index];
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        [properties setObject:section forKey:@"section"];
        courseString = [courseString substringFromIndex:index + 1];
        [_courses setObject:properties forKey:class];
    }
    
    for(NSString *class in _courses){
        NSMutableDictionary *properties = [_courses objectForKey:class];
        NSString *relevantData = [courseDetails substringFromIndex:[courseDetails rangeOfString:class].location];
        relevantData = [relevantData substringToIndex:130];
        NSNumber *credits = [[NSNumber alloc] initWithDouble: [[[[relevantData substringFromIndex:32] substringToIndex:5] stringByReplacingOccurrencesOfString:@" " withString:@""] doubleValue]];
        NSString *primaryDays = [[[relevantData substringFromIndex:46] substringToIndex:5] stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *primaryTimes = [[[relevantData substringFromIndex:53] substringToIndex:8] stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *primaryBldgCode = [[[relevantData substringFromIndex:61] substringToIndex:3] stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *primaryRoomNum = [[[relevantData substringFromIndex:65] substringToIndex:4] stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *secondaryDays = [[[relevantData substringFromIndex:74] substringToIndex:5] stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *secondaryTimes = [[[relevantData substringFromIndex:81] substringToIndex:8] stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *secondaryBldgCode = [[[relevantData substringFromIndex:89] substringToIndex:3]stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *secondaryRoomNum = [[[relevantData substringFromIndex:93] substringToIndex:4] stringByReplacingOccurrencesOfString:@" " withString:@""];
        [properties setValue:credits forKey:@"Credits"];
        [properties setObject:primaryDays forKey:@"PrimaryDays"];
        [properties setObject:primaryTimes forKey:@"PrimaryTimes"];
        [properties setObject:primaryBldgCode forKey:@"PrimaryBldgCode"];
        [properties setObject:primaryRoomNum forKey:@"PrimaryRoomNum"];
        [properties setObject:secondaryDays forKey:@"SecondaryDays"];
        [properties setObject:secondaryTimes forKey:@"SecondaryTimes"];
        [properties setObject:secondaryBldgCode forKey:@"SecondaryBldgCode"];
        [properties setObject:secondaryRoomNum forKey:@"SecondaryRoomNum"];
        //[_courses setObject:properties forKey:class];
    }
    _courseKeys = [[NSArray alloc] initWithArray:[_courses allKeys]];
    NSLog(@"Courses: %@",[_courses description]);
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshClasses"];
    [_activityIndicator stopAnimating];
    [self courseTableView].dataSource = self;
    [self courseTableView].delegate = self;
    [[self courseTableView] reloadData];
    //data = [NSURLConnection sendSynchronousRequest:fbLoginRequest returningResponse:&response error:&error];
    
}

-(void)animateCellMsg{
    [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [_cellMsgLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0 delay:2.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [_cellMsgLabel setAlpha:0];
        } completion:^(BOOL finished) {
            isAnimating = NO;
        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    courseIndex = indexPath.row;
    NSLog(@"Selected Index: %ld", (long)selectedIndex);
    NSLog(@"Number of contacts: %lu", (unsigned long)[_contacts count]);
    if(courseIndex > selectedIndex){
        courseIndex -= [_contacts count];
    }
    [self performSegueWithIdentifier:@"ShowCourseDetails" sender:self];
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(isAnimating){
        return nil;
    }
    return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //Address the bug in ios7 where separators would disappear
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(!isUpdating){
        network = [internetReachability currentReachabilityStatus];
        if(network == NotReachable){
            isAnimating = YES;
            [_cellMsgLabel setText:@"Please check internet connection"];
            [self performSelectorOnMainThread:@selector(animateCellMsg) withObject:nil waitUntilDone:NO];
            //_alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
            //[_alertMsg show];
        }else if([[FBSession activeSession] accessTokenData] == nil){
            isAnimating = YES;
            [_cellMsgLabel setText:@"Log in to Facebook to view friends"];
            [self performSelectorOnMainThread:@selector(animateCellMsg) withObject:nil waitUntilDone:NO];
            //_alertMsg = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"You are not signed into facebook. In order to view friends in your classes, please sign into facebook at the login screen." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            //[_alertMsg show];
        }else{
            NSInteger row = indexPath.row;
            selectedIndex = row;
            if(!showContact){
                isUpdating = YES;
                NSString *course = [_courseKeys objectAtIndex:row];
                NSString *requestString = [NSString stringWithFormat:@"%@%@term=%@&course=%@",socialSchedulerURLString,classesWithContactURLString,termCode,course];
                NSURL *requestURL = [NSURL URLWithString:requestString];
                NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                    NSError *error;
                    NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
                    _contacts = [[NSMutableArray alloc] initWithArray:[JSON objectForKey:@"data"]];
                    if([_contacts count] > 0){
                        for(int i = 0; i< [_contacts count]; i++){
                            [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row+i+1 inSection:0]];
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_courseTableView beginUpdates];
                            showContact = YES;
                            [_courseTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation: UITableViewRowAnimationFade];
                            [_courseTableView endUpdates];
                            isUpdating = NO;
                        });
                    }else{
                        isUpdating = NO;
                        
                        [_cellMsgLabel setText:[NSString stringWithFormat:@"No friends in %@ 😥",course]];
                        [self performSelectorOnMainThread:@selector(animateCellMsg) withObject:nil waitUntilDone:NO];
                    }
                    
                }];
            }else{
                isUpdating = YES;
                showContact = NO;
                selectedIndex = 0;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_courseTableView beginUpdates];
                    showContact = NO;
                    [_contacts removeAllObjects];
                    
                    [_courseTableView deleteRowsAtIndexPaths:insertIndexPaths withRowAnimation:     UITableViewRowAnimationAutomatic];
                    [insertIndexPaths removeAllObjects];
                    [_courseTableView endUpdates];
                    isUpdating = NO;
                });
            }
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int fbConst = 0;
    if(!loggedIntoFB){
        fbConst = 1;
    }
    return [_courses count] + [_contacts count] + fbConst;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger rowNumber = indexPath.row;
    NSInteger numContacts = [_contacts count];
    if(indexPath.row == ([_contacts count]+[_courseKeys count])){
        FBLoginCell *fbCell = (FBLoginCell *)[tableView dequeueReusableCellWithIdentifier:@"Facebook"];
        [fbCell.loginView setReadPermissions:@[@"public_profile",@"user_friends",@"email",@"user_likes"]];
        [fbCell.loginView setDefaultAudience:FBSessionDefaultAudienceFriends];
        [fbCell.loginView setPublishPermissions:@[@"publish_actions"]];
        [fbCell.loginView setDelegate:self];
        return fbCell;
    }
    if((rowNumber >= selectedIndex+1 && rowNumber < selectedIndex + numContacts +1)  && showContact){
        ClassContactCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        NSDictionary *contact = [_contacts objectAtIndex:numContacts - (rowNumber - selectedIndex)];
        NSString *name = [contact objectForKey:@"name"];
        NSString *fbid = [contact objectForKey:@"fbid"];
        NSString *section = [contact objectForKey:@"section"];
        NSString *nameWithSection = [NSString stringWithFormat:@"%@ (%@)",name, section];
        
        [cell.contactPictureView setImage:[UIImage imageNamed:@"fb_default.jpg"]];
        [cell.nameLabel setText:nameWithSection];
        if([[contactPics allKeys] containsObject:fbid]){
            [cell.contactPictureView setImage:[contactPics objectForKey:fbid]];
        }else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&height=100&width=100",fbid]]]];
                [contactPics setObject:contactPic forKey:fbid];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.contactPictureView setImage:contactPic];
                    [cell setNeedsLayout];
                });
            });
        }
        return cell;
    }else{
        CourseCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CourseCell"];
        if(showContact && rowNumber > selectedIndex)
            rowNumber -= numContacts;
        NSString *course = [_courseKeys objectAtIndex:rowNumber];
        NSDictionary *properties = [_courses objectForKey:course];
        NSString *section = [NSString stringWithFormat:@"Section: %@",[properties objectForKey:@"section"]];
        [cell.courseNumberLabel setText: course];
        [cell.sectionNumberLabel setText: section];
        return cell;
    }
}

#pragma mark FBLoginViewDelegate methods
// Facebook login related functions
-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user{
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    NSLog(@"Logged in");
    NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
    [_activityIndicator startAnimating];
    NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
    NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
    [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSLog(@"Successfully submitted fb token");
        loggedIntoFB = YES;
        [_courseTableView reloadData];
        [_activityIndicator stopAnimating];
    }];
}

-(void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView{
    loggedIntoFB = NO;
    [_courseTableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"ShowCourseDetails"]){
        CourseDetailViewController *viewController = [segue destinationViewController];
        NSString *course = [_courseKeys objectAtIndex:courseIndex];
        NSDictionary *properties = [_courses objectForKey:course];
        viewController.course = course;
        viewController.section = [properties objectForKey:@"section"];
        NSString *primBldgString = [NSString stringWithFormat:@"%@ %@",[properties objectForKey:@"PrimaryBldgCode"],[properties objectForKey:@"PrimaryRoomNum"]];
        NSString *secBldgString = [NSString stringWithFormat:@"%@ %@",[properties objectForKey:@"SecondaryBldgCode"],[properties objectForKey:@"SecondaryRoomNum"]];
        if([properties objectForKey:@"SecondaryBldgCode"] == nil || [[properties objectForKey:@"SecondaryBldgCode"] isEqualToString:@""]){
            viewController.hasDiscussion = NO;
        }else{
            viewController.hasDiscussion = YES;
            viewController.secondaryBldgString = secBldgString;
            viewController.secDays = [properties objectForKey:@"SecondaryDays"];
            NSString *secTime = [properties objectForKey:@"SecondaryTimes"];
            viewController.secondaryTimes = secTime;
        }
        viewController.primaryBldgString = primBldgString;
        viewController.primDays = [properties objectForKey:@"PrimaryDays"];
        NSLog(@"Passing in primDays: %@",[properties objectForKey:@"PrimaryDays"]);
        NSString *primTime = [properties objectForKey:@"PrimaryTimes"];
        viewController.primaryTimes = primTime;
        viewController.bldgCodes = bldgCodes;
    }
}

-(IBAction)logout:(id)sender{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Schedule"];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)dismissDetails:(UIStoryboardSegue *)segue{
    
}

// Experimental feature
-(IBAction)addToCalendar:(UIBarButtonItem *)sender{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if(error){
            NSLog(@"Error requestion calendar: %@", [error description]);
        }else if(granted){
            //NSDateComponents *components = [[NSDateComponents alloc] init];
            for(NSString *course in _courseKeys){
                //NSDictionary *properties = [_courses objectForKey:course];
                //NSInteger classLength = [[[properties objectForKey:@"PrimaryTimes"] substringFromIndex:4] integerValue] - [[[properties objectForKey:@"PrimaryTimes"] substringToIndex:4] integerValue];
                //EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                
                //NSString *days = [properties objectForKeyedSubscript:@"PrimaryDays"];
                //NSMutableArray *daysOfTheWeek = [[NSMutableArray alloc] init];
               
                /*
                EKRecurrenceRule *recurrence = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly
                                                                                            interval:1
                                                                                       daysOfTheWeek:daysOfTheWeek
                                                                                      daysOfTheMonth:nil
                                                                                     monthsOfTheYear:nil
                                                                                      weeksOfTheYear:nil
                                                                                       daysOfTheYear:nil
                                                                                        setPositions:nil
                                                                                                 end:nil];
                [event setTitle:course];
                //[event setRecurrenceRules:<#(NSArray *)#>];
                [event setStartDate:[[NSDate alloc] init]];
                event.endDate = [[NSDate alloc] initWithTimeInterval:600 sinceDate:event.startDate];
                [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                
                NSError *error;
                [eventStore saveEvent:event span:EKSpanThisEvent error:&error];
                 */
            }
        }else{
            NSLog(@"Calendar access not granted");
        }
    }];
    
}

@end
