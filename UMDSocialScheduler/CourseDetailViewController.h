//
//  CourseDetailViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 6/10/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactCell.h"
#import <MapKit/MapKit.h>
#import "Reachability.h"
#import <CoreLocation/CoreLocation.h>
@interface CourseDetailViewController : UIViewController<MKMapViewDelegate>

@property (strong, nonatomic) NSString *course;
@property (strong, nonatomic) NSString *section;
@property (strong, nonatomic) NSString *primaryBldgString;
@property (strong, nonatomic) NSString *secondaryBldgString;
@property (strong, nonatomic) NSMutableString *primDays;
@property (strong, nonatomic) NSMutableString *secDays;
@property (strong, nonatomic) NSString *primaryTimes;
@property (strong, nonatomic) NSString *secondaryTimes;
@property BOOL hasDiscussion;

@property (weak, nonatomic) IBOutlet UILabel *discussionLabel;
@property (weak, nonatomic) IBOutlet UILabel *courseLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *primaryBuildingLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryBuildingLabel;
@property (weak, nonatomic) IBOutlet UILabel *primaryDays;
@property (weak, nonatomic) IBOutlet UILabel *secondaryDays;
@property (weak, nonatomic) IBOutlet UILabel *primaryTimesBegin;
@property (weak, nonatomic) IBOutlet UILabel *secondaryTimesBegin;
@end
