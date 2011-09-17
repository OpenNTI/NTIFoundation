//
//  NTIWebView.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/21.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIWebView.h"
#import "TestAppDelegate.h"
#import "NTIAppPreferences.h"
#import "NTINoteView.h"
#import "NTINoteLoader.h"
#import "UIWebView-NTIExtensions.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import "NTINoteSavingDelegates.h"
#import "NSString-NTIExtensions.h"
#import "NSArray-NTIExtensions.h"
#import "NTIUtilities.h"
#import "OQColor-NTIExtensions.h"

NSString* const NTINotificationWebViewFontDidChangeName = @"NTINotificationWebViewFontDidChangeName";

@implementation NTIWebView
static id fc( id o NS_CONSUMED ) //shut the analyzer up
{
	return o;
}
- (void)installCustomEdit
{
	NSArray* menus = [NSArray arrayWithObjects: 
					  fc([[UIMenuItem alloc] initWithTitle: @"Remove Highlight" 
								 action: @selector(removeHighlight:)]),
					  fc([[UIMenuItem alloc] initWithTitle: @"Define" 
								 action: @selector(define:)]),
					  fc([[UIMenuItem alloc] initWithTitle: @"Highlight" 
												 action: NWA_CREATE_HIGHLIGHT]),
					  fc([[UIMenuItem alloc] initWithTitle: @"Note"
												 action: NWA_CREATE_NOTE]),
					  nil];
	[menus makeObjectsPerformSelector: @selector(autorelease)];
	[UIMenuController sharedMenuController].menuItems = menus;
}

-(id)initWithCoder: (id)c
{
	self = [super initWithCoder: c];
	scrollDelegates = [[NSMutableArray alloc] initWithCapacity: 2];
	overlayedFormControllers = [[NSMutableArray alloc] initWithCapacity:2];
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self installCustomEdit];
	//Create the dictionary popover
	popoverViewController = [[UIViewController alloc] init];
	popoverView = [[UIWebView alloc] init];
	[popoverViewController setView: popoverView];
	popoverController = [[UIPopoverController alloc]
							initWithContentViewController: popoverViewController];
	[popoverController setPopoverContentSize: CGSizeMake( 320, 400 )];
	[popoverView setDelegate: (id)self];
}


-(BOOL)canBecomeFirstResponder
{
	return YES;
}

- (BOOL) becomeFirstResponder
{
	BOOL result = [super becomeFirstResponder];
	if( result ) {
		[self installCustomEdit];
	}
	return result;
}

- (BOOL) resignFirstResponder
{
	BOOL result = [super resignFirstResponder];
	//When we resign, we don't want to remove our menu. We can still
	//get tapped on without being the responder. If someone else becomes
	//responder and wants the menu, they'll get it. And when we become first
	//again, we get it.
	return result;
}

-(void)overlayFormController: (NTIWebOverlayedFormController*)formController
{
	[self->overlayedFormControllers addObject: formController];
	[[self scrollView] addSubview: [formController view]];
	[self addScrollDelegate: formController];
}

-(void)clearOverlayedFormControllers
{
	for( id cont in self->overlayedFormControllers ) {
		[[cont view] removeFromSuperview];
		[self removeScrollDelegate: cont];
	}
	[self->overlayedFormControllers removeAllObjects];
}

-(id)showNotes
{
    [self callFunction: @"NTIShowNotes"];
	return self;
}

-(id)hideNotes
{
	[self callFunction: @"NTIHideNotes"];
	return self;
}

-(id)showHighlights
{
    [self callFunction: @"NTIShowHighlights"];
	return self;
}

-(id)hideHighlights
{
    [self callFunction: @"NTIHideHighlights"];
	return self;
}

-(NSString*)ntiPrevHref
{
	return [self callFunction: @"NTIGetPrevHref"];
}

-(NSString*)ntiNextHref
{
	return [self callFunction: @"NTIGetNextHref"];
}

-(NSString*)changeFontSize: (NSString*)direction
{
	id result = [self callFunction: direction];
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName: NTINotificationWebViewFontDidChangeName
	 object: self];
	 return result;
}

- (NSString*)increaseFontSize
{
	return [self changeFontSize: @"NTIIncreaseFontSize"];
}

- (NSString*)decreaseFontSize
{
	return [self changeFontSize: @"NTIDecreaseFontSize"];
}

- (void)setFontSize: (NSString*)size
{
	[self callFunction: @"NTISetFontSize" withString: size];
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName: NTINotificationWebViewFontDidChangeName
	 object: self];
}

-(id)shouldUseMathFace: (BOOL)use
{
	[self callFunction: @"NTISetShouldUseMathFace" withBool: use];
	return self;
}

- (NSString*)serifFont
{
	NSString* result = [self setFontFace: @"Palatino"];
	[self callFunction: @"NTISetSerifMath"];
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName: NTINotificationWebViewFontDidChangeName
	 object: self];
	return result;
}

- (NSString*)sansSerifFont
{
	NSString* result = [self setFontFace: @"Open Sans"];
	[self callFunction: @"NTISetSansSerifMath"];
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName: NTINotificationWebViewFontDidChangeName
	 object: self];
	return result;
}

- (NSString*)setFontFace: (NSString*)face
{
	[self callFunction: @"NTISetFontFace" withString: face];
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName: NTINotificationWebViewFontDidChangeName
	 object: self];
	return face;
}

-(void)setHighlightColor: (OQColor*)color
{
	[self callFunction: @"NTIChangeHighlightColor" withString: color.cssString];	
}

- (CGPoint)lastWindowTouchPoint
{
	return [((NTIWindow*)[self window]) tapLocation];
}

- (CGPoint)lastTouchPoint
{
	return [self convertPoint: [self lastWindowTouchPoint] fromView: [self window]];
}

- (void)define: (id)sender
{
	NSString* toDefine = [self selectedToken];
	
	CGRect rect;
	rect.origin.x = [self lastTouchPoint].x;
	rect.origin.y = [self lastTouchPoint].y;
	rect.size.width = [self selectionWidth];
	rect.size.height = [self selectionHeight];

	
	//Choose iOS 5 view if present and we don't 
	//have a specific definition (TODO)
	id refClass = getClass_UIReferenceLibraryViewController();
	if(		refClass
	   &&	[refClass dictionaryHasDefinitionForTerm: toDefine] ) {
		popoverController.contentViewController = [[[refClass alloc] 
													initWithTerm: toDefine] 
												   autorelease];
		[[TestAppDelegate sharedDelegate]
		 presentPopover: popoverController
		 fromRect: rect inView: self
		 permittedArrowDirections: UIPopoverArrowDirectionAny
		 animated: YES];
		return;
	}
	

	//Load the results
	popoverController.contentViewController = popoverViewController;
	[popoverView loadRequest: [NSURLRequest requestWithURL: 
							   [NSURL URLWithString: @"about:blank"]]];
	
	[popoverView loadRequest: [NSURLRequest requestWithURL: 
								[NSURL URLWithString: toDefine
									   relativeToURL: [[NTIAppPreferences prefs] dictionaryURL]]]];
	

	//We might like to clear the selection now, but we can't. We can
	//clear it from the DOM (using collapse() or empty()), but that doesn't cause the highlighting to 
	//go away--and then the UIWebView and DOM are out of sync. 
	//Instapaper has the same 'issue'
	//[self stringByEvaluatingJavaScriptFromString: @"window.getSelection().collapse();"] );
	[[TestAppDelegate sharedDelegate] 
	 presentPopover: popoverController
	 fromRect: rect 
	 inView: self
	 permittedArrowDirections: UIPopoverArrowDirectionAny 
	 animated: YES];
	 
}

#pragma mark - 
#pragma mark Highlights

-(void)highlight: (id)sender
{
	[self callFunction: @"NTIHighlightSelection"];
}

- (void)removeHighlight: (id)sender
{
	[self callFunctionNeedingHTMLWindowPoint: @"NTIRemoveHighlightAt"
							 withWindowPoint: [self lastWindowTouchPoint]];
}

-(BOOL)pointWasOnHighlight: (CGPoint)windowPoint
{
	return [[self callFunctionNeedingHTMLWindowPoint: @"NTIIsPointHighlighted"
									 withWindowPoint: windowPoint] 
			javascriptBoolValue];
}

-(BOOL)pointWasOnAnnotationOrInteresting: (CGPoint)windowPoint
{
	return [[self callFunctionNeedingHTMLWindowPoint: @"NTIIsPointHighlightedOrInteresting"
									 withWindowPoint: windowPoint] 
			javascriptBoolValue];	
}

-(BOOL)touchWasOnHighlight: (UITouch*)windowTouch
{
	return [self pointWasOnHighlight: [windowTouch locationInView: nil]];
}

-(BOOL)touchWasOnHighlight
{
	return [self pointWasOnHighlight: [self lastWindowTouchPoint]];
}

-(BOOL)pointWasOnInlineNote: (CGPoint)windowPoint
{
	return [[self callFunctionNeedingHTMLWindowPoint: @"NTIIsPointInlineNote"
									 withWindowPoint: windowPoint]
			javascriptBoolValue];
}

-(BOOL)touchWasOnInlineNote: (UITouch*)windowTouch
{
	return [self pointWasOnInlineNote: [windowTouch locationInView: nil]];
}

-(BOOL)touchWasOnInlineNote
{
	return [self pointWasOnInlineNote: [self lastWindowTouchPoint]];
}

- (BOOL) wasSingleTouch: (UIEvent*) event
{
	NSSet* touches = [event allTouches];
	if( 	[event type] == UIEventTypeTouches
	   &&	((		[touches count] == 1
			  &&	[[touches anyObject] tapCount] == 1)
			 || [touches count] == 0) ) {
	   return YES;
	}
	return NO;
}

-(BOOL)wantsEvent: (UIEvent*) event
		  atPoint: (CGPoint)point 
{
	BOOL result = YES;
	if(		[self wasSingleTouch: event]
	   &&	[[[event allTouches] anyObject] phase] == UITouchPhaseBegan ) {
		result = [self wantsTapAtPoint: point];
	}
	return result;
}

-(BOOL)wantsTapAtPoint: (CGPoint)point
{
	CGPoint viewPoint = [self convertPoint: point toView: nil];
	return [self pointWasOnAnnotationOrInteresting: viewPoint];
}

-(BOOL)wantsTapAtPointToIntercept: (CGPoint)point
{
	CGPoint winPoint = [self convertPoint: point toView: nil];
	BOOL onInteresting = [self pointWasOnHighlight: winPoint];
	if( !onInteresting ) {
		onInteresting = [self pointWasOnInlineNote: winPoint];
	}
	return onInteresting;
}

-(void)interceptTapAtPoint: (CGPoint)localPoint
{
	UIMenuController* menu = [UIMenuController sharedMenuController];
	CGRect rect = CGRectMake( localPoint.x, localPoint.y, 15, 15 );
	//In order for the menu to show, there must be a first responder.
	//Since they touched us, we can assume it should be us. iOS5 is more strict
	//about that.
	[self becomeFirstResponder];
	[menu setTargetRect: rect inView: self];
	[menu setMenuVisible: YES animated: YES];

}

/**
 * We capture one-touch events on annotated text to show
 * the edit menu to remove a highlight without having to select it.
 */
-(UIView*)hitTest: (CGPoint)point
		withEvent: (UIEvent*)event
{

	id result = nil;
	BOOL wasSingleTouch = [self wasSingleTouch: event];
	BOOL onInteresting = NO;
	if( wasSingleTouch ) {
		CGPoint winPoint = [self convertPoint: point toView: nil];
		onInteresting = [self pointWasOnHighlight: winPoint];
		if( !onInteresting ) {
			onInteresting = [self pointWasOnInlineNote: winPoint];
		}
	}
	if( onInteresting ) {
		result = self;
	}
	else {
		result = [super hitTest: point withEvent: event];
	}
	return result;
}

-(void)touchesEnded: (NSSet*)touches withEvent: (UIEvent*)event 
{
	//This SHOULD only get called over annotated text (because otherwise
	//we fail the hit test). Verify before showing the menu.
	BOOL show = NO;
	NSUInteger touchCount = [touches count];
	if( touchCount == 1 ) {
		id theTouch = [touches anyObject];
		if( [theTouch tapCount] == 1 ) {
			BOOL onInteresting = [self touchWasOnHighlight: theTouch];
			if( !onInteresting ) {
				onInteresting = [self touchWasOnInlineNote: theTouch];
			}
			if( onInteresting ) {
				show = YES;
			}
		}
	}

	if( show ) {
		[self interceptTapAtPoint: [[touches anyObject] locationInView: self]];
	}
	else {
		[super touchesEnded: touches withEvent: event];
	}
}

-(BOOL)canPerformAction: (SEL)action withSender: (id)sender
{
	//Only show define if there's one word selected
	if( action == @selector(define:) && [self selectedToken] ) {
		return YES;
	}
	BOOL touchWasHL = [self touchWasOnHighlight];
	BOOL touchWasNote = [self touchWasOnInlineNote];
	//Highlight and unhighlight are mutually exclusive
	if(		action == @selector(removeHighlight:)
	   &&	[[NTIAppPreferences prefs] highlightsEnabled]
	   &&	touchWasHL ) {
		return YES;
	}
	if(		action == NWA_CREATE_HIGHLIGHT
	   &&	[[NTIAppPreferences prefs] highlightsEnabled]
	   &&	!touchWasHL && !touchWasNote
	   &&	[[self selectedText] length] > 0 ) {
		return YES;
	}
	
	//TODO: If we let the super enable copy: (the only action it would enable),
	//then we can get AT MOST one item in the menu (and if two are possible, we
	//get a 'more...' menu). OTOH, if we disable
	//copy:, then we can have several actions at the top level. Therefore,
	//we bypass super and go on to the next responder.
	return [self.nextResponder canPerformAction: action withSender: sender];
}

- (void)webView: (UIWebView*)view didFailLoadWithError: (NSError *)error
{
	NSLog( @"Broken: %@", error);
}

- (BOOL)webView: (UIWebView *)webView shouldStartLoadWithRequest: (NSURLRequest*)request
navigationType: (UIWebViewNavigationType)navigationType
{
	if( [[[request URL] absoluteString] hasPrefix: 
		 [[[NTIAppPreferences prefs] dictionaryURL] absoluteString]] ) {
		return YES;
	}
	[[UIApplication sharedApplication] openURL: [request URL]];
	return NO;
}

#pragma mark Scrolling
-(id)addScrollDelegate: (id)delegate
{
	if( delegate ) {
		[scrollDelegates addObject: delegate];
	}
	return self;
}

-(void)removeScrollDelegate: (id)delegate
{
	[scrollDelegates removeObject: delegate];
}


-(void)didRotateFromInterfaceOrientation: (UIInterfaceOrientation)old
{
	//FIXME: Need to move these to their correct coordinates!
	if( [overlayedFormControllers count] ) {
		NSLog( @"Need to move overlays to correct new location." );
	}
	//The transform for this view or our superview is not correct.
	/*
	for( UIView* overlay in overlays ) {
		overlay.layer.transform = self.superview.layer.transform;
	}
	*/
}

- (void)scrollViewDidScroll: (UIScrollView*)sv
{
	if( [[NTIWebView superclass] instancesRespondToSelector: _cmd] ) {
		[super scrollViewDidScroll: sv];
	}
	
	for( id del in scrollDelegates ) {
		if( [del respondsToSelector: _cmd] ) {
			[del scrollViewDidScroll: sv];
		}		
	}
}

-(UIView*)viewForZoomingInScrollView: (UIScrollView*)scrollView
{
//	UIView* view = [overlays objectAtIndex: 1];
//	//CANNOT access scrollView.zoomScale here!
//	NSLog( @"View: %@ center %@ ", view, NSStringFromCGPoint( view.center ) );
//	return [overlays objectAtIndex: 1];
	return nil;
}
//
//-(void)scrollViewDidEndZooming: (UIScrollView*)sv withView: (UIView*)scrolledView atScale: (float)zoom
//{
//	UIView* view = [overlays objectAtIndex: 1];
//	NSLog( @"View: %@ center %@ scale %f offset %@",
//		  view, NSStringFromCGPoint( view.center ), zoom,
//		  NSStringFromCGPoint( sv.contentOffset ) );
//	
//}
-(void)scrollViewWillBeginZooming: (UIScrollView*)sv withView: (UIView*)view
{
	if( [[self superclass] instancesRespondToSelector: _cmd] ) {
		[super scrollViewWillBeginZooming: sv withView: view];
	}
	self->overlayBeginOffset = sv.contentOffset;
	self->overlayBeginZoom = sv.zoomScale;
	
//	//Store everything back at its HTML coordinates
//	for( UIView* overlay in overlays ) {
//		CGRect frame = overlay.frame;
//		frame.origin = [self htmlPointFromViewPoint: frame.origin];
//		overlay.frame = frame;
//	}
	
}
//
//-(void)scrollViewDidEndZooming: (UIScrollView*)sv withView: (UIView*)view atScale: (float)zoom
//{
//	if( [[self superclass] instancesRespondToSelector: _cmd] ) {
//		[super scrollViewDidEndZooming: sv withView: view atScale: zoom];
//	}
//
//	CGPoint offset = [sv contentOffset];
//	CGPoint delta = CGPointMake( offset.x - overlayBeginOffset.x,
//								offset.y - overlayBeginOffset.y );
//	CGFloat distance = [NTIWindow distanceBetween: offset and: overlayBeginOffset];
//	delta.x = distance;
//	delta.y = distance;
//	for( UIView* overlay in overlays ) {
////		CGRect frame = [overlay frame];
////		frame.origin.x += delta.x;
////		frame.origin.y += delta.y;
////		[overlay setFrame: frame];
//////		overlay.center = [self viewPointFromHTMLPoint: overlay.center];
//////		CGRect frame = overlay.frame;
//////		frame.origin = [self viewPointFromHTMLPoint: frame.origin];
//////		overlay.frame = frame;
////		//overlay.center = [sv convertPoint: overlay.center fromView: overlay];
////		
////		
////		CGRect bounds = [overlay frame];
////		bounds.size.height = bounds.size.height * zoom;
////		bounds.size.width = bounds.size.width * zoom;
////		[overlay setFrame: bounds];
//		overlay.layer.contentsScale = zoom; //view.layer.contentsScale;
//		
////		CATransform3D tx = view.layer.transform;
//		CATransform3D tx = CATransform3DScale( overlay.layer.transform, zoom, zoom, 1.0 );
//		overlay.layer.transform = tx;
//		//[overlay.layer setValue: [NSNumber numberWithFloat: zoom] forKeyPath: @"transform.scale"];
//		//overlay.layer.position = view.layer.position;
//		//overlay.layer.anchorPoint = CGPointZero;
//		
//		[overlay.layer setNeedsLayout];
//		[overlay setNeedsDisplay];
//	}
//	
//	NSLog( @"C: %f %@", zoom, NSStringFromCGPoint( [sv contentOffset] ) );

//}
//
//-(void)scrollViewDidZoom: (UIScrollView*)sv
//{
//	if( [[self superclass] instancesRespondToSelector: _cmd] ) {
//		[super scrollViewDidZoom: sv];
//	}
//	
//	for( id del in scrollDelegates ) {
//		if( [del respondsToSelector: @selector(_cmd:)] ) {
//			[del scrollViewDidZoom: sv];
//		}		
//	}
//	
////	CGFloat zoom = sv.zoomScale;
////	CGFloat zoomDelta = zoom - self->overlayBeginZoom;
////	CGPoint offset = [sv contentOffset];
////	CGPoint delta = CGPointMake( offset.x - overlayBeginOffset.x,
////								offset.y - overlayBeginOffset.y );
////	delta.x *= zoom;
////	delta.y *= zoom;
////	for( id overlay in overlays ) {
////		CGRect bounds = [overlay frame];
////		bounds.size.height += bounds.size.height * zoomDelta;
////		bounds.size.width += bounds.size.width * zoomDelta;
////		bounds.origin.x += delta.x;
////		bounds.origin.y += delta.y;
////		[overlay setFrame: bounds];
////	}
////	
////	NSLog( @"C: %f %@", zoom, NSStringFromCGPoint( [sv contentOffset] ) );	
////
////	self->overlayBeginOffset = sv.contentOffset;
////	self->overlayBeginZoom = sv.zoomScale;
//	
//}

- (void)dealloc
{
	[popoverController release];
	[popoverViewController release];
	[popoverView release];
	[scrollDelegates release];
	[overlayedFormControllers release];
	[super dealloc];
}

@end
