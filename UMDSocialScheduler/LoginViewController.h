//
//  LoginViewController.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/6/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
@interface LoginViewController : UIViewController<FBLoginViewDelegate,UIWebViewDelegate,UITextFieldDelegate,UIAlertViewDelegate, UIActionSheetDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@end
