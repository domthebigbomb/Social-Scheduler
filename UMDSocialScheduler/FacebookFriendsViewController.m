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
@interface FacebookFriendsViewController ()

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
    //[[self contactTableView] setHidden:YES];
    userSchedule = [[NSDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Courses"]];
    contactSchedules = [[NSMutableDictionary alloc] init];
    socialSchedulerURL = @"http://www.umdsocialscheduler.com/";
    getListOfFriendsURLString = @"friends_with_app";
    fbLoginURLString = @"access?access_token=";
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
            
            for(NSDictionary *contact in contacts){
                NSString *contactFBID = [NSString stringWithFormat:@"%@",[contact objectForKey:@"fbid"]];
                NSURLRequest *scheduleRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.umdsocialscheduler.com/schedule?term=201401&fbid=%@",contactFBID]]];
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
            NSLog(@"Contact JSON: %@", [JSON yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"  "]);
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
    
    ContactCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    int rowNumber = indexPath.row;
    NSDictionary *contactInfo = [contacts objectAtIndex:rowNumber];
    NSString *name = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"name"]];
    NSString *fbid = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"fbid"]];
    NSString *share = [NSString stringWithFormat:@"%@",[contactInfo objectForKey:@"share"]];
    cell.contactProfPic.profileID = nil;
    //UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal",fbid]]]];
    //[contactPics addObject:contactPic];
    //cell.contactPic = [[UIImageView alloc] initWithImage:[contactPics objectAtIndex:rowNumber]];
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
    
    
    [cell.nameLabel setText: name];
    cell.contactProfPic.profileID = cell.fbid;
    if([share isEqualToString:@"0"]){
        [cell.showScheduleButton setEnabled:NO];
        [cell.showScheduleButton setHidden:YES];
    }
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
