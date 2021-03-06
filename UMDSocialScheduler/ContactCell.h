//
//  ContactCell.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/9/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
@interface ContactCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *contactPic;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numCoursesLabel;
@property (weak, nonatomic) IBOutlet UIView *imageShadow;
@property (weak, nonatomic) IBOutlet UIButton *showScheduleButton;
@property (strong, nonatomic) NSString *fbid;
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (weak, nonatomic) IBOutlet UIView *cardShadow;

@end
