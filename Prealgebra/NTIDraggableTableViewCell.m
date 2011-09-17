//
//  NTIDraggableTableViewCell.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIDraggableTableViewCell.h"
#import "OmniUI/OUIDragGestureRecognizer.h"
#import <QuartzCore/QuartzCore.h>
#import "NTIDraggingUtilities.h"

@implementation NTIDraggableTableViewCell

-(id)initWithStyle: (UITableViewCellStyle)style
   reuseIdentifier: (NSString*)reuseIdentifier
{
	self = [super initWithStyle: style reuseIdentifier: reuseIdentifier];
	enableDragTracking( self.imageView, self, @selector(imageViewDidDrag:));
    return self;
}

-(void)imageViewDidDrag: (OUIDragGestureRecognizer*)dragger
{
	trackDragging( self, dragger, &self->draggingProxyView );
}
@end
