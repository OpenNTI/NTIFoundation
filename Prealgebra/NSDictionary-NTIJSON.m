//
//  NSDictionary-NTIJSON.m
//  Prealgebra
//
//  Created by Christopher Utz on 7/14/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSDictionary-NTIJSON.h"
#import "NTIOSCompat.h"
#import "NTIJSON.h"
#import <OmniFoundation/OmniFoundation.h>

@implementation NSDictionary (NSDictionary_NTIJSON)

-(NSString*)stringWithJsonRepresentation
{
	//Use iOS 5 if available.
	NTI_RETURN_SELF_TO_JSON();
	
	NSMutableString* json = [[[NSMutableString alloc] initWithCapacity: 20] autorelease];
	
	[json appendString: @"{ "];
	
	for( id key in self ) {
		id value = [self objectForKey: key];
		if( [value respondsToSelector: _cmd] ) {
			//TODO: Escaping quotes, etc.
			value = [value stringWithJsonRepresentation];
			[json appendFormat: @"\"%@\": %@,",
			 key, value];
		}
		else {
			[json appendFormat: @"\"%@\": \"%@\",",
			 key, value];
		}
	}
	
	//Unlike arrays, dictionaries do not tolerate a trailing comma, 
	//so we kill two birds with one stone ard replace it with the trailing
	//delemiter if needed
	if( self.count ) {
		[json replaceCharactersInRange: NSMakeRange( [json length] - 1, 1 )
							withString: @"}" ];
	}
	else {
		[json appendString: @"}"];
	}
	
	return json;
}

@end
