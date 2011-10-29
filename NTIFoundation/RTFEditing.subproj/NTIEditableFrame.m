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
		
		if(textPosition){
			id attributes = [self attribute: OAAttachmentAttributeName 
								 atPosition: textPosition 
							 effectiveRange: NULL];
			OATextAttachment* attachment = [attributes objectForKey: OAAttachmentAttributeName];
			if(attachment){
				NSLog(@"OATextAttachment %@ was touched at point %@", attachment, NSStringFromCGPoint(p));
				id attachmentCell = [attachment attachmentCell];
				BOOL handled = [self->nr_attachmentDelegate editableFrame: self 
														   attachmentCell: attachmentCell 
														wasTouchedAtPoint: p];
				if(handled){
					return;
				}
				
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
