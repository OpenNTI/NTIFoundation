//
//  NSMutableArray-NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 12/13/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NSMutableArray-NTIExtensionsTest.h"
#import "NSMutableArray-NTIExtensions.h"

@implementation NSMutableArray_NTIExtensionsTest

-(void)testPop
{
	NSMutableArray* array = [NSMutableArray arrayWithObjects: @"One", @"Two", @"Three", nil];
	NSString* last = [array pop];
	
	XCTAssertEqualObjects(last, @"Three");
	XCTAssertEqual((int)[array count], 2);
	
	XCTAssertEqualObjects([array objectAtIndex: 0], @"One");
	XCTAssertEqualObjects([array objectAtIndex: 1], @"Two");
}

-(void)testRemoveAndReturnLastObject
{
	NSMutableArray* array = [NSMutableArray arrayWithObjects: @"One", @"Two", @"Three", nil];
	NSString* last = [array removeAndReturnLastObject];
	
	XCTAssertEqualObjects(last, @"Three");
	XCTAssertEqual((int)[array count], 2);
	
	XCTAssertEqualObjects([array objectAtIndex: 0], @"One");
	XCTAssertEqualObjects([array objectAtIndex: 1], @"Two");
}

-(void)testPush
{
	NSMutableArray* array = [NSMutableArray arrayWithObjects: @"One", @"Two", @"Three", nil];
	[array push: @"Four"];
	XCTAssertEqual((int)[array count], 4);
	XCTAssertEqualObjects([array lastObject], @"Four");
}

@end
