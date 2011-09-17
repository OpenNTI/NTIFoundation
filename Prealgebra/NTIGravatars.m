//
//  NTIGravatars.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIGravatars.h"
#import <OmniFoundation/NSData-OFEncoding.h>
#import <OmniFoundation/NSData-OFSignature.h>

static NTIGravatars* instance;

@interface NTIGravatars()

@end

@implementation NTIGravatars

+(NTIGravatars*)gravatars
{
	if( instance == nil ) {
		instance = [[NTIGravatars alloc] init];
	}
	return instance;
}

-(id)init
{
	self = [super init];
	self->cache = [[NSCache alloc] init];
	[self->cache setName: @"Gravatar cache"];
	self->gravatar_q = dispatch_queue_create( "com.nextthought.GravatarQ", NULL );
	return self;
}

static NSString* md5StringFromEmailString( NSString* email )
{
	NSData* utf = [[email lowercaseString] dataUsingEncoding: NSUTF8StringEncoding];
	NSData* md5 = [utf md5Signature];
	return [md5 unadornedLowercaseHexString];;
}

-(void)fetchIconAtUrl: (NSString*)urlString
				 then: (NTIGravatarCallback)callback
{
	UIImage* image = [self->cache objectForKey: urlString];
	if( image ) {
		callback( image );
	}
	else {
		callback = [callback copy];
		dispatch_async( self->gravatar_q, ^{
			NSURL* url = [NSURL URLWithString: urlString];
			//If anything goes wrong, the caller gets a nil callback
			NSData* imageData = [NSData dataWithContentsOfURL: url];
			UIImage* image = [UIImage imageWithData: imageData];
			if( image ) {
				[self->cache setObject: image forKey: urlString];
				//Callback on the main thread
				dispatch_async( dispatch_get_main_queue(), ^{
					callback( image );
					[callback release];
				});
			}
		});
	}
}

-(void)fetchIconForEmail: (NSString*)email then: (NTIGravatarCallback)callback
{
	if( ![email containsString: @"@"] ) {
		email = [email stringByAppendingString: @"@nextthought.com"];
	}
	
	NSString* md5 = md5StringFromEmailString( email );
	NSString* urlString = [NSString stringWithFormat:
						   @"http://www.gravatar.com/avatar/%@?s=88&d=mm", 
						   md5];
	[self fetchIconAtUrl: urlString
					then: callback];
}

-(void)fetchIconForUser: (id)user
				   then: (NTIGravatarCallback)callback
{
	BOOL username = NO;
	NSString* string = nil;
	if( [user respondsToSelector: @selector(avatarURL)] ) {
		string = [[user valueForKey: @"avatarURL"] 
				  stringByReplacingAllOccurrencesOfString: @"s=44"
				  withString: @"s=88"];
	}
	if( !string && [user respondsToSelector: @selector(Username)] ) {
		string = [user valueForKey: @"Username"];
		username = YES;
	}
	if( string ) {
		if( username ) {
			[self fetchIconForEmail: string then: callback];
		}
		else {
			[self fetchIconAtUrl: string then: callback];
		}
	}
}


@end
