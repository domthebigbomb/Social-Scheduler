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
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *mainDetailView;
@property (strong, nonatomic) UIAlertView *alertView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *dismissButton;
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
    MKPlacemark *placemark;
    MKPolyline *existingRoute;
    CLLocation *oldLocation;
    BOOL updateRoute;
    BOOL updateBox;
    CLLocationManager *locationManager;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *locationUpdate = [locations firstObject];
    if(updateRoute){
        NSLog(@"Location Update: %@",[locationUpdate description]);
        NSLog(@"Old Location: %@", [oldLocation description]);
        if([locationUpdate coordinate].latitude != [oldLocation coordinate].latitude || [locationUpdate coordinate].longitude != [oldLocation coordinate].longitude){
            NSLog(@"New Location Found");
            [_mapView removeOverlay:existingRoute];
            
            NSString *bingString = [NSString stringWithFormat:@"http://dev.virtualearth.net/REST/v1/Routes/Walking?wayPoint.1=%f,%f&Waypoint.2=%f,%f&routePathOutput=Points&optimize=distance&key=AlBhfcixLlJBZA9wNxVFB5LEmiD3bvYak8mkWGCCaI8waSs6NPUDzdJw1oKy3cA9", locationManager.location.coordinate.latitude , locationManager.location.coordinate.longitude, placemark.coordinate.latitude,placemark.coordinate.longitude];
            NSLog(@"Bing Request URL: %@", bingString);
            
            NSURL *bingURL = [NSURL URLWithString:bingString];
            NSURLRequest *bingDirections = [[NSURLRequest alloc] initWithURL:bingURL];
            [NSURLConnection sendAsynchronousRequest:bingDirections queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSError *err;
                NSDictionary *responseFields = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
                if([[responseFields objectForKey:@"statusCode"] integerValue] ==  200){
                    NSArray *routePath = [[NSArray alloc] initWithArray:[[[[[[[responseFields objectForKey:@"resourceSets"] firstObject] objectForKey:@"resources"] firstObject] objectForKey:@"routePath"] objectForKey:@"line"] objectForKey:@"coordinates"]];
                    
                    CLLocationCoordinate2D directionPoints[[routePath count]];
                    
                    int i = 0;
                    for(NSArray *coordinate in routePath){
                        CLLocationCoordinate2D point = CLLocationCoordinate2DMake([[coordinate firstObject] doubleValue], [[coordinate lastObject] doubleValue]);
                        directionPoints[i] = point;
                        i++;
                    }
                    MKPolyline *line = [MKPolyline polylineWithCoordinates:directionPoints count:[routePath count]];
                    [_mapView addOverlay:line level:MKOverlayLevelAboveLabels];
                    existingRoute = line;
                    if(updateBox){
                        NSLog(@"Updating Bounding Box with mylocation");
                        NSArray *bbox = [[[[[responseFields objectForKey:@"resourceSets"] firstObject] objectForKey:@"resources"] firstObject] objectForKey:@"bbox"];
                        NSLog(@"Bounding Box: %@", [bbox description]);
                        CLLocationDegrees centerLat = ([[bbox objectAtIndex:0] doubleValue] + [[bbox objectAtIndex:2] doubleValue])/2;
                        CLLocationDegrees centerLon = ([[bbox objectAtIndex:1] doubleValue] + [[bbox objectAtIndex:3] doubleValue])/2;
                        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(centerLat, centerLon);
                        MKCoordinateSpan span = MKCoordinateSpanMake([[bbox objectAtIndex:2] doubleValue] - [[bbox objectAtIndex:0] doubleValue] + 0.0015, [[bbox objectAtIndex:3] doubleValue] - [[bbox objectAtIndex:1] doubleValue] + 0.002);
                        NSLog(@"Span: %f", span.latitudeDelta);
                        MKCoordinateRegion boundingBox = MKCoordinateRegionMake(center, span);
                        [_mapView setRegion:boundingBox];
                        updateBox = NO;
                    }
                    oldLocation = locationUpdate;
                }else if ([[responseFields objectForKey:@"statusCode"] integerValue] == 404){
                    _alertView = [[UIAlertView alloc] initWithTitle:@"Uh Oh" message:[[responseFields objectForKey:@"errorDetails"] firstObject] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    NSLog(@"Too far away");
                    //[_alertView show];
                    CLLocationDegrees lat = [[primaryAddress objectForKey:@"lat"] doubleValue];
                    CLLocationDegrees lon = [[primaryAddress objectForKey:@"lon"] doubleValue];
                    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(lat, lon);
                    MKCoordinateRegion zoomedRegion = [_mapView regionThatFits: MKCoordinateRegionMakeWithDistance(coordinates, 200, 200)];
                    [_mapView setRegion:zoomedRegion];
                }
            }];
        }
        updateRoute = NO;
        [self performSelector:@selector(refreshRoute) withObject:nil afterDelay:10.0f];

    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [locationManager setDelegate:nil];
    [locationManager stopUpdatingLocation];
    [_mapView removeOverlays:[_mapView overlays]];
    [_mapView setDelegate: nil];
    //[self.mapView setDelegate:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    oldLocation = [[CLLocation alloc] init];
    existingRoute = [[MKPolyline alloc] init];
    //_mainDetailView.layer.cornerRadius = 5;
    _mainDetailView.layer.masksToBounds = NO;
    _mainDetailView.layer.shadowOffset = CGSizeMake(5, 5);
    _mainDetailView.layer.shadowRadius = 5;
    _mainDetailView.layer.shadowOpacity = 0.6;
    Reachability *internetReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus network = [internetReachability currentReachabilityStatus];
    //NSURL *bldgURL = [NSURL URLWithString:@"http://www.kimonolabs.com/api/cqwtzoos?apikey=437387afa6c3bf7f0367e782c707b51d"];
    //_bldgCodes = [[NSArray alloc] init];
    primaryAddress = [[NSDictionary alloc] init];
    secondaryAddress = [[NSDictionary alloc] init];
    _primaryDays = [[NSMutableString alloc] initWithString:_primDays];
    if(_hasDiscussion){
        _secondaryDays = [[NSMutableString alloc] initWithString: _secDays];
    }
    NSLog(@"Primary Days: %@", _primDays);
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
                                          [address objectForKey:@"building"], kABPersonAddressStreetKey,
                                          nil];
            
            /*
             [address objectForKey:@"city"],kABPersonAddressCityKey,
             [address objectForKey:@"country"],kABPersonAddressCountryKey,
             [address objectForKey:@"country_code"], kABPersonAddressCountryCodeKey,
             [address objectForKey:@"road"], kABPersonAddressStreetKey,
             [address objectForKey:@"state"], kABPersonAddressStateKey,
             [address objectForKey:@"postcode"],kABPersonAddressZIPKey,
             [address objectForKey:@"building"], kABPersonAddressProperty,

             */
            placemark = [[MKPlacemark alloc] initWithCoordinate:coordinates addressDictionary:locationDict];
            // Pin class on the map
            NSLog(@"%@",[placemark description]);
            [_mapView addAnnotation:placemark];
            
            
            // Add the walking directions from current location to class
            /*
            MKMapItem *dest = [[MKMapItem alloc] initWithPlacemark:placemark];
            MKDirectionsRequest *walkingRequest = [[MKDirectionsRequest alloc] init];
            [walkingRequest setSource:[MKMapItem mapItemForCurrentLocation]];
            [walkingRequest setDestination: dest];
            [walkingRequest setTransportType:MKDirectionsTransportTypeAny];
            [walkingRequest setRequestsAlternateRoutes:NO];
            MKDirections *walkingDirections = [[MKDirections alloc] initWithRequest:walkingRequest];
            [walkingDirections calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
                if(!error){
                    for(MKRoute *route in [response routes]){
                        //[_mapView addOverlay:[route polyline] level:MKOverlayLevelAboveLabels];
                    }
                }
            }];
            */
            
            if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
                MKCoordinateRegion zoomedRegion = [_mapView regionThatFits: MKCoordinateRegionMakeWithDistance(coordinates, 200, 200)];
                [_mapView setRegion:zoomedRegion];
            }
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
    [_secondaryDaysLabel setHidden:NO];
    [_secondaryTimesBegin setHidden:NO];
    [_courseLabel setText: _course];
    [_sectionLabel setText:[NSString stringWithFormat:@"Section %@",_section]];
    [_primaryBuildingLabel setText:_primaryBldgString];
    NSUInteger length = [_primaryDays length];
    for(int i = 1; i< length; i++){
        [_primaryDays insertString:@" " atIndex: i+(i-1)];
    }
    _primaryDays = (NSMutableString *)[_primaryDays stringByReplacingOccurrencesOfString:@"T" withString:@"Tu"];
    _primaryDays = (NSMutableString *)[_primaryDays stringByReplacingOccurrencesOfString:@"H" withString:@"Th"];
    [_primaryDaysLabel setText:_primaryDays];
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
        length = [_secondaryDays length];
        for(int i = 1; i< length; i++){
            [_secondaryDays insertString:@" " atIndex: i+(i-1)];
        }
        _secondaryDays = (NSMutableString *)[_secondaryDays stringByReplacingOccurrencesOfString:@"T" withString:@"Tu"];
        _secondaryDays = (NSMutableString *)[_secondaryDays stringByReplacingOccurrencesOfString:@"H" withString:@"Th"];
        [_secondaryDaysLabel setText:_secondaryDays];
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
        [_secondaryDaysLabel setHidden:YES];
        [_secondaryTimesBegin setHidden:YES];
    }
    
    updateBox = YES;
    updateRoute = YES;
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    if([overlay isKindOfClass:[MKTileOverlay class]]){
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }else if([overlay isKindOfClass:[MKPolyline class]]){
        MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        [polylineRenderer setStrokeColor:[UIColor redColor]];
        [polylineRenderer setLineWidth:2.5f];
        return polylineRenderer;
    }
    return nil;
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


-(void)refreshRoute{
    NSLog(@"Update Route");
    updateRoute = YES;
}

-(IBAction)showOpenStreetLicense:(UIButton *)button{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.openstreetmap.org/copyright"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
