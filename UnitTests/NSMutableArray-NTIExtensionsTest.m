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
	
	STAssertEqualObjects(last, @"Three", nil);
	STAssertEquals((int)[array count], 2, nil);
	
	STAssertEqualObjects([array objectAtIndex: 0], @"One", nil);
	STAssertEqualObjects([array objectAtIndex: 1], @"Two", nil);
}

-(void)testRemoveAndReturnLastObject
{
	NSMutableArray* array = [NSMutableArray arrayWithObjects: @"One", @"Two", @"Three", nil];
	NSString* last = [array removeAndReturnLastObject];
	
	STAssertEqualObjects(last, @"Three", nil);
	STAssertEquals((int)[array count], 2, nil);
	
	STAssertEqualObjects([array objectAtIndex: 0], @"One", nil);
	STAssertEqualObjects([array objectAtIndex: 1], @"Two", nil);
}

-(void)testPush
{
	NSMutableArray* array = [NSMutableArray arrayWithObjects: @"One", @"Two", @"Three", nil];
	[array push: @"Four"];
	STAssertEquals((int)[array count], 4, nil);
	STAssertEqualObjects([array lastObject], @"Four", nil);
}

@end
