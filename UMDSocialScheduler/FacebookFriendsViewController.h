//
//  FacebookFriendsViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/7/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
@interface FacebookFriendsViewController : UIViewController<FBLoginViewDelegate,UITableViewDataSource,UIScrollViewDelegate, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *greyedBackgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *scheduleImageView;
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;
@property (weak, nonatomic) IBOutlet UIScrollView *scheduleScrollView;

@end
