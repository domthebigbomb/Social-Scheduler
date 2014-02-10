//
//  SocialSchedulerSecondViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/5/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "SocialSchedulerSecondViewController.h"
#import "SocialSchedulerFirstViewController.h"
#import "CourseCell.h"
@interface SocialSchedulerSecondViewController ()
@property (strong,nonatomic) NSDictionary *courses;
@property (weak, nonatomic) IBOutlet UITableView *courseTableView;
@property (strong,nonatomic) NSArray *courseKeys;
@end

@implementation SocialSchedulerSecondViewController{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated{
    _courses = [[NSDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Courses"]];
    _courseKeys = [[NSArray alloc] initWithArray:[_courses allKeys]];
    NSLog(@"Courses: %@",[_courses description]);
    [self courseTableView].dataSource = self;
    [[self courseTableView] reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_courses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CourseCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CourseCell"];
    int rowNumber = indexPath.row;
    NSString *course = [_courseKeys objectAtIndex:rowNumber];
    NSString *section = [NSString stringWithFormat:@"Section: %@",[_courses objectForKey:course]];
    [cell.courseNumberLabel setText: course];
    [cell.sectionNumberLabel setText: section];
    return cell;
}

@end
