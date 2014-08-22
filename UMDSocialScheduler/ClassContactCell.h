//
//  ClassContactCell.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/11/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClassContactCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *shadow;
@property (weak, nonatomic) IBOutlet UIImageView *contactPictureView;
@property (weak, nonatomic) IBOutlet UIButton *scheduleButton;

@end
