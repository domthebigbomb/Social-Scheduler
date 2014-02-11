
//
//  SocialSchedulerSecondViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/5/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "SocialSchedulerSecondViewController.h"
#import <YAJL/YAJL.h>
#import "CourseCell.h"
#import "ClassContactCell.h"
@interface SocialSchedulerSecondViewController ()
@property (strong,nonatomic) NSMutableDictionary *courses;
@property (weak, nonatomic) IBOutlet UITableView *courseTableView;
@property (strong,nonatomic) NSArray *courseKeys;
@property (strong, nonatomic) NSMutableArray *contacts;

@end

@implementation SocialSchedulerSecondViewController{
    NSString *socialSchedulerURLString;
    NSString *classesWithContactURLString;
    NSString *fbLoginURLString;
    NSMutableArray *insertIndexPaths;
    NSMutableDictionary *contactPics;
    int selectedIndex;
    BOOL showContact;
}

- (void)viewDidLoad
{
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    classesWithContactURLString = @"friends?";
    fbLoginURLString = @"access?access_token=";
    NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
    NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
    NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
    insertIndexPaths = [[NSMutableArray alloc] init];
    contactPics = [[NSMutableDictionary alloc] init];
    NSURLResponse *response;
    NSData *data;
    NSError *error;
    data = [NSURLConnection sendSynchronousRequest:fbLoginRequest returningResponse:&response error:&error];
    

    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated{
    _courses = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Courses"]];
    _courseKeys = [[NSArray alloc] initWithArray:[_courses allKeys]];
    NSLog(@"Courses: %@",[_courses description]);
    [self courseTableView].dataSource = self;
    [self courseTableView].delegate = self;
    [[self courseTableView] reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    int row = indexPath.row;
    selectedIndex = row;
    if(!showContact){
    NSString *course = [_courseKeys objectAtIndex:row];
    NSString *requestString = [NSString stringWithFormat:@"%@%@term=201401&course=%@",socialSchedulerURLString,classesWithContactURLString,course];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        id JSON = [data yajl_JSON];
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
        [cell.nameLabel setText:nameWithSection];
        if([[contactPics allKeys] containsObject:fbid]){
            [cell.contactPictureView setImage:[contactPics objectForKey:fbid]];
        }else{
            UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&height=100&width=100",fbid]]]];
            [cell.contactPictureView setImage:contactPic];
            [contactPics setObject:contactPic forKey:fbid];
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
