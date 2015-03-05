//
//  ScheduleManager.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/21/15.
//  Copyright (c) 2015 DTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ScheduleManager : NSObject

+(ScheduleManager *)sharedInstance;

/**
 Sets up the schedule manager by setting the user id and retrieving the friend list
 */
-(void)setupManagerWithFacebookUserID:(NSString *)userID completion:(void (^)(NSError *error, NSArray* friendList))completionBlock;

/**
 Sets the manager's default user id
 */
-(void)setFacebookUserID:(NSString *)userID;

/**
 Queries facebook /me to retrieve the user id after v2 changes
 */
-(void)fetchUserID;

/**
 Starts querying user's facebook friend's
 */
-(void)startFetchingFriendsWithCompletion: (void (^)(NSError *error, NSArray* friendList))completionBlock;

/**
 Attempts to save schedule to parse. Returns YES if user is connected to facebook
 */

-(BOOL)trySaveScheduleForTerm:(NSString *)term Courses:(NSArray *)courses HTML:(NSString *)htmlString ImageData:(NSData *)imageData;

/**
 Queries parse for the given term code and facebook ID and returns a UIImage if found, nil otherwise. This function is synchronous!
 */
-(UIImage *)imageForTerm:(NSString *)term forFacebookID:(NSString *)facebookID;

/**
 Takes in an array of facebook friend ids and returns an array of uiimage's with schedules (not supported)
 */
-(NSArray *)imagesForFriendlist:(NSArray *)friendIDs;

/**
 Returns an array of facebook IDs from facebook friend list data
 */
-(NSArray *)facebookIDsFromFriendlist:(NSArray *)fbFriendList;

/**
 Takes in user's facebook friend list and returns an array of the intersection with umd schedules. List should be a list of facebookIDs
 */
-(void)umdFriendListForTerm:(NSString *)term completion:(void (^)(NSError *error, NSArray* umdSchedules))completionBlock;

/**
 Queries parse to return any schedules that contain a given course. That list is then filtered against current user's friend list and the intersection of the two sets is returned as an array.
 */
-(void)friendsInCourse:(NSString *)course term:(NSString *)term completion:(void (^)(NSError* error, NSArray* friendSchedules))completionBlock;

-(PFObject *)currentUser;

@end
