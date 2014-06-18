//
//  CourseDetailViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 6/10/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "CourseDetailViewController.h"
#import <AddressBook/AddressBook.h>

@interface CourseDetailViewController ()
@property (strong,nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIView *mainDetailView;
@property (strong,nonatomic) IBOutlet UIStepper *zoomStepper;
@end

@implementation CourseDetailViewController{
    NSString *socialSchedulerURLString;
    NSString *classesWithContactURLString;
    NSString *fbLoginURLString;
    NSString *termCode;
    NSMutableDictionary *contactSchedules;
    NSMutableDictionary *contactPics;
    NSDictionary *primaryAddress;
    NSDictionary *secondaryAddress;
    NSUInteger zoomLevel;
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
    zoomLevel = [_zoomStepper value];
    _mainDetailView.layer.cornerRadius = 5;
    _mainDetailView.layer.masksToBounds = NO;
    _mainDetailView.layer.shadowOffset = CGSizeMake(5, 5);
    _mainDetailView.layer.shadowRadius = 5;
    _mainDetailView.layer.shadowOpacity = 0.6;
    Reachability *internetReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus network = [internetReachability currentReachabilityStatus];
    [_zoomStepper addTarget:self action:@selector(stepperValueChanged) forControlEvents:UIControlEventValueChanged];
    //NSURL *bldgURL = [NSURL URLWithString:@"http://www.kimonolabs.com/api/cqwtzoos?apikey=437387afa6c3bf7f0367e782c707b51d"];
    //_bldgCodes = [[NSArray alloc] init];
    primaryAddress = [[NSDictionary alloc] init];
    secondaryAddress = [[NSDictionary alloc] init];
    [_mapView setDelegate:self];
    MKTileOverlay *tiles = [[MKTileOverlay alloc] initWithURLTemplate:@"http://tile.openstreetmap.org/{z}/{x}/{y}.png"];
    [tiles setCanReplaceMapContent:YES];
    [_mapView addOverlay:tiles level:MKOverlayLevelAboveLabels];
    
    if(network == NotReachable){
        NSLog(@"No Internet");
    }else{
        //NSData *data = [NSData dataWithContentsOfURL:bldgURL];
        //NSError *error;
        //_bldgCodes = [[[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] objectForKey:@"results"] objectForKey:@"BuildingCodes"];
        //NSLog(@"%@",[_bldgCodes description]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *primBldg = @"";
            for(NSDictionary *building in _bldgCodes){
                if([[building objectForKey:@"code"] isEqualToString:[_primaryBldgString substringToIndex:3]]){
                    primBldg = [[building objectForKey:@"name"] objectForKey:@"text"];
                    if([primBldg rangeOfString:@" ("].location != NSNotFound){
                        primBldg = [primBldg substringToIndex:[primBldg rangeOfString:@"("].location];
                    }
                    primBldg = [primBldg stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                }
            }
            NSURL *primSearchURL = [NSURL URLWithString:[NSString stringWithFormat: @"http://nominatim.openstreetmap.org/search?q=%@&format=json&addressdetails=1",primBldg]];
            NSData *primData = [NSData dataWithContentsOfURL:primSearchURL];
            NSError *err;
            NSMutableArray *addresses = [NSJSONSerialization JSONObjectWithData:primData options:kNilOptions error:&err];
            for(NSDictionary *address in addresses){
                if([[[address objectForKey:@"address"] objectForKey:@"city"] isEqualToString:@"College Park"]){
                    primaryAddress = address;
                }
            }
            NSDictionary *address = [primaryAddress objectForKey:@"address"];
            NSLog(@"%@",[primaryAddress description]);
            CLLocationDegrees lat = [[primaryAddress objectForKey:@"lat"] doubleValue];
            CLLocationDegrees lon = [[primaryAddress objectForKey:@"lon"] doubleValue];
            CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(lat, lon);
            NSDictionary *locationDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [address objectForKey:@"city"],kABPersonAddressCityKey,
                                          [address objectForKey:@"country"],kABPersonAddressCountryKey,
                                          [address objectForKey:@"country_code"], kABPersonAddressCountryCodeKey,
                                          [address objectForKey:@"road"], kABPersonAddressStreetKey,
                                          [address objectForKey:@"state"], kABPersonAddressStateKey,
                                          [address objectForKey:@"postcode"],kABPersonAddressZIPKey,
                                          nil];
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinates addressDictionary:locationDict];
            NSLog(@"%@",[placemark description]);
            [_mapView addAnnotation:placemark];
            MKCoordinateRegion zoomedRegion = [_mapView regionThatFits: MKCoordinateRegionMakeWithDistance(coordinates, 200, 200)];
            [_mapView setRegion:zoomedRegion];
            
            if(_hasDiscussion){
                NSString *secBldg = @"";
                for(NSDictionary *building in _bldgCodes){
                    if([[building objectForKey:@"code"] isEqualToString:[_primaryBldgString substringToIndex:3]]){
                        secBldg = [[building objectForKey:@"name"] objectForKey:@"text"];
                        if([secBldg rangeOfString:@" ("].location != NSNotFound){
                            secBldg = [secBldg substringToIndex:[secBldg rangeOfString:@"("].location];
                        }
                        secBldg = [secBldg stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                    }
                }
                if(![secBldg isEqualToString:primBldg]){
                    NSURL *secSearchURL = [NSURL URLWithString:[NSString stringWithFormat: @"http://nominatim.openstreetmap.org/search?q=%@&format=json&addressdetails=1",secBldg]];
                    NSData *secData = [NSData dataWithContentsOfURL:secSearchURL];
                    NSError *err;
                    NSMutableArray *addresses = [NSJSONSerialization JSONObjectWithData:secData options:kNilOptions error:&err];
                    for(NSDictionary *address in addresses){
                        if([[[address objectForKey:@"address"] objectForKey:@"city"] isEqualToString:@"College Park"]){
                        secondaryAddress = address;
                        }
                    }
                }
            }
        });
    }
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    classesWithContactURLString = @"friends?";
    fbLoginURLString = @"access?access_token=";
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    contactSchedules = [[NSMutableDictionary alloc] init];
    
    [_secondaryBuildingLabel setHidden:NO];
    [_secondaryDays setHidden:NO];
    [_secondaryTimesBegin setHidden:NO];
    [_courseLabel setText: _course];
    [_sectionLabel setText:[NSString stringWithFormat:@"Section %@",_section]];
    [_primaryBuildingLabel setText:_primaryBldgString];
    NSUInteger length = [_primDays length];
    for(int i = 1; i< length; i++){
        [_primDays insertString:@" " atIndex: i+(i-1)];
    }
    _primDays = (NSMutableString *)[_primDays stringByReplacingOccurrencesOfString:@"T" withString:@"Tu"];
    _primDays = (NSMutableString *)[_primDays stringByReplacingOccurrencesOfString:@"H" withString:@"Th"];
    [_primaryDays setText:_primDays];
    NSString *primBeginAMPM = @"";
    NSInteger primBeginHour = [[[_primaryTimes substringToIndex:4] substringToIndex:2] integerValue];
    NSString *primBeginMin = [[_primaryTimes substringToIndex:4] substringFromIndex:2];
    if(primBeginHour < 12){
        primBeginAMPM = @"am";
    }else{
        primBeginAMPM = @"pm";
        if(primBeginHour > 12){
            primBeginHour /= 12;
        }
    }
    NSString *primEndAMPM = @"";
    NSInteger primEndHour = [[[_primaryTimes substringFromIndex:4] substringToIndex:2] integerValue];
    NSString *primEndMin = [[_primaryTimes substringFromIndex:4]substringFromIndex:2];
    if(primEndHour < 12){
        primEndAMPM = @"am";
    }else{
        primEndAMPM = @"pm";
        if(primEndHour > 12){
            primEndHour /= 12;
        }
    }
    
    NSString *primaryTime = [NSString stringWithFormat:@"%ld:%@%@-%ld:%@%@",(long)primBeginHour,primBeginMin,primBeginAMPM,(long)primEndHour,primEndMin,primEndAMPM];
    [_primaryTimesBegin setText:primaryTime];
    
    if(_hasDiscussion){
        [_secondaryBuildingLabel setText:_secondaryBldgString];
        length = [_secDays length];
        for(int i = 1; i< length; i++){
            [_secDays insertString:@" " atIndex: i+(i-1)];
        }
        _secDays = (NSMutableString *)[_secDays stringByReplacingOccurrencesOfString:@"T" withString:@"Tu"];
        _secDays = (NSMutableString *)[_secDays stringByReplacingOccurrencesOfString:@"H" withString:@"Th"];
        [_secondaryDays setText:_secDays];
        NSString *secBeginAMPM = @"";
        NSInteger secBeginHour = [[[_secondaryTimes substringToIndex:4] substringToIndex:2] integerValue];
        NSString *secBeginMin = [[_secondaryTimes substringToIndex:4] substringFromIndex:2];
        if(secBeginHour < 12){
            secBeginAMPM = @"am";
        }else{
            secBeginAMPM = @"pm";
            if(secBeginHour > 12){
                secBeginHour /= 12;
            }
        }
        NSString *secEndAMPM = @"";
        NSInteger secEndHour = [[[_secondaryTimes substringFromIndex:4] substringToIndex:2] integerValue];
        NSString *secEndMin = [[_secondaryTimes substringFromIndex:4]substringFromIndex:2];
        if(secEndHour < 12){
            secEndAMPM = @"am";
        }else{
            secEndAMPM = @"pm";
            if(secEndHour > 12){
                secEndHour /= 12;
            }
        }
        
        NSString *secondaryTime = [NSString stringWithFormat:@"%ld:%@%@-%ld:%@%@",(long)secBeginHour,secBeginMin,secBeginAMPM,(long)secEndHour,secEndMin,secEndAMPM];
        [_secondaryTimesBegin setText:secondaryTime];
    }else{
        [_discussionLabel setText:@"No Discussion"];
        [_secondaryBuildingLabel setHidden:YES];
        [_secondaryDays setHidden:YES];
        [_secondaryTimesBegin setHidden:YES];
    }
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    if([overlay isKindOfClass:[MKTileOverlay class]]){
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return nil;
}

-(void)stepperValueChanged{
    if([_zoomStepper value] > zoomLevel){
        [self zoomIn];
        zoomLevel = [_zoomStepper value];
    }else if([_zoomStepper value] < zoomLevel){
        [self zoomOut];
        zoomLevel = [_zoomStepper value];
    }
}

-(void)zoomIn{
    MKCoordinateRegion region = [_mapView region];
    MKCoordinateSpan span = region.span;
    NSLog(@"Lat:%f\nLon:%f",span.latitudeDelta,span.longitudeDelta);
    span.longitudeDelta = region.span.longitudeDelta/2.0;
    span.latitudeDelta = region.span.latitudeDelta/2.0;
    region.span = span;
    [_mapView setRegion:region];
}

-(void)zoomOut{
    MKCoordinateRegion region = [_mapView region];
    MKCoordinateSpan span = region.span;
    NSLog(@"Lat:%f\nLon:%f",span.latitudeDelta,span.longitudeDelta);
    span.longitudeDelta = region.span.longitudeDelta*2.0;
    span.latitudeDelta = region.span.latitudeDelta*2.0;
    region.span = span;
    [_mapView setRegion:region];
}

-(IBAction)showOpenStreetLicense:(UIButton *)button{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.openstreetmap.org/copyright"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
