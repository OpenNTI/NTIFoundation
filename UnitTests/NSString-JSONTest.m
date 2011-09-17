//
//  NSString-JSONTest.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/07/29.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSString-JSONTest.h"
#import "NSString-NTIJSON.h"

@implementation NSString_JSONTest

// All code under test must be linked into the Unit Test bundle
static NSNumber* n(int x )
{
	return [NSNumber numberWithInt: x];	
}

static NSNumber* f(NSString* x )
{
	return [NSDecimalNumber decimalNumberWithString: x];	
}


-(void)testParseArrays
{
	STAssertEqualObjects( 
						 [@"[]" jsonObjectValue], [NSArray array], 
						 @"empty array");
	STAssertEqualObjects([@"[\"Hi\"]" jsonObjectValue],  [NSArray arrayWithObject: @"Hi"],
						 @"One string");
	STAssertEqualObjects([@"[[\"Hi\"]]" jsonObjectValue],
						 [NSArray arrayWithObject: [NSArray arrayWithObject: @"Hi"]],
						 @"One nested string" );
	
	NSArray* expected = [NSArray arrayWithObjects: 
						 [NSArray arrayWithObjects: @"Hi", n(42), nil],
						 [NSArray arrayWithObjects: f(@"98.6"), @"Boo", nil],
						 nil];
	STAssertEqualObjects(
		[@"[[\"Hi\",42], [98.6, \"Boo\"]]" jsonObjectValue],
		expected,
		 @"One nested string" );

	expected = [NSArray arrayWithObjects:
						 [NSArray arrayWithObjects: n(50), n(123), n(135), n(19), @"1", nil],
						 [NSArray arrayWithObjects: n(50), n(223), n(135), n(19), @"2", nil],
						 [NSArray arrayWithObjects: n(310), n(428), n(135), n(19), @"3", nil],
						 nil];
	STAssertEqualObjects(
		[@"[[50,123,135,19,\"1\"],[50,223,135,19,\"2\"],[310,428,135,19,\"3\"]]" jsonObjectValue],
		expected,
		@"Complex array"
	);
	
}

@end
