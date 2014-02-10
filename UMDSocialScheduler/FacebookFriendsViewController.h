//
//  FacebookFriendsViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/7/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
@interface FacebookFriendsViewController : UIViewController<FBLoginViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;

@end
