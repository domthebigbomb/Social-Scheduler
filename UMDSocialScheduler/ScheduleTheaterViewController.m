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
    //self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //self.modalPresentationStyle = UIModalPresentationFullScreen;
    //self.modalPresentationStyle = UIModalPresentationPopover;
    _termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
    [_doneButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    [_doneButton.layer setBorderWidth:1.0f];
    [self.view setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.9]];
    [_scrollView setDelegate:self];
    [_picPanGesture addTarget:self action:@selector(dragPicture:)];
    NSLog(@"Center: %f", _scheduleView.center.y);
}

-(void)viewDidAppear:(BOOL)animated{
    [_activity startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage *contactPic = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.umdsocialscheduler.com/schedule_image?term=%@&fbid=%@",_termCode, _fbid]]]];
        [self performSelectorOnMainThread:@selector(updateScheduleImage:) withObject:contactPic waitUntilDone:NO];
    });
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"Mail Sent");
    }else if(result == MFMailComposeResultCancelled){
        NSLog(@"User Cancelled");
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)doubleTappedSchedule:(id)sender {
    NSLog(@"Double Tapped");
    if([_scrollView zoomScale] == 1.0){
        [_scrollView setZoomScale:2.0 animated:YES];
    }else{
        [_scrollView setZoomScale:1.0 animated:YES];
    }
}


- (IBAction)tappedSchedule:(UIGestureRecognizer *)sender {
    NSLog(@"Schedule Tapped");
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIActionSheet *scheduleActions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save to Photos", @"Email Schedule", nil];
        [scheduleActions showInView:self.view];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Action button index: %ld",(long)buttonIndex);
    switch (buttonIndex) {
        case 0:
            UIImageWriteToSavedPhotosAlbum(_scheduleView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            break;
        case 1:
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
                picker.mailComposeDelegate = self;
                NSString *subject = (_studentName != nil) ? [NSString stringWithFormat:@"%@'s Schedule",_studentName] : @"Schedule";

                [picker setSubject:subject];
                NSData *myData = UIImageJPEGRepresentation(_scheduleView.image, 1.0);
                NSString *fileName = [NSString stringWithFormat:@"%@.jpg",subject];
                [picker addAttachmentData:myData mimeType:@"image/jpg" fileName:fileName];
                
                [self presentViewController:picker animated:YES completion:nil];
                
            }else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Mailing not supported on this device" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                [alert show];
            }
            break;
        default:
            break;
    }
}

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo{
    if(!error){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Saved Successfully" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
    }
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
            [_scheduleView setAlpha: difference + .5];
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
                [_scheduleView setAlpha:1.0];
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
    _scheduleView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [_scheduleView setImage:image];
    [UIView animateWithDuration:0.2 animations:^{
        _scheduleView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        scheduleOrigin = _scheduleView.frame;
        lastGesturePoint = [_picPanGesture translationInView:_picPanGesture.view];
        [_activity stopAnimating];
    }];
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _scheduleView;
}


-(IBAction)dismissSchedule:(id)sender{
    [_scrollView setZoomScale:1 animated:YES];

    [UIView animateWithDuration:0.2 animations:^{
        //_scheduleView.layer.anchorPoint = CGPointMake(_pointOfOrigin.x/viewWidth, _pointOfOrigin.y/viewHeight);
        //_scheduleView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [_scheduleView setAlpha:0.7];
        [self.view setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

@end
