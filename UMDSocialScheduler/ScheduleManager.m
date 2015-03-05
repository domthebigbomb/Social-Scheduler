//
//  ScheduleManager.m
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/21/15.
//  Copyright (c) 2015 DTech. All rights reserved.
//

#import "ScheduleManager.h"
#import <FacebookSDK/FacebookSDK.h>

@interface ScheduleManager()
@property NSString *userID;
@property NSMutableArray *userFriends;
@property (nonatomic, strong) PFObject *currentUser;
@end

@implementation ScheduleManager
-(id)init{
    self = [super init];
    if(self){
        _userFriends = [[NSMutableArray alloc] init];
    }
    return self;
}

+(ScheduleManager *)sharedInstance{
    static ScheduleManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[ScheduleManager alloc] init];
    });
    return _sharedInstance;
}

-(void)setupManagerWithFacebookUserID:(NSString *)userID completion:(void (^)(NSError *, NSArray *))completionBlock{
    _userID = userID;
    // Note to self: Facebook ids we get back are UNIQUE to this app. We will not need actual facebook id (the one that links to their page)
    [self startFetchingFriendsWithCompletion:^(NSError *error, NSArray *friendList) {
        if(!error){
            NSLog(@"Fetched %ld facebook friends", [friendList count]);
            _userFriends = [friendList mutableCopy];
        }else{
            NSLog(@"Error setting up manager: %@", [error localizedDescription]);
        }
        if(completionBlock){
            completionBlock(error, _userFriends);
        }

    }];
}

-(void)fetchUserID{
    if ([[FBSession activeSession] accessTokenData]) {
        [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *aUser, NSError *error) {
            _userID = [aUser objectForKey:@"id"];
            NSLog(@"User id %@",_userID);
        }];
    }
}

-(void)setFacebookUserID:(NSString *)userID{
    _userID = userID;
}

#pragma mark - Returns YES if logged into facebook;
-(BOOL)trySaveScheduleForTerm:(NSString *)term Courses:(NSArray *)courses HTML:(NSString *)htmlString ImageData:(NSData *)imageData{
    if([[FBSession activeSession] accessTokenData]){
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *aUser, NSError *error) {
             if (!error) {
                 NSLog(@"User id %@",[aUser objectForKey:@"id"]);
                 _userID = [aUser objectForKey:@"id"];
                 PFQuery *userQuery = [PFQuery queryWithClassName:@"Student"];
                 [userQuery whereKey:@"facebookID" equalTo:[aUser objectForKey:@"id"]];
                 [userQuery findObjectsInBackgroundWithBlock:^(NSArray *userObjects, NSError *error) {
                     if(!error){
                         PFObject *student;
                         if([userObjects count] > 0){
                             NSLog(@"User found");
                             student = [userObjects firstObject];
                         }else{
                             NSLog(@"User doesn't exist, adding to parse!");
                             student = [[PFObject alloc] initWithClassName:@"Student"];
                             student[@"facebookID"] = [aUser objectForKey:@"id"];
                             student[@"schedules"] = [[NSMutableArray alloc] init];
                             student[@"sharing"] = @YES;
                         }
                         
                         PFFile *imageFile = [PFFile fileWithName:@"schedule.jpg" data:imageData];
                         [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                             if (!error) {
                                 if (succeeded) {
                                     PFQuery *scheduleQuery = [PFQuery queryWithClassName:@"Schedule"];
                                     [scheduleQuery whereKey:@"facebookID" equalTo:[aUser objectForKey:@"id"]];
                                     [scheduleQuery whereKey:@"term" equalTo:term];
                                     [scheduleQuery findObjectsInBackgroundWithBlock:^(NSArray *schedules, NSError *error) {
                                         if(!error){
                                             PFObject *schedule;
                                             if([schedules count] > 0){
                                                 NSLog(@"Updating schedule...");
                                                 schedule = [schedules firstObject];
                                             }else{
                                                 NSLog(@"Creating new schedule entry");
                                                 schedule = [[PFObject alloc] initWithClassName:@"Schedule"];
                                                 schedule[@"term"] = term;
                                                 schedule[@"facebookID"] = [aUser objectForKey:@"id"];
                                             }
                                             schedule[@"html"] = htmlString;
                                             schedule[@"image"] = imageFile;
                                             schedule[@"courses"] = courses;
                                             schedule[@"courseString"] = [courses componentsJoinedByString:@","];
                                             [schedule saveInBackground];
                                             
                                             NSMutableArray *schedules = [student[@"schedules"] mutableCopy];
                                             [schedules addObject:schedule];
                                             student[@"schedules"] = schedules;
                                             [student saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                 if(succeeded){
                                                     if(!error){
                                                         _currentUser = student;
                                                     }else{
                                                         NSLog(@"Error saving student: %@", [error localizedDescription]);
                                                     }
                                                 }
                                             }];

                                         }else{
                                             NSLog(@"Error finding schedules");
                                         }
                                     }];
                                }
                             } else {
                                 NSLog(@"Error");
                             }
                         }];
                         
                     }else{
                         NSLog(@"Error querying students %@", error.localizedDescription);
                     }
                 }];
             }else{
                 NSLog(@"Error querying user's facebook id %@", error.localizedDescription);
             }
         }];
        return YES;
    }else{
        NSLog(@"Not connected with facebook!");
        return NO;
    }
}

-(UIImage *)imageForTerm:(NSString *)term forFacebookID:(NSString *)facebookID{
    PFQuery *scheduleQuery = [[PFQuery alloc] initWithClassName:@"Schedule"];
    [scheduleQuery whereKey:term equalTo:@"term"];
    [scheduleQuery whereKey:facebookID equalTo:@"facebookID"];
    NSError *error;
    NSArray *schedules = [scheduleQuery findObjects:&error];
    if(!error){
        PFObject *schedule = [schedules firstObject];
        PFFile *imgFile = schedule[@"image"];
        NSData *imgData = [imgFile getData:&error];
        if (!error) {
            UIImage *scheduleImage = [UIImage imageWithData:imgData];
            return scheduleImage;
        }
    }else{
        NSLog(@"Error querying image");
    }
    return nil;
}

-(BOOL)friendlist:(NSArray *)friendList containsFacebookID:(NSString *)facebookID{
    for(NSDictionary<FBGraphUser>* user in friendList){
        if([[user objectForKey:@"id"] isEqualToString:facebookID] && ![facebookID isEqualToString:_userID]){
            return YES;
        }
    }
    return NO;
}

-(NSArray *)facebookIDsFromFriendlist:(NSArray *)fbFriendList{
    NSMutableArray *facebookIDs = [[NSMutableArray alloc] initWithCapacity:[fbFriendList count]];
    NSString *fbIdKey = @"id";
    for(NSDictionary *friend in fbFriendList){
        if([friend objectForKey: fbIdKey]){
            [facebookIDs addObject:[friend objectForKey: fbIdKey]];
        }
    }
    return facebookIDs;
}

-(void)startFetchingFriendsWithCompletion:(void (^)(NSError *, NSArray *))completionBlock{
    [_userFriends removeAllObjects];
    [self queryFriendListWithPath:@"/me/friends" completion:^(NSError* error) {
        completionBlock(error, _userFriends);
    }];
}

-(void)queryFriendListWithPath:(NSString *)path completion:(void(^)(NSError* error))completionBlock{
    [FBRequestConnection startWithGraphPath:path
                                 parameters:nil
                                 HTTPMethod:@"GET" completionHandler:
     ^(FBRequestConnection *connection, NSDictionary *result, NSError *error) {
         //NSLog(@"Friends: %@", [result description]);
         [_userFriends addObjectsFromArray:[result objectForKey:@"data"]];
         NSDictionary *paging = [result objectForKey:@"paging"];
         if([paging objectForKey:@"next"]){
             NSString *nextPath = [paging objectForKey:@"next"];
             NSString *afterParam = @"friends?";
             nextPath = [nextPath substringFromIndex:[nextPath rangeOfString:afterParam].location];
             nextPath = [NSString stringWithFormat:@"%@%@",@"/me/",nextPath];
             //NSLog(@"Querying next page...: %@", nextPath);
             [self queryFriendListWithPath:nextPath completion:completionBlock];
         }else{
             NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
             [_userFriends sortUsingDescriptors:@[descriptor]];
             completionBlock(error);
         }
     }];
}

-(void)friendsInCourse:(NSString *)course term:(NSString *)term completion:(void (^)(NSError* error, NSArray * friends))completionBlock{
    if([[FBSession activeSession] accessTokenData]){
        PFQuery *friendQuery = [[PFQuery alloc] initWithClassName:@"Schedule"];
        [friendQuery whereKey:@"term" equalTo:term];
        [friendQuery whereKey:@"courseString" containsString:course];
        NSError *parseError;
        [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *schedules, NSError *error) {
            if(!error){
                NSMutableArray *friendsInCourse = [[NSMutableArray alloc] init];
                for(PFObject *schedule in schedules){
                    if([self friendlist:_userFriends containsFacebookID:schedule[@"facebookID"]]){
                        [friendsInCourse addObject:schedule];
                    }
                }
                completionBlock(nil, friendsInCourse);
            }else{
                completionBlock(parseError, nil);
            }
        }];
    }
}

-(void)umdFriendListForTerm:(NSString *)term completion:(void (^)(NSError *, NSArray *))completionBlock{
    PFQuery *query = [PFQuery queryWithClassName:@"Schedule"];
    [query whereKey:@"term" equalTo:term];
    NSArray *fbFriendIDs = [self facebookIDsFromFriendlist:_userFriends];
    [query whereKey:@"facebookID" containedIn:fbFriendIDs];
    [query findObjectsInBackgroundWithBlock:^(NSArray *matchingSchedule, NSError *error) {
        completionBlock(error, matchingSchedule);
    }];
    // FInish the query
}

-(PFObject *)currentUser{
    return _currentUser;
}

@end
