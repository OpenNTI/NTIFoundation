//
//  NSMutableDictionary+NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 8/15/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSMutableDictionary-NTIExtensions.h"

@implementation NSMutableDictionary(NTIExtensions)

-(NSMutableDictionary*)stripKeysWithNullValues
{
	[self performSelector: @selector(removeObjectForKey:)
		withEachObjectInSet: [self keysOfEntriesPassingTest: ^BOOL(id key, id obj, BOOL*stop) {
		return [obj isNull];
	}]];
	return self;
}

@end
