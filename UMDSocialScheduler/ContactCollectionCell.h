//
//  ContactCollectionCell.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 9/16/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *contactPic;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionLabel;

@end
