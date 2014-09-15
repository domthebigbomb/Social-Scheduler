//
//  ScheduleTheaterViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 7/31/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface ScheduleTheaterViewController : UIViewController<UIScrollViewDelegate,UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) NSString *studentName;
@property (strong, nonatomic) NSString *termCode;
@property (strong, nonatomic) NSString *fbid;
@property CGPoint pointOfOrigin;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *picPanGesture;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *scheduleView;
-(IBAction)dismissSchedule:(id)sender;
@end
