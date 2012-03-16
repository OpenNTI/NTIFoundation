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
	STAssertEquals([NSNumber numberWithUnsignedInteger: slices.count], [NSNumber numberWithInt: 1], @"We should have one object in the global inspector");
	STAssertEqualObjects(detailSlice, [slices objectAtIndex: 0], @"slices should be equal");
	
}

@end
