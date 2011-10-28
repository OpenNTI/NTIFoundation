// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniUI/OUIScalingScrollView.h>

@class OUIEditableFrame;
@class NTIEditableFrameScrollViewDelegate;
@interface NTIEditableFrameScrollView : OUIScalingScrollView
{
@private
	OUIEditableFrame *_textView;
	NTIEditableFrameScrollViewDelegate* _scrollDelegate;
}

@property(strong,nonatomic) IBOutlet OUIEditableFrame *textView;

@end
