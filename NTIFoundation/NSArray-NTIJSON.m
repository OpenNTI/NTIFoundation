//
//  NSArray-NTIJSON.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSArray-NTIJSON.h"
#import "NTIJSON.h"
#import "NTIFoundationOSCompat.h"

@implementation NSArray (NTIJSON)
-(NSString*)stringWithJsonRepresentation
{
	//use ios5 if possible.
	NTI_RETURN_SELF_TO_JSON();
	
	NSMutableString* json = [NSMutableString stringWithCapacity: 20];
	[json appendString: @"["];
	
	NSMutableArray* serializedObjects = [NSMutableArray arrayWithCapacity: [self count]];
	for( id friend in self ) {
		if( [friend respondsToSelector: _cmd] ) {
			[serializedObjects addObject: [friend stringWithJsonRepresentation]];
		}
		else {
			[serializedObjects addObject: [NSString stringWithFormat:@"\"%@\"", friend]];
		}
	}
	[json appendString: [serializedObjects componentsJoinedByComma]];
	//JSON allows a trailing comma in arrays
	[json appendString: @"]"];
	return json;
}
@end
