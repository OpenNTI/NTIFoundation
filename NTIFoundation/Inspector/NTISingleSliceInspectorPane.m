//
//  NTISingleSliceInspectorPane.m
//  NTIFoundation
//
//  Created by Chris Hansen on 4/17/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//

#import <OmniUI/OUIInspectorSlice.h>
#import "NTISingleSliceInspectorPane.h"

@interface NTISingleSliceInspectorPane (){
@private
	NSMutableArray* sliceConstraints;
}
@end

@implementation NTISingleSliceInspectorPane

-(id)initWithInspectorSlice:(OUIInspectorSlice *)slice
{
	self = [super init];
	if(self){
		self.slice = slice;
		self.title = slice.title;
		
		self->sliceConstraints = [NSMutableArray new];
	}
	return self;
}

-(void)inspectorWillShow:(OUIInspector *)inspector
{
	[self showSlice: self.slice];
}

-(void)setSlice:(OUIInspectorSlice *)slice
{
	self->_slice = slice;
	self.title = slice.title;
	
	[self addChildViewController: self.slice];
	[self.slice didMoveToParentViewController: self];
	
	[self showSlice: self->_slice];
}

-(void)showSlice: (OUIInspectorSlice*)slice
{
	if(!self.isViewLoaded){
		return;
	}
	[self addChildViewController: self.slice.detailPane];
	[self.slice.detailPane didMoveToParentViewController: self];
	[self.view addSubview: self.slice.detailPane.view];
	
	[self.view removeConstraints: self->sliceConstraints];
	self.slice.detailPane.view.translatesAutoresizingMaskIntoConstraints = NO;
	
	self->sliceConstraints = (NSMutableArray*)[NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
																					  options: 0
																					  metrics: nil
																						views: @{@"view":self.slice.detailPane.view}];
	[self->sliceConstraints addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[view]|"
																			   options: 0
																			   metrics: nil
																				 views: @{@"view":self.slice.detailPane.view}]];
	[self.view addConstraints: self->sliceConstraints];

	[self.slice updateInterfaceFromInspectedObjects: OUIInspectorUpdateReasonDefault];
	[self updateInterfaceFromInspectedObjects: OUIInspectorUpdateReasonDefault];
}

-(void)updateInterfaceFromInspectedObjects:(OUIInspectorUpdateReason)reason
{
	[self.slice.detailPane updateInterfaceFromInspectedObjects: reason];
}

-(BOOL)respondsToSelector:(SEL)aSelector
{
	return [super respondsToSelector: aSelector] || [self.slice.detailPane respondsToSelector: aSelector];
}

-(id)forwardingTargetForSelector:(SEL)aSelector
{
	return self.slice.detailPane;
}

@end
