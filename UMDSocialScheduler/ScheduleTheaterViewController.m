//
//  ScheduleTheaterViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 7/31/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "ScheduleTheaterViewController.h"

@implementation ScheduleTheaterViewController{
    CGRect scheduleOrigin;
    CGPoint lastGesturePoint;
    CGPoint scheduleCenter;
}

-(void)viewDidLoad{
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    _termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    [_doneButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    [_doneButton.layer setBorderWidth:1.0f];
    [self.view setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.9]];
    [_scrollView setDelegate:self];
    [_picPanGesture addTarget:self action:@selector(dragPicture:)];
}

-(void)viewDidAppear:(BOOL)animated{
    [_activity startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.umdsocialscheduler.com/schedule_image?term=%@&fbid=%@",_termCode, _fbid]]]];
        [self performSelectorOnMainThread:@selector(updateScheduleImage:) withObject:contactPic waitUntilDone:NO];
    });
}

-(void)dragPicture:(UIPanGestureRecognizer *)gesture{
    UIGestureRecognizerState state = [gesture state];
    
    
    switch (state) {
        case UIGestureRecognizerStateBegan:
            scheduleCenter = _scheduleView.center;
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [gesture translationInView:_scheduleView.superview];
            _scheduleView.center = CGPointMake(_scheduleView.center.x, _scheduleView.center.y + translation.y);
            [gesture setTranslation:CGPointZero inView:_scheduleView.superview];
            // Difference between current position and the original position
            double difference = fabs(_scheduleView.center.y - scheduleCenter.y);
            if(difference < 150){
                difference /= 150;
                difference = 0.9 - difference;
                if(difference < 0.25){
                    difference = 0.25;
                }
            }else{
                difference = 0.25;
            }
            //NSLog(@"Difference: %@",[NSNumber numberWithDouble:difference]);
            
            [_doneButton setAlpha:difference];
            [self.view setBackgroundColor:[UIColor colorWithWhite:0 alpha:difference]];
            
            break;
        }
            
        case UIGestureRecognizerStateEnded:{
            double difference = (_scheduleView.center.y - scheduleCenter.y);
            if(difference < -150){
                NSLog(@"Dismiss controller up");
                [UIView animateWithDuration:0.5 animations:^{
                    [self.view setAlpha:0];
                } completion:^(BOOL finished) {
                    [self dismissViewControllerAnimated:NO completion:nil];
                }];
                break;
            }else if(difference > 150){
                NSLog(@"Dismiss controller down");
                [UIView animateWithDuration:0.25 animations:^{
                    [self.view setAlpha:0];
                } completion:^(BOOL finished) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
                break;
            }
        }
        case UIGestureRecognizerStateCancelled: {
            [UIView animateWithDuration:0.25 animations:^{
                [self.view setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.9]];
                [_doneButton setAlpha:1.0];
                _scheduleView.center = scheduleCenter;
            }];
            break;
        }
            
        default:
            break;
    }
}

-(void)updateScheduleImage:(UIImage *)image{
    [_scrollView setZoomScale:1.0];
    [_scheduleView setImage:image];
    scheduleOrigin = _scheduleView.frame;
    lastGesturePoint = [_picPanGesture translationInView:_picPanGesture.view];
    [_activity stopAnimating];
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _scheduleView;
}

-(IBAction)dismissSchedule:(id)sender{
    [_scrollView setZoomScale:1 animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
