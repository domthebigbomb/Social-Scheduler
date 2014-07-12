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
@interface CourseDetailViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) NSString *course;
@property (weak, nonatomic) NSString *section;
@property (weak, nonatomic) NSString *primaryBldgString;
@property (weak, nonatomic) NSString *secondaryBldgString;
@property (weak, nonatomic) NSMutableString *primDays;
@property (weak, nonatomic) NSMutableString *secDays;
@property (weak, nonatomic) NSString *primaryTimes;
@property (weak, nonatomic) NSString *secondaryTimes;
@property (weak, nonatomic) NSArray *bldgCodes;
@property (strong, nonatomic) NSMutableString *primaryDays;
@property (strong, nonatomic) NSMutableString *secondaryDays;

@property BOOL hasDiscussion;

@property (weak, nonatomic) IBOutlet UILabel *discussionLabel;
@property (weak, nonatomic) IBOutlet UILabel *courseLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *primaryBuildingLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryBuildingLabel;
@property (weak, nonatomic) IBOutlet UILabel *primaryDaysLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryDaysLabel;
@property (weak, nonatomic) IBOutlet UILabel *primaryTimesBegin;
@property (weak, nonatomic) IBOutlet UILabel *secondaryTimesBegin;
@property (weak, nonatomic) IBOutlet UIButton *licenseButton;
-(IBAction)showOpenStreetLicense:(UIButton *)button;

@end
