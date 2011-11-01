//
//  NTIEditableFrame.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/22.
//  Copyright (c) 2011 NextThought. All rights reserved.
//
#import "OmniUI/OUIEditableFrame.h"
#import <OmniAppKit/OATextAttachment.h>
#import "NTIEditableFrame.h"
#import "OmniUI/OUEFTextRange.h"
#import "NTIFoundation.h"

@interface OUIEditableFrame(NTIActiveTapExtensions)
- (void)_activeTap:(UITapGestureRecognizer *)r;
@end

@implementation NTIEditableFrame
@synthesize attachmentDelegate=nr_attachmentDelegate;

-(NSDictionary*)typingAttributes
{
	NSMutableDictionary* attrs = [NSMutableDictionary dictionaryWithDictionary: [super typingAttributes]];
	if( [attrs objectForKey: kNTIChunkSeparatorAttributeName] ){
		[attrs removeObjectForKey: kNTIChunkSeparatorAttributeName];
	}
	return attrs;
}

-(void)setTypingAttributes: (NSDictionary*)typingAttributes
{
	NSMutableDictionary* attrs = [NSMutableDictionary dictionaryWithDictionary: typingAttributes];
	if( [attrs objectForKey: kNTIChunkSeparatorAttributeName] ){
		[attrs removeObjectForKey: kNTIChunkSeparatorAttributeName];
	}
	[super setTypingAttributes: attrs];
}

-(void)replaceRange: (OUEFTextRange*)range withObject: (id)object
{
	UITextRange* textRange = (id)range;
	
	if( [object isKindOfClass: [NSString class]] ){
		return [self replaceRange: textRange withText: object];
	}
	
	NSAttributedString* attrString = nil;
	
	if( [object isKindOfClass: [NSAttributedString class]]){
		attrString = object;
	}
	else if( [object respondsToSelector: @selector(attachmentCell)] ){
		attrString = [NSAttributedString attributedStringFromObject: object];
	}
	
	if(!attrString){
		return;
	}
	
	//We are going to replace the selectedRange so we need to know how to wrap our string.
	//If we are at the start we have our string than a separator
	BOOL leading = YES;
	BOOL following = YES;
	
	leading = ![textRange.start isEqual: [self beginningOfDocument]];
	following = ![textRange.end isEqual: [self endOfDocument] ];
	
	//Note:  We don't check to see if what we are replacing is immediatly proceeded or followed by
	//a separator.  We assume we can handle the case of two separators in a row
	attrString = [attrString attributedStringAsChunkWithLeadingSeparator: leading
														  andTrailingSeparator: following];
	
	//TODO do we need to save off and restore typingAttributes here?
	NSMutableAttributedString* fullString = [[NSMutableAttributedString alloc] 
											 initWithAttributedString: [self attributedText]];
	[fullString replaceCharactersInRange: range.range withAttributedString: attrString];
	[self setAttributedText: fullString];

}

-(OATextAttachmentCell*)attachmentCellForPoint:(CGPoint)point fromView :(UIView *)view
{
	//Convert the provided point to our coordinate space
	CGPoint convertedPoint = [self convertPoint: point fromView: view];
	
	UITextPosition* textPosition = [self tappedPositionForPoint: convertedPoint];
	
	if(textPosition){
		id attributes = [self attribute: OAAttachmentAttributeName 
							 atPosition: [self positionFromPosition: textPosition offset: -1] 
						 effectiveRange: NULL];
		OATextAttachment* attachment = [attributes objectForKey: OAAttachmentAttributeName];
		if(attachment){
			NSLog(@"OATextAttachment %@ was touched at point %@", attachment, NSStringFromCGPoint(convertedPoint));
			id attachmentCell = [attachment attachmentCell];
			
			return attachmentCell;
		}
	}
	return nil;
}

//Highjack the single tap recognizer to test if an ouattachmentcell was touched.  if
//so forward it onto our delegate
-(void)_activeTap: (UITapGestureRecognizer*)r
{
	//If we don't have a delegate that responds to attachmentCell:wasTouchedAtPoint
	//there is no point in doing the work
	if( ![self->nr_attachmentDelegate respondsToSelector: 
		 @selector(editableFrame:attachmentCell:wasTouchedAtPoint:)] ){
		[super _activeTap: r];
		return;
	}
	
	if(r.numberOfTapsRequired == 1){
		CGPoint p = [r locationInView:self];
		UITextPosition* textPosition = [self tappedPositionForPoint: p];
		OATextAttachmentCell* attachmentCell = [self attachmentCellForPoint: p fromView: self];
		
		if(attachmentCell){			
			//We select the attachment cell so that any editing will replace it.
			[self setSelectedTextRange: [self textRangeFromPosition: textPosition 
														 toPosition: [self positionFromPosition: textPosition offset:1]] 
						   showingMenu: NO];
			
			BOOL handled = [self->nr_attachmentDelegate editableFrame: self 
													   attachmentCell: attachmentCell 
													wasTouchedAtPoint: p];
			if(handled){
				return;
			}
		}
	}
	[super _activeTap: r];
}

#pragma mark - Writing Direction
//Omni no longer crashes on these selectors, but they do log
//large stacks, which are annoying and not helpful to us.
//We override to stop that.

-(UITextWritingDirection)baseWritingDirectionForPosition: (UITextPosition*)position
											 inDirection: (UITextStorageDirection)direction
{
	OBFinishPortingLater( "Stop ignoring writing direction" );
	return UITextWritingDirectionNatural;
}

-(void)setBaseWritingDirection: (UITextWritingDirection)writingDirection
					  forRange: (UITextRange*)range
{
	OBFinishPortingLater( "Stop ignoring writing direction" );
}

@end
