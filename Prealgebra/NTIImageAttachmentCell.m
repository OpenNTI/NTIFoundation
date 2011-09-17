//Originally based on code: 
// Copyright 2011 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NTIImageAttachmentCell.h"
#import "NTIUtilities.h"

//We would use a ImageProvider if we had a reference to data
//and not the image itself
//#import <ImageIO/CGImageSource.h>

@implementation NTIImageAttachmentCell
@synthesize image;
-(id)initWithImage: (UIImage*)i size: (CGSize)size
{
	self = [super init];
	self->image = [i retain];
	self->imageSize = size;
	return self;
}

- (void)dealloc;
{
	NTI_RELEASE( self->image );
	[super dealloc];
}

#pragma mark -
#pragma mark OATextAttachmentCell subclass

- (void)drawWithFrame:(CGRect)cellFrame inView:(UIView *)controlView;
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextDrawImage(ctx, cellFrame, [self->image CGImage] );
}

- (CGSize)cellSize;
{
	return self->imageSize;
}


@end
