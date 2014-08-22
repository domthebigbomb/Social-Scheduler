//
//  CourseDetailViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 6/10/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "CourseDetailViewController.h"
#import <AddressBook/AddressBook.h>
#import <QuartzCore/QuartzCore.h>

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
    MKPointAnnotation *bldgPoint;
    MKPointAnnotation *disBldgPoint;
    MKPointAnnotation *selectedPoint;
    MKPolyline *existingRoute;
    CLLocation *oldLocation;
    BOOL updateRoute;
    BOOL updateBox;
    BOOL viewingMain;
    BOOL routeUpdating;
    UIColor *backgroundColor;
    CLLocationManager *locationManager;
    CLLocation *lastUserLocation;
    Reachability *internetReachability;
    NetworkStatus network;
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
    //NSLog(@"Course Detail Did Load");
    viewingMain = YES;
    backgroundColor = self.view.backgroundColor;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    _mapView.delegate = self;
    routeUpdating = NO;
    oldLocation = [[CLLocation alloc] init];
    existingRoute = [[MKPolyline alloc] init];
    selectedPoint = [[MKPointAnnotation alloc] init];
    _mainDetailView.layer.masksToBounds = NO;
    _mainDetailView.layer.shadowOffset = CGSizeMake(5, 5);
    _mainDetailView.layer.shadowRadius = 5;
    _mainDetailView.layer.shadowOpacity = 0.6;

    _etaLabel.layer.cornerRadius = 3.0f;
    
    internetReachability = [Reachability reachabilityForInternetConnection];

    primaryAddress = [[NSDictionary alloc] init];
    secondaryAddress = [[NSDictionary alloc] init];
    _primaryDays = [[NSMutableString alloc] initWithString:_primDays];
    if(_hasDiscussion){
        _secondaryDays = [[NSMutableString alloc] initWithString: _secDays];
    }else{
        [_secMLabel setHidden:YES];
        [_secTuLabel setHidden:YES];
        [_secWLabel setHidden:YES];
        [_secThLabel setHidden:YES];
        [_secFLabel setHidden:YES];
    }
    //NSLog(@"Primary Days: %@", _primDays);
    [_mapView setDelegate:self];
    MKTileOverlay *tiles = [[MKTileOverlay alloc] initWithURLTemplate:@"http://tile.openstreetmap.org/{z}/{x}/{y}.png"];
    [tiles setCanReplaceMapContent:YES];
    [_mapView addOverlay:tiles level:MKOverlayLevelAboveLabels];
    
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    classesWithContactURLString = @"friends?";
    fbLoginURLString = @"access?access_token=";
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    contactSchedules = [[NSMutableDictionary alloc] init];

    [_secondaryBuildingLabel setHidden:NO];
    [_secondaryTimesBegin setHidden:NO];
    [_courseLabel setText: _course];
    [_sectionLabel setText:[NSString stringWithFormat:@"Section %@",_section]];
    [_primaryBuildingLabel setText:_primaryBldgString];
    NSUInteger length = [_primaryDays length];
    
    for(int i = 0; i< length; i++){
        char currDay = [_primaryDays characterAtIndex:i];
        if(currDay == 'M'){
            // String evan = evan
            _mainMLabel.layer.cornerRadius = 5.0f;
            [_mainMLabel setAlpha:1];
            [_mainMLabel.layer setBorderColor:[UIColor blackColor].CGColor];
            [_mainMLabel.layer setBorderWidth:1.0f];
        }else if (currDay == 'T'){
            _mainTuLabel.layer.cornerRadius = 5.0f;
            [_mainTuLabel setAlpha:1];
            [_mainTuLabel.layer setBorderColor:[UIColor blackColor].CGColor];
            [_mainTuLabel.layer setBorderWidth:1.0f];
        }else if (currDay == 'W'){
            _mainWLabel.layer.cornerRadius = 5.0f;
            [_mainWLabel setAlpha:1];
            [_mainWLabel.layer setBorderColor:[UIColor blackColor].CGColor];
            [_mainWLabel.layer setBorderWidth:1.0f];
        }else if (currDay == 'H'){
            _mainThLabel.layer.cornerRadius = 5.0f;
            [_mainThLabel setAlpha:1];
            [_mainThLabel.layer setBorderColor:[UIColor blackColor].CGColor];
            [_mainThLabel.layer setBorderWidth:1.0f];
        }else{
            _mainFLabel.layer.cornerRadius = 5.0f;
            [_mainFLabel setAlpha:1];
            [_mainFLabel.layer setBorderColor:[UIColor blackColor].CGColor];
            [_mainFLabel.layer setBorderWidth:1.0f];
        }
    }

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
        for(int i = 0; i< length; i++){
            char currDay = [_secondaryDays characterAtIndex:i];
            if(currDay == 'M'){
                _secMLabel.layer.cornerRadius = 5.0f;
                [_secMLabel setAlpha:1];
                [_secMLabel.layer setBorderColor:[UIColor blackColor].CGColor];
                [_secMLabel.layer setBorderWidth:1.0f];
            }else if (currDay == 'T'){
                _secTuLabel.layer.cornerRadius = 5.0f;
                [_secTuLabel setAlpha:1];
                [_secTuLabel.layer setBorderColor:[UIColor blackColor].CGColor];
                [_secTuLabel.layer setBorderWidth:1.0f];
            }else if (currDay == 'W'){
                _secWLabel.layer.cornerRadius = 5.0f;
                [_secWLabel setAlpha:1];
                [_secWLabel.layer setBorderColor:[UIColor blackColor].CGColor];
                [_secWLabel.layer setBorderWidth:1.0f];
            }else if (currDay == 'H'){
                _secThLabel.layer.cornerRadius = 5.0f;
                [_secThLabel setAlpha:1];
                [_secThLabel.layer setBorderColor:[UIColor blackColor].CGColor];
                [_secThLabel.layer setBorderWidth:1.0f];
            }else{
                _secFLabel.layer.cornerRadius = 5.0f;
                [_secFLabel setAlpha:1];
                [_secFLabel.layer setBorderColor:[UIColor blackColor].CGColor];
                [_secFLabel.layer setBorderWidth:1.0f];
            }
        }
        
        _secondaryDays = (NSMutableString *)[_secondaryDays stringByReplacingOccurrencesOfString:@"T" withString:@"Tu"];
        _secondaryDays = (NSMutableString *)[_secondaryDays stringByReplacingOccurrencesOfString:@"H" withString:@"Th"];
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
        [_discussionLabel setTextColor:[UIColor blackColor]];
        [_discussionLabel setText:@"No Discussion"];
        [_secondaryBuildingLabel setHidden:YES];
        [_secondaryTimesBegin setHidden:YES];
    }
    
    // Set default region to UMCP
    CLLocationCoordinate2D umcpCenter = CLLocationCoordinate2DMake(38.9875, -76.9400);
    MKCoordinateRegion zoomedRegion = [_mapView regionThatFits: MKCoordinateRegionMakeWithDistance(umcpCenter, 1500, 1500)];
    [_mapView setRegion:zoomedRegion animated:YES];
    
    updateBox = YES;
}

-(void)viewDidAppear:(BOOL)animated{
    NSLog(@"Course Detail Did Appear");
    network = [internetReachability currentReachabilityStatus];
    
    if(network == NotReachable){
        NSLog(@"No Internet");
        [_etaLabel setText:@"No Internet Connction"];
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *primBldg = @"";
            NSDictionary *mainBuilding;
            for(NSDictionary *building in _bldgCodes){
                if([[building objectForKey:@"code"] isEqualToString:[_primaryBldgString substringToIndex:3]]){
                    mainBuilding = [[NSDictionary alloc] initWithDictionary:building];
                    primBldg = [[building objectForKey:@"name"] objectForKey:@"text"];
                    if([primBldg rangeOfString:@" ("].location != NSNotFound){
                        primBldg = [primBldg substringToIndex:[primBldg rangeOfString:@" ("].location];
                    }
                    primBldg = [primBldg stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                }
            }
            // primBldg = @"Chemistry+Building";
            NSURL *primSearchURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://nominatim.openstreetmap.org/search?q=%@&viewbox=-76.9605,39.0035,-76.9168,38.9749&bounded=1&format=json&addressdetails=1",primBldg]];
            NSLog(@"Sending Primary Search: %@",[primSearchURL description]);
            [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:primSearchURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *primData, NSError *connectionError) {
                if(!connectionError){
                    NSError *err;
                    //NSData *primData = [NSData dataWithContentsOfURL:primSearchURL];
                    NSMutableArray *addresses = [NSJSONSerialization JSONObjectWithData:primData options:kNilOptions error:&err];
                    for(NSDictionary *address in addresses){
                        if([[[address objectForKey:@"address"] objectForKey:@"city"] isEqualToString:@"College Park"]){
                            primaryAddress = address;
                        }
                    }
                    NSLog(@"%@",[primaryAddress description]);
                    CLLocationDegrees lat = [[primaryAddress objectForKey:@"lat"] doubleValue];
                    CLLocationDegrees lon = [[primaryAddress objectForKey:@"lon"] doubleValue];
                    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(lat, lon);
                    bldgPoint = [[MKPointAnnotation alloc] init];
                    [bldgPoint setCoordinate:coordinates];
                    [bldgPoint setSubtitle:[[mainBuilding objectForKey:@"name"] objectForKey:@"text"]];
                    [bldgPoint setTitle:@"Main"];
                    selectedPoint = bldgPoint;
                    // Pin class on the map
                    // moved away from mkplacemark to mkpoint to customize the labels
                    [_etaLabel setText:@"Est Time: Getting Location Data"];
                    [self performSelectorOnMainThread:@selector(placeClassAndZoom:) withObject:bldgPoint waitUntilDone:NO];
                }
            }];
           
            
            if(_hasDiscussion){
                NSString *secBldg = @"";
                NSDictionary *secBuilding;
                for(NSDictionary *building in _bldgCodes){
                    if([[building objectForKey:@"code"] isEqualToString:[_secondaryBldgString substringToIndex:3]]){
                        secBuilding = [[NSDictionary alloc] initWithDictionary:building];
                        secBldg = [[building objectForKey:@"name"] objectForKey:@"text"];
                        if([secBldg rangeOfString:@" ("].location != NSNotFound){
                            secBldg = [secBldg substringToIndex:[secBldg rangeOfString:@"("].location];
                        }
                        secBldg = [secBldg stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                    }
                }
                if(![secBldg isEqualToString:primBldg]){
                    NSURL *secSearchURL = [NSURL URLWithString:[NSString stringWithFormat: @"http://nominatim.openstreetmap.org/search?q=%@&viewbox=-76.9605,39.0035,-76.9168,38.9749&bounded=1&format=json&addressdetails=1",secBldg]];
                    NSLog(@"Sending Secondary Search: %@",[secSearchURL description]);
                    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:secSearchURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *secData, NSError *connectionError) {
                        if(!connectionError){
                            NSError *err;
                            //NSData *secData = [NSData dataWithContentsOfURL:secSearchURL];
                            NSMutableArray *addresses = [NSJSONSerialization JSONObjectWithData:secData options:kNilOptions error:&err];
                            for(NSDictionary *address in addresses){
                                if([[[address objectForKey:@"address"] objectForKey:@"city"] isEqualToString:@"College Park"]){
                                    secondaryAddress = address;
                                }
                            }
                            NSLog(@"%@",[secondaryAddress description]);
                            CLLocationDegrees lat = [[secondaryAddress objectForKey:@"lat"] doubleValue];
                            CLLocationDegrees lon = [[secondaryAddress objectForKey:@"lon"] doubleValue];
                            CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(lat, lon);
                            disBldgPoint = [[MKPointAnnotation alloc] init];
                            [disBldgPoint setCoordinate:coordinates];
                            [disBldgPoint setSubtitle:[[secBuilding objectForKey:@"name"] objectForKey:@"text"]];
                            [disBldgPoint setTitle:@"Discussion"];
                            [self performSelectorOnMainThread:@selector(placeClassAndZoom:) withObject:disBldgPoint waitUntilDone:NO];
                        }
                    }];
                }
            }
        });
        //dispatch_async(dispatch_get_main_queue(), ^{});
    }
}

-(void)placeClassAndZoom:(MKPointAnnotation *)pin{
    NSLog(@"%@",[pin title]);
    if(pin == bldgPoint){
        if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
            //MKCoordinateRegion zoomedRegion = [_mapView regionThatFits: MKCoordinateRegionMakeWithDistance(coordinates, 200, 200)];
            //[_mapView setRegion:zoomedRegion animated:NO];
            _alertView = [[UIAlertView alloc] initWithTitle:@"Location error" message:@"Please allow UMDSocialScheduler to use your location in the Settings app. We use your location to provide a route to your class" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
            [_alertView show];
            [_etaLabel setText:@"Est Time: Check Location Settings"];
            MKCoordinateRegion zoomedRegion = [_mapView regionThatFits: MKCoordinateRegionMakeWithDistance(bldgPoint.coordinate, 200, 200)];
            [_mapView setRegion:zoomedRegion animated:YES];
        }
        [_mapView addAnnotation:pin];
        NSLog(@"Main Pin added");
        updateRoute = YES;
        [locationManager startUpdatingLocation];
    }else{
        [_mapView addAnnotation:pin];
        NSLog(@"Discussion Pin added");
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [locationManager setDelegate:nil];
    [locationManager stopUpdatingLocation];
    [_mapView removeOverlays:[_mapView overlays]];
    [_mapView setDelegate: nil];
    oldLocation = nil;
    //[self.mapView setDelegate:nil];
}

#pragma mark - MkMapViewDelegate

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    MKPinAnnotationView *pinView = nil;
    if(annotation != mapView.userLocation){
        static NSString *defaultPin = @"pinIdentifier";
        pinView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:defaultPin];
        pinView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:defaultPin];
        
        UIButton *calloutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        calloutButton.frame = CGRectMake(0, 0, 45, 25);
        //calloutButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [calloutButton setTitle:@"Route" forState:UIControlStateNormal];
        
        if(annotation == disBldgPoint){
            pinView.pinColor = MKPinAnnotationColorPurple; //Optional
            [calloutButton setTitleColor:[_discussionLabel textColor] forState:UIControlStateNormal];
        }else{
            [calloutButton setTitleColor:[_mainLabel textColor] forState:UIControlStateNormal];
        }

        pinView.rightCalloutAccessoryView = calloutButton;
        pinView.canShowCallout = YES; // Allows you to tap pin
        pinView.animatesDrop = YES;
    
    }
    return pinView;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    selectedPoint = (MKPointAnnotation *)[[_mapView selectedAnnotations] firstObject];
    NSLog(@"Route called for building: %@",[selectedPoint subtitle]);
    [_mapView deselectAnnotation:selectedPoint animated:YES];
    if(lastUserLocation != nil){
        updateRoute = YES;
        updateBox = YES;
        oldLocation = nil;
        [self performSelector:@selector(drawRouteWithCurrentLocation:) withObject:[NSNumber numberWithBool:YES]];
    }else{
        NSLog(@"Routing ignored, no userlocation");
    }
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    if([overlay isKindOfClass:[MKTileOverlay class]]){
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }else if([overlay isKindOfClass:[MKPolyline class]]){
        MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        if(selectedPoint == bldgPoint){
            // Main
            [polylineRenderer setStrokeColor:[UIColor redColor]];
            [_etaLabel setTextColor:[self.view backgroundColor]];
        }else{
            [polylineRenderer setStrokeColor:[_discussionLabel textColor]];
            [_etaLabel setTextColor:[_discussionLabel textColor]];
        }
        [polylineRenderer setLineWidth:2.5f];
        return polylineRenderer;
    }
    return nil;
}

-(void)drawRouteWithCurrentLocation:(NSNumber *)switchDestination{
    BOOL swapRoute = [switchDestination boolValue];
    CLLocation *myLocation = [[CLLocation alloc] initWithLatitude:lastUserLocation.coordinate.latitude longitude:lastUserLocation.coordinate.longitude];
    if(updateRoute && !routeUpdating){
        routeUpdating = YES;
        if([myLocation coordinate].latitude != [oldLocation coordinate].latitude || [myLocation coordinate].longitude != [oldLocation coordinate].longitude){
            NSLog(@"New Location Found");
            NSLog(@"Old Location: %@", [oldLocation description]);
            NSLog(@"Location Update: %@",[myLocation description]);
            [_mapView removeOverlay:existingRoute];
            
            NSString *bingString = [NSString stringWithFormat:@"http://dev.virtualearth.net/REST/v1/Routes/Walking?wayPoint.1=%f,%f&Waypoint.2=%f,%f&routePathOutput=Points&optimize=distance&key=AlBhfcixLlJBZA9wNxVFB5LEmiD3bvYak8mkWGCCaI8waSs6NPUDzdJw1oKy3cA9", locationManager.location.coordinate.latitude , locationManager.location.coordinate.longitude, selectedPoint.coordinate.latitude,selectedPoint.coordinate.longitude];
            NSLog(@"Bing Request URL: %@", bingString);
            
            NSURL *bingURL = [NSURL URLWithString:bingString];
            NSURLRequest *bingDirections = [[NSURLRequest alloc] initWithURL:bingURL];
            [NSURLConnection sendAsynchronousRequest:bingDirections queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSError *err;
                NSDictionary *responseFields = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
                NSLog(@"Bing Response: %@",[responseFields description]);
                if([[responseFields objectForKey:@"statusCode"] integerValue] ==  200){
                    NSNumber *travelTime = [[[[[responseFields objectForKey:@"resourceSets"] firstObject] objectForKey:@"resources"] firstObject] objectForKey:@"travelDuration"];
                    NSNumber *minutes = [NSNumber numberWithInt:[travelTime intValue] / 60];
                    NSNumber *seconds = [NSNumber numberWithInt:[travelTime intValue] % 60];
                    if(viewingMain){
                        [_etaLabel setText:[NSString stringWithFormat:@"Estimated Time: %@ min %@ sec",minutes, seconds]];
                    }
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
                        [_mapView setRegion:boundingBox animated:YES];
                        updateBox = NO;
                    }
                    routeUpdating = NO;
                    oldLocation = myLocation;
                }else if ([[responseFields objectForKey:@"statusCode"] integerValue] == 404){
                    _alertView = [[UIAlertView alloc] initWithTitle:@"Uh Oh" message:[[responseFields objectForKey:@"errorDetails"] firstObject] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    NSLog(@"Too far away");
                    [_etaLabel setText:@"You are too far away to show a route"];
                    //[_alertView show];
                    CLLocationDegrees lat = [[primaryAddress objectForKey:@"lat"] doubleValue];
                    CLLocationDegrees lon = [[primaryAddress objectForKey:@"lon"] doubleValue];
                    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(lat, lon);
                    MKCoordinateRegion zoomedRegion = [_mapView regionThatFits: MKCoordinateRegionMakeWithDistance(coordinates, 200, 200)];
                    [_mapView setRegion:zoomedRegion animated:YES];
                    oldLocation = myLocation;
                    updateBox = YES;
                    routeUpdating = NO;
                    //[self performSelector:@selector(refreshRoute) withObject:nil afterDelay:10.0f];
                    //[_mapView setRegion:zoomedRegion];
                }
            }];
        }else{
            NSLog(@"Same Location");
            routeUpdating = NO;
        }
        updateRoute = NO;
        if(!swapRoute){
            // Only send another request in 10 seconds if route needs updating
            [self performSelector:@selector(refreshRoute) withObject:nil afterDelay:10.0f];
        }
    }

}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *locationUpdate = [locations firstObject];
    lastUserLocation = locationUpdate;
    [self performSelector:@selector(drawRouteWithCurrentLocation:) withObject:[NSNumber numberWithBool:NO]];
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
