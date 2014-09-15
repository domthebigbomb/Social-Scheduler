//
//  ClassesViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 9/3/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <EventKit/EventKit.h>

@interface ClassesViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property BOOL coursesFound;

@property (weak, nonatomic) IBOutlet UICollectionView *classCollectionView;
- (IBAction)showSchedule:(UIButton *)sender;

@end
