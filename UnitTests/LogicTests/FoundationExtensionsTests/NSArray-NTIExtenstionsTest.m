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
	XCTAssertNil([[NSArray array] lastObjectOrNil]);
	
	NSArray* array = [NSArray arrayWithObject: @"One"];
	XCTAssertEqualObjects([array lastObjectOrNil], @"One");
	
	array = [NSArray arrayWithObjects: @"One", @"Two", nil];
	XCTAssertEqualObjects([array lastObjectOrNil], @"Two");
}

-(void)testIsEmptyArray
{
	XCTAssertTrue([NSArray isEmptyArray: nil], @"nil is empty");
	XCTAssertTrue([NSArray isEmptyArray: [NSArray array]]);
	XCTAssertFalse([NSArray isEmptyArray: [NSArray arrayWithObject: @"One"]]);
}

-(void)testIsNotEmptyArray
{
	XCTAssertFalse([NSArray isNotEmptyArray: nil], @"nil is empty");
	XCTAssertFalse([NSArray isNotEmptyArray: [NSArray array]]);
	XCTAssertTrue([NSArray isNotEmptyArray: [NSArray arrayWithObject: @"One"]]);
}

-(void)testLastNonNullObject
{
	NSArray* array = nil;
	XCTAssertNil([array lastNonNullObject]);
	XCTAssertNil([[NSArray array] lastNonNullObject]);
	array = [NSArray arrayWithObjects: @"One", @"Two", [NSNull null], nil];
	XCTAssertEqualObjects([array lastNonNullObject], @"Two");
}

-(void)testNotEmpty
{
	XCTAssertFalse([[NSArray array] notEmpty]);
	NSArray* array = nil;
	XCTAssertFalse([array notEmpty], @"Nil should be empty");
	XCTAssertTrue([[NSArray arrayWithObject: @"One"] notEmpty]);
}

- (void)testIsEmpty
{
	XCTAssertFalse(@[@"not-empty"].isEmpty, @"isEmpty incorrecty computes true for a non-empty array.");
	
	XCTAssertTrue(@[].isEmpty, @"isEmpty incorrectly computes false for an empty array.");
	
	NSArray *nilArray = nil;
	XCTAssertFalse(nilArray.isEmpty, @"isEmpty incorrectly computes true for nil.");
}

@end
