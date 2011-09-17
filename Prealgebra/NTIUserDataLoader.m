//
//  NTINoteLoader.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/14.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIUserDataLoader.h"
#import "NTIUtilities.h"
#import "OmniFoundation/NSDictionary-OFExtensions.h"
#import "OmniFoundation/NSMutableDictionary-OFExtensions.h"
#import "NSString-NTIExtensions.h"

@implementation NTIUserDataLoaderBase

@synthesize page;
//Returns an object that will make the given request, or nil.
//The object must be scheduled in a run loop.
+(id)dataLoaderBaseWithRequest: (NSURLRequest*)request
					  username: (NSString*)username
					  password: (NSString*)password
{
	NTIUserDataLoaderBase* loader = [[self alloc] initWithUsername: username
														  password: password];
	loader->nr_connection = [[NSURLConnection alloc] initWithRequest: request
															delegate: loader
													startImmediately: NO];
	if( !loader->nr_connection ) {
		[loader release];
		loader = nil;
	}
	else {
		[loader autorelease];
	}
	return loader;
}

-(id)initWithUsername: (NSString*)u password: (NSString*)p
{
	self = [super initWithUsername: u password: p];
	return self;
}

-(id)scheduleInCurrentRunLoop
{
	[self->nr_connection scheduleInRunLoop: [NSRunLoop currentRunLoop]
								   forMode: NSDefaultRunLoopMode];	
	[self->nr_connection start];
	return self;
}

-(BOOL)statusWasSuccess
{
	return self.statusCode >= 200 && self.statusCode < 300;	
}

-(void)dealloc
{
	NTI_RELEASE( self->page );
	[super dealloc];
}

@end

@implementation NTIUserDataLoader

-(id)initWithUsername: (NSString*)u password: (NSString*)p
{
	self = [super initWithUsername: u password: p];
	return self;
}

+(id)_dataLoaderForRequest: (NSMutableURLRequest*)request
				  username: (NSString*)username
				  password: (NSString*)password
				  delegate: (id)delegate
				  callback: (id)callback
{
	//The loader copies the request, so we have to do this first.
	if( [delegate respondsToSelector: @selector(ifModifiedSinceForDataLoader:)] ) {
		NSDate* lastMod = [delegate ifModifiedSinceForDataLoader: nil];
		if( lastMod ) {
			[request setValue: [lastMod httpHeaderStringValue]
		   forHTTPHeaderField: @"If-Modified-Since"];
			//When NSURL gets a 304, it likes to return the cached value
			//As a 200 response. If we're making a If-Mod-Since
			//request, we really don't want that--we want to be able to
			//examine the status code.
			[request setCachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
		}
	}
	if( username && password ) {
		//While we use Basic auth, we can save ourselves a roundtrip to the
		//server by pre-authenticating the outgoing connection.
		NSString* auth = [[[NSString stringWithFormat: @"%@:%@", username, password] 
						  dataUsingEncoding: NSUTF8StringEncoding] base64String];
		[request setValue: [NSString stringWithFormat: @"Basic %@", auth]
		forHTTPHeaderField: @"Authorization"];
	}
	NTIUserDataLoader* loader = [self dataLoaderBaseWithRequest: request
													   username: username
													   password: password];
	if( loader ) {
		loader->delegate = [delegate retain];
		loader->completionCallback = [callback copy];

		[loader scheduleInCurrentRunLoop];
	}
	return loader;
}

+(id)_dataLoaderForURL: (NSURL*)pageUrl
			  username: (NSString*)username
			  password: (NSString*)password
			  delegate: (id)delegate
			  callback: (id)callback
{
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: pageUrl];
	return [self _dataLoaderForRequest: request 
							  username: username
							  password: password
							  delegate: delegate
							  callback: callback];
}

+(NTIUserDataLoader*)dataLoaderForDataserver: (NSURL*)url
									username: (NSString*)username
									password: (NSString*)password
										page: (NSString*)page
									delegate: (id)delegate
{
	return [self dataLoaderForDataserver: url
								username: username
								password: password
									page: page
									type: kNTIUserDataLoaderTypeGeneratedData
								delegate: delegate];
}

+(NTIUserDataLoader*)dataLoaderForDataserver: (NSURL*)url
									username: (NSString*)username
									password: (NSString*)password
										page: (NSString*)page
										type: (NSString*)type
									delegate: (id)delegate
{
	NSURL* pageUrl = [NSURL URLWithString: 
					  [NSString stringWithFormat: @"users/%@/Pages/%@/%@?format=plist",
					   username, page, type] 
							relativeToURL: url];
	
	NTIUserDataLoader* loader = [self _dataLoaderForURL: pageUrl
											   username: username
											   password: password
											   delegate: delegate
											   callback: nil];
	if( loader ) {								 
		loader->page = [page copy];
	}

	return loader;
}



-(void)connection: (NSURLConnection*)connection didFailWithError: (NSError*)error
{
	[super connection: connection didFailWithError: error];
	if( [delegate respondsToSelector: @selector(dataLoader:didFailWithError:)] ) {
		[delegate dataLoader: self didFailWithError: error];
	}
}

-(void)connectionDidFinishLoading: (NSURLConnection*)connection
{
	[super connectionDidFinishLoading: connection];
	if( [self statusWasSuccess] ) {
		//Parse the data
		NSMutableArray* results = [NSMutableArray arrayWithCapacity: 5];
		id dataObj = [self objectFromData];
		id items;
		if( [dataObj respondsToSelector: @selector(objectForKey:)] ) {
			NSDictionary* dict =  dataObj;
			//Work on both the old and newer dataservers. The old one
			//wrapped an Items dictionary around, the new one doesn't if we
			//use the Notes tree. In the new one, if we use the UserGeneratedData
			//tree, then we do get Items around an *array* instead of dict
			items = [dict objectForKey: @"Items"];
			if( !items ) {
				items = dict;
			}
		}
		else {
			items = dataObj;
		}
		
		if( [items isKindOfClass: [NSDictionary class]] ) {
			for( id k in items ) {
				//Some top-level items, like Last Modified, aren't 
				//valid dictionaries for notes
				id val = [items objectForKey: k];
				if( [val respondsToSelector: @selector(objectForKey:)] ) {
					id model = [NTIUserData objectFromPropertyListObject: [items objectForKey: k]];
					if( model ){
						[results addObject: model];
					}
				}
			}
		}
		else if( [items isKindOfClass: [NSArray class]] ) {
			for( id dict in items ) {
				id model = [NTIUserData objectFromPropertyListObject: dict];
				if( [self wantsResult: model] ) {
					if( model ){
						[results addObject: model];
					}
				}
			}
		}
		if( [delegate respondsToSelector: @selector(dataLoader:didFinishWithResult:)] ) {
			[delegate dataLoader: self didFinishWithResult: results];
		}
		else if( self->completionCallback ) {
			self->completionCallback( results );
		}
	}
	else if(	self.statusCode == 304
			&&	[delegate respondsToSelector: @selector(dataLoaderGotNotModifiedResponse:)] ) {
		[delegate dataLoaderGotNotModifiedResponse: self];	
	}
	else if( [delegate respondsToSelector: @selector(dataLoader:didFailWithError:)] ) {
		[delegate dataLoader: self didFailWithError: nil];
	}
}

-(BOOL)wantsResult: (id)result
{
	BOOL wants = ![result isNull];	
	if( [self->delegate respondsToSelector: _cmd] ) {
		wants = [self->delegate wantsResult: result];
	}
	return wants;
}

-(void)dealloc
{
	NTI_RELEASE( self->delegate );
	NTI_RELEASE( self->completionCallback );
	[super dealloc];
}

@end

@implementation NTIFriendsListDataLoader

+(NTIFriendsListDataLoader*)dataLoaderForDataserver: (NSURL*)url
										   username: (NSString*)user
										   password: (NSString*)password
										   delegate: (id)delegate
{
	NSURL* pageUrl = [NSURL URLWithString: 
					  [NSString stringWithFormat: @"users/%@/FriendsLists/?format=plist",
					   user] 
							relativeToURL: url];	
	return [self _dataLoaderForURL: pageUrl
						  username: user
						  password: password
						  delegate: delegate
						  callback: nil];
}

@end

@implementation NTIUserSearchDataLoader

+(NTIUserSearchDataLoader*)dataLoaderForDataserver: (NSURL*)url
										  username: (NSString*)user
										  password: (NSString*)password
									  searchString: (NSString*)searchString
										  delegate: (id)delegate
{
	NSURL* pageUrl = [NSURL URLWithString: 
					  [[NSString stringWithFormat: @"UserSearch/%@?format=plist",
					   searchString] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
							relativeToURL: url];	
	return [self _dataLoaderForURL: pageUrl
						  username: user
						  password: password
						  delegate: delegate
						  callback: nil];
}

+(NTIUserSearchDataLoader*)dataLoaderForDataserver: (NSURL*)url
										  username: (NSString*)user
										  password: (NSString*)password
									  searchString: (NSString*)searchString
										  callback: (NTIObjectProcBlock)callback
{
	NSURL* pageUrl = [NSURL URLWithString: 
					  [[NSString stringWithFormat: @"UserSearch/%@?format=plist",
						searchString] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
							relativeToURL: url];	
	NTIUserSearchDataLoader* loader = [self _dataLoaderForURL: pageUrl
													 username: user
													 password: password
													 delegate: nil
													 callback: callback];
	return loader;
}

@end

@implementation NTIContentSearchDataLoader

+(NTIContentSearchDataLoader*)dataLoaderForContent: (NSURL*)url
										  username: (NSString*)user
										  password: (NSString*)password
									  searchString: (NSString*)searchString
										  delegate: (id)delegate
{
	NSURL* pageUrl = [NSURL URLWithString: 
					  [[NSString stringWithFormat: @"Search/%@?format=plist",
						searchString] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
							relativeToURL: url];	
	return [self _dataLoaderForURL: pageUrl
						  username: user
						  password: password
						  delegate: delegate
						  callback: nil];
}

@end

@implementation NTIUserDataSearchDataLoader

+(NTIUserDataSearchDataLoader*)dataLoaderForDataserver: (NSURL*)url
											  username: (NSString*)user
											  password: (NSString*)password
										  searchString: (NSString*)searchString
											  delegate: (id)delegate;

{
	NSURL* pageUrl = [NSURL URLWithString: 
					  [[NSString 
						stringWithFormat: @"users/%@/Search/RecursiveUserGeneratedData/%@?format=plist",
						user, searchString]
						   stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
							relativeToURL: url];	
	return [self _dataLoaderForURL: pageUrl
						  username: user
						  password: password
						  delegate: delegate
						  callback: nil];
}

@end

@implementation NTIUserDataMutaterBase : NTIUserDataLoaderBase

+(id)mutateURLForObject: (NTIUserData*)object 
				   user: (NSString*)user
		  relativeToURL: (NSURL*)url
{
	return [NSURL URLWithString: 
			 [NSString stringWithFormat: @"Objects/%@?format=plist",
			  object.OID] 
				  relativeToURL: url];
}

+(BOOL)validateObject: (NTIUserData*)object
{
	return object != nil && object.OID != nil;	
}

+(id)updateObject: (NTIUserData*)object
	 onDataserver: (NSURL*)url
		 username: (NSString*)username
		 password: (NSString*)password
		 complete: (id)complete
{
	if( ![self validateObject: object] ) {
		return nil;
	}
	
	NSString* method = [self requestMethodForObject: object];
	NSURL* pageUrl = nil;
	pageUrl = [self mutateURLForObject: object user: username relativeToURL: url];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: pageUrl];
	[request setHTTPMethod: method];
	NSData* data = [self httpBodyForObject: object];
	if( data ) {
		[request setHTTPBody: data];
	}
	
	NTIUserDataMutaterBase* loader = [self dataLoaderBaseWithRequest: request
															username: username
															password: password];
	if( loader ) {
		loader->completionCallback = [complete copy]; //Blocks are copied at first
		loader->data = [object retain];
	}
	
	return loader;	
}

+(NSData*)httpBodyForObject: (NTIUserData*)object
{
	return nil;	
}

+(NSString*)requestMethodForObject: (NTIUserData*)object
{
	OBRequestConcreteImplementation( self, _cmd );
	return @"POST";
}

-(void)connectionDidFinishLoading: (NSURLConnection*)connection
{
	[super connectionDidFinishLoading: connection];
	if( [self statusWasSuccess] ) {
		if( self->completionCallback ) {
			NTIUserData* completeNote = nil;
			if( self.statusCode == 204 ) {
				//No content
				//mock up a note with the Last Modified time
				//from the server
				completeNote = [[self->data copy] autorelease];
				completeNote.LastModified = -1;
			}
			else {
				NSDictionary* dict = [self dictionaryFromData];
				completeNote = [NTIUserData objectFromPropertyListObject: dict];
			}
			
			self->completionCallback( completeNote );
		}
	}
}

-(void)connection: (NSURLConnection*)connection didFailWithError: (NSError*)error
{
	self->completionCallback( nil );	
}

-(void)dealloc
{
	NTI_RELEASE( self->data );
	[super dealloc];
}

@end

@implementation NTIUserDataDeleter

+(NTIUserDataDeleter*)deleteObject: (NTIUserData*)object
					  onDataserver: (NSURL*)url
						  username: (NSString*)username
						  password: (NSString*)password
						  complete: (NTIUserDataCallback)complete
{
	return [[self updateObject: object
				  onDataserver: url
					  username: username
					  password: password
					  complete: (id)complete] scheduleInCurrentRunLoop];
}

+(NSString*)requestMethodForObject: (id)_
{
	return @"DELETE";	
}

@end



@implementation NTIShareableUserDataUpdater

+(NTIShareableUserDataUpdater*)updateSharingOf: (NTIShareableUserData*)object 
								  onDataserver: (NSURL*)url
									  username: (NSString*)user
									  password: (NSString*)password
									  complete: (NTIShareableUserDataCallback)c;
{
	return [[self updateObject: object
				  onDataserver: url
					  username: user
					  password: password
					  complete: (id)c] scheduleInCurrentRunLoop];
}

+(NSData*)httpBodyForObject: (NTIShareableUserData*)object
{
	NSDictionary* body = [NSDictionary dictionaryWithObject: object.sharedWith 
													 forKey: @"sharedWith"];
	return [NSPropertyListSerialization dataWithPropertyList: body
													  format: NSPropertyListXMLFormat_v1_0
													 options: 0
													   error: NULL];
}

+(NSString*)requestMethodForObject: (NTIUserData*)object
{
	return @"PUT";
}


-(void)dealloc
{
	[super dealloc];
}

@end


@implementation NTIFriendsListFriendUpdater

+(NTIFriendsListFriendUpdater*)updateFriendsOf: (NTIFriendsList*)object 
								  onDataserver: (NSURL*)url
									  username: (NSString*)user
									  password: (NSString*)password
									  complete: (NTIFriendsListCallback)c;
{
	return [[self updateObject: object
				  onDataserver: url
					  username: user
					  password: password
					  complete: (id)c] scheduleInCurrentRunLoop];
}

+(NSData*)httpBodyForObject: (NTIFriendsList*)object
{
	NSArray* ofStrings = [object valueForKeyPath: @"friends.@distinctUnionOfObjects.Username"];
	
	NSDictionary* body = [NSDictionary dictionaryWithObject: ofStrings forKey: @"friends"];
	return [NSPropertyListSerialization dataWithPropertyList: body
													  format: NSPropertyListXMLFormat_v1_0
													 options: 0
													   error: NULL];
}

+(NSString*)requestMethodForObject: (NTIUserData*)object
{
	return @"PUT";
}

-(void)dealloc
{
	[super dealloc];
}

@end


@implementation NTIFriendsListSaver


+(NTIFriendsListSaver*)save: (NTIFriendsList*)object 
			   onDataserver: (NSURL*)url
				   username: (NSString*)user
				   password: (NSString*)password
				   complete: (NTIFriendsListCallback)c
{
	return [[self updateObject: object
				  onDataserver: url
					  username: user
					  password: password
					  complete: (id)c] scheduleInCurrentRunLoop];

}

+(BOOL)validateObject: (NTIUserData*)object
{
	return object != nil;	
}

+(NSData*)httpBodyForObject: (NTIFriendsList*)object
{
	return [object toPropertyListData];
}

+(NSString*)requestMethodForObject: (NTIUserData*)object
{
	return @"POST";
}

+(id)mutateURLForObject: (NTIUserData*)object 
				   user: (NSString*)user
		  relativeToURL: (NSURL*)url
{
	return [NSURL URLWithString: 
			[NSString stringWithFormat: @"users/%@/FriendsLists/?format=plist",
			 user] 
				  relativeToURL: url];
}

@end

