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
#import <CoreLocation/CoreLocation.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
@interface CourseDetailViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate, EKEventEditViewDelegate>

@property (strong, nonatomic) NSString *course;
@property (strong, nonatomic) NSString *section;
@property (strong, nonatomic) NSString *primaryBldgString;
@property (strong, nonatomic) NSString *secondaryBldgString;
@property (strong, nonatomic) NSMutableString *primDays;
@property (strong, nonatomic) NSMutableString *secDays;
@property (strong, nonatomic) NSString *primaryTimes;
@property (strong, nonatomic) NSString *secondaryTimes;
@property (strong, nonatomic) NSArray *bldgCodes;
@property (strong, nonatomic) NSMutableString *primaryDays;
@property (strong, nonatomic) NSMutableString *secondaryDays;

@property BOOL hasDiscussion;

@property (weak, nonatomic) IBOutlet UILabel *mainMLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainTuLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainWLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainThLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainFLabel;
@property (weak, nonatomic) IBOutlet UILabel *secMLabel;
@property (weak, nonatomic) IBOutlet UILabel *secTuLabel;
@property (weak, nonatomic) IBOutlet UILabel *secWLabel;
@property (weak, nonatomic) IBOutlet UILabel *secThLabel;
@property (weak, nonatomic) IBOutlet UILabel *secFLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UILabel *discussionLabel;
@property (weak, nonatomic) IBOutlet UILabel *courseLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *primaryBuildingLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryBuildingLabel;
@property (weak, nonatomic) IBOutlet UILabel *primaryTimesBegin;
@property (weak, nonatomic) IBOutlet UILabel *secondaryTimesBegin;
@property (weak, nonatomic) IBOutlet UIButton *licenseButton;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;
-(IBAction)showOpenStreetLicense:(UIButton *)button;

@end
