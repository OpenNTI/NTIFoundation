//
//  NTIUserCache.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/06.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIUserCache.h"
#import "NTIUserDataLoader.h"
#import "NTIAppPreferences.h"

@implementation NTIUserCache

+(NTIUserCache*)cache
{
	static NTIUserCache* cache = nil;
	if( !cache ) {
		cache = [[NTIUserCache alloc] init];
	}
	return cache;
}

-(id)init
{
	self = [super init];
	self->cache = [[NSCache alloc] init];
	[self->cache setName: @"NTIUserCache"];
	[[NSNotificationCenter defaultCenter] 
	 addObserver: self
	 selector: @selector(_didCacheData:)
	 name: NTINotificationUserDataDidCache
	 object: nil];
	return self;
}

-(void)_didCacheData: (NSNotification*)note
{
	id ent = [note.userInfo objectForKey: NTINotificationUserDataDidCacheKey];
	if( [ent isKindOfClass: [NTIEntity class]] ) {
		[self->cache setObject: ent forKey: [ent Username]];
	}
}

-(void)resolveUser: (id)user
			  then: (NTIObjectProcBlock)block
{
	id result = [self->cache objectForKey: [user Username]];
	if( result ) {
		block( result );
	}
	else {
		block = [block copy];
		NTIObjectProcBlock callback = ^(id userList)
		{
			if( userList && [userList count] == 1 ) {
				id theUser = [userList firstObject];
				[self->cache setObject: theUser
								forKey: [user Username]];
				block( theUser );
				[block release];
			}
		};
		NTIAppPreferences* prefs = [NTIAppPreferences prefs];
		[NTIUserSearchDataLoader dataLoaderForDataserver: prefs.dataserverURL
												username: prefs.username
												password: prefs.password
											searchString: [user Username]
												callback: callback];
	}
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	NTI_RELEASE( self->cache );
	[super dealloc];
}

@end
