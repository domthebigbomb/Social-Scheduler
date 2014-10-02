//
//  ClassesViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 9/3/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "ClassesViewController.h"
#import "CourseCell.h"
#import "FBLoginCell.h"
#import "AFNetworking.h"
#import "ClassContactCell.h"
#import "CourseDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ScheduleTheaterViewController.h"
#import "CourseCollectionCell.h"

@interface ClassesViewController()

@property (strong,nonatomic) NSMutableDictionary *courses;
@property (strong,nonatomic) NSMutableDictionary *contactsInCourses;
@property (weak, nonatomic) IBOutlet UILabel *cellMsgLabel;
@property (strong,nonatomic) NSArray *courseKeys;
@property (strong, nonatomic) NSMutableDictionary *contacts;
@property (strong, nonatomic) UIAlertView *alertMsg;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation ClassesViewController{
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
    BOOL isUpdating;
    BOOL isAnimating;
    BOOL loggedIntoScheduler;
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
    _contacts = [[NSMutableDictionary alloc] init];
}

-(void)viewDidAppear:(BOOL)animated{
    isUpdating = NO;
    isAnimating = NO;
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    
    if([[FBSession activeSession] accessTokenData] == nil){
        loggedIntoFB = NO;
        NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
        NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
        NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
    }
    
    
    
    if(![reachability isReachable]){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else if([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshClasses"]){
        [self refreshClasses];
    }else if([_courseKeys count] == 0){
        [self refreshClasses];
    }
}

-(void)grabFriendsInClass:(NSString *)course{
    if(![reachability isReachable]){
        isAnimating = YES;
        [_cellMsgLabel setText:@"Please check internet connection"];
    }else if([[FBSession activeSession] accessTokenData] == nil){
        isAnimating = YES;
        [_cellMsgLabel setText:@"Log in to Facebook to view friends"];
    }else if(!loggedIntoScheduler){
        isAnimating = YES;
        [_cellMsgLabel setText:@"Error connecting Facebook to Scheduler"];
    }else{
        //NSString *course = [_courseKeys objectAtIndex:row];
        isUpdating = YES;
        
        NSString *requestString = [NSString stringWithFormat:@"%@%@term=%@&course=%@",socialSchedulerURLString,classesWithContactURLString,termCode,course];
        NSURL *requestURL = [NSURL URLWithString:requestString];
        NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError *error;
            if(data != nil){
                NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
                NSArray *contacts = [[NSArray alloc] initWithArray:[JSON objectForKey:@"data"]];
                [_contacts setObject:contacts forKey:course];
                
                NSMutableDictionary *properties = [_courses objectForKey:course];
                [properties setObject:[[NSArray alloc] initWithArray:[JSON objectForKey:@"data"]]forKey:@"contacts"];
                if([contacts count] > 0){
                    
                }else{
                    isUpdating = NO;
                }
                [[self classCollectionView] reloadData];
            }
        }];
    }
}

-(void)refreshClasses{
    [_classCollectionView setUserInteractionEnabled:NO];
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
            [self classCollectionView].dataSource = self;
            [self classCollectionView].delegate = self;
            [[self classCollectionView] reloadData];
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
            [_classCollectionView setDataSource:self];
            [_classCollectionView setDelegate:self];
            [_classCollectionView reloadData];
            [_classCollectionView setUserInteractionEnabled:YES];
        }];
    }else{
        [_classCollectionView setUserInteractionEnabled:YES];
    }
}

#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    int fbConst = 0;
    if(!loggedIntoFB){
        fbConst = 1;
    }
    return [_courses count] + fbConst;
}
// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}
// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CourseCollectionCell *cell = (CourseCollectionCell *)[cv dequeueReusableCellWithReuseIdentifier:@"Course" forIndexPath:indexPath];
    CGRect newFrame = CGRectMake(0, 0, 300, 400);
    //[cell.mainContentView setFrame:newFrame];
    NSInteger rowNumber = indexPath.row;
    //[cell.mainContentView.layer setFrame:newFrame];
    cell.layer.cornerRadius = 2.0f;
    cell.mainContentView.layer.cornerRadius = 2.0f;
    NSString *course = [_courseKeys objectAtIndex:rowNumber];
    NSDictionary *properties = [_courses objectForKey:course];
    NSString *section = [NSString stringWithFormat:@"Section: %@",[properties objectForKey:@"section"]];
    [cell.courseNumberLabel setText: course];
    [cell.sectionNumberLabel setText: section];
    
    if(![[_contacts allKeys] containsObject:course] && loggedIntoScheduler){
        NSString *requestString = [NSString stringWithFormat:@"%@%@term=%@&course=%@",socialSchedulerURLString,classesWithContactURLString,termCode,course];
        NSURL *requestURL = [NSURL URLWithString:requestString];
        NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.responseSerializer = [AFJSONResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Request String: %@", requestString);
            NSMutableDictionary *JSON = (NSMutableDictionary *)responseObject;
            NSArray *contacts;
            if([[JSON objectForKey:@"data"] count] != 0){
                NSLog(@"Contacts found");
                contacts = [[NSArray alloc] initWithArray:[JSON objectForKey:@"data"]];
            }else{
                contacts = [[NSArray alloc] init];
            }
            [_contacts setObject:contacts forKey:course];
            NSLog(@"%@: %lu contacts", course, (unsigned long)[contacts count]);
            /*
             NSMutableDictionary *properties = [_courses objectForKey:course];
             [properties setObject:[[NSArray alloc] initWithArray:[JSON objectForKey:@"data"]]forKey:@"contacts"];
             */
            //[[self classCollectionView] reloadItemsAtIndexPaths:@[indexPath]];
            dispatch_async(dispatch_get_main_queue(), ^{
                //[[self classCollectionView] reloadData];
                NSLog(@"Reloading %@",course);
                //[[[self classCollectionView] cellForItemAtIndexPath:indexPath] setNeedsLayout];
                CGRect newFrame = cell.contentView.frame;
                //newFrame.size.height += 56 * [contacts count];
                //[cell.contentView setFrame: newFrame];
                [[self classCollectionView] reloadItemsAtIndexPaths:@[indexPath]];
            });

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@",[error description]);
        }];
        [operation start];
    }
    return cell;
}
// 4
/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 return [[UICollectionReusableView alloc] init];
 }*/


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Select Item
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout
// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize retval = CGSizeMake(300, 150);
    NSUInteger numContacts = ([[_contacts objectForKey:[_courseKeys objectAtIndex:indexPath.row]] count]);
    //[cell.mainContentView setFrame:newFrame];
    retval.height += 56 * numContacts;
    NSLog(@"IndexPath: %@",[NSNumber numberWithInteger:indexPath.row]);
    NSLog(@"%@: %lu",[_courseKeys objectAtIndex:indexPath.row],(unsigned long)numContacts);
    return retval;
}


// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(15, 0, 15, 0);
    // Top, Left, Bottom, Right
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

-(IBAction)showSchedule:(UIButton *)sender{
    ScheduleTheaterViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ScheduleTheater"];
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:_classCollectionView];
    NSIndexPath *indexPath = [_classCollectionView indexPathForItemAtPoint:buttonPosition];
    NSInteger rowNumber = indexPath.row;
    NSInteger numContacts = [_contacts count];
    NSDictionary *selectedContact;
    //selectedContact = [[NSDictionary alloc] initWithDictionary:[_contacts objectAtIndex:numContacts - (rowNumber - selectedIndex)]];
    vc.pointOfOrigin = buttonPosition;
    vc.studentName = [selectedContact objectForKey:@"name"];
    vc.fbid = [selectedContact objectForKey:@"fbid"];
    [self.tabBarController setModalPresentationStyle:UIModalPresentationCurrentContext];
    [self.tabBarController presentViewController:vc animated:NO completion:NO];
    [vc.view setAlpha:0];
    [UIView animateWithDuration:0.5 animations:^{
        [vc.view setAlpha:1];
    }];
}


- (IBAction)showCourseDetails:(id)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:_classCollectionView];
    NSIndexPath *indexPath = [_classCollectionView indexPathForItemAtPoint:buttonPosition];
    courseIndex = indexPath.row;
    NSLog(@"%ld pressed", (long)indexPath.row);
    [self performSegueWithIdentifier:@"ShowCourseDetails" sender:self];
    
}

@end
