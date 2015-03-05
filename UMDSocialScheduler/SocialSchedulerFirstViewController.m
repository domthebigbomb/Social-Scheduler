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
#import "AFNetworking.h"
#import "UIImage+Trim.h"
#import <Parse/Parse.h>
#import "ScheduleManager.h"
@interface SocialSchedulerFirstViewController ()
- (IBAction)postSchedule:(UIButton *)sender;
- (IBAction)logout:(UIButton *)sender;
- (IBAction)shareBarButton:(UIBarButtonItem *)sender;
@property (weak, nonatomic) IBOutlet UIButton *shareToFbButton;
@property (weak, nonatomic) IBOutlet UIWebView *visibleWebView;
@property (weak, nonatomic) IBOutlet UILabel *shareMsgLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *sharingActivity;
@property (strong,nonatomic) UIImageView *scheduleImageView;
@property (strong, nonatomic) UIAlertView *alertMsg;
@end

@implementation SocialSchedulerFirstViewController{
    NSString *zoomScript;
    NSString *socialSchedulerURLString;
    NSString *uploadScheduleURLString;
    NSString *updateCoursesURLString;
    NSString *postToFbURLString;
    NSString *fbLoginURLString;
    NSString *scheduleHtml;
    NSString *coursesString;
    NSString *termCode;
    int count;
    AFNetworkReachabilityManager *reachability;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"View Did Load");
    count = 0;
    [_shareMsgLabel setAlpha:0];
    zoomScript = @"document.body.style.zoom = 1.8;";
    fbLoginURLString = @"access?access_token=";
    socialSchedulerURLString = @"http://www.umdsocialscheduler.com/";
    uploadScheduleURLString = @"render_schedule";
    updateCoursesURLString = @"add_schedule";
    postToFbURLString = @"post_schedule";
    _visibleWebView.scalesPageToFit = YES;
    //[[UIColor alloc] initWithRed:204.0f green:51.0f blue:51.0f alpha:0.5f]
    UIColor *tintColor =
    [[UIColor alloc] initWithHue:0.0 saturation:.75 brightness:.80 alpha:1.0];
    [[UITabBar appearance] setTintColor:tintColor];
    _shareToFbButton.layer.cornerRadius = 3.0f;
    _newSchedule = NO;
    
    reachability = [AFNetworkReachabilityManager sharedManager];
    coursesString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Courses"];
    termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    _newSchedule = [[NSUserDefaults standardUserDefaults] boolForKey:@"refreshSchedule"];
    _htmlString = [[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"];
    
    [_visibleWebView loadHTMLString:_htmlString baseURL:nil];
    _visibleWebView.delegate = self;

}


-(void)viewDidAppear:(BOOL)animated{
    NSLog(@"View Did Appear");

    [_sharingActivity startAnimating];
    
    
    if(_htmlString != nil){
        scheduleHtml = [NSString stringWithString: _htmlString];
    }
    if(_newSchedule == YES || [_htmlString length]>0){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshSchedule"];
        
        // Render Schedule in backend
        if(_newSchedule == YES){
            NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
            NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
            NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
       
            [_sharingActivity stopAnimating];
            [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSString *renderURLString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,uploadScheduleURLString];
                NSMutableURLRequest *renderRequest = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:renderURLString] standardizedURL]];
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
                    NSLog(@"Schedule request...");
                    [renderConnection start];
                }
                else
                {
                    NSLog(@"Schedule request...");
                    NSLog(@"Connection could not be made");
                }
                
                // Add post call to send schedule data CMSC330||stuff
                NSString *addCoursesURLString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,updateCoursesURLString];
                NSMutableURLRequest *addScheduleRequest = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:addCoursesURLString] standardizedURL]];
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
                    NSLog(@"Courses request...");
                    NSLog(@"Connection Successful");
                    [addScheduleConnection start];
                }
                else
                {
                    NSLog(@"Courses request...");
                    NSLog(@"Connection could not be made");
                }
            }];
            
        }else{
            [_sharingActivity stopAnimating];
        }
        //NSLog(@"%@",_htmlString);
    }else{
        //[self performSegueWithIdentifier:@"ShowLogin" sender:self];
        [_sharingActivity stopAnimating];
    }
}

-(void)renderSchedule{
    /* assumes already passed in valid fbloginaccesstoken */
    NSString *renderURLString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,uploadScheduleURLString];
    NSMutableURLRequest *renderRequest = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:renderURLString] standardizedURL]];
    
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

}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    //NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
    NSString *description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Data JSON: %@", description);
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    NSLog(@"Error: %@" , error);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"Connection Finished");
}


-(UIView*)viewForZoomingInScrollView:(UIScrollView *)aScrollView {
    return _scheduleImageView;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"Webview finished loading");
    [_visibleWebView stringByEvaluatingJavaScriptFromString:zoomScript];
    //_visibleWebView.delegate = nil;
    [self performSelector:@selector(saveScheduleToServer) withObject:nil afterDelay:0.25f];

}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"Webview failed to load with error: %@", error.localizedDescription);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)cancelLogin:(UIStoryboardSegue *)segue{
    
}

-(void)showSchedule:(UIStoryboardSegue *)segue{
    
}

-(UIImage *)getSchedule{
    UIGraphicsBeginImageContextWithOptions([_visibleWebView bounds].size,NO,0);
    [[_visibleWebView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = [image imageByTrimmingWhitePixelsWithOpacity:100];
    return image;
}

- (NSString *)documentsPathForFileName:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:name];
}

-(NSData *)imageFromStorage:(NSString *)relativePath{
    NSString *fullPath = [self documentsPathForFileName:relativePath];
    NSData *imgData = [NSData dataWithContentsOfFile:fullPath];
    return imgData;
}

-(void)saveScheduleToServer{
    if(_newSchedule){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshSchedule"];
        UIImage *scheduleImage = [self getSchedule];
        NSString *relativePath = @"scheduleImage.jpg";
        NSString *path = [self documentsPathForFileName:[NSString stringWithFormat:@"scheduleImage.jpg"]];
        NSData *imageData = UIImageJPEGRepresentation(scheduleImage, 0.5f);
        [imageData writeToFile:path atomically:YES];
        [[NSUserDefaults standardUserDefaults] setObject:relativePath forKey:@"schedulePath"];
        NSMutableArray *courses = [[coursesString componentsSeparatedByString:@"/"] mutableCopy];
        
        [[ScheduleManager sharedInstance] trySaveScheduleForTerm:termCode Courses:courses HTML:_htmlString ImageData:imageData];
    }
}

- (IBAction)takeSnapshot:(UIButton *)sender {
    UIImage *snapshot = [self getSchedule];
    UIImageWriteToSavedPhotosAlbum(snapshot, self, nil, nil);
}

- (IBAction)postSchedule:(UIButton *)sender {
    [_shareToFbButton setEnabled:NO];
    [_sharingActivity startAnimating];
    if([[FBSession activeSession] accessTokenData]){
        NSLog(@"Permissions: %@",[[FBSession activeSession] permissions]);
        NSString *fbLoginString = [NSString stringWithFormat:@"%@%@%@",socialSchedulerURLString,fbLoginURLString,[[FBSession activeSession] accessTokenData]];
        NSURL *fbLoginURL = [NSURL URLWithString:fbLoginString];
        NSURLRequest *fbLoginRequest = [NSURLRequest requestWithURL:fbLoginURL];
        [NSURLConnection sendAsynchronousRequest:fbLoginRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError *error;
            NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
            NSLog(@"Login Response: %@", response);
            NSLog(@"Login Error: %@", connectionError);
            NSLog(@"Login JSON: %@",[JSON description]);
        
        // Add post call to send schedule data CMSC330||stuff
        
            NSString *postURLString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,postToFbURLString];
            NSURLRequest *shareRequest = [NSURLRequest requestWithURL:[[NSURL URLWithString:postURLString] standardizedURL]];
            [NSURLConnection sendAsynchronousRequest:shareRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSError *error;
                NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];
                NSLog(@"Share Rsponse: %@", response);
                NSLog(@"Share Error: %@", connectionError);
                NSLog(@"Share JSON: %@", [JSON description]);
                
                BOOL success = [[JSON valueForKey:@"success"] boolValue];
                if(!success){
                    NSString *renderURLString = [NSString stringWithFormat:@"%@%@",socialSchedulerURLString,uploadScheduleURLString];
                    NSMutableURLRequest *renderRequest = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:renderURLString] standardizedURL]];
                    
                    scheduleHtml = [scheduleHtml stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
                    
                    scheduleHtml = [NSString stringWithFormat:@"term=%@&html=%@",termCode,scheduleHtml];
                    NSData *postData = [scheduleHtml dataUsingEncoding:NSASCIIStringEncoding];
                    
                    [renderRequest setHTTPMethod:@"POST"];
                    [renderRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                    [renderRequest setHTTPBody:postData];
                    scheduleHtml = [scheduleHtml stringByRemovingPercentEncoding];

                    NSURLResponse *response;
                    NSData *data;
                    NSError *error;
                    data = [NSURLConnection sendSynchronousRequest:renderRequest returningResponse: &response error: &error];
                    NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];                    NSLog(@"Render Rsponse: %@", response);
                    NSLog(@"Render Error: %@", connectionError);
                    NSLog(@"Render JSON: %@", [JSON description]);
                    
                    BOOL success = [[JSON valueForKey:@"success"] boolValue];
                    if(!success){
                        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Uh Oh" message:@"There seems to be a problem sharing your schedule to Facebook. Check your connection and make sure you are logged into FB" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                        [_alertMsg show];
                        [_sharingActivity stopAnimating];
                        [_shareToFbButton setEnabled:YES];
                    }else{
                        [NSURLConnection sendAsynchronousRequest:shareRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                            NSError *error;
                            NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error: &error];                            NSLog(@"Share Rsponse: %@", response);
                            NSLog(@"Share Error: %@", connectionError);
                            NSLog(@"Share JSON: %@", [JSON description]);
                            BOOL success = (BOOL)[JSON valueForKey:@"success"];
                            if(!success){
                                _alertMsg = [[UIAlertView alloc] initWithTitle:@"Uh Oh" message:@"There seems to be a problem connecting to UMDSocialScheduler server." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                                [_alertMsg show];
                                [_sharingActivity stopAnimating];
                                [_shareToFbButton setEnabled:YES];
                            }else{
                                [_shareMsgLabel setText:@"Successfully posted to Facebook!"];
                                [self performSelectorOnMainThread:@selector(animateShareLabel) withObject:nil waitUntilDone:NO];
                            }
                        }];
                    }
                }else{
                    [_shareMsgLabel setText:@"Successfully posted to Facebook!"];
                    [self performSelectorOnMainThread:@selector(animateShareLabel) withObject:nil waitUntilDone:NO];
                }
            }];
        }];
    }else{
        [_shareMsgLabel setText:@"Log in to Facebook to share"];
        [self performSelectorOnMainThread:@selector(animateShareLabel) withObject:nil waitUntilDone:NO];
    }
}

-(void)animateShareLabel{
    [_sharingActivity stopAnimating];
    [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [_shareMsgLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0 delay:2.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [_shareMsgLabel setAlpha:0];
        } completion:^(BOOL finished) {
            _shareToFbButton.enabled = YES;
        }];
    }];
}


- (IBAction)shareBarButton:(UIBarButtonItem *)sender {
    UIImage *snapshot = [self getSchedule];
    NSString *text = @"Shared with UMD Social Scheduler for iOS. Download here: https://itunes.apple.com/us/app/umd-social-scheduler/id819921928?ls=1&mt=8";
    NSArray* datatoshare = @[snapshot, text];  // ...or other kind of data.
    UIActivityViewController* activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:datatoshare applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:^{}];
}

-(IBAction)logout:(id)sender{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Schedule"];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
