//
//  NTIDraggableImageView.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIDraggableImageView.h"
#import "NTIDraggingUtilities.h"

@implementation NTIDraggableImageView


-(id)initWithImage: (UIImage*)i
{
	return [self initWithImage: i dragResponder: nil];
}

-(id)initWithImage: (UIImage*)image
	 dragResponder: (UIResponder*)dragResponder
{
	self = [super initWithImage: image];
	if( !self ) {
		return nil;
	}
	enableDragTracking( self, self, @selector(imageViewDidDrag:));
	self->nr_dragResponder = dragResponder;
	return self;
}

-(UIResponder*) nextResponder
{
	if( self->nr_dragResponder ) {
		return self->nr_dragResponder;
	}
	return [super nextResponder];
}

-(void)imageViewDidDrag: (id)dragger
{
	trackDragging( self, dragger, &self->draggingProxyView );
}
@end
