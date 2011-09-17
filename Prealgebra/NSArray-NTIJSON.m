//
//  NSArray-NTIJSON.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSArray-NTIJSON.h"
#import "NTIJSON.h"
#import "NTIOSCompat.h"

@implementation NSArray (NTIJSON)
-(NSString*)stringWithJsonRepresentation
{
	//use ios5 if possible.
	NTI_RETURN_SELF_TO_JSON();
	
	NSMutableString* json = [NSMutableString stringWithCapacity: 20];
	[json appendString: @"["];
	for( id friend in self ) {
		if( [friend respondsToSelector: _cmd] ) {
			//TODO: Escaping quotes, etc.
			friend = [friend stringWithJsonRepresentation];
			[json appendFormat: @" %@, ", friend];
		}
		else {
			[json appendFormat: @" \"%@\", ", friend];
		}
	}
	//JSON allows a trailing comma in arrays
	[json appendString: @"]"];
	return json;
}
@end
