//
//  SocialSchedulerFirstViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/5/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
@interface SocialSchedulerFirstViewController : UIViewController<UIWebViewDelegate,UIScrollViewDelegate,FBLoginViewDelegate,NSURLConnectionDelegate>
@property (strong) NSString *loginData;
@property (strong,nonatomic) NSString *htmlString;
@property BOOL newSchedule;
-(void)renderSchedule;
-(IBAction)showSchedule:(UIStoryboardSegue *)segue;
-(IBAction)cancelLogin:(UIStoryboardSegue *)segue;
@end
