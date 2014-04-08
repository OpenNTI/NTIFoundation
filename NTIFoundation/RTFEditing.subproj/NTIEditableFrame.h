//
//  NTIEditableFrame.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/22.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniUI/OUITextView.h"
#import <OmniAppKit/OATextAttachmentCell.h>

@class NTIEditableFrame;
@interface NTIEditableFrameTextAttachmentCellDelegate
-(BOOL)editableFrame: (NTIEditableFrame*)editableFrame 
	  attachmentCell: (OATextAttachmentCell*) attachmentCell
   wasTouchedAtPoint: (CGPoint)point;
@end

/**
 * Extend the OUITextView with some helpful messages (particularily around attachment handling)
 */
@interface NTIEditableFrame : OUITextView{
	@private
	id __weak nr_attachmentDelegate;
}

+(NSAttributedString*)attributedStringMutatedForDisplay: (NSAttributedString*)str;
+(CGFloat)heightForAttributedString: (NSAttributedString*)str width: (CGFloat)width;

@property (nonatomic, weak) id attachmentDelegate;
@property (nonatomic, assign) BOOL allowsAddingCustomObjects;

-(void)replaceRange: (UITextRange*)range withObject: (id)object;
-(OATextAttachmentCell*)attachmentCellForPoint: (CGPoint)point fromView: (UIView*)view;

@end

