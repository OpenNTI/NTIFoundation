//
//  NTITapCatchingGestureRecognizer.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/30.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTITapCatchingGestureRecognizer.h"
#import "NTIUtilities.h"


@implementation NTITapCatchingGestureRecognizer

-(id) initWithTarget: (id)target action: (SEL)action
{
	if( (self = [super initWithTarget: target action: action]) ) {
		[self setCancelsTouchesInView: NO];
	}
	return self;
}

-(id)canBePreventedBy: (id)other
{
	if( preventingSet == nil ) {
		preventingSet = [[NSMutableSet setWithObject: other] retain];
	}
	else {
		[preventingSet addObject: other];
	}
	return self;
}

-(id)canPrevent: (id)other
{
	if( preventedSet == nil ) {
		preventedSet = [[NSMutableSet setWithObject: other] retain];
	}
	else {
		[preventedSet addObject: other];
	}
	return self;
}

- (BOOL)canBePreventedByGestureRecognizer: (UIGestureRecognizer*)preventingGestureRecognizer
{
	//BOOL messages to nil return NO
	return [preventingSet containsObject: preventingGestureRecognizer];
}

-(BOOL)canPreventGestureRecognizer: (UIGestureRecognizer*)preventedGestureRecognizer
{
	return [preventedSet containsObject: preventedGestureRecognizer];
}

-(void)dealloc
{
	NTI_RELEASE( self->preventedSet );
	NTI_RELEASE( self->preventingSet );
	[super dealloc];
}
@end


@implementation NTILongPressCatchingGestureRecognizer

-(id) initWithTarget: (id)target action: (SEL)action
{
	if( (self = [super initWithTarget: target action: action]) ) {
		[self setCancelsTouchesInView: NO];
	}
	return self;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
	return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
	return NO;
}

@end
