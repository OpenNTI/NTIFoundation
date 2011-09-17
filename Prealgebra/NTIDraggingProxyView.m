//
//  NTIDraggingProxyView.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/12.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIDraggingProxyView.h"
#import "NTIUtilities.h"

@implementation NTIDraggingProxyView

@synthesize proxyFor, currentDragTarget=_nr_currentDragTarget, currentDragLocation;

-(id)initWithImage: (UIImage*)image forObject: (UIResponder*)theObject
{
	self = [super initWithImage: image];
	self->proxyFor = [theObject retain];
	return self;
}

-(void)dealloc
{
	NTI_RELEASE(self->proxyFor);
	self.currentDragTarget = nil;
	[super dealloc];
}

static id findResponder( UIResponder* p, SEL sel )
{
	if( p == nil ) {
		return nil;
	}
	
	if( [p respondsToSelector: sel] ) {
		return p;
	}
	return findResponder( [p nextResponder], sel );
	
}

-(NTIDragOperation)draggingSourceOperationMask
{
	NTIDragOperation dragOp = NTIDragOperationEvery;
	id resp = findResponder( self.proxyFor,@selector(draggingSourceOperationMaskForLocal:) );
	if( resp ) {
		dragOp = [resp draggingSourceOperationMaskForLocal: YES];
	}
	return dragOp;
}

-(id)draggingSource
{
	return self.proxyFor;
}

-(id)draggingDestination
{
	return self.currentDragTarget;
}

-(CGPoint)draggingLocation
{
	return self.currentDragLocation;
}

-(UIImage*)draggedImage
{
	return self.image;	
}

-(id)objectUnderDrag
{
	id result = self.proxyFor;
	id resp = findResponder( self.proxyFor, @selector(dragOperation:objectForDestination:) );
	if( resp ) {
		result = [resp dragOperation: self objectForDestination: self.currentDragTarget];
	}
	return result;
}

@end
