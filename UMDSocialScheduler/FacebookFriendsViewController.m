//
//  FacebookFriendsViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/7/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "FacebookFriendsViewController.h"
#import <YAJL/YAJL.h>
#import "ContactCell.h"
#import "ContactScheduleCell.h"
@interface FacebookFriendsViewController ()
- (IBAction)showSchedule:(UIButton *)sender;
- (IBAction)hideSchedule:(UIButton *)sender;

@property (strong,nonatomic) UITapGestureRecognizer *tapGesture;
@end

@implementation FacebookFriendsViewController{
    NSString *socialSchedulerURL;
    NSString *getListOfFriendsURLString;
    NSString *fbLoginURLString;
    NSMutableData *contactData;
    NSDictionary *jsonDict;
    NSDictionary *userSchedule;
    NSMutableDictionary *contactSchedules;
    NSMutableArray *contacts;
    NSMutableArray *contactPics;
    
    UIImage *contactScheduleImage;
    NSString *scheduleFbid;
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
    contactPics = [[NSMutableArray alloc] init];
    userSchedule = [[NSDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Courses"]];
    contactSchedules = [[NSMutableDictionary alloc] init];
    

    socialSchedulerURL = @"http://www.umdsocialscheduler.com/";
    getListOfFriendsURLString = @"friends_with_app";
    fbLoginURLString = @"access?access_token=";

    //[_scheduleImageView setUserInteractionEnabled:YES];
    //[_scheduleImageView addGestureRecognizer:_tapGesture];
    [_scheduleScrollView addSubview:_scheduleImageView];
    [_scheduleScrollView setDelegate: self];
    
	NSString *getContactString = [NSString stringWithFormat:@"%@%@",socialSchedulerURL,getListOfFriendsURLString];
    NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURL,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
    NSURL *getContactURL = [NSURL URLWithString:getContactString];
    NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
    NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
    [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        id JSON = [data yajl_JSON];
        NSLog(@"Login Response: %@", response);
        NSLog(@"Login Error: %@", connectionError);
        NSLog(@"Login JSON: %@",[JSON yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"  "]);
        NSURLRequest *request = [NSURLRequest requestWithURL:getContactURL];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            [contactData appendData:data];
            id JSON = [data yajl_JSON];
            //jsonDict = [[NSDictionary alloc] initWithDictionary:[JSON valueForKey:@"data"]];
            contacts = [[NSMutableArray alloc] initWithArray:[JSON valueForKey:@"data"]];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
            [contacts sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            NSLog(@"Sorted Contacts: %@",[contacts description]);
            
            for(NSDictionary *contact in contacts){
                NSString *contactFBID = [NSString stringWithFormat:@"%@",[contact objectForKey:@"fbid"]];
                NSURLRequest *scheduleRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.umdsocialscheduler.com/schedule?term=201401&fbid=%@",contactFBID]]];
                
                UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&height=100&width=100",contactFBID]]]];
                [contactPics addObject:contactPic];
                
                NSURLResponse *response;
                NSError *error;
                NSData *data = [NSURLConnection sendSynchronousRequest:scheduleRequest returningResponse:&response error:&error];
                id JSON = [data yajl_JSON];
                NSArray *contactCourses = [[NSArray alloc] initWithArray:[JSON valueForKey:@"data"]];
                [contactSchedules setObject:contactCourses forKey:contactFBID];
            }
             
            NSLog(@"%@",[jsonDict description]);
            NSLog(@"Contact Response: %@", response);
            NSLog(@"Contact Error: %@", connectionError);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self contactTableView] setHidden:NO];
                [[self contactTableView] reloadData];
            });

        }];
    }];
    
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

    NSArray *contactSchedule = [[NSArray alloc] initWithArray:[contactSchedules objectForKey:fbid]];
    NSMutableArray *mutualClasses = [[NSMutableArray alloc] init];
    for(NSDictionary *class in contactSchedule){
        NSString *courseName = [class objectForKey:@"course_code"];
        NSString *section = [class objectForKey:@"section"];
        if([[userSchedule allKeys] containsObject:courseName] && [[userSchedule objectForKey:courseName] isEqualToString:section]){
            [mutualClasses addObject:courseName];
        }
    }
    [cell.numCoursesLabel setText:@"No Mutual Classes"];
    for(int i = 0; i< [mutualClasses count]; i++){
        if(i==0){
            [cell.numCoursesLabel setText: [mutualClasses firstObject]];
        }else{
            [cell.numCoursesLabel setText: [NSString stringWithFormat:@"%@, %@",[cell.numCoursesLabel text],[mutualClasses objectAtIndex:i]]];
        }
    }
    cell.fbid = fbid;
    [cell.contactPic setImage: [contactPics objectAtIndex:rowNumber]];
    [cell.nameLabel setText: name];
    cell.contactProfPic.profileID = cell.fbid;
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
    UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.umdsocialscheduler.com/schedule_image?term=201401&fbid=%@", contact.fbid]]]];
    contactScheduleImage = contactPic;
    [_tapGesture setEnabled: YES];
    
    [_scheduleImageView setImage:contactScheduleImage];
    [_greyedBackgroundView setHidden:NO];
}

- (IBAction)hideSchedule:(UIButton *)sender {
    [_greyedBackgroundView setHidden:YES];
}




@end
