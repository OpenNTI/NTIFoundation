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
#import <objc/runtime.h>
#import "NTIHTMLReader.h"
#import <OmniAppKit/OAFontDescriptor.h>
#import <OmniUI/UIScrollView-OUIExtensions.h>
#import <OmniUI/OUIKeyboardNotifier.h>
#import "NSAttributedString-NTIExtensions.h"
#import "NTITextAttachment.h"

static CGFloat rowHeightForAttributedString(NSAttributedString *string, CGFloat width, BOOL multiline)
{
    CGSize size = CGSizeMake(width, 0.0);
    NSStringDrawingOptions options = NSStringDrawingUsesFontLeading;
    if (multiline) {
        options = options | NSStringDrawingUsesLineFragmentOrigin;
    }
    
    CGRect bounds = [string boundingRectWithSize:size
                                         options:options
                                         context:nil];
    return ceil(bounds.size.height + 1);
}


@interface OATextAttachmentCell ()

/**
 * Returns a bounding rectangle which encloses the receiver's attachment content, with the bounding rectangle itself bounded by and relative to a given rectangle. E.g., for determining the rectangle within which user interaction should be restricted.
 * @param rect A rectangle which the attachment bounds are relative to and bounded by.
 @return A bounding rectangle -- relative to and bounded by a given rectangle -- which encloses the cell's attachment content.
 */
- (CGRect)attachmentBoundsInRect:(CGRect)rect;

@end


@interface NTIEditableFrame()<UIGestureRecognizerDelegate>{
@private
	BOOL shouldSelectCells;
}
@property (nonatomic, strong) UIGestureRecognizer* attachmentGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer* attachmentLongPressRecognizer;
@end

@implementation NTIEditableFrame
@synthesize shouldSelectAttachmentCells = shouldSelectCells;

+(UIFont*)defaultFont
{
	Class readerClass = [NTIHTMLReader readerClass];
	
	OAFontDescriptor* fontDescriptor = [[OAFontDescriptor alloc]
										initWithFamily: [readerClass defaultFontFamily]
										size: [readerClass defaultFontSize]];
	
	return [fontDescriptor font];
}

+(NSAttributedString*)attributedStringMutatedForDisplay: (NSAttributedString*)str
{
	//Sometimes we get plain text from the webapp.  When that happens we get passed an attributed
	//string with no attributes (it obviosly doesn't go through the html parser so we don't pick up the default from there)
	//If we have no fonts in the attributed string lets set a default.
	__block BOOL hasFont = NO;
	[str enumerateAttribute: NSFontAttributeName
					inRange: NSMakeRange(0, str.length) options: 0 usingBlock:^(id value, NSRange range, BOOL *stop) {
						hasFont = OFNOTNULL(value);
						*stop = hasFont;
					}];
	
	if(!hasFont){
		UIFont* defaultFont = [self defaultFont];
		if(defaultFont){
			NSMutableAttributedString* withFont = [[NSMutableAttributedString alloc] initWithAttributedString: str];
			[withFont addAttribute: NSFontAttributeName value: [self defaultFont] range: NSMakeRange(0, withFont.length)];
			str = withFont;
		}
	}
	
	return str;
}

+(CGFloat)heightForAttributedString:(NSAttributedString *)str width:(CGFloat)width
{
	str = [self attributedStringMutatedForDisplay: str];
	return rowHeightForAttributedString(str, width, YES);
}

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
	self->_contentOffsetBeforeBecomingFirstResponder = self.contentOffset;
	
	BOOL r = [super becomeFirstResponder];
	
	if(self.allowsAddingCustomObjects){
		UIMenuController* menuController = [UIMenuController sharedMenuController];
		UIMenuItem* item = [[UIMenuItem alloc] initWithTitle: @"Add Whiteboard" action: @selector(addWhiteboard:)];
		NSArray* menuItems = OFISNULL(menuController.menuItems) ? @[item] : [menuController.menuItems arrayByAddingObject: item];
		menuController.menuItems = menuItems;
	}
	
	return r;
}

-(BOOL)resignFirstResponder
{
	BOOL r = [super resignFirstResponder];
	if(r){
		UIMenuController* menuController = [UIMenuController sharedMenuController];
		menuController.menuItems = nil;
	}
	return r;
}

-(void)_commonInit
{
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(didChangeNotification:)
												 name: UITextViewTextDidChangeNotification
											   object: self];
	
	self.attachmentGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapped:)];
	self.attachmentGestureRecognizer.delegate = self;
	[self addGestureRecognizer: self.attachmentGestureRecognizer];
	
	self.attachmentLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(longPressed:)];
	self.attachmentLongPressRecognizer.delegate = self;
	[self addGestureRecognizer: self.attachmentLongPressRecognizer];
	
	//We set a default font here.  This will be the font until attributedString
	//gets set.  Which is good for us.  THis effectively acts as the default
	//for new editors.
	
	self.font = [self defaultFont];
}

//Note this matches the default that we use in the parser if no
//font is specified.
-(UIFont*)defaultFont
{
	return [[self class] defaultFont];
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
	
	newAttrText = [[self class] attributedStringMutatedForDisplay: newAttrText];
	
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
	if (    attachment != nil
		&& [attachment respondsToSelector: @selector(attachmentRenderer)]) {
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

-(void)tapped: (UIGestureRecognizer*)r
{
	//If we don't have a delegate that responds to attachmentCell:wasTouchedAtPoint
	//there is no point in doing the work
	if( ![self.attachmentDelegate respondsToSelector:
		 @selector(editableFrame:attachmentCell:wasTouchedAtPoint:)] ){
		return;
	}
	
	CGPoint p = [r locationInView: self.textInputView];
	
	
	//UITextRange* range = [self characterRangeAtPoint: p]; //Ugh always nil in ios7 GM
	UITextRange* range = [self workingCharacterRangeForPoint: p];
	OATextAttachmentCell* attachmentCell = [self attachmentCellForRange: range];
	
	// Handle attachment tap
	if ( attachmentCell ) {
		[self attachmentCell: attachmentCell
		   wasTouchedAtPoint: p
			   withTextRange: range];
	}
}

- (void)attachmentCell: (OATextAttachmentCell *)attachmentCell
	 wasTouchedAtPoint: (CGPoint)point
		 withTextRange: (UITextRange *)textRange
{
	//If we are editing select the attachment cell so that any editing will replace it.
	if ( self.isEditable ) {
		[self setSelectedTextRange: textRange
					   showingMenu: NO];
	}
	
	if (   self->shouldSelectCells
		&& [self.attachmentDelegate respondsToSelector:
			@selector(editableFrame:attachmentCell:wasSelectedWithRect:)] ) {
			CGRect rect = [self boundsForAttachmentCell: attachmentCell
										  withTextRange: textRange];
			[self.attachmentDelegate editableFrame: self
									attachmentCell: attachmentCell
							   wasSelectedWithRect: rect];
		}
	else {
		[self.attachmentDelegate editableFrame: self
								attachmentCell: attachmentCell
							 wasTouchedAtPoint: point];
	}
}

-(void)longPressed: (UIGestureRecognizer*)sender
{
	if(![self.attachmentDelegate respondsToSelector: @selector(editableFrame:attachmentCell:wasSelectedWithRect:)]){
		return;
	}
	
	CGPoint p = [sender locationInView: self.textInputView];
	
	UITextRange* range = [self workingCharacterRangeForPoint: p];
	OATextAttachmentCell* attachmentCell = [self attachmentCellForRange: range];
	
	if(sender.state == UIGestureRecognizerStateBegan){
		self->shouldSelectCells = YES;
		if([self.attachmentDelegate respondsToSelector: @selector(editableFrame:attachmentCells:selectionModeChangedWithRects:)]){

			[self.attachmentDelegate editableFrame: self
								   attachmentCells: [self attachmentCells]
					 selectionModeChangedWithRects: [self attachmentCellRects]];
		}
	
		if(attachmentCell && self->shouldSelectCells){
			[self.attachmentDelegate editableFrame: self
									attachmentCell: attachmentCell
							   wasSelectedWithRect: [self boundsForAttachmentCell: attachmentCell
																	withTextRange: range]];
		}
	}
	if(sender.state == UIGestureRecognizerStateEnded){
		self->shouldSelectCells = NO;
	}
}

-(void)setShouldSelectAttachmentCells: (BOOL)s
{
	self->shouldSelectCells = s;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return [gestureRecognizer isEqual: self.attachmentGestureRecognizer]
	&& [otherGestureRecognizer isEqual: self.attachmentLongPressRecognizer];
}

-(BOOL)point: (CGPoint)p insideAttachmentCell: (OATextAttachmentCell*)cell withTextRange: (UITextRange*)range
{
	if ( ![cell respondsToSelector: @selector(attachmentBoundsInRect:)] ) {
		return NO;
	}
	
	CGRect attachmentBounds = [self boundsForAttachmentCell: cell withTextRange: range];
	
	return (   p.x >= attachmentBounds.origin.x
			&& p.x <= attachmentBounds.origin.x + attachmentBounds.size.width
			&& p.y >= attachmentBounds.origin.y
			&& p.y <= attachmentBounds.origin.y + attachmentBounds.size.height);
}

-(CGRect)boundsForAttachmentCell: (OATextAttachmentCell*)cell withTextRange: (UITextRange*)range
{
	NSRange glyphRange = [self characterRangeForTextRange:range];
	CGRect glyphRect = [self.layoutManager
						boundingRectForGlyphRange:glyphRange
						inTextContainer:self.textContainer];
	return [cell attachmentBoundsInRect:glyphRect];
}

-(NSArray*)attachmentCells
{
	NSMutableArray* cells = [NSMutableArray new];
	[self.attributedText eachAttachment: ^(OATextAttachment* attachment, BOOL* stop){
		if([attachment respondsToSelector:@selector(attachmentRenderer)]){
			id cell = [(id)attachment attachmentRenderer];
			[cells addObject: cell];
		}
	}];
	
	return [NSArray arrayWithArray: cells];
}

-(NSArray*)attachmentCellRects
{
	NSMutableArray* rects = [NSMutableArray new];

	[self.attributedText enumerateAttribute: NSAttachmentAttributeName
									inRange: NSMakeRange(0, self.attributedText.length)
									options: 0
								 usingBlock:^(id value, NSRange range, BOOL *stop) {
									 UITextRange* textRange = [self textRangeForCharacterRange: range];
									 OATextAttachmentCell* cell = [self attachmentCellForRange: textRange];
									 CGRect rect = [self boundsForAttachmentCell: cell withTextRange: textRange];
									 if(!CGRectEqualToRect(rect, CGRectZero)){
										 [rects addObject: [NSValue valueWithCGRect: rect]];
									 }
								 }];

	return [NSArray arrayWithArray: rects];
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
		return NO;
	}
	else {
        return [super canPerformAction:action
                            withSender:sender];
    }
}

-(id)targetForAction: (SEL)action withSender: (id)sender
{
	if(sender != self && action == @selector(addWhiteboard:)){
		if(self.allowsAddingCustomObjects && OFNOTNULL([self.nextResponder targetForAction: _cmd withSender: sender])){
			return self;
		}
		return nil;
	}
	
	return [super targetForAction: action withSender: sender];
}

-(void)addWhiteboard: (id)sender
{
	//Reforward as us being the sender
	[[UIApplication sharedApplication] sendAction: _cmd to: nil from: self forEvent: nil];
}

#pragma mark gesture recognizer delegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	if([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]){
		return NO;
	}
	return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if(self.attachmentGestureRecognizer != gestureRecognizer && self.attachmentLongPressRecognizer != gestureRecognizer){
		return YES;
	}
	
	if( ![self.attachmentDelegate respondsToSelector:
		  @selector(editableFrame:attachmentCell:wasTouchedAtPoint:)] ){
		return NO;
	}
	
	CGPoint p = [touch locationInView: gestureRecognizer.view];
		
	UITextRange* range = [self workingCharacterRangeForPoint: p];
	OATextAttachmentCell* attachmentCell = [self attachmentCellForRange: range];
	
	//Ignore the tap if not in the bounds of an attachment cell
	return [self point: p insideAttachmentCell: attachmentCell withTextRange: range];
}

-(UIEdgeInsets)insetsForUserDataEditor
{
	CGFloat inset = [[self class] oui_defaultTopAndBottomPadding];
	return UIEdgeInsetsMake(0, 20 - inset, 0, 14 - inset);
}

//MARK: IOS8 workaround for the fact that the cursor isn't scrolled to when
//the line goes below the frame
-(void)didChangeNotification: (NSNotification*)notification
{
	OUITextView* textView = notification.object;
	[textView scrollTextSelectionToVisibleWithAnimation: YES];
}

#pragma mark keyboard handling
//Based on similar functions from UIScrollView-OUIExtensions

//same as omnis adjustForKeyboardHidingWithPreferedFinalBottomContentInset:... but it adjusts the scroll indicator
//insets as well.
- (void)nti_adjustForKeyboardHidingWithPreferedFinalBottomContentInset:(CGFloat)bottomInset animated:(BOOL)animated;
{
	UIEdgeInsets finalInsets = UIEdgeInsetsMake(self.contentInset.top, self.contentInset.left, bottomInset, self.contentInset.right);
	if (animated) {
		[self animateAlongsideKeyboardHiding:^{
			[self setContentInset:finalInsets];
			[self setScrollIndicatorInsets: finalInsets];
		}];
	}
	else {
		[self setContentInset:finalInsets];
		[self setScrollIndicatorInsets: finalInsets];
	}
}

//similar to omnis  -scrollRectToVisibleAboveLastKnownKeyboard:.... differs in these ways.  Adjusts the scroll indicators appropriately.  Also, if the rect is already visible we still adjust the offset so that we can scroll all the way to the bottom, we just don't scroll automatically. We also make sure to only adjust the contentInset by the portion that would be covered by the keyboard.
- (void)nti_scrollRectToVisibleAboveLastKnownKeyboard:(CGRect)rect animated:(BOOL)animated completion:(void (^)(BOOL))completion;
{
	OUIKeyboardNotifier *sharedNotifier = [OUIKeyboardNotifier sharedNotifier];
	CGFloat yPointOfKeyboardTop = [sharedNotifier getMinYOfLastKnownKeyboardInView:self.superview];
	CGFloat yOffset = [self minOffsetToScrollRectToVisible:rect aboveMinY:yPointOfKeyboardTop];
	UIEdgeInsets workableInsets = self.contentInset;
	CGFloat maxY = CGRectGetMaxY(self.frame) - yPointOfKeyboardTop;
	if (workableInsets.bottom < maxY) {
		workableInsets.bottom = maxY;
	}
	
	CGPoint necessaryOffset = self.contentOffset;
	if(yOffset > self.contentOffset.y){
		necessaryOffset = CGPointMake(self.contentOffset.x, yOffset);
	}
	
	
	if (animated) {
		UIViewAnimationOptions options = (sharedNotifier.lastAnimationCurve << 16) | UIViewAnimationOptionBeginFromCurrentState;  // http://macoscope.com/blog/working-with-keyboard-on-ios/  (Dec 20, 2013)
		[UIView animateWithDuration:sharedNotifier.lastAnimationDuration
							  delay:0.0f
							options:options
						 animations:^{
							 [self setContentInset:workableInsets];
							 [self setContentOffset:necessaryOffset];
							 [self setScrollIndicatorInsets: workableInsets];
						 } completion:completion];
	}
	else {
		[self setContentInset:workableInsets];
		[self setContentOffset:necessaryOffset animated:NO];
		if (completion) {
			completion(YES);
		}
	}
}


-(void)dealloc
{
	[self removeFromAttachmentCells: self.attributedText];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UITextViewTextDidChangeNotification
												  object: self];
}

@end
