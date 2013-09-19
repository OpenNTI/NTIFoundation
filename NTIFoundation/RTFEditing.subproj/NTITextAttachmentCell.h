//
//  NTITextAttachmentCell.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <OmniAppKit/OATextAttachmentCell.h>

@class OUIEditableFrame;

@interface NTITextAttachmentCell : OATextAttachmentCell{
	@private
	NSHashTable* editableFrames;
}

//EditableFrame should call these methods
-(void)attachEditableFrame: (OUIEditableFrame*)frame;
-(void)removeEditableFrame: (OUIEditableFrame*)frame;

//Subclasses should call this method to request to be redrawn.
//Note this isn't intended to make cells live views.  Calling this is
//expensive, requiring any editable frames displaying the cell to be
//redrawn
-(void)setNeedsRedrawn;
@end
