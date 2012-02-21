//
//  NTIInspectorSliceObjectPair.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 2/14/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIInspectorSliceObjectPair.h"
#import <OmniUI/OUIInspectorSlice.h>
#import <OmniFoundation/OmniFoundation.h>

@implementation NTIInspectorSliceObjectPair

-(id)initWithInspectableObject: (id)object andSlices: (NSArray *)slices
{
	self = [super init];
	if (self) {
		self->inspectableObject = object;
		self->inspectorSlices = [NSMutableArray arrayWithArray: slices];
	}
	return self;
}

NSComparisonResult compareByTitle(OUIInspectorSlice* a, OUIInspectorSlice* b, void* context);
NSComparisonResult compareByTitle(OUIInspectorSlice* a, OUIInspectorSlice* b, void* context)
{
	return [[a title] caseInsensitiveCompare: [b title]];
}


-(void)addSlices: (NSArray *)slices
{
	for(id slice in slices){
		if(![self->inspectorSlices containsObject: slice]){
			[self->inspectorSlices insertObject: slice 
					 inArraySortedUsingFunction: compareByTitle 
										context: NULL];
		}
	}
}

-(NSArray *)slices
{
	return [self->inspectorSlices copy];
}

-(id)inspectableObject
{
	return inspectableObject;
}

-(BOOL)containsInspectableObject: (id)object
{
	if ( self->inspectableObject == object) {
		return YES;
	}
	else {
		return NO;
	}
}

@end
