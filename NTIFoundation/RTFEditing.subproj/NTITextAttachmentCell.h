//
//  NTITextAttachmentCell.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <OmniAppKit/OATextAttachmentCell.h>

@class OUITextView;

@interface NTITextAttachmentCell : OATextAttachmentCell{
	@private
	NSHashTable* editableFrames;
}

//EditableFrame should call these methods
-(void)attachEditableFrame: (OUITextView*)frame;
-(void)removeEditableFrame: (OUITextView*)frame;

//Subclasses should call this method to request to be redrawn.
//Note this isn't intended to make cells live views.  Calling this is
//expensive, requiring any editable frames displaying the cell to be
//redrawn
-(void)setNeedsRedrawn;
@end
