//
//  NTINoteLoader.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/14.
//  Copyright 2011 NextThought. All rights reserved.
//


#import "NTIUserData.h"


@class NTIUserDataLoader;
@protocol NTIUserDataLoaderDelegate <NSObject>
@optional
-(void)dataLoader: (NTIUserDataLoader*)loader didFinishWithResult: (NSArray*)result;
-(void)dataLoader: (NTIUserDataLoader*)loader didFailWithError: (NSError*)error;
-(BOOL)wantsResult: (id)resultObject;

//If implemented and returns non-nil, this will be the value
//used in IF-MODIFIED-SINCE header. Setting this means we don't return
//cached data to didFinishWithResult; instead, we will invoke
//dataLoaderGotNotModifiedResponse: (or failing that, didFailWithError:)
-(NSDate*)ifModifiedSinceForDataLoader: (NTIUserDataLoader*)loader;
-(void)dataLoaderGotNotModifiedResponse: (NTIUserDataLoader*)loader;

@end

#include "NTIAbstractDownloader.h"
@interface NTIUserDataLoaderBase : NTIBufferedDownloader {
	@private
	//The connection for which we are the delegate. It retains
	//us.
	NSURLConnection* nr_connection;
	@package
	NSString* page;
	//Provides storage for a completion callback, subclasses 
	//decide what the callback should be.
	NTIObjectProcBlock completionCallback; 
}
@property (readonly,nonatomic) NSString* page;
-(id)scheduleInCurrentRunLoop;
@end

#define kNTIUserDataLoaderTypeStream @"Stream"
#define kNTIUserDataLoaderTypeRecursiveStream @"RecursiveStream"
#define kNTIUserDataLoaderTypeGeneratedData @"UserGeneratedData"
#define kNTIUserDataLoaderTypeRecursiveUserGeneratedData @"RecursiveUserGeneratedData"

@interface NTIUserDataLoader : NTIUserDataLoaderBase {
	@protected
	id<NTIUserDataLoaderDelegate> delegate;
}

//Loads the UserGeneratedData
+(NTIUserDataLoader*)dataLoaderForDataserver: (NSURL*)url
									username: (NSString*)user
									password: (NSString*)password
										page: (NSString*)page
									delegate: (id)delegate;

+(NTIUserDataLoader*)dataLoaderForDataserver: (NSURL*)url
									username: (NSString*)user
									password: (NSString*)password
										page: (NSString*)page
										type: (NSString*)type
									delegate: (id)delegate;

//Subclassing

/**
 * Called to see if the given item should be included
 * in the results returned to the delegate. This implementation
 * checks with the delegate; if it has no opinion, returns YES.
 */
-(BOOL)wantsResult: (id)result;

@end

typedef void(^NTIUserDataCallback)(NTIUserData*);
@interface NTIUserDataMutaterBase: NTIUserDataLoaderBase {
	@protected 
	NTIUserData* data;
}

//For subclasses. Returns an object that must be scheduled.
+(id)updateObject: (NTIUserData*)object
	 onDataserver: (NSURL*)url
		 username: (NSString*)username
		 password: (NSString*)password
		 complete: (id)complete;

+(BOOL)validateObject: (NTIUserData*)object;
+(NSData*)httpBodyForObject: (NTIUserData*)object;
+(NSString*)requestMethodForObject : (NTIUserData*)object;

@end


@interface NTIUserDataDeleter : NTIUserDataMutaterBase

//Deletes the specified object on the dataserver, if possible.
//Upon completion, the complete callback will be called. If there was an
//error, it will be called with NIL. If the object was deleted, it
//will be called with an object having LastModified of -1: This allows
//you to rely on the OID being the same to handle removing from
//your datastructures.
+(NTIUserDataDeleter*)deleteObject: (NTIUserData*)obj
					  onDataserver: (NSURL*)url
						  username: (NSString*)username
						  password: (NSString*)password
						  complete: (NTIUserDataCallback)complete;

@end

@interface NTIFriendsListDataLoader : NTIUserDataLoader {
}

//Loads the UserGeneratedData
+(NTIFriendsListDataLoader*)dataLoaderForDataserver: (NSURL*)url
										   username: (NSString*)user
										   password: (NSString*)password
										   delegate: (id)delegate;

@end

@interface NTIUserSearchDataLoader : NTIUserDataLoader {

}


+(NTIUserSearchDataLoader*)dataLoaderForDataserver: (NSURL*)url
										  username: (NSString*)user
										  password: (NSString*)password
									  searchString: (NSString*)searchString
										  delegate: (id)delegate;
+(NTIUserSearchDataLoader*)dataLoaderForDataserver: (NSURL*)url
										  username: (NSString*)user
										  password: (NSString*)password
									  searchString: (NSString*)searchString
										  callback: (NTIObjectProcBlock)callback;
@end

@interface NTIContentSearchDataLoader : NTIUserDataLoader {
}


+(NTIContentSearchDataLoader*)dataLoaderForContent: (NSURL*)url
										  username: (NSString*)user
										  password: (NSString*)password
									  searchString: (NSString*)searchString
										  delegate: (id)delegate;
@end

@interface NTIUserDataSearchDataLoader : NTIUserDataLoader {
}


+(NTIUserDataSearchDataLoader*)dataLoaderForDataserver: (NSURL*)url
											  username: (NSString*)user
											  password: (NSString*)password
										  searchString: (NSString*)searchString
											  delegate: (id)delegate;
@end


typedef void(^NTIShareableUserDataCallback)(NTIShareableUserData*);

@interface NTIShareableUserDataUpdater : NTIUserDataMutaterBase {
}

+(NTIShareableUserDataUpdater*)updateSharingOf: (NTIShareableUserData*)object 
								  onDataserver: (NSURL*)url
									  username: (NSString*)user
									  password: (NSString*)password
									  complete: (NTIShareableUserDataCallback)c;
@end

typedef void(^NTIFriendsListCallback)(NTIFriendsList*);

@interface NTIFriendsListFriendUpdater : NTIUserDataMutaterBase {
}

+(NTIFriendsListFriendUpdater*)updateFriendsOf: (NTIFriendsList*)object 
								  onDataserver: (NSURL*)url
									  username: (NSString*)user
									  password: (NSString*)password
									  complete: (NTIFriendsListCallback)c;
@end

@interface NTIFriendsListSaver : NTIUserDataMutaterBase {
}

+(NTIFriendsListSaver*)save: (NTIFriendsList*)object 
			   onDataserver: (NSURL*)url
				   username: (NSString*)user
				   password: (NSString*)password
				   complete: (NTIFriendsListCallback)c;
@end


