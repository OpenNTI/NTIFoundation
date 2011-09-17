//Originally based on code by:
// Copyright 2010-2011 The Omni Group.	All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniUI/OUIScalingViewController.h>
#import <OmniUI/OUIEditableFrameDelegate.h>
#import <OmniUI/OUIDocumentViewController.h>

@class NTIRTFDocument;
@class NTIEditableFrame;

@interface NTIRTFTextViewController : OUIScalingViewController <OUIEditableFrameDelegate>
{
@private
	NSUndoManager* undoManager;
	UITextRange* selectedBeforeDrag;
}

@property(retain,nonatomic) IBOutlet NTIEditableFrame *editor;
@property(nonatomic,readonly) NTIRTFDocument* document;

-(id)initWithDocument: (NTIRTFDocument*)document;
-(void)documentContentsDidChange;
@end
