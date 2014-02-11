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
    int count;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    count = 0;
    zoomScript = @"document.body.style.zoom = 1.5;";
    
    _scheduleFound = NO;
    
}


-(void)viewDidAppear:(BOOL)animated{
    _visibleWebView.delegate = self;
    _htmlString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"];
    _courses = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Courses"]];
    if(_scheduleFound == YES || [_htmlString length]>0){
        NSMutableString *header = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];
        [header appendString:@"<head><style type='text/css'>html, body {	height: 100%;	padding: 0;	margin: 0;} "];
        [header appendString:@"#table {display: table; 	height: 100%;	width: 100%;} "];
        [header appendString:@"#cell {	display: table-cell; 	vertical-align: middle;}</style></head>"];
        NSString *body = @"<div id='table'><div id='cell'>";
        NSString *footer = @"</div></div></body></html>";
        _htmlString = [NSString stringWithFormat:@"%@ %@ %@ %@",header,body,_htmlString,footer];
        [_visibleWebView loadHTMLString:_htmlString baseURL:nil];
        //courses = [_courses mutableCopy];
        [[NSUserDefaults standardUserDefaults] setObject:_htmlString forKey:@"Schedule"];
        [[NSUserDefaults standardUserDefaults] setObject:_courses forKey:@"Courses"];
        //NSLog(@"HTML: %@",_htmlString);


    }else{
        [self performSegueWithIdentifier:@"ShowLogin" sender:self];
    }
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
    UIGraphicsBeginImageContextWithOptions([_visibleWebView bounds].size,NO,2.0f);
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
