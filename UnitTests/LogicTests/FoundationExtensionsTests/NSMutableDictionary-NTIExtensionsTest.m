//
//  NSMutableDictionary-NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 8/15/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSMutableDictionary-NTIExtensionsTest.h"
#import "NSMutableDictionary-NTIExtensions.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@implementation NSMutableDictionary_NTIExtensionsTest

-(void)testStripKeysWithNullValues
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObject: @"value1" forKey: @"key1"];
	dict = [dict stripKeysWithNullValues];
	assertThat(dict, hasEntry(@"key1", @"value1"));
	
	[dict setObject: [NSNull null] forKey: @"key2"];
	[dict setObject: @"value3" forKey: @"key3"];
	
	dict = [dict stripKeysWithNullValues];
	
	assertThat(dict, hasEntries(@"key1", @"value1", @"key3", @"value3", nil));
	assertThat(dict, isNot(hasKey(@"key2")));
}

@end

#undef HC_SHORTHAND
