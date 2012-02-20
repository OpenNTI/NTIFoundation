//
//  NTIInspectorSliceObjectPair.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 2/14/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIInspectorSliceObjectPair.h"
#import <OmniUI/OUIInspectorSlice.h>
@implementation NTIInspectorSliceObjectPair

-(id)initWithInspectableObject: (id)object andSlices: (NSArray *)slices
{
	self = [super init];
	if (self) {
		self->inspectableObject = object;
		self->inspectorSlices = slices;
	}
	return self;
}

-(void)addSlices: (NSArray *)slices
{
	self->inspectorSlices = [self->inspectorSlices arrayByAddingObjectsFromArray: slices];
}

-(NSArray *)slices
{
	//Sort slices alphabetically by title
	return [self->inspectorSlices sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2) {
		NSString* title1 = [(OUIInspectorSlice *)obj1 title];
		NSString* title2 = [(OUIInspectorSlice *)obj2 title];
		return [title1 caseInsensitiveCompare: title2];
	}];
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
