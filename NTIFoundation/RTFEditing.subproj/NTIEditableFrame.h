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

@interface NSObject(NTI_EDITABLE_FRAME_OBJECTS)
-(void)addWhiteboard:(id)sender;
@end

@class NTIEditableFrame;
//@interface NTIEditableFrameTextAttachmentCellDelegate
//-(BOOL)editableFrame: (NTIEditableFrame*)editableFrame 
//	  attachmentCell: (OATextAttachmentCell*) attachmentCell
//   wasTouchedAtPoint: (CGPoint)point;
//@end
@protocol NTIEditableFrameTextAttachmentCellDelegate <NSObject>
@optional
-(BOOL)editableFrame: (NTIEditableFrame*)editableFrame
	  attachmentCell: (OATextAttachmentCell*)attachmentCell
   wasTouchedAtPoint: (CGPoint)point;

-(BOOL)editableFrame: (NTIEditableFrame*)editableFrame
	  attachmentCell: (OATextAttachmentCell*)attachmentCell
 wasSelectedWithRect: (CGRect)rect;

-(void)editableFrame: (NTIEditableFrame*)editableFrame
	 attachmentCells: (NSArray*)cells
selectionModeChangedWithRects: (NSArray*)rects;

@end

/**
 * Extend the OUITextView with some helpful messages (particularily around attachment handling)
 */
@interface NTIEditableFrame : OUITextView

+(NSAttributedString*)attributedStringMutatedForDisplay: (NSAttributedString*)str;
+(CGFloat)heightForAttributedString: (NSAttributedString*)str width: (CGFloat)width;

@property (nonatomic, weak) id<NTIEditableFrameTextAttachmentCellDelegate> attachmentDelegate;
@property (nonatomic, assign) BOOL allowsAddingCustomObjects;
@property (nonatomic, assign) BOOL shouldSelectAttachmentCells;
@property (nonatomic, assign) CGPoint contentOffsetBeforeBecomingFirstResponder;

-(void)replaceRange: (UITextRange*)range withObject: (id)object;
-(OATextAttachmentCell*)attachmentCellForPoint: (CGPoint)point fromView: (UIView*)view;

@end

