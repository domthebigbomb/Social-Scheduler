//
//  CourseCollectionCell.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 9/3/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CourseCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *courseNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *mainContentView;
@property (strong, nonatomic) NSArray *contacts;

@end
