//
//  NTIGlobalInspectorSlice.m
//  NTIFoundation
//
//  Created by Christopher Utz on 7/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIGlobalInspectorSlice.h"

@interface NTIGlobalInspectorSlice ()

@end

@implementation NTIGlobalInspectorSlice
@synthesize paneMaker;

-(id)initWithTitle: (NSString*)t paneMaker: (NTIInspectorPaneMaker)pm
{
	if (!(self = [super initWithNibName: nil bundle: nil]))
        return nil;
	
	self.title = t;
	self.paneMaker = pm;
	return self;
}

-(NSArray*)inspectedObjectsForItemAtIndex: (NSUInteger)itemIndex
{
	return [self appropriateObjectsForInspection];
}

-(OUIInspectorPane*)makeDetailsPaneForItemAtIndex: (NSUInteger)itemIndex
{
	OBASSERT(itemIndex == 0);
	return self.paneMaker(self);
}

@end
