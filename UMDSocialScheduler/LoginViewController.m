 //
//  LoginViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/6/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "LoginViewController.h"
#import "SocialSchedulerFirstViewController.h"
#import "AFNetworking.h"
#import "ScheduleManager.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *superViewCenterConstraint;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *profilePictureView;
@property (weak, nonatomic) IBOutlet UIImageView *circleMask;
@property (weak, nonatomic) IBOutlet UIImageView *loginContainer;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;

@property (weak, nonatomic) IBOutlet UIView *visualView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)login:(UIButton *)sender;
@property (strong, nonatomic) UIWebView *webPage;
@property (strong, nonatomic)UITapGestureRecognizer *tap;
@property (strong, nonatomic) UIAlertView *alertMsg;
@property (strong, nonatomic) UIActionSheet *actionMsg;
@property (weak, nonatomic) IBOutlet UIView *loginFieldsView;
@property (strong, nonatomic) UIPickerView *semesterPickerView;
@property (weak, nonatomic) IBOutlet UITextField *semesterField;
@property (weak, nonatomic) IBOutlet FBLoginView *fbLoginView;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpacerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *welcomeHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameHeight;

@end

@implementation LoginViewController{
    NSString *scheduleURL;
    NSString *loginScript;
    NSString *htmlScript;
    NSString *courseScript;
    NSString *htmlString;
    NSString *testURL;
    NSString *courseDetails;
    NSString *courseString;
    NSString *renderScheduleURL;
    NSArray *semesters;
    NSArray *years;
    NSArray *semesterInfo;
    NSInteger semesterIndex;
    NSInteger yearIndex;
    NSDictionary *semesterDict;
    NSURL *semesterURL;
    AFNetworkReachabilityManager *reachability;
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
    
    NSLog(@"App Loaded");
    _semesterPickerView = [[UIPickerView alloc] init];
    
    semesterURL = [NSURL URLWithString:@"http://www.kimonolabs.com/api/d9c7z5py?apikey=e228433aba70a1ea083189f321776248"];
    
    reachability = [AFNetworkReachabilityManager sharedManager];
    
    semesters = [[NSMutableArray alloc] init];
    semesters = @[@"Fall 2013",@"Winter 2014",@"Spring 2014",@"Summer I 2014",@"Summer II 2014",@"Fall 2014"];
    [_fbLoginView setReadPermissions:@[@"public_profile",@"user_friends",@"email"]];
    
    [_fbLoginView setDefaultAudience:FBSessionDefaultAudienceFriends];
    [_fbLoginView setPublishPermissions:@[@"publish_actions"]];
    [_fbLoginView setDelegate:self];
    
    renderScheduleURL = @"http://www.umdsocialscheduler.com/render_schedule?";
    
    count = 0;
    testURL = @"http://testudo.umd.edu/ssched/index.html";
    htmlScript = @"document.body.innerHTML";
    courseScript = @"document.getElementsByName('schedstr')[0].value";
    //semesters = @[@"Spring", @"Summer",@"Fall", @"Winter"];
    //years = @[@"2014",@"2013",@"2012"];
    semesterIndex = 0;
    yearIndex = 0;
    
    [_semesterPickerView selectRow:[semesters count]/2 inComponent:0 animated:NO];
    //[_semesterPickerView selectRow:0 inComponent:0 animated:NO];
    [_semesterPickerView setDelegate:self];
    [_semesterPickerView setDataSource: self];
    _webPage = [[UIWebView alloc] init];
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    //_tap = [[UITapGestureRecognizer alloc] initwi]
    _tap.enabled = YES;
    [self.view addGestureRecognizer:_tap];
    [_semesterField setInputView:_semesterPickerView];

    //self.originalCenter = self.view.center;
    [self loadDesignElements];
    
}

-(void)viewDidLayoutSubviews{
    [self setDesignLayout];
}


-(void)viewDidAppear:(BOOL)animated{
    NSLog(@"App Appeared");
    [_semesterField setEnabled:YES];
    [_usernameField setEnabled:YES];
    [_passwordField setEnabled:YES];
    [_loginButton setEnabled:YES];
    
    if([reachability isReachable]){
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:semesterURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if(data != nil){
                NSError *error;
                semesterDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                NSString *semesterText = [[[[[semesterDict objectForKey:@"results"] objectForKey:@"Data"] firstObject] objectForKey:@"property1"] objectForKey:@"text"];
                semesterText = [semesterText substringFromIndex:[semesterText rangeOfString:@"Continue"].location + 11];
                semesters = [semesterText componentsSeparatedByString:@"\n"];
                [_semesterPickerView selectRow:[semesters count]/2 inComponent:0 animated:YES];
                [_semesterPickerView selectRow:0 inComponent:0 animated:YES];
                [_semesterPickerView reloadAllComponents];
                [_semesterField setText:@""];
                NSLog(@"Semesters Loaded");
            }
            [_semesterField setText:[semesters firstObject]];
        }];
        // NSData *data = [NSData dataWithContentsOfURL:semesterURL];
    }else{
        [_semesterField setText:[semesters firstObject]];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"save_login"] && [[NSUserDefaults standardUserDefaults] stringForKey:@"username"] != nil){
        NSLog(@"Found Credentials");
        [_usernameField setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"username"]];
        [_passwordField setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"password"]];
    }else{
        [_usernameField setText:@""];
        [_passwordField setText:@""];
    }

    scheduleURL = @"https://www.sis.umd.edu%2Ftestudo%2FstudentSched%3Fterm%3D201401&h=xAQGVU3yP";
    scheduleURL = @"https://www.sis.umd.edu/testudo/studentSched?term=";
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"] != nil){
        //NSLog(@"Schedule: %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"]);
        [self performSegueWithIdentifier:@"Relog" sender:self];
    }
}

-(void)setDesignLayout{
    _circleMask.layer.cornerRadius = _circleMask.frame.size.width/2;
    [_circleMask addSubview:_profilePictureView];
    _loginContainerView.layer.cornerRadius = _loginContainerView.frame.size.width/2;
    _loginContainer.layer.cornerRadius = 4.0f;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    if (screenHeight == 480) {
        _topSpacerHeight.constant = 15;
        _nameHeight.constant = 24;
    }else if(screenHeight == 568){
        _topSpacerHeight.constant = 55;
    }else if(screenHeight == 667){
        _topSpacerHeight.constant = 64;
        _welcomeHeight.constant = 90;
    }else{
        //iP6+
        _topSpacerHeight.constant = 80;
        _welcomeHeight.constant = 90;
    }

}

-(void)loadDesignElements{
    [_loginButton setTitleColor:[self.view backgroundColor] forState:UIControlStateNormal];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    NSLog(@"Movement: %d",screenHeight == 667);
    if(UI_USER_INTERFACE_IDIOM() ==UIUserInterfaceIdiomPhone){
        if(screenHeight >= 736){
            [_welcomeLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:32]];
            [_statusLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:24]];
        }else if(screenHeight >= 667){
            [_welcomeLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:30]];
            [_statusLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:24]];
        }else if(screenHeight >= 568){
            
        }else{
            [_statusLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:48]];
        }

    }else{
        //ipad
        
    }
        if(screenHeight == 568){
        //iP5
    }else if(screenHeight == 667){
        //iP6
    }else if(screenHeight < 568){
        //iP4
    }else{
        //iP6+
        
    }

    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        CGRect frame = _usernameField.frame;
        frame.size.height = 100;
        [_usernameField setFrame: frame];
        [_passwordField setFrame: frame];
    }
    if([[FBSession activeSession] accessTokenData] != nil){
        NSLog(@"Facebook Token Found");
        FBAccessTokenData *token = [[FBSession activeSession] accessTokenData];
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@",token]]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if([(NSHTTPURLResponse *)response statusCode] != 200){
                [[FBSession activeSession] closeAndClearTokenInformation];
            }
            NSLog(@"Facebook Response: %@",[response description]);
        }];
        if([[NSDate date] compare:[token expirationDate]] == NSOrderedDescending){
            // Token is expired
            [[FBSession activeSession] closeAndClearTokenInformation];
        }else{
            NSLog(@"Token valid");
        }
    }
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    count ++;
    [_webPage stringByEvaluatingJavaScriptFromString:loginScript];
    htmlString = [_webPage stringByEvaluatingJavaScriptFromString:htmlScript];
    if(count != 0){
        if([htmlString rangeOfString:@"Invalid Login"].location != NSNotFound){
            NSLog(@"Login Failed");
            count = 0;
            htmlString = @"";
            webView.delegate = nil;
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"University ID and/or Password incorrect" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
            [_alertMsg show];
            [_activityIndicator stopAnimating];
            [_loginButton setEnabled:YES];
            [_usernameField setEnabled:YES];
            [_passwordField setEnabled:YES];
        }else if ([htmlString rangeOfString:@"An Error occurred while running this application"].location != NSNotFound){
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Server Error" message:@"There seems to be a problem loading schedules. UMD sometimes shuts down the schedule viewing services on sundays to do maintence. Please contact the Office of the Registrar if problem persists." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [_alertMsg show];
            [_activityIndicator stopAnimating];
            [_loginButton setEnabled:YES];
            [_usernameField setEnabled:YES];
            [_passwordField setEnabled:YES];
            [_semesterField setEnabled:YES];
        }else if([htmlString rangeOfString:@"You are not currently registered"].location != NSNotFound){
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Schedule Error" message:@"You have not registered for any classes in the selected semester" delegate:nil cancelButtonTitle:@"Got it" otherButtonTitles: nil];
            [_alertMsg show];
            [_activityIndicator stopAnimating];
            [_loginButton setEnabled:YES];
            [_usernameField setEnabled:YES];
            [_passwordField setEnabled:YES];
            [_semesterField setEnabled:YES];
        }else{
            NSLog(@"Login Success");
            courseString = [NSString stringWithString:htmlString];
            // Prepare the html page
            courseDetails = [NSString stringWithString:[_webPage stringByEvaluatingJavaScriptFromString:courseScript]];
            htmlString = [_webPage stringByEvaluatingJavaScriptFromString:htmlScript];
            NSLog(@"HTML Retrieved");
            htmlString = [htmlString substringFromIndex:[htmlString rangeOfString:@"--><center>"].location];
            htmlString = [htmlString substringFromIndex:3];
            NSLog(@"Trimmed first half");
            htmlString = [htmlString substringToIndex:[htmlString rangeOfString:@"</center>"].location];
            NSMutableString *header = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];
            [header appendString:@"<head><style type='text/css'>html, body {	height: 100%;	padding: 0;	margin: 0;} "];
            [header appendString:@"#table {display: table; 	height: 100%;	width: 100%;} "];
            [header appendString:@"#cell {	display: table-cell; 	vertical-align: middle;}</style></head>"];
            NSString *body = @"<div id='table'><div id='cell'>";
            NSString *footer = @"</div></div></body></html>";
            htmlString = [NSString stringWithFormat:@"%@ %@ %@ %@",header,body,htmlString,footer];
            
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<img src=\"/graphics/common/pixels/trans.gif\" height=\"30\" width=\"50\">" withString:@""];
            //htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<img[^>]*>" withString:@"" options:NSCaseInsensitiveSearch | NSRegularExpressionSearch range:NSMakeRange(0, [htmlString length])];

            // Extract courses
            NSString *searchString = @"<input type=\"hidden\" name=\"schedstr\" value=\"";
            searchString = @"href=\"javascript:bookstorelist(\'";
            courseString = [courseString substringFromIndex:[courseString rangeOfString:searchString].location + [searchString length]];
            courseString = [courseString substringToIndex:[courseString rangeOfString:@"\'"].location];
            
            // Parse course details
            //String brodder = "jonathan";
            [_activityIndicator stopAnimating];
            _webPage.delegate = nil;
            [self performSegueWithIdentifier:@"Login" sender:self];
        }
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    _alertMsg = [[UIAlertView alloc] initWithTitle:@"Server Error" message:@"Failed to load mobilemy.umd.edu" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [_alertMsg show];
    [_activityIndicator stopAnimating];
    [_usernameField setEnabled:YES];
    [_passwordField setEnabled:YES];
    [_semesterField setEnabled:YES];
    [_loginButton setEnabled: YES];
    NSLog(@"%@",[error localizedDescription]);
}

// Picker functinos
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    //if (component == 0){
    return [semesters count];
    // }
    /*else{
        return [years count];
    }*/
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    //if (component == 0)
        return [semesters objectAtIndex:row];
    //else{
    //    return [years objectAtIndex:row];
    //}
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    _tap.enabled = YES;
    
    if (component == 0) {
        semesterIndex = row;
    } else {
        yearIndex = row;
    }
    NSString *semesterString = [semesters objectAtIndex:semesterIndex];
    [_semesterField setText:semesterString];
    
    [self saveTermCode:semesterString];
}

-(void)saveTermCode:(NSString *) semesterString{
    NSString *yearString = [semesterString substringFromIndex:[semesterString rangeOfString:@"2"].location];
    semesterString = [semesterString substringToIndex:[semesterString rangeOfString:@" 2"].location];
    
    NSString *season = [NSString stringWithString: semesterString];
    NSInteger year = [yearString integerValue];
    if([season isEqualToString:@"Winter"]){
        year--;
        season = @"12";
    }else if([season isEqualToString:@"Spring"]){
        season = @"01";
    }else if([season isEqualToString:@"Summer I"]){
        season = @"05";
    }else if([season isEqualToString:@"Summer II"]){
        season = @"07";
    }else if([season isEqualToString:@"Fall"]){
        season = @"08";
    }else{
        season = @"01";
        year = 2014;
        //default case
    }
    semesterInfo = [[NSArray alloc] initWithObjects:season, [NSString stringWithFormat:@"%ld",(long)year], nil];
    NSString *termCode = [NSString stringWithFormat:@"%ld%@",(long)year,season];
    [[NSUserDefaults standardUserDefaults] setObject:termCode forKey:@"SemesterInfo"];
}

// Facebook login related functions
-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user{
    NSLog(@"Facebook fetched user info");
    NSLog(@"User ID: %@", [user objectID]);
    //[[ScheduleManager sharedInstance] setFacebookUserID:[user objectID]];
    [[ScheduleManager sharedInstance] setupManagerWithFacebookUserID:[user objectID] completion:nil];
    _profilePictureView.profileID = [user objectID];
    [_profilePictureView setHidden: NO];
    [_statusLabel setText:[NSString stringWithFormat:@"%@",[user name]]];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    NSLog(@"Facebook showing logged in");
}

-(void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView{
    NSLog(@"Facebook showing logged out");
    [_profilePictureView setHidden:YES];
    _profilePictureView.profileID = nil;
    [_statusLabel setText:@""];
}

// UIAlertView
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        NSString *username = _usernameField.text;
        NSString *password = _passwordField.text;
        NSString *newScheduleURL = @"";
        username = [self cleanUpSpecialCharactersOfString:username];
        password = [self cleanUpSpecialCharactersOfString:password];
        loginScript = [NSString stringWithFormat:@"document.lform.in_tx_username.value='%@';document.lform.in_pw_userpass.value='%@'; doLogin();",username,password];
        loginScript = [NSString stringWithFormat:@"document.getElementsByName('ldapid')[0].value='%@'; document.getElementsByName('ldappass')[0].value='%@'; document.getElementsByName('login')[0].click();",username,password];
        NSLog(@"\nUsername:%@ Password:%@",_usernameField.text,_passwordField.text);
        [self performSelector:@selector(hideKeyboard)];
        
        NSString *termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
        NSLog(@"TermCode: %@",termCode);
        newScheduleURL = [NSString stringWithFormat:@"%@%@",scheduleURL,termCode];
        
        _webPage.delegate = self;
        [_usernameField setEnabled:NO];
        [_passwordField setEnabled:NO];
        [_semesterField setEnabled:NO];
        [_activityIndicator startAnimating];
        [_webPage loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:newScheduleURL]]];
    }else{
        [_fbLoginView.subviews[0] sendActionsForControlEvents:UIControlEventTouchUpInside];
        [self performSelector:@selector(hideKeyboard)];
    }
}

// Keyboard Related Methods
-(void)animateTextField:(UITextField *)textfield up:(BOOL)up{
    int movementDistance = 40;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;

    NSLog(@"Movement: %d",screenHeight == 667);
    if(screenHeight == 568){
        //iP5
        movementDistance = 110;
    }else if(screenHeight == 667){
        //iP6
        movementDistance = 140;
    }else if(screenHeight < 568){
        //iP4
        movementDistance = 160;
    }else{
        //iP6+
        movementDistance = 140;
    }
    
    const float movementDuration = 0.3f; // tweak as needed
    
    
    int movement = (up ? -movementDistance : movementDistance);
    _superViewCenterConstraint.constant = _superViewCenterConstraint.constant - movement;
    [self.view setNeedsLayout];
    [UIView animateWithDuration:movementDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    _tap.enabled = YES;
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField:textField up:YES];
}

-(void)hideKeyboard{
    [_usernameField resignFirstResponder];
    [_semesterField resignFirstResponder];
    [_passwordField resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField isEqual:_usernameField]){
        [_passwordField becomeFirstResponder];
    }else {
        [self performSelector:@selector(login:) withObject:self];
    }
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"] != nil &&
       ([_usernameField.text length] != 0 || [_passwordField.text length] != 0)){
    }
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"] != nil &&
       ([_usernameField.text length] == 0 && [_passwordField.text length] == 0)){
        // Enabling Back button
    }
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    [_usernameField resignFirstResponder];
    [_passwordField resignFirstResponder];
    [_semesterField resignFirstResponder];
    [self animateTextField:textField up:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    SocialSchedulerFirstViewController *vc = (SocialSchedulerFirstViewController *)[((UITabBarController *)[segue destinationViewController]).viewControllers objectAtIndex:0];
    vc.loginData = @"Potato";
    if([[segue identifier] isEqualToString:@"Login"]){
        
        NSString *webPageCode = htmlString;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Schedule"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Courses"];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"refreshSchedule"];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"refreshClasses"];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"refreshFriends"];
        [[NSUserDefaults standardUserDefaults] setObject:webPageCode forKey:@"Schedule"];
        [[NSUserDefaults standardUserDefaults] setObject:courseString forKey:@"Courses"];
        [[NSUserDefaults standardUserDefaults] setObject:courseDetails forKey:@"CourseDetails"];
    }else if ([[segue identifier] isEqualToString:@"Cancel"]){
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"refreshSchedule"];
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"refreshClasses"];
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"refreshFriends"];
    }
}

-(NSString *)cleanUpSpecialCharactersOfString:(NSString *)stringToClean{
    stringToClean = [stringToClean stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    stringToClean = [stringToClean stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    return stringToClean;
}

-(IBAction)login:(UIButton *)sender {
    if([[_usernameField text]isEqualToString:@""] || [[_passwordField text] isEqualToString:@""]){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Please complete enter both University ID (Not a number) and Password" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else if([[_semesterField text]isEqualToString:@""]){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Please select a semester to view" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else{
        if(![reachability isReachable]){
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
            [_alertMsg show];
        }else{
            if([[FBSession activeSession] accessTokenData] == nil){
                _alertMsg = [[UIAlertView alloc] initWithTitle:@"Warning" message:
                             @"You are not connected with Facebook. You will not be able to: \n -Share your schedule to Facebook \n -View friends in your classes \n -View your friends' schedules" delegate:self cancelButtonTitle:@"I'll connect" otherButtonTitles:@"Not right now", nil];
                [_alertMsg show];
            }else{
                NSString *username = _usernameField.text;
                NSString *password = _passwordField.text;
                NSString *newScheduleURL = @"";
                username = [self cleanUpSpecialCharactersOfString:username];
                password = [self cleanUpSpecialCharactersOfString:password];
                loginScript = [NSString stringWithFormat:@"document.lform.in_tx_username.value='%@';document.lform.in_pw_userpass.value='%@'; doLogin();",username,password];
                loginScript = [NSString stringWithFormat:@"document.getElementsByName('ldapid')[0].value='%@'; document.getElementsByName('ldappass')[0].value='%@'; document.getElementsByName('login')[0].click();",username,password];
                //NSLog(@"\nUsername:%@ Password:%@",_usernameField.text,_passwordField.text);
                [self performSelector:@selector(hideKeyboard)];
                
                [self saveTermCode:_semesterField.text];
                NSString *termCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SemesterInfo"];
                NSLog(@"TermCode: %@",termCode);
                newScheduleURL = [NSString stringWithFormat:@"%@%@",scheduleURL,termCode];
                
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"save_login"]){
                    [[NSUserDefaults standardUserDefaults] setObject:[_usernameField text] forKey:@"username"];
                    [[NSUserDefaults standardUserDefaults] setObject:[_passwordField text] forKey:@"password"];
                }
                
                _webPage.delegate = self;
                [_loginButton setEnabled: NO];
                [_usernameField setEnabled:NO];
                [_passwordField setEnabled:NO];
                [_semesterField setEnabled:NO];
                [_activityIndicator startAnimating];
                NSLog(@"URL: %@",newScheduleURL);
                [_webPage loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:newScheduleURL]]];
            }
        }
    }
}

- (void)openSession
{
    if(FBSession.activeSession.state != FBSessionStateOpen)
    {
        [FBSession openActiveSessionWithPublishPermissions:@[@"stuff"]
                                           defaultAudience:FBSessionDefaultAudienceFriends
                                              allowLoginUI:NO
                                         completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                             if(!error && session.isOpen)
                                             {
                                             }
                                             else
                                             {
                                                 // handle the error
                                             }
                                             // here, you can handle the session state changes in switch case or
                                             //something else
                                             
                                             
                                         }];
    }
}

@end
