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

@interface NTIEditableFrame()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIGestureRecognizer* attachmentGestureRecognizer;
@end

@implementation NTIEditableFrame
@synthesize attachmentDelegate=nr_attachmentDelegate;

-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame: frame];
	if(self){
		[self _commonInit];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	if(self){
		[self _commonInit];
	}
	return self;
}

-(BOOL)becomeFirstResponder
{
	BOOL r = [super becomeFirstResponder];
	
	if(self.allowsAddingCustomObjects){
		UIMenuController* menuController = [UIMenuController sharedMenuController];
		UIMenuItem* item = [[UIMenuItem alloc] initWithTitle: @"Add Whiteboard" action: @selector(addWhiteboard:)];
		NSArray* menuItems = OFISNULL(menuController.menuItems) ? @[item] : [menuController.menuItems arrayByAddingObject: item];
		menuController.menuItems = menuItems;
	}
	
	return r;
}

-(void)addWhiteboard: (id)sender
{
	NSLog(@"adding whiteboard");
	if (![sender respondsToSelector: @selector(nextResponder)]) {
		[self addWhiteboard: self];
		return;
	}
	
	id responder = [sender nextResponder];
	if(OFISNULL(responder)){
		NSLog(@"no messages to add whiteboard found in responder chain");
		return;
	}
	else if([responder respondsToSelector: @selector(addWhiteboard:)]){
		NSLog(@"message found, calling addWhiteboard: with obj: %@", sender);
		[responder addWhiteboard: sender];
		return;
	}
	
	[self addWhiteboard: responder];
}

-(void)_commonInit
{
	self.attachmentGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapped:)];
	self.attachmentGestureRecognizer.delegate = self;
	[self addGestureRecognizer: self.attachmentGestureRecognizer];
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

-(void)detachFromOldFrames: (NSAttributedString*)newAttrText
{
	[newAttrText eachAttachment: ^(OATextAttachment* attachment, BOOL* stop){
		if([attachment respondsToSelector:@selector(attachmentRenderer)]){
			id cell = [(id)attachment attachmentRenderer];
			if([cell respondsToSelector: @selector(detachAllEditableFrames)]){
				[cell detachAllEditableFrames];
			}
		}
	}];
}
-(void)setAttributedText: (NSAttributedString *)newAttrText
{
	//TODO: I'm pretty sure there is a bug here.  If we are in a cell that gets reused
	//simply resetting the attributed text doesn't seem to do the trick if there are things
	//like video attachment cells.  Things go haywire (videos don't always show up, sometimes it wont
	//take touches, etc).  This is probably an indication of a leak or misunderstanding in how textkit works
	[self removeFromAttachmentCells: self.attributedText];
	[self detachFromOldFrames: newAttrText];
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

-(OATextAttachmentCell*)attachmentCellForPoint:(CGPoint)point
{
	//UITextRange* range = [self characterRangeAtPoint: point]; //Ugh always nil in ios7 GM
	UITextRange* range = [self workingCharacterRangeForPoint: point];
	return[self attachmentCellForRange: range];
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

#pragma mark UIResponder

- (BOOL)canPerformAction:(SEL)action
              withSender:(id)sender
{
    if (action == @selector(cut:)) {
        return self.isEditable;
    }
    if (action == @selector(paste:)) {
        return self.isEditable;
    }
    if (action == @selector(addWhiteboard:)) {
		return self.allowsAddingCustomObjects;
	}
	else {
        return [super canPerformAction:action
                            withSender:sender];
    }
}

#pragma mark gesture recognizer delegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if(self.attachmentGestureRecognizer != gestureRecognizer){
		return YES;
	}
	
	if( ![self->nr_attachmentDelegate respondsToSelector:
		  @selector(editableFrame:attachmentCell:wasTouchedAtPoint:)] ){
		return NO;
	}
	
	CGPoint p = [touch locationInView: gestureRecognizer.view];
	
	//UITextRange* range = [self characterRangeAtPoint: p]; //Ugh always nil in ios7 GM
	UITextRange* range = [self workingCharacterRangeForPoint: p];
	OATextAttachmentCell* attachmentCell = [self attachmentCellForRange: range];
	
	return OFNOTNULL(attachmentCell);
}

-(UIEdgeInsets)insetsForUserDataEditor
{
	CGFloat inset = [[self class] oui_defaultTopAndBottomPadding];
	return UIEdgeInsetsMake(0, 20 - inset, 0, 14 - inset);
}

@end
