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

-(void)setTypingAttributes:(NSDictionary *)typingAttributes
{
	NSMutableDictionary* attrs = [NSMutableDictionary dictionaryWithDictionary: typingAttributes];
	if( [attrs objectForKey: kNTIChunkSeparatorAttributeName] ){
		[attrs removeObjectForKey: kNTIChunkSeparatorAttributeName];
	}
	[super setTypingAttributes: attrs];
}

//Highjack the single tap recognizer to test if an ouattachmentcell was touched.  if
//so forward it onto our delegate
- (void)_activeTap:(UITapGestureRecognizer *)r
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

@end


static UITextWritingDirection (*_original_baseWritingDirectionForPosition_inDirection)(id self, SEL _cmd, UITextPosition* position, UITextStorageDirection dir) = NULL;
static void (*_original_setBaseWritingDirection_forRange)(id self, SEL _cmd, UITextWritingDirection dir, UITextRange* range);

static UITextWritingDirection _baseWritingDirectionForPosition_inDirection( 
	id self, SEL _cmd,  UITextPosition* position,  UITextStorageDirection direction ) 
{
	return UITextWritingDirectionLeftToRight;
}

static void _setBaseWritingDirection_forRange( 
	id self, SEL _cmd, UITextWritingDirection writingDirection, UITextRange* range )
{
	if( writingDirection != UITextWritingDirectionLeftToRight ) {
		_original_setBaseWritingDirection_forRange( self, _cmd, writingDirection, range );
	}
}   


static void NTIEditableFramePerformPosing(void) __attribute__((constructor));
static void NTIEditableFramePerformPosing(void)
{
	@autoreleasepool {
	if( [[[UIDevice currentDevice] systemVersion] hasPrefix: @"4"] ) {
		//Not needed on ios4
		return;
	}
	
    Class viewClass = NSClassFromString(@"OUIEditableFrame");
	_original_baseWritingDirectionForPosition_inDirection
		 = (typeof(_original_baseWritingDirectionForPosition_inDirection))
		 	OBReplaceMethodImplementation( 
				viewClass,
				@selector(baseWritingDirectionForPosition:inDirection:),
				(IMP)_baseWritingDirectionForPosition_inDirection);
				
	_original_setBaseWritingDirection_forRange
		= (typeof(_original_setBaseWritingDirection_forRange))
			OBReplaceMethodImplementation(
				viewClass,
				@selector(setBaseWritingDirection:forRange:),
				(IMP)_setBaseWritingDirection_forRange);
	}
}
