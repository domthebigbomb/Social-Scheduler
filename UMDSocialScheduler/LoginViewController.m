//
//  LoginViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/6/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "LoginViewController.h"
#import "FlatTheme.h"
#import "SocialSchedulerFirstViewController.h"
@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *profilePictureView;
@property (weak, nonatomic) IBOutlet UIImageView *circleMask;
@property (weak, nonatomic) IBOutlet UIImageView *borderMask;
@property (weak, nonatomic) IBOutlet UIImageView *loginContainer;
@property (weak, nonatomic) IBOutlet UIView *visualView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)login:(UIButton *)sender;
@property (strong, nonatomic) UIWebView *webPage;
@property (strong, nonatomic)UITapGestureRecognizer *tap;
@property CGPoint originalCenter;
@property (strong, nonatomic) UIAlertView *alertMsg;

@end

@implementation LoginViewController{
    NSString *scheduleURL;
    NSString *loginScript;
    NSString *htmlScript;
    NSString *htmlString;
    NSString *testURL;
    int count;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    FBLoginView *loginView = [[FBLoginView alloc] initWithReadPermissions:@[@"basic_info",@"email",@"user_likes"]];
    loginView.delegate = self;
    loginView.frame = CGRectOffset(loginView.frame, 52, 480);
    [self.view addSubview:loginView];
    
    count = 0;
    
    scheduleURL = @"https://mobilemy.umd.edu/portal/server.pt;MYUMSESSION=31CqSykpJ1DWxzwpvwRFK6J2XT4ccpltBcNSX9cybklfbKmfjxvS!1501198949?cached=false&redirect=https%3A%2F%2Fmobilemy.umd.edu%2Fportal%2Fserver.pt%2Fgateway%2FPTARGS_0_340574_368_211_0_43%2Fhttps%3B%2Fwww.sis.umd.edu%2Ftestudo%2FstudentSched%3Fterm%3D201401&space=Login";
    testURL = @"http://testudo.umd.edu/ssched/index.html";
    htmlScript = @"document.body.innerHTML";
    
    _webPage = [[UIWebView alloc] init];
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    _tap.enabled = NO;
    [self.view addGestureRecognizer:_tap];
    self.originalCenter = self.view.center;
    
    [self loadDesignElements];
}

-(void)loadDesignElements{
    // NSString* fontName = @"Avenir-Book";
    NSString* boldFontName = @"Avenir-Black";
    // UIColor* darkColor = [UIColor colorWithRed:7.0/255 green:61.0/255 blue:48.0/255 alpha:1.0f];
    _loginButton.layer.cornerRadius = 3.0f;
    //_loginButton.backgroundColor = [self.view backgroundColor];
    _loginButton.titleLabel.font = [UIFont fontWithName:boldFontName size:20.0f];
    [_loginButton setTitleColor:[self.view backgroundColor] forState:UIControlStateNormal];
    
    _circleMask.layer.cornerRadius = _circleMask.frame.size.width/2;
    [_circleMask addSubview:_profilePictureView];
    _borderMask.layer.cornerRadius = _borderMask.frame.size.width/2;
    [_borderMask addSubview:_circleMask];
    _loginContainer.layer.cornerRadius = 4.0f;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    count ++;
    [_webPage stringByEvaluatingJavaScriptFromString:loginScript];
    htmlString = [_webPage stringByEvaluatingJavaScriptFromString:htmlScript];
    if(count == 2){
        if([htmlString rangeOfString:@"alertErrorTitle"].location == NSNotFound){
            NSLog(@"Login Success");
            htmlString = [_webPage stringByEvaluatingJavaScriptFromString:htmlScript];
            NSLog(@"HTML Retrieved");
            htmlString = [htmlString substringFromIndex:[htmlString rangeOfString:@"--><center>"].location];
            htmlString = [htmlString substringFromIndex:3];
            NSLog(@"Trimmed first half");
            htmlString = [htmlString substringToIndex:[htmlString rangeOfString:@"</center>"].location];
            //String brodder = "jonathan";
            [_activityIndicator stopAnimating];
            _webPage.delegate = nil;
            NSLog(@"%@",htmlString);
            [self performSegueWithIdentifier:@"ShowSchedule" sender:self];
        }else{
            NSLog(@"Login Failed");
            count = 0;
            htmlString = @"";
            webView.delegate = nil;
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"University ID and/or Password incorrect" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
            [_alertMsg show];
            [_activityIndicator stopAnimating];
            [_usernameField setEnabled:YES];
            [_passwordField setEnabled:YES];
            
        }
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"%@",[error localizedDescription]);
}


// Facebook login related functions
-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user{
    _profilePictureView.profileID = [user id];
    [_statusLabel setText:[NSString stringWithFormat:@"%@",[user name]]];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    NSLog(@"Logged in");
}

-(void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView{
    _profilePictureView.profileID = nil;
    [_statusLabel setText:@""];
}


// Keyboard Related Methods
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    _tap.enabled = YES;
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    _visualView.center = CGPointMake(self.originalCenter.x, self.originalCenter.y - 120);
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField isEqual:_usernameField]){
        [_passwordField becomeFirstResponder];
    }else{
        [self performSelector:@selector(login:) withObject:self];
    }
    return YES;
}

-(void)hideKeyboard
{
    _visualView.center = self.originalCenter;
    [_usernameField resignFirstResponder];
    [_passwordField resignFirstResponder];
    _tap.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier] isEqualToString:@"ShowSchedule"]){
        SocialSchedulerFirstViewController *scheduleController = (SocialSchedulerFirstViewController *)segue.destinationViewController;
        NSString *webPageCode = htmlString;
        scheduleController.htmlString = webPageCode;
        scheduleController.scheduleFound = YES;
    }
}

- (IBAction)login:(UIButton *)sender {
    if([[_usernameField text]isEqualToString:@""] || [[_passwordField text] isEqualToString:@""]){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Please complete enter both University ID (Not a number) and Password" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else{
    loginScript = [NSString stringWithFormat:@"document.lform.in_tx_username.value='%@';document.lform.in_pw_userpass.value='%@'; doLogin();",_usernameField.text,_passwordField.text];
    [self performSelector:@selector(hideKeyboard)];
    _webPage.delegate = self;
    [_usernameField setEnabled:NO];
    [_passwordField setEnabled:NO];
    [_activityIndicator startAnimating];
    [_webPage loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:scheduleURL]]];
    }
}
@end
