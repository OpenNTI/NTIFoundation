//
//  NSArray-NTIExtenstionsTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 12/13/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSArray-NTIExtensions.h"
#import "NSArray-NTIExtenstionsTest.h"

@implementation NSArray_NTIExtenstionsTest

-(void)testLastObjectOrNil
{
	STAssertNil([[NSArray array] lastObjectOrNil], nil);
	
	NSArray* array = [NSArray arrayWithObject: @"One"];
	STAssertEqualObjects([array lastObjectOrNil], @"One", nil);
	
	array = [NSArray arrayWithObjects: @"One", @"Two", nil];
	STAssertEqualObjects([array lastObjectOrNil], @"Two", nil);
}

-(void)testIsEmptyArray
{
	STAssertTrue([NSArray isEmptyArray: nil], @"nil is empty");
	STAssertTrue([NSArray isEmptyArray: [NSArray array]], nil);
	STAssertFalse([NSArray isEmptyArray: [NSArray arrayWithObject: @"One"]], nil);
}

-(void)testIsNotEmptyArray
{
	STAssertFalse([NSArray isNotEmptyArray: nil], @"nil is empty");
	STAssertFalse([NSArray isNotEmptyArray: [NSArray array]], nil);
	STAssertTrue([NSArray isNotEmptyArray: [NSArray arrayWithObject: @"One"]], nil);
}

-(void)testLastNonNullObject
{
	NSArray* array = nil;
	STAssertNil([array lastNonNullObject], nil);
	STAssertNil([[NSArray array] lastNonNullObject], nil);
	array = [NSArray arrayWithObjects: @"One", @"Two", [NSNull null], nil];
	STAssertEqualObjects([array lastNonNullObject], @"Two", nil);
}

-(void)testNotEmpty
{
	STAssertFalse([[NSArray array] notEmpty], nil);
	NSArray* array = nil;
	STAssertFalse([array notEmpty], @"Nil should be empty");
	STAssertTrue([[NSArray arrayWithObject: @"One"] notEmpty], nil);
}

@end
