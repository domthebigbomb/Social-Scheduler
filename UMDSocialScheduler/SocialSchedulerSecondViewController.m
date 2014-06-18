
//
//  SocialSchedulerSecondViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/5/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "SocialSchedulerSecondViewController.h"
#import "CourseCell.h"
#import "Reachability.h"
#import "ClassContactCell.h"
#import "CourseDetailViewController.h"

@interface SocialSchedulerSecondViewController ()
@property (strong,nonatomic) NSMutableDictionary *courses;
@property (weak, nonatomic) IBOutlet UITableView *courseTableView;
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    classesWithContactURLString = @"friends?";
    fbLoginURLString = @"access?access_token=";
    internetReachability = [Reachability reachabilityForInternetConnection];
    loggedIntoFB = NO;
    NSURL *bldgURL = [NSURL URLWithString:@"http://www.kimonolabs.com/api/cqwtzoos?apikey=437387afa6c3bf7f0367e782c707b51d"];
    NSData *data = [NSData dataWithContentsOfURL:bldgURL];
    NSError *error;
    bldgCodes = [[NSArray alloc] initWithArray:[[[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] objectForKey:@"results"] objectForKey:@"BuildingCodes"]];
    insertIndexPaths = [[NSMutableArray alloc] init];
    contactPics = [[NSMutableDictionary alloc] init];
    //[self refreshClasses];
}

-(void)viewDidAppear:(BOOL)animated{
    network = [internetReachability currentReachabilityStatus];
    isUpdating = NO;

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
        NSLog(@"Successfully logged into Facebook");
        loggedIntoFB = YES;
        [_courseTableView reloadData];
    }];
    courseString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Courses"];
    courseDetails = [[NSUserDefaults standardUserDefaults] stringForKey:@"CourseDetails"];
    
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //Address the bug in ios7 where separators would disappear
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(!isUpdating && loggedIntoFB){
    network = [internetReachability currentReachabilityStatus];
    if(network == NotReachable){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else if([[FBSession activeSession] accessTokenData] == nil){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"You are not signed into facebook. In order to view friends in your classes, please sign into facebook at the login screen." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [_alertMsg show];
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
                
                    for(int i = 0; i< [_contacts count]; i++){
                        [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row+i+1 inSection:0]];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_courseTableView beginUpdates];
                        showContact = YES;
                        [_courseTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation: UITableViewRowAnimationAutomatic];
                        [_courseTableView endUpdates];
                        isUpdating = NO;
                    });
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
    return [_courses count] + [_contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger rowNumber = indexPath.row;
    NSInteger numContacts = [_contacts count];
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
        NSString *primTime = [properties objectForKey:@"PrimaryTimes"];
        viewController.primaryTimes = primTime;
        viewController.bldgCodes = bldgCodes;
    }
}

-(IBAction)dismissDetails:(UIStoryboardSegue *)segue{
    
}

@end
