// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NTIEditableFrameScrollView.h"

#import <OmniUI/OUIEditableFrame.h>
#import <OmniUI/OUIMinimalScrollNotifierImplementation.h>

@interface NTIEditableFrameScrollViewDelegate : OUIMinimalScrollNotifierImplementation<UIScrollViewDelegate>
{
	id _textView;
}
-(id)initWithView: (id)view;
@end

@implementation NTIEditableFrameScrollViewDelegate

-(id)initWithView: (id)view
{
	self = [super init];
	self->_textView = view;
	return self;
}

-(UIView*)viewForZoomingInScrollView: (id)_
{
	return self->_textView;
}

@end

@implementation NTIEditableFrameScrollView

@synthesize textView = _textView;

-(void)installDelegate
{
	if( self.delegate == nil && self->_textView ) {
		//If the delegate is missing, scroll offsets can be wrong.
		if( self->_scrollDelegate == nil ) {
			self->_scrollDelegate = [[NTIEditableFrameScrollViewDelegate alloc] initWithView: self->_textView];
		}
		self.delegate = self->_scrollDelegate;
	}
}

-(id)initWithCoder: (NSCoder*)coder
{
	self = [super initWithCoder: coder];
	[self installDelegate]; 
	return self;
}

-(id)delegate
{
	id r = [super delegate];
	if( !r && self->_textView ) {
		//During the initialization process from a NIB, we need to fake one
		//of these before we can actually install it.
		r = [[NTIEditableFrameScrollViewDelegate alloc] initWithView: self->_textView];
	}
	return r;
}

-(void)layoutSubviews;
{
	OBPRECONDITION(_textView); // not hooked up in xib?
	
	if( _textView ) {
		[self installDelegate];
		CGRect bounds = self.bounds;

		// First make sure the text is the right width so that it can
		//calculate the right used height
		CGRect textFrame = _textView.frame;
		if( textFrame.size.width != bounds.size.width ) {
			_textView.frame = CGRectMake(0, 0, bounds.size.width, textFrame.size.height);
		}

		// Then ensure the height is large enough to span the text (or our height).
		CGSize usedSize = _textView.viewUsedSize;
		CGFloat height = MAX(bounds.size.height, usedSize.height);
		if( height != textFrame.size.height ) {
			_textView.frame = CGRectMake(0, 0, bounds.size.width, height);
		}
	}

	[super layoutSubviews];
}

@end
