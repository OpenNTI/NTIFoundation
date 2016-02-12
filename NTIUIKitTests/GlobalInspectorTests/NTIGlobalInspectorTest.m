//
//  NTIGlobalInspectorTest.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 3/14/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIGlobalInspectorTest.h"
#import "NTIGlobalInspector.h"
#import <OmniUI/OUIDetailInspectorSlice.h>
@implementation NTIGlobalInspectorTest

- (void)testAddingAndRetrievingSlices
{
	OUIDetailInspectorSlice* detailSlice = [[OUIDetailInspectorSlice alloc] init];
	[NTIGlobalInspector addSliceToGlobalRegistry: detailSlice];
	NSArray* slices = [NTIGlobalInspector globalSliceRegistry];
	XCTAssertEqual(slices.count, (NSUInteger)1, @"We should have one object in the global inspector");
	XCTAssertEqualObjects(detailSlice, [slices objectAtIndex: 0], @"slices should be equal");
	
}

@end
