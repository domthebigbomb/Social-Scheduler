//
//  SocialSchedulerSecondViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/5/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface SocialSchedulerSecondViewController : UIViewController<FBLoginViewDelegate,UITableViewDataSource,UITableViewDelegate>{
}
@property BOOL coursesFound;

-(IBAction)dismissDetails:(UIStoryboardSegue *)segue;

@end
