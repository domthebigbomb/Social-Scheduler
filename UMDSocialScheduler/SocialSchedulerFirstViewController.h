//
//  SocialSchedulerFirstViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/5/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SocialSchedulerFirstViewController : UIViewController<UIWebViewDelegate>

@property (strong,nonatomic) NSString *htmlString;
@property BOOL scheduleFound;

-(IBAction)showSchedule:(UIStoryboardSegue *)segue;
@end
