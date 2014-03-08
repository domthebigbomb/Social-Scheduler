//
//  SocialSchedulerFirstViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/5/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "SocialSchedulerFirstViewController.h"
#import "LoginViewController.h"
#import <CoreGraphics/CoreGraphics.h>
#import "Reachability.h"
#import <YAJL/YAJL.h>
@interface SocialSchedulerFirstViewController ()
- (IBAction)takeSnapshot:(UIButton *)sender;
- (IBAction)shareBarButton:(UIBarButtonItem *)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scheduleScrollView;
@property (weak, nonatomic) IBOutlet UIWebView *visibleWebView;
@property (strong,nonatomic) UIImageView *scheduleImageView;
@end

@implementation SocialSchedulerFirstViewController{
    NSString *zoomScript;
    UIImage *scheduleImage;
    NSString *socialSchedulerURLString;
    NSString *uploadScheduleURLString;
    NSString *updateCoursesURLString;
    NSString *fbLoginURLString;
    NSString *scheduleHtml;
    NSString *coursesString;
    NSString *termCode;
    int count;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    count = 0;
    zoomScript = @"document.body.style.zoom = 1.5;";
    fbLoginURLString = @"access?access_token=";
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    uploadScheduleURLString = @"render_schedule";
    updateCoursesURLString = @"add_schedule";
    _newSchedule = NO;
}


-(void)viewDidAppear:(BOOL)animated{
    _visibleWebView.delegate = self;
    _newSchedule = [[NSUserDefaults standardUserDefaults] boolForKey:@"refreshSchedule"];
    _htmlString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"];
    coursesString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Courses"];
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    if(_htmlString != nil)
        scheduleHtml = [NSString stringWithString: _htmlString];
    if(_newSchedule == YES || [_htmlString length]>0){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshSchedule"];
        NSMutableString *header = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];
        [header appendString:@"<head><style type='text/css'>html, body {	height: 100%;	padding: 0;	margin: 0;} "];
        [header appendString:@"#table {display: table; 	height: 100%;	width: 100%;} "];
        [header appendString:@"#cell {	display: table-cell; 	vertical-align: middle;}</style></head>"];
        NSString *body = @"<div id='table'><div id='cell'>";
        NSString *footer = @"</div></div></body></html>";
        _htmlString = [NSString stringWithFormat:@"%@ %@ %@ %@",header,body,_htmlString,footer];
        [_visibleWebView loadHTMLString:_htmlString baseURL:nil];
        // Render Schedule in backend
        if(_newSchedule == YES){
            NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
            NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
            NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
       
            
            [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                
                
                // Add post call to send schedule data CMSC330||stuff

                NSString *renderURLString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,uploadScheduleURLString];
                NSString *addCoursesURLString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,updateCoursesURLString];
                NSMutableURLRequest *renderRequest = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:renderURLString] standardizedURL]];
                NSMutableURLRequest *addScheduleRequest = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:addCoursesURLString] standardizedURL]];
                
                scheduleHtml = [scheduleHtml stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            
                scheduleHtml = [NSString stringWithFormat:@"term=%@&html=%@",termCode,scheduleHtml];
                NSData *postData = [scheduleHtml dataUsingEncoding:NSASCIIStringEncoding];

                [renderRequest setHTTPMethod:@"POST"];
                [renderRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                [renderRequest setHTTPBody:postData];
            
                NSURLConnection *renderConnection = [[NSURLConnection alloc]  initWithRequest:renderRequest delegate:self];
                
                scheduleHtml = [scheduleHtml stringByRemovingPercentEncoding];
                if(renderConnection)
                {
                    NSLog(@"Connection Successful");
                    [renderConnection start];
                }
                else
                {
                    NSLog(@"Connection could not be made");
                }
                
                coursesString = [coursesString stringByReplacingOccurrencesOfString:@"|" withString:@","];
                coursesString = [coursesString stringByReplacingOccurrencesOfString:@"/" withString:@"|"];
                coursesString = [coursesString substringToIndex:[coursesString length]-1];
                coursesString = [NSString stringWithFormat:@"term=%@&schedule=%@",termCode,coursesString];
                postData = [coursesString dataUsingEncoding:NSASCIIStringEncoding];
                [addScheduleRequest setHTTPMethod:@"POST"];
                [addScheduleRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                [addScheduleRequest setHTTPBody:postData];
                NSURLConnection *addScheduleConnection = [[NSURLConnection alloc]  initWithRequest:addScheduleRequest delegate:self];
                if(addScheduleConnection)
                {
                    NSLog(@"Connection Successful");
                    [addScheduleConnection start];
                }
                else
                {
                    NSLog(@"Connection could not be made");
                }
            }];
        }
        //NSLog(@"%@",_htmlString);
    }else{
        [self performSegueWithIdentifier:@"ShowLogin" sender:self];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    //id JSON = [data yajl_JSON];
    NSString *description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Data JSON: %@", description);
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    NSLog(@"Error: %@" , error);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"Connection Finished");
}


- (UIView*)viewForZoomingInScrollView:(UIScrollView *)aScrollView {
    return _scheduleImageView;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [_visibleWebView stringByEvaluatingJavaScriptFromString:zoomScript];
    _visibleWebView.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)showSchedule:(UIStoryboardSegue *)segue{
    
}

/*
-(UIImage *)cropImage:(UIImage *)scheduleImage{
    UIImage *croppedImage = [[UIImage alloc] init];
    NSArray *RGBarray =    [self getRGBAsFromImage:scheduleImage atX:0 andY:0 count:[scheduleImage size].height * [scheduleImage size].width];
    int yIndex = [scheduleImage size].height/3;
    int xIndex = 0;
    int originalWidth = [scheduleImage size].width;
    UIColor *whitePixel = [RGBarray objectAtIndex:yIndex*originalWidth+xIndex];
    UIColor *currentPixel = [RGBarray objectAtIndex:yIndex*originalWidth+xIndex];
    while([currentPixel isEqual:whitePixel]){
        xIndex++;
        currentPixel = [RGBarray objectAtIndex:yIndex*originalWidth+xIndex];
    }
    NSLog(@"%d",xIndex);
    CGRect rect = CGRectMake(10, -30, 2*([scheduleImage size].width), 1.2*[scheduleImage size].height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([scheduleImage CGImage], rect);
    croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    if([RGBarray objectAtIndex:yIndex*originalWidth+x] == [UIColor whiteColor]){
        
    }
 
    return croppedImage;
}
*/
-(UIImage *)getSchedule{
    UIGraphicsBeginImageContextWithOptions([_visibleWebView bounds].size,NO,0);
    [[_visibleWebView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //capturedScreen = [self cropImage:capturedScreen];
    return capturedScreen;
}

/*
- (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy count:(int)count
    {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
        
        // First get the image into your data buffer
        CGImageRef imageRef = [image CGImage];
        NSUInteger width = CGImageGetWidth(imageRef);
        NSUInteger height = CGImageGetHeight(imageRef);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
    
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGContextRelease(context);
    
        // Now your rawData contains the image data in the RGBA8888 pixel format.
        int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
        for (int ii = 0 ; ii < count ; ++ii)
        {
            CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
            CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
            CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
            CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
            byteIndex += 4;
            
            UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            [result addObject:acolor];
        }
    
        free(rawData);
    
        return result;
}
*/

- (IBAction)takeSnapshot:(UIButton *)sender {
    UIImage *snapshot = [self getSchedule];
    UIImageWriteToSavedPhotosAlbum(snapshot, self, nil, nil);
}

- (IBAction)shareBarButton:(UIBarButtonItem *)sender {
    UIImage *snapshot = [self getSchedule];
    NSString *text = @"Shared via UMD Social Scheduler for iOS";
    NSArray* datatoshare = @[snapshot, text];  // ...or other kind of data.
    UIActivityViewController* activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:datatoshare applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:^{}];
}
@end
