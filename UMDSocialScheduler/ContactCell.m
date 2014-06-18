//
//  ContactCell.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/9/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "ContactCell.h"

@implementation ContactCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [_whiteBackgroundView layer].cornerRadius = 3.0f;
        [_shadowView layer].cornerRadius = 3.0f;
        
    }
    return self;
}

-(void)awakeFromNib{
    /*
    _cardView.layer.shadowOffset = CGSizeMake(3, 3);
    _cardView.layer.shadowRadius = 4;
    _cardView.layer.shadowOpacity = 0.5;
     */
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
