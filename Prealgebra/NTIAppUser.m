//
//  NTIAppUser.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/09.
//  Copyright (c) 2011 NextThought. All rights reserved.
//
#import "TestAppDelegate.h"
#import "NTIAppUser.h"
#import "NTIAbstractDownloader.h"
#import "NTIAppPreferences.h"
#import "NSArray-NTIExtensions.h"
#import "NTIUserDataLoader.h"
#import "NTIUtilities.h"

@interface NTIAppUser()<NTIUserDataLoaderDelegate>
-(void)defaultsChanged: (id)_;
-(void)setFriendsLists: (NSArray*)fl;
@end

@implementation NTIAppUser

static NTIAppUser* theUser = nil;

+(NTIAppUser*)appUser
{
	@synchronized(self) {
	if( theUser == nil ) {
		theUser = [[NTIAppUser alloc] init];
		
		[[NSNotificationCenter defaultCenter]
		 addObserver: theUser
		 selector: @selector(defaultsChanged:) 
		 name: NSUserDefaultsDidChangeNotification
		 object: nil];
		[theUser defaultsChanged: nil];
		
	}
	return theUser;
	}
}

-(id)init
{
	self = [super init];
	return self;
}

-(void)defaultsChanged: (id)_
{
	//At some point during startup, the preferences will 
	//change. When this happens, we load our data. 
	//This may happen in the future, and we load our data then as well.
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];
	if(		![prefs.username isEqual: self->cachedUsername]
	   ||	![prefs.password isEqual: self->cachedPassword] ) {
		NTI_RELEASE( self->cachedPassword );
		NTI_RELEASE( self->cachedUsername );
		self->cachedUsername = [prefs.username retain];
		self->cachedPassword = [prefs.password retain];
		[NTIFriendsListDataLoader
		 dataLoaderForDataserver: prefs.dataserverURL
		 username: self->cachedUsername
		 password: self->cachedPassword
		 delegate: self];
		[NTIUserSearchDataLoader
		 dataLoaderForDataserver: prefs.dataserverURL
		 username: self->cachedUsername
		 password: self->cachedPassword
		 searchString: self->cachedUsername
		 delegate: self];
	}
}

-(void)dataLoader: (NTIUserDataLoader*)loader didFailWithError: (NSError*)error
{
	NTI_PRESENT_ERROR( error );
}

-(void)dataLoader: (NTIUserDataLoader*)loader didFinishWithResult: (NSArray*)result
{
	if( [loader isKindOfClass: [NTIFriendsListDataLoader class]] ) {
		[self setFriendsLists: result];
	}
	else if( [loader isKindOfClass: [NTIUserSearchDataLoader class]] ) {
		NTIUserData* obj = [result anyObject];
		NSArray* properties = [[obj toPropertyListObject] allKeys];
		[self setValuesForKeysWithDictionary: [obj dictionaryWithValuesForKeys: properties]];
		[self cache]; //Request to be used for our OID in the future.
		self.lastLoginDate = [NSDate date];
		//TODO: Update the login date on the server.
	}
}

-(NSString*)Username
{
	return [[self->cachedUsername retain] autorelease];
}

-(NSString*)ID
{
	return [self Username];	
}

-(NSString*)password
{
	return [[self->cachedPassword retain] autorelease];
}

-(void)setPassword: (NSString*)string
{
	string = [string copy];
	NTI_RELEASE( self->cachedPassword );
	self->cachedPassword = string;
}

//For KVO, must use the setter
-(void)setFriendsLists: (NSArray*)incoming
{
	id copy = [incoming mutableCopy];
	NTI_RELEASE( self->mutableFriendsLists );
	self->mutableFriendsLists = copy;
}

-(NSUInteger)countOfFriendsLists
{
	return self->mutableFriendsLists.count;	
}

-(id)objectInFriendsListsAtIndex: (NSUInteger)ix
{
	return [self->mutableFriendsLists objectAtIndex: ix];	
}

-(void)insertObject: (id)obj 
inFriendsListsAtIndex: (NSUInteger)ix
{
	[self->mutableFriendsLists insertObject: obj atIndex: ix];	
}

-(void)removeObjectFromFriendsListsAtIndex: (NSUInteger)index
{
	[self->mutableFriendsLists removeObjectAtIndex: index];	
}

-(NSArray*)friendsLists
{
	//FIXME: Race condition here. Handle like the library does.
	NSArray* result = nil;
	if( [NSArray isEmptyArray: self->mutableFriendsLists] ) {
		result = [NSArray array];
	}
	else {
		result = [[self->mutableFriendsLists copy] autorelease];
	}
	return result;		
}

-(NTIFriendsList*)friendsListNamed: (NSString*)name
{
	NTIFriendsList* result = nil;
	for( NTIFriendsList* list in self->mutableFriendsLists ) {
		if( [list.Username isEqual: name] ) {
			result = list;
			break;
		}
	}
	return result;
}

-(void)didDeleteFriendsList: (NTIFriendsList*)list
{
	NSUInteger ix = [self->mutableFriendsLists indexOfObjectIdenticalTo: list];
	if( ix != NSNotFound ) {
		[self removeObjectFromFriendsListsAtIndex: ix];
	}
}

-(void)didCreateFriendsList: (NTIFriendsList*)list
{
	if( list ) {
		[self insertObject: list inFriendsListsAtIndex: [self countOfFriendsLists]];
	}
}


-(void)registerDeviceForRemoteNotification: (NSData*)devToken
{
	NSString* externalString = [devToken unadornedLowercaseHexString];
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];
	NSURL* regUrl = [prefs
					 URLRelativeToRoot: [NSString stringWithFormat: @"/dataserver/users/%@/Devices/%@",
										 prefs.username, externalString]];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL: regUrl];
	req.HTTPMethod = @"PUT";
	//json-ify the data
	req.HTTPBody = [[NSString stringWithFormat: @"\"%@\"", externalString]
					dataUsingEncoding: NSUTF8StringEncoding];
	//Fire and forget.
	NTIAbstractDownloader* down = [[[NTIAbstractDownloader alloc]
									initWithUsername: prefs.username password: prefs.password] autorelease];
	[[[NSURLConnection alloc] initWithRequest: req delegate: down] autorelease];	
}

-(id)toPropertyListObject
{
	NSMutableDictionary* dict = [super toPropertyListObject];
	[dict setObject: self.password forKey: @"password"];
	return dict;
}

#pragma mark - Copying
//Note that because we can be copied for editing,
//we must take care with how we prohibit the release/retain/dealloc methods
//that is typical for a singleton

-(id)copyWithZone: (NSZone*)zone
{
	NTIAppUser* copy = [super copyWithZone: zone];
	copy->mutableFriendsLists = [self->mutableFriendsLists copy];
	copy->cachedUsername = [self->cachedUsername copy];
	copy->cachedPassword = [self->cachedPassword copy];
	return copy;
}

#pragma mark - Singleton
-(id)retain
{
	if( self == theUser ) return self;
	
	return [super retain];
}

-(id)autorelease
{
	if( self == theUser ) return self;
	
	return [super autorelease];
}

-(oneway void)release
{
	if( self == theUser ) return;
	[super release];
}


-(void)dealloc
{
	NTI_RELEASE( self->mutableFriendsLists );
	NTI_RELEASE( self->cachedUsername );
	NTI_RELEASE( self->cachedPassword );
	[super dealloc];
}

@end
