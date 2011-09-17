//
//  NTIAppUser.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/09.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"
#import "NTIUserData.h"


/**
 * The app user is a singleton and represents the user of the application.
 */
@interface NTIAppUser : NTIUser<NSCopying> { //TODO: Right superclass?
	@private
	NSMutableArray* mutableFriendsLists;
	NSString* cachedUsername;
	NSString* cachedPassword;
}

+(NTIAppUser*)appUser;

//The password. Setting this neither changes 
//the defaults nor the server. 
@property (nonatomic,copy) NSString* password;

//An array of NTIFriendsList objects, possibly empty. We are KVO compliant
//for this.
@property (nonatomic,readonly) NSArray* friendsLists;

//A shortcut to getting a particular friends list, or nil
-(NTIFriendsList*)friendsListNamed: (NSString*)name;
-(void)didDeleteFriendsList: (NTIFriendsList*)list;
-(void)didCreateFriendsList: (NTIFriendsList*)list;

-(void)registerDeviceForRemoteNotification: (NSData*)token;

@end
