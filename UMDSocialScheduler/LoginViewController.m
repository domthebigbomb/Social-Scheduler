 //
//  LoginViewController.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/6/14.
//  Copyright (c) 2014 DTech. All rights reserved.
//

#import "LoginViewController.h"
#import "SocialSchedulerFirstViewController.h"
#import "Reachability.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *profilePictureView;
@property (weak, nonatomic) IBOutlet UIImageView *circleMask;
@property (weak, nonatomic) IBOutlet UIImageView *borderMask;
@property (weak, nonatomic) IBOutlet UIImageView *loginContainer;
@property (weak, nonatomic) IBOutlet UIView *visualView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)login:(UIButton *)sender;
- (IBAction)cancel:(UIButton *)sender;
@property (strong, nonatomic) UIWebView *webPage;
@property (strong, nonatomic)UITapGestureRecognizer *tap;
@property (strong, nonatomic) UIAlertView *alertMsg;
@property (strong, nonatomic) UIActionSheet *actionMsg;
@property CGPoint originalCenter;
@property (weak, nonatomic) IBOutlet UIView *loginFieldsView;
@property (strong, nonatomic) IBOutlet UIPickerView *semesterPickerView;
@property (weak, nonatomic) IBOutlet UITextField *semesterField;
@property (weak, nonatomic) IBOutlet FBLoginView *fbLoginView;

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
    _semesterPickerView = [[UIPickerView alloc] init];
    
    NSURL *semesterURL = [NSURL URLWithString:@"http://www.kimonolabs.com/api/d9c7z5py?apikey=e228433aba70a1ea083189f321776248"];
    
    Reachability *internetReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus network = [internetReachability currentReachabilityStatus];
    
    semesters = [[NSMutableArray alloc] init];
    if(network == NotReachable){
        semesters = @[@"Fall 2013",@"Winter 2014",@"Spring 2014",@"Summer I 2014",@"Summer II 2014",@"Fall 2014"];
    }else{
        NSData *data = [NSData dataWithContentsOfURL:semesterURL];
        NSError *error;
        semesterDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSString *semesterText = [[[[[semesterDict objectForKey:@"results"] objectForKey:@"Data"] firstObject] objectForKey:@"property1"] objectForKey:@"text"];
        semesterText = [semesterText substringFromIndex:[semesterText rangeOfString:@"Continue"].location + 11];
        semesters = [semesterText componentsSeparatedByString:@"\n"];
    }
    [_fbLoginView setReadPermissions:@[@"basic_info",@"email",@"user_likes"]];
    [_fbLoginView setDefaultAudience:FBSessionDefaultAudienceFriends];
    [_fbLoginView setPublishPermissions:@[@"publish_actions" ]];
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
    [_semesterPickerView setDelegate:self];
    [_semesterPickerView setDataSource: self];
    [_semesterPickerView selectRow:[semesters count]/2 inComponent:0 animated:YES];
    _webPage = [[UIWebView alloc] init];
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    _tap.enabled = YES;
    [self.view addGestureRecognizer:_tap];
    [_semesterField setInputView:_semesterPickerView];

    self.originalCenter = self.view.center;
    [self loadDesignElements];
}

-(void)viewDidAppear:(BOOL)animated{
    //scheduleURL = @"https://mobilemy.umd.edu/portal/server.pt;MYUMSESSION=31CqSykpJ1DWxzwpvwRFK6J2XT4ccpltBcNSX9cybklfbKmfjxvS!1501198949?cached=false&redirect=https%3A%2F%2Fmobilemy.umd.edu%2Fportal%2Fserver.pt%2Fgateway%2FPTARGS_0_340574_368_211_0_43%2Fhttps%3B%2Fwww.sis.umd.edu%2Ftestudo%2FstudentSched%3Fterm%3D201401&space=Login";
    scheduleURL = @"https://www.sis.umd.edu%2Ftestudo%2FstudentSched%3Fterm%3D201401&h=xAQGVU3yP";
    scheduleURL = @"https://www.sis.umd.edu/testudo/studentSched?term=";
}

-(void)loadDesignElements{
    // NSString* fontName = @"Avenir-Book";
    //NSString* boldFontName = @"Avenir-Black";
    //_loginButton.layer.cornerRadius = 3.0f;
    //_loginButton.titleLabel.font = [UIFont fontWithName:boldFontName size:20.0f];
    [_loginButton setTitleColor:[self.view backgroundColor] forState:UIControlStateNormal];
    [_backButton setTitleColor:[self.view backgroundColor] forState:UIControlStateNormal];
    
    
    _circleMask.layer.cornerRadius = _circleMask.frame.size.width/2;
    [_circleMask addSubview:_profilePictureView];
    _borderMask.layer.cornerRadius = _borderMask.frame.size.width/2;
    [_borderMask addSubview:_circleMask];
    _loginContainer.layer.cornerRadius = 4.0f;
    
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"] != nil){
        [_backButton setHidden:NO];
        [_backButton setEnabled:YES];
        [_loginButton setHidden:YES];
        [_loginButton setEnabled:NO];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"save_login"] && [[NSUserDefaults standardUserDefaults] stringForKey:@"username"] != nil){
        NSLog(@"Found Credentials");
        [_usernameField setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"username"]];
        [_passwordField setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"password"]];
    }

    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        CGRect frame = _usernameField.frame;
        frame.size.height = 100;
        [_usernameField setFrame: frame];
        [_passwordField setFrame: frame];
    }
    
    //_visualView.center = CGPointMake(self.originalCenter.x, self.originalCenter.y - 120);
    //_visualView.center = self.originalCenter;
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
            [_usernameField setEnabled:YES];
            [_passwordField setEnabled:YES];
        }else if ([htmlString rangeOfString:@"An Error occurred while running this application"].location != NSNotFound){
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Server Error" message:@"There seems to be a problem loading schedules. Please contact the Office of the Registrar if problem persists" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [_alertMsg show];
            [_activityIndicator stopAnimating];
            [_usernameField setEnabled:YES];
            [_passwordField setEnabled:YES];
            [_semesterField setEnabled:YES];
        }else if([htmlString rangeOfString:@"You are not currently registered"].location != NSNotFound){
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Schedule Error" message:@"You have not registered for any classes in the selected semester" delegate:nil cancelButtonTitle:@"Got it" otherButtonTitles: nil];
            [_alertMsg show];
            [_activityIndicator stopAnimating];
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
            
            // Extract courses
            NSString *searchString = @"<input type=\"hidden\" name=\"schedstr\" value=\"";
            searchString = @"href=\"javascript:bookstorelist(\'";
            courseString = [courseString substringFromIndex:[courseString rangeOfString:searchString].location + [searchString length]];
            courseString = [courseString substringToIndex:[courseString rangeOfString:@"\'"].location];
            
            // Parse course details
            //String brodder = "jonathan";
            [_activityIndicator stopAnimating];
            _webPage.delegate = nil;
            //NSLog(@"\n%@",courseString);
            [self performSegueWithIdentifier:@"ShowSchedule" sender:self];
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
    if (component == 0)
        return [semesters objectAtIndex:row];
    else{
        return [years objectAtIndex:row];
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    _tap.enabled = YES;
    
    if (component == 0) {
        semesterIndex = row;
    } else {
        yearIndex = row;
    }
    NSString *semesterString = [semesters objectAtIndex:semesterIndex];
    NSString *yearString = [semesterString substringFromIndex:[semesterString rangeOfString:@"2"].location];
    semesterString = [semesterString substringToIndex:[semesterString rangeOfString:@" 2"].location];
    
    NSString *termString = [NSString stringWithFormat:@"%@ %@",semesterString,yearString];
    [_semesterField setText:termString];
    
    NSString *season = [NSString stringWithString: semesterString ];
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
    _profilePictureView.profileID = [user id];
    [_profilePictureView setHidden: NO];
    [_statusLabel setText:[NSString stringWithFormat:@"%@",[user name]]];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    NSLog(@"Logged in");
}

-(void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView{
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
    }
}

// Keyboard Related Methods
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    _tap.enabled = YES;
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    _visualView.center = CGPointMake(_originalCenter.x, _originalCenter.y - 120);
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField isEqual:_usernameField]){
        [_passwordField becomeFirstResponder];
    }else{
        [self performSelector:@selector(login:) withObject:self];
    }
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"] != nil &&
       ([_usernameField.text length] != 0 || [_passwordField.text length] != 0)){
        // Enabling Login button
        [_loginButton setHidden:NO];
        [_loginButton setEnabled:YES];
        [_backButton setEnabled:NO];
        [_backButton setHidden:YES];
    }
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"Schedule"] != nil &&
       ([_usernameField.text length] == 0 && [_passwordField.text length] == 0)){
        // Enabling Back button
        [_loginButton setHidden:YES];
        [_loginButton setEnabled:NO];
        [_backButton setEnabled:YES];
        [_backButton setHidden:NO];
    }
    return YES;
}

-(void)hideKeyboard
{
    _visualView.center = _originalCenter;
    [_usernameField resignFirstResponder];
    [_passwordField resignFirstResponder];
    [_semesterField resignFirstResponder];
    //_tap.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier] isEqualToString:@"ShowSchedule"]){
        NSString *webPageCode = htmlString;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Schedule"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Courses"];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"refreshSchedule"];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"refreshClasses"];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"refreshFriends"];
        [[NSUserDefaults standardUserDefaults] setObject:webPageCode forKey:@"Schedule"];
        [[NSUserDefaults standardUserDefaults] setObject:courseString forKey:@"Courses"];
        [[NSUserDefaults standardUserDefaults] setObject:courseDetails forKey:@"CourseDetails"];
    }else if ([[segue identifier] isEqualToString:@"CancelLogin"]){
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
    Reachability *internetReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus network = [internetReachability currentReachabilityStatus];
    if([[_usernameField text]isEqualToString:@""] || [[_passwordField text] isEqualToString:@""]){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Please complete enter both University ID (Not a number) and Password" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else if([[_semesterField text]isEqualToString:@""]){
        _alertMsg = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Please select a semester to view" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [_alertMsg show];
    }else{
        if(network == NotReachable){
            _alertMsg = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"You are not connected to the internet! Please check your settings" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
            [_alertMsg show];
        }else{
            if([[FBSession activeSession] accessTokenData] == nil){
                /*
                _actionMsg = [[UIActionSheet alloc] initWithTitle:@"Warning" delegate:self cancelButtonTitle:@"I'll login to Facebook" destructiveButtonTitle:@"destruct" otherButtonTitles: nil];
                [_actionMsg showInView:self.view];
                */
                _alertMsg = [[UIAlertView alloc] initWithTitle:@"Warning" message:
                             @"You are not logged into Facebook. You will not be able to: \n -View friends in your classes \n -View your friends' schedules \nwithout being logged in!" delegate:self cancelButtonTitle:@"I'll login" otherButtonTitles:@"Not right not", nil];
                [_alertMsg show];
            }else{
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
                
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"save_login"]){
                    [[NSUserDefaults standardUserDefaults] setObject:[_usernameField text] forKey:@"username"];
                    [[NSUserDefaults standardUserDefaults] setObject:[_passwordField text] forKey:@"password"];
                }
                
                _webPage.delegate = self;
                [_usernameField setEnabled:NO];
                [_passwordField setEnabled:NO];
                [_semesterField setEnabled:NO];
                [_activityIndicator startAnimating];
                [_webPage loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:newScheduleURL]]];
            }
        }
    }
}

- (IBAction)cancel:(UIButton *)sender {
    [self performSegueWithIdentifier:@"CancelLogin" sender:self];
}
@end
