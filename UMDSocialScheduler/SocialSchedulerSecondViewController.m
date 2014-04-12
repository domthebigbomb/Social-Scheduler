
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
    NSString *termCode;
    NSMutableArray *insertIndexPaths;
    NSMutableDictionary *contactPics;
    Reachability *internetReachability;
    NetworkStatus network;
    int selectedIndex;
    BOOL showContact;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    classesWithContactURLString = @"friends?";
    fbLoginURLString = @"access?access_token=";
    internetReachability = [Reachability reachabilityForInternetConnection];

    insertIndexPaths = [[NSMutableArray alloc] init];
    contactPics = [[NSMutableDictionary alloc] init];
}

-(void)viewDidAppear:(BOOL)animated{
    network = [internetReachability currentReachabilityStatus];
    
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    if(network == NotReachable){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else{
        [self refreshClasses];
    }
}

-(void)refreshClasses{
    NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
    [_activityIndicator startAnimating];
    NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
    NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
    NSURLResponse *response;
    NSData *data;
    NSError *error;
    data = [NSURLConnection sendSynchronousRequest:fbLoginRequest returningResponse:&response error:&error];
    courseString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Courses"];
    
    // Parse Course String to get classes
    _courses = [[NSMutableDictionary alloc] init];
    NSUInteger index;
    while(![courseString isEqualToString:@""]){
        index =[courseString rangeOfString:@"|"].location;
        NSString *class = [courseString substringToIndex:index];
        courseString = [courseString substringFromIndex:index + 1];
        index =[courseString rangeOfString:@"/"].location;
        NSString *section = [courseString substringToIndex: index];
        courseString = [courseString substringFromIndex:index + 1];
        [_courses setObject:section forKey:class];
    }
    
    _courseKeys = [[NSArray alloc] initWithArray:[_courses allKeys]];
    NSLog(@"Courses: %@",[_courses description]);
    [_activityIndicator stopAnimating];
    [self courseTableView].dataSource = self;
    [self courseTableView].delegate = self;
    [[self courseTableView] reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    network = [internetReachability currentReachabilityStatus];

    //Address the bug in ios7 where separators would disappear
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if(network == NotReachable){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else{
        int row = indexPath.row;
        selectedIndex = row;
        if(!showContact){
            NSString *course = [_courseKeys objectAtIndex:row];
            NSString *requestString = [NSString stringWithFormat:@"%@%@term=%@&course=%@",socialSchedulerURLString,classesWithContactURLString,termCode,course];
            NSURL *requestURL = [NSURL URLWithString:requestString];
            NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSError *error;
                NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
                _contacts = [[NSMutableArray alloc] initWithArray:[JSON objectForKey:@"data"]];
                
                int i = 0;
                for(NSDictionary *contact in _contacts){
                    [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row+i+1 inSection:0]];
                    i++;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_courseTableView beginUpdates];
                    showContact = YES;
                    [_courseTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                    [_courseTableView endUpdates];
                    
                });
            }];
        }else{
            showContact = NO;
            selectedIndex = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_courseTableView beginUpdates];
                showContact = NO;
                [_courseTableView deleteRowsAtIndexPaths:insertIndexPaths withRowAnimation: UITableViewRowAnimationAutomatic];
                [insertIndexPaths removeAllObjects];
                [_contacts removeAllObjects];
                [_courseTableView endUpdates];
            });
        }
    }
}

/*
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    [_courseTableView beginUpdates];
    showContact = NO;
    [_courseTableView deleteRowsAtIndexPaths:insertIndexPaths withRowAnimation: UITableViewRowAnimationAutomatic];
    [insertIndexPaths removeAllObjects];
    [_contacts removeAllObjects];
    [_courseTableView endUpdates];
    [_courseTableView reloadData];
}
*/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_courses count] + [_contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    int rowNumber = indexPath.row;
    int numContacts = [_contacts count];
    if((rowNumber >= selectedIndex+1 && rowNumber < selectedIndex + numContacts +1)  && showContact){
        ClassContactCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        NSDictionary *contact = [_contacts objectAtIndex:numContacts - (rowNumber - selectedIndex)];
        NSString *name = [contact objectForKey:@"name"];
        NSString *section = [contact objectForKey:@"section"];
        NSString *fbid = [contact objectForKey:@"fbid"];
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
        NSString *section = [NSString stringWithFormat:@"Section: %@",[_courses objectForKey:course]];
        [cell.courseNumberLabel setText: course];
        [cell.sectionNumberLabel setText: section];
        return cell;

    }
}

@end
