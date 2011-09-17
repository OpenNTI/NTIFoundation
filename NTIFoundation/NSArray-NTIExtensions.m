//
//  NSArray-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/15.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSArray-NTIExtensions.h"
#import <OmniFoundation/OmniFoundation.h>


@implementation NSArray (NTIExtensions)
+(BOOL)isEmptyArray: (id)a
{
	return a == nil || [a isNull] || [a count] == 0;
}

-(id)firstObject
{
	return [self objectAtIndex: 0];	
}

-(id)secondObject
{
	return [self objectAtIndex: 1];
}

-(id)lastObjectOrNil
{
	return [NSArray isEmptyArray: self]
			? nil
			: self.lastObject; 
}

-(id)lastNonNullObject
{
	id result = nil;
	for( NSInteger i = [self count] - 1; i >= 0; i-- ) {
		result = [self objectAtIndex: i];
		if( OFNOTNULL( result ) ) {
			break;
		}
	}
	
	return OFNOTNULL( result ) ? result : nil;
}

@end
