//
//  NTIEditableFrame.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/22.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <OmniAppKit/OATextAttachment.h>
#import "NTIEditableFrame.h"
#import "NTIFoundation.h"
#import <OmniAppKit/NSAttributedString-OAExtensions.h>
#import "NTITextAttachmentCell.h"
#import <OmniUI/OUITextSelectionSpan.h>
#import <OmniAppKit/OAFontDescriptor.h>
#import <objc/runtime.h>

@interface OUITextSelectionSpan(NTIEditableFrame)
-(OAFontDescriptor*)_secondaryFontDescriptorForInspectorSlice:(OUIInspectorSlice*)inspector;
@end

@implementation OUITextSelectionSpan(NTIEditableFrame)

+(void)load
{
	static dispatch_once_t once_token;
	dispatch_once(&once_token, ^{
		Method originalMethod = class_getInstanceMethod([self class], @selector(fontDescriptorForInspectorSlice:));
		Method newMethod = class_getInstanceMethod([self class], @selector(_secondaryFontDescriptorForInspectorSlice:));
		
		method_exchangeImplementations(originalMethod, newMethod);
	});
}

-(OAFontDescriptor*)_secondaryFontDescriptorForInspectorSlice:(OUIInspectorSlice*)inspector;
{
	OAFontDescriptor* desc = (OAFontDescriptor*)[self.textView attribute:OAFontDescriptorAttributeName inRange:self.range];
	if(desc)
		return desc;
	
	UIFont* font = self.textView.font;
	if(font)
		desc = [[OAFontDescriptor alloc] initWithFont: font];
	
	return desc;
}

@end

@implementation NTIEditableFrame
@synthesize attachmentDelegate=nr_attachmentDelegate;

-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame: frame];
	if(self){
		UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapped:)];
		self.font = [UIFont systemFontOfSize: [UIFont systemFontSize]];
		[self addGestureRecognizer: tap];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	if(self){
		UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapped:)];
		self.font = [UIFont systemFontOfSize: [UIFont systemFontSize]];
		[self addGestureRecognizer: tap];
	}
	return self;
}

//TODO: Figure out if these typingAtributes messages are still needed
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

-(void)removeFromAttachmentCells: (NSAttributedString*)attrText
{
	[attrText eachAttachment: ^(OATextAttachment* attachment, BOOL* stop){
		if([attachment respondsToSelector:@selector(attachmentRenderer)]){
			id cell = [(id)attachment attachmentRenderer];
			if([cell respondsToSelector: @selector(removeEditableFrame:)]){
				[cell removeEditableFrame: self];
			}
		}
	}];
}

-(void)attachToAttachmentCells: (NSAttributedString*)newAttrText
{
	[newAttrText eachAttachment: ^(OATextAttachment* attachment, BOOL* stop){
		if([attachment respondsToSelector:@selector(attachmentRenderer)]){
			id cell = [(id)attachment attachmentRenderer];
			if([cell respondsToSelector: @selector(attachEditableFrame:)]){
				[cell attachEditableFrame: self];
			}
		}
	}];
}

-(void)setAttributedText: (NSAttributedString *)newAttrText
{
	
	[self removeFromAttachmentCells: self.attributedText];
	[self attachToAttachmentCells: newAttrText];
	
	[super setAttributedText: newAttrText];
}

-(void)replaceRange: (UITextRange*)range withObject: (id)object
{
	UITextRange* textRange = (id)range;
	
	if( [object isKindOfClass: [NSString class]] ){
		return [self replaceRange: textRange withText: object];
	}
	
	NSAttributedString* attrString = [NSAttributedString attributedStringFromObject: object];
	
	if(!attrString){
		return;
	}
	
	//TODO: rather that setting the attribute string here maybe we can just call super with our
	//generated string?  That seems like it would be more efficient in general
	NSRange characterRange = [self characterRangeForTextRange: range];
	self.attributedText = [self.attributedText attributedStringByReplacingRange: characterRange
																	  withChunk: attrString];
	[self.delegate textViewDidChange: self];
}

//The characterRangeAtPoint always returns nil in IOS7. Well thats not exactly true, after extensive searching it
//seems like occasionally if you've made a text selection at least once before calling it you can get it to return non nil values.  I've seen
//that happen about 10% of the time and only in text only (non attachment cell) text views.  So here we roll our own using
//the layoutManager and textContainer.  Hopefully they can get the kinks worked out of characterRangeForPoint: soon.
//
//Note this probably isn't a sufficient replacement for the native function.  Empirically it works well for large attachment cells
//and that is really what we need
-(UITextRange*)workingCharacterRangeForPoint: (CGPoint)p
{
	
	//Returns the index of the glyph CLOSEST to the touch.  Note this is not necessarily the glyph that was touched
	NSUInteger gIndex = [self.layoutManager glyphIndexForPoint: p
											   inTextContainer: self.textContainer
								fractionOfDistanceThroughGlyph: NULL];
	if(gIndex == NSNotFound){
		return nil;
	}
	
	//Now get the bounding rect for the glyph we might have touched and see if the point is within it
	CGRect rect = [self.layoutManager boundingRectForGlyphRange: NSMakeRange(gIndex, 1)
												inTextContainer: self.textContainer];
	
	if(!CGRectContainsPoint(rect, p)){
		return nil;
	}
	
	//Ok we actually touched the glyph now we turn the glyph into a UITextRange
	NSUInteger charIdx = [self.layoutManager characterIndexForGlyphAtIndex: gIndex];
	if(charIdx == NSNotFound){
		return nil;
	}
	
	return [self textRangeForCharacterRange: NSMakeRange(charIdx, 1)];
}

-(OATextAttachmentCell*)attachmentCellForPoint:(CGPoint)point fromView :(UIView *)view
{
	//Convert the provided point to our coordinate space
	CGPoint convertedPoint = [self.textInputView convertPoint: point fromView: view];
	
	//UITextRange* range = [self characterRangeAtPoint: convertedPoint]; //Ugh always nil in ios7 GM
	UITextRange* range = [self workingCharacterRangeForPoint: convertedPoint];
	
	return [self attachmentCellForRange: range];
}

-(OATextAttachmentCell*)attachmentCellForRange: (UITextRange*)range
{
	if(!range){
		return nil;
	}
	
	NSRange characterRange = [self characterRangeForTextRange: range];
	
	if( characterRange.location >= self.attributedText.length ){
		return nil;
	}
	
	id attributes = [self.attributedText attributesAtIndex: characterRange.location effectiveRange: NULL];
	OATextAttachment* attachment = [attributes objectForKey: NSAttachmentAttributeName];
	if(attachment){
		return [(id)attachment attachmentRenderer];
	}
	return nil;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

-(UIView *)hitTest: (CGPoint)point withEvent: (UIEvent *)event
{
	//If the point isn't even in our view just call super. Could return nil here?
	UIView* supersResult = [super hitTest: point withEvent: event];
	
	if( !supersResult ){
		return nil;
	}
	
	//Shortcut, if we don't have a delegate or one that responds to our event just call super
	if(	OFISNULL(self->nr_attachmentDelegate) ||
	   ![self->nr_attachmentDelegate respondsToSelector:
			@selector(editableFrame:attachmentCell:wasTouchedAtPoint:)]){
		return supersResult;
	}
	
	
	OATextAttachmentCell* attachmentCell = [self attachmentCellForPoint: point fromView: self];
	if(attachmentCell){
		//If we are editing select the attachment cell so that any editing will replace it.
		if(self.isEditable){
			UITextRange* range = [self workingCharacterRangeForPoint: point];
			[self setSelectedTextRange: range
						   showingMenu: NO];
		}
		
		BOOL handled = [self->nr_attachmentDelegate editableFrame: self
												   attachmentCell: attachmentCell
												wasTouchedAtPoint: point];
			
		if(handled){
			// From the docs the return value should be
			//"The view object that is the farthest descendent the current view and contains point. Returns nil if the point lies completely outside the receiver’s view hierarchy."
			//we want to return the view that represents the attachment we have clicked.  We can't return the tablecell (self) or the editor as that causes those views to perform
			//some action.
			//TODO If we return anything besides nil the row gets touched and the accessory row pops down....
			return nil;
		}
	}
	
	return supersResult;
}

-(void)tapped: (UITapGestureRecognizer*)r
{
	//If we don't have a delegate that responds to attachmentCell:wasTouchedAtPoint
	//there is no point in doing the work
	if( ![self->nr_attachmentDelegate respondsToSelector: 
		 @selector(editableFrame:attachmentCell:wasTouchedAtPoint:)] ){
		return;
	}
	
	CGPoint p = [r locationInView: self.textInputView];
	
	
	//UITextRange* range = [self characterRangeAtPoint: p]; //Ugh always nil in ios7 GM
	UITextRange* range = [self workingCharacterRangeForPoint: p];
	OATextAttachmentCell* attachmentCell = [self attachmentCellForRange: range];
	
	if(attachmentCell){
		//If we are editing select the attachment cell so that any editing will replace it.
		if(self.isEditable){
			[self setSelectedTextRange: range
						   showingMenu: NO];
		}
		
		[self->nr_attachmentDelegate editableFrame: self
									attachmentCell: attachmentCell
								 wasTouchedAtPoint: p];

	}
}

-(void)dealloc
{
	[self removeFromAttachmentCells: self.attributedText];
}

@end
