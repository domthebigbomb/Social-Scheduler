
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
#import "ClassContactCell.h"
#import "CourseDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ScheduleTheaterViewController.h"
#import "AFNetworking.h"
#import "ScheduleManager.h"

@interface SocialSchedulerSecondViewController ()
@property (strong,nonatomic) NSMutableDictionary *courses;
@property (strong,nonatomic) NSMutableDictionary *contactsInCourses;
@property (weak, nonatomic) IBOutlet UITableView *courseTableView;
@property (weak, nonatomic) IBOutlet UILabel *cellMsgLabel;
@property (strong,nonatomic) NSArray *courseKeys;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) UIAlertView *alertMsg;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;

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
    AFNetworkReachabilityManager *reachability;
    NSInteger selectedIndex;
    NSInteger courseIndex;
    BOOL loggedIntoFB;
    BOOL showContact;
    BOOL isUpdating;
    BOOL isAnimating;
    BOOL loggedIntoScheduler;
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
    reachability = [AFNetworkReachabilityManager sharedManager];
    loggedIntoFB = YES;
    loggedIntoScheduler = NO;
    insertIndexPaths = [[NSMutableArray alloc] init];
    contactPics = [[NSMutableDictionary alloc] init];
    _contactsInCourses = [[NSMutableDictionary alloc] init];
}

-(void)viewDidAppear:(BOOL)animated{
    isUpdating = NO;
    isAnimating = NO;
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    
    if([[FBSession activeSession] accessTokenData] == nil){
        loggedIntoFB = NO;
    }
    
    if(![reachability isReachable]){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else if([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshClasses"]){
        [self refreshClasses];
    }else if([_courseKeys count] == 0){
        [self refreshClasses];
    }
    //[[UINavigationBar appearance] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
}

-(void)refreshClasses{
    [_courseTableView setUserInteractionEnabled:NO];
    NSURL *bldgURL = [NSURL URLWithString:@"http://www.kimonolabs.com/api/cqwtzoos?apikey=437387afa6c3bf7f0367e782c707b51d"];
    
    if([bldgCodes count] == 0){
        [_activityIndicator startAnimating];
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:bldgURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError *error;
            bldgCodes = [[NSArray alloc] initWithArray:[[[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] objectForKey:@"results"] objectForKey:@"BuildingCodes"]];
            
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
            [_activityIndicator stopAnimating];
            [self courseTableView].dataSource = self;
            [self courseTableView].delegate = self;
            [[self courseTableView] reloadData];
        }];
    }
    
    if([[FBSession activeSession] accessTokenData] != nil){
        NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
        NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
        NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
        [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError *err;
            NSDictionary *responseData = [[NSDictionary alloc] initWithDictionary:[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err]] ;
            NSLog(@"Attempt to submit token: %@",[responseData description]);
            if(responseData == nil){
                loggedIntoFB = NO;
            }else if([[responseData objectForKey:@"success"] integerValue] == 0){
                NSLog(@"Unsuccessful authorization of access token");
            }else{
                loggedIntoScheduler = YES;
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshClasses"];
            }
            [_courseTableView setDataSource:self];
            [_courseTableView setDelegate:self];
            [_courseTableView reloadData];
            //[_activityIndicator stopAnimating];
            [_courseTableView setUserInteractionEnabled:YES];
        }];
    }else{
        [_courseTableView setUserInteractionEnabled:YES];
    }
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
        if(![reachability isReachable]){
            isAnimating = YES;
            [_cellMsgLabel setText:@"Please check internet connection"];
            [self performSelectorOnMainThread:@selector(animateCellMsg) withObject:nil waitUntilDone:NO];
        }else if([[FBSession activeSession] accessTokenData] == nil){
            isAnimating = YES;
            [_cellMsgLabel setText:@"Log in to Facebook to view friends"];
            [self performSelectorOnMainThread:@selector(animateCellMsg) withObject:nil waitUntilDone:NO];
        }
        /*
        else if(!loggedIntoScheduler){
            isAnimating = YES;
            [_cellMsgLabel setText:@"Error connecting Facebook to Scheduler"];
            [self performSelectorOnMainThread:@selector(animateCellMsg) withObject:nil waitUntilDone:NO];
        }
         */
         else{
            NSInteger row = indexPath.row;
            selectedIndex = row;
            //NSString *course = [_courseKeys objectAtIndex:row];

            if(!showContact){
                isUpdating = YES;
                NSString *course = [_courseKeys objectAtIndex:row];
                [[ScheduleManager sharedInstance] friendsInCourse:course term:termCode completion:^(NSError *error, NSArray *friendSchedules) {
                    if(!error){
                        NSLog(@"Found %@", [friendSchedules firstObject][@"facebookID"]);
                        NSMutableDictionary *properties = [_courses objectForKey:course];
                        [properties setObject:friendSchedules forKey:@"contacts"];
                        
                        if([_contacts count] > 0){
                            NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
                            for(int i = 0; i< [_contacts count]; i++){
                                [indexPaths addObject:[NSIndexPath indexPathForRow:row+i+1 inSection:0]];
                            }
                            [insertIndexPaths addObjectsFromArray:indexPaths];
                            [properties setObject:indexPaths forKey:@"indexPaths"];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_courseTableView beginUpdates];
                                showContact = YES;
                                [_courseTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
                                [_courseTableView endUpdates];
                                isUpdating = NO;
                            });
                        }

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
                    //NSMutableDictionary *properties = [_courses objectForKey:course];

                    [_courseTableView deleteRowsAtIndexPaths:insertIndexPaths withRowAnimation: UITableViewRowAnimationRight];
                    //NSMutableArray *indexPaths = [properties objectForKey:@"indexPaths"];
                    //[indexPaths removeAllObjects];
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger rowNumber = indexPath.row;
    NSInteger numContacts = [_contacts count];
    BOOL isIpad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? YES : NO;
    if(indexPath.row == ([_contacts count]+[_courseKeys count])){
        // Facebook cell
        return 46;
    }
    if((rowNumber >= selectedIndex+1 && rowNumber < selectedIndex + numContacts +1)  && showContact){
        // Contact cell
        if(isIpad){
            return 100;
        }
        return 55;
    }else{
        // Course Cell
        if(isIpad){
            return 80;
        }
        return 46;
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger rowNumber = indexPath.row;
    NSInteger numContacts = [_contacts count];
    if(indexPath.row == ([_contacts count]+[_courseKeys count])){
        FBLoginCell *fbCell = (FBLoginCell *)[tableView dequeueReusableCellWithIdentifier:@"Facebook"];
        [fbCell.loginView setReadPermissions:@[@"public_profile",@"user_friends",@"email"]];
        [fbCell.loginView setDefaultAudience:FBSessionDefaultAudienceFriends];
        [fbCell.loginView setPublishPermissions:@[@"publish_actions"]];
        [fbCell.loginView setDelegate:self];
        if([fbCell respondsToSelector:@selector(setLayoutMargins:)])
            fbCell.layoutMargins = UIEdgeInsetsZero;
        return fbCell;
    }
    if((rowNumber >= selectedIndex+1 && rowNumber < selectedIndex + numContacts +1)  && showContact){
        ClassContactCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        NSDictionary *contact = [_contacts objectAtIndex:numContacts - (rowNumber - selectedIndex)];
        NSString *name = [contact objectForKey:@"name"];
        NSString *fbid = [contact objectForKey:@"fbid"];
        NSString *section = [contact objectForKey:@"section"];
        NSString *nameWithSection = [NSString stringWithFormat:@"%@ (%@)",name, section];
        BOOL shareEnabled = [[contact objectForKey:@"share"] boolValue];
        
        // Disable share button is necessary
        if(!shareEnabled){
            [cell.scheduleButton setHidden:YES];
        }else{
            [cell.scheduleButton setHidden:NO];
        }
        
        // Layout contact picture design
        cell.contactPictureView.layer.cornerRadius = cell.contactPictureView.layer.frame.size.width/2;
        cell.contactPictureView.layer.masksToBounds = YES;
        //cell.contactPictureView.layer.borderColor = [self.view backgroundColor].CGColor;
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            //cell.contactPictureView.layer.borderWidth = 2.0f;
        }else{
            //cell.contactPictureView.layer.borderWidth = 1.0f;
        }
        //cell.shadow.layer.shadowColor = [UIColor blackColor].CGColor;
        //cell.shadow.layer.shadowOffset = CGSizeMake(1, 3);
        //cell.shadow.layer.shadowOpacity = 0.8;
        //cell.shadow.layer.shadowRadius = 1.0f;
        //cell.shadow.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:cell.contactPictureView.frame cornerRadius:cell.contactPictureView.layer.frame.size.width/2].CGPath;
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
        if([cell respondsToSelector:@selector(setLayoutMargins:)])
            [cell setLayoutMargins:UIEdgeInsetsZero];

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
        if([cell respondsToSelector:@selector(setLayoutMargins:)])
            cell.layoutMargins = UIEdgeInsetsZero;

        return cell;
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

#pragma mark FBLoginViewDelegate methods
// Facebook login related functions
-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user{
    NSLog(@"User id: %@", [user objectID]);
    [[ScheduleManager sharedInstance] setupManagerWithFacebookUserID:[user objectID] completion:nil];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    NSLog(@"Logged in");
    loggedIntoFB = YES;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshClasses"];
    [_courseTableView reloadData];
    /*
    NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
    //[_activityIndicator startAnimating];
    NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
    NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
    [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSError *error;
        NSDictionary *submitDict = [[NSDictionary alloc] initWithDictionary:[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error]];
        NSLog(@"Successfully submitted fb token");
        loggedIntoFB = YES;
        loggedIntoScheduler = YES;
        if([[submitDict objectForKey:@"success"] boolValue]){
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshClasses"];
        }
        [_courseTableView reloadData];
    }];
     */
}

-(void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView{
    loggedIntoFB = NO;
    [_courseTableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"ShowCourseDetails"]){
        [self.tabBarController setModalPresentationStyle:UIModalPresentationFullScreen];
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

-(IBAction)debugShowSchedule:(id)sender{
    ScheduleTheaterViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ScheduleTheater"];
    vc.fbid = @"623886246";
    [self.tabBarController setModalPresentationStyle:UIModalPresentationCurrentContext];
    [self.tabBarController presentViewController:vc animated:NO completion:nil];
}

-(IBAction)showSchedule:(UIButton *)sender{
    ScheduleTheaterViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ScheduleTheater"];
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:_courseTableView];
    NSIndexPath *indexPath = [_courseTableView indexPathForRowAtPoint:buttonPosition];
    NSInteger rowNumber = indexPath.row;
    NSInteger numContacts = [_contacts count];
    NSDictionary *selectedContact;
    selectedContact = [[NSDictionary alloc] initWithDictionary:[_contacts objectAtIndex:numContacts - (rowNumber - selectedIndex)]];
    vc.pointOfOrigin = buttonPosition;
    vc.studentName = [selectedContact objectForKey:@"name"];
    vc.fbid = [selectedContact objectForKey:@"fbid"];
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self.tabBarController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self.tabBarController presentViewController:vc animated:NO completion:nil];
    [vc.view setAlpha:0];
    [UIView animateWithDuration:0.5 animations:^{
        [vc.view setAlpha:1];
    }];
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
    NSString *termCode = [[NSUserDefaults standardUserDefaults] objectForKey:@"SemesterInfo"];

    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if(error){
            NSLog(@"Error requestion calendar: %@", [error description]);
        }else if(granted){
            NSDateComponents *components = [[NSDateComponents alloc] init];
            for(NSString *course in _courseKeys){
                NSDictionary *properties = [_courses objectForKey:course];
                NSInteger classLength = [[[properties objectForKey:@"PrimaryTimes"] substringFromIndex:4] integerValue] - [[[properties objectForKey:@"PrimaryTimes"] substringToIndex:4] integerValue];
                EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                NSString *days = [properties objectForKeyedSubscript:@"PrimaryDays"];
                NSMutableArray *daysOfTheWeek = [[NSMutableArray alloc] init];
                [daysOfTheWeek addObject:[EKRecurrenceDayOfWeek dayOfWeek:EKMonday]];
    
                EKRecurrenceRule *recurrence = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly
                                                                                            interval:1
                                                                                       daysOfTheWeek:daysOfTheWeek
                                                                                      daysOfTheMonth:nil
                                                                                     monthsOfTheYear:nil
                                                                                      weeksOfTheYear:nil
                                                                                       daysOfTheYear:nil
                                                                                        setPositions:nil
                                                                                                 end:nil];
                [components setDay:24];
                [components setMonth:10];
                [components setYear:2014];
                EKRecurrenceEnd *endRecurrence = [EKRecurrenceEnd recurrenceEndWithEndDate:[[NSCalendar  currentCalendar] dateFromComponents:components]];
                [event setTitle:course];
                event.endDate = [[NSDate alloc] initWithTimeInterval:classLength sinceDate:event.startDate];
                [event setRecurrenceRules:@[recurrence, endRecurrence]];
                [event setStartDate:[[NSDate alloc] init]];
                [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                
                NSError *error;
                [eventStore saveEvent:event span:EKSpanThisEvent error:&error];
                
            }
        }else{
            NSLog(@"Calendar access not granted");
        }
    }];
    
}

@end
