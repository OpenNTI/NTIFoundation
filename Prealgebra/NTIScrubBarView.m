//
//  NTIScrubBarView.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/18.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIScrubBarView.h"
#import "NTINavigationParser.h"
#import "NTIWindow.h"
#import "WebAndToolController.h"
#import "NTIWebView.h"
#import "NTIAppPreferences.h"
#import <QuartzCore/QuartzCore.h>

#define TAG_ACC_VIEW_LABEL 1
#define SECTION_INSET 10
#define SECTION_WIDTH 10
#define VERT_NUM_PAGES 50

@interface NTIScrubBarView()
-(void)contextualMenuAction: (NSNotification*)n;
-(void)defaultsChanged: (id)s;
@end

@interface NSObject(NTIScrubBarViewActions)
-(void)navigationItemSelected:(id)i percent:(CGFloat)f;
@end

@implementation NTIScrubBarAccessoryView

//-(void)drawRect: (CGRect)rect
//{
//	[super drawRect: rect];
//	CGContextRef context = UIGraphicsGetCurrentContext();
//	CGContextSetFillColorWithColor( context, [UIColor whiteColor].CGColor );//  self.backgroundColor.CGColor );
//	UIRectFrameUsingBlendMode( self.bounds, kCGBlendModeLuminosity );
//}
@end

@implementation NTIScrubBarAccessoryPointerView 

-(void)drawRect: (CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath( context );
	UIColor* color = [UIColor colorWithRed: 0.456f
									 green: 0.509f
									  blue: 0.587f
									 alpha: 1.000f];
	
	CGContextSetFillColorWithColor( context, [color CGColor] );
	CGContextSetStrokeColorWithColor( context, [color CGColor] );
	CGContextSetLineJoin( context, kCGLineJoinRound );
	CGContextSetLineCap( context,  kCGLineCapRound );
	//TODO: An arc at the end?
	CGContextMoveToPoint( context, self.bounds.size.width, 0 );
	CGContextAddLineToPoint( context, 0, self.bounds.size.height / 2);
	CGContextAddLineToPoint( context, self.bounds.size.width, self.bounds.size.height );
	CGContextClosePath( context );
	//CGContextFillPath( context );
	CGContextDrawPath( context, kCGPathFillStroke );
//	UIRectFrame( self.bounds );
}

@end

@implementation NTIScrubBarView

@synthesize delegate, controller;

+(BOOL)dots
{
	return [[NTIAppPreferences prefs] scrubBarDots];
}

-(CGFloat)sectionInset
{
	return [NTIScrubBarView dots] ? 0 : 0;
}

-(CGFloat)sectionWidth
{
	return [NTIScrubBarView dots] ? 2 * SECTION_WIDTH: 15;
}

-(CGFloat)sectionSep
{
	return [NTIScrubBarView dots] ? 4 : 2;
}

-(id)initWithCoder: (id)c
{
	self = [super initWithCoder: c];
	UINib* accNib = [UINib nibWithNibName: @"ScrubBarAccessory" bundle: nil];
	self->accView = [[[accNib instantiateWithOwner: self options: nil] objectAtIndex: 0] retain];
	self->accView.hidden = YES;
	self->accView.userInteractionEnabled = NO;
	
	self->accView.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
	self->accView.layer.shadowOpacity = 0.65f;
	self->accView.layer.cornerRadius = 10;
	self->accView.layer.shadowOffset = CGSizeMake( 2, 2 );
	self->accLabel = (id)[accView viewWithTag: 1];

	[NTIWindow addTapAndHoldObserver: self
							selector: @selector(contextualMenuAction:) 
							  object: nil];

	self->displayForced = NO;
	[[NSNotificationCenter defaultCenter]
	 addObserver: self 
	 selector: @selector(defaultsChanged:) 
	 name: NSUserDefaultsDidChangeNotification
	 object:nil];
	
	return self;
}

-(void)defaultsChanged: (id)_
{
	//TODO: Scroll position
	//We may be called on the background web thread, so we queue the 
	//update for the next display cycle. (Doing it from the web thread
	//can crash.) Note that we also get this notification during 
	//startup when defaults are registered.
	[self setNeedsRedisplay];
}

-(void)setNeedsRedisplay
{
	self->displayForced = YES;
	[self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
	if( self->displayForced && [NSThread isMainThread]) {
		self->displayForced = NO;
		[self displayItem: self->currentItem];
	}
	[super drawRect: rect];
}

-(void)displayItem: (NTINavigationItem*)item
{
	for( id v in self.subviews ) {
		[v removeFromSuperview];
	}
	self->ignoreScrollsUntilNextDisplay = NO;
	self->accView.hidden = YES;
	
	if( !item || ![item parent] ) {
		[self->currentItem release];
		self->currentItem = nil;
		return;
	}
	[self->currentItem autorelease];
	self->currentItem = [item retain];
	
	NSInteger numSiblings = 0;
	NSInteger maxHeight = 0;
	NSInteger totalHeight = 0;
	for( NTINavigationItem* child in [[item parent] children] ) {
		numSiblings++;
		totalHeight += child.recursiveRelativeSize;
		maxHeight = MAX( maxHeight, child.recursiveRelativeSize );
	}
	//TODO: We assume we are the content height height
	//Divide into the number of "pages"
	
	//TODO: This should be much, much, much smarter
	//We simply scale the entire height to fit our entire height.
	CGSize mySize = self.bounds.size;
	//Leave two pixels above and below each item
	
	CGFloat totalNumPages = totalHeight / mySize.height;
	
	//Assuming totalHeight is larger than me. Safe assumption.

	CGFloat scaleFactor = (mySize.height - 4 * numSiblings) / totalHeight;

	CGPoint top = CGPointMake( [self sectionInset], 2 );
	for( NTINavigationItem* child in [[item parent] children] ) {
		NSInteger relativeHeight = child.recursiveRelativeSize;
		if( relativeHeight <= 0 ) {
			continue;
		}
		CGFloat numPages = relativeHeight / mySize.height;
		//How many of our 100 pages does this get?
		CGFloat percentPages = numPages / totalNumPages;
		numPages = VERT_NUM_PAGES * percentPages;
		CGFloat actualHeight = scaleFactor * relativeHeight;
		CGFloat pageSize = actualHeight / numPages;
		CGFloat frameHeight = [NTIScrubBarView dots]
								? [NTIScrubBarSectionView heightForDotDisplayOfPages: numPages]
								: actualHeight;
		CGSize thisSize = CGSizeMake( [self sectionWidth], frameHeight );
		CGRect frame;
		frame.origin = top;
		frame.size = thisSize;
		NTIScrubBarSectionView* view = [[[NTIScrubBarSectionView alloc] initWithFrame: frame] autorelease];
		view.navItem = child;
		view.pageSize = pageSize;
		view.pageCount = numPages;
		view.controller = self.controller;
		
		
		[self addSubview: view];
		if( [child isEqual: item] ) {
			//FIXME: Coupling of concerns here.
			NTIWebView* web = [[self controller] webview];
			CGRect htmlView = [web htmlVisibleRect];
			CGRect htmlContent = [web htmlContentRect];
			
			CGFloat thumbProportion = htmlView.size.height / htmlContent.size.height;
			CGFloat thumbHeight = MAX(frameHeight * thumbProportion, 5);
			view.thumbHeight = thumbHeight;
			view.selected = YES;
		}
		
		top.y += frameHeight + [self sectionSep];
	}
	
	//Center the dots.
	if( [NTIScrubBarView dots] ) {
		CGFloat reqHeight = top.y;
		CGFloat excess = self.bounds.size.height - reqHeight;
		if( excess > 0 ) {
			CGFloat border = excess / 2;
			top.y = border;
			for( UIView* subview in self.subviews ) {
				CGRect frame = subview.frame;
				frame.origin = top;
				subview.frame = frame;
				top.y += frame.size.height + [self sectionSep];
			}
		}
	}
	
}

-(void)scrollSelectedToPercent: (CGFloat)percent maxPercent: (CGFloat)maxPercent
{
	if( ignoreScrollsUntilNextDisplay ) {
		return;
	}
	for( NTIScrubBarSectionView* v in self.subviews ) {
		if( v.selected ) {
			[v scrollToPercent: percent maxPercent: maxPercent];
			break;
		}
	}
}

-(BOOL)isShowingAccView
{
	return self->accView.hidden == NO;
}

-(BOOL)shouldTrackMoves: (NSSet*)touches
{
	return [self isShowingAccView] && [touches count] == 1;
}

-(void)moveAccViewTo: (CGPoint)viewPoint
{
	CGPoint displayOrigin = viewPoint;
	//Set it just to our right
	displayOrigin.x = self.bounds.size.width;
	//And centered vertically about the touch point
	displayOrigin.y -= self->accView.bounds.size.height / 2;

	CGRect frame = self->accView.frame;
	
	//And never let it draw offscreen 
	if( frame.size.height + displayOrigin.y > self.bounds.size.height ) {
		displayOrigin.y = self.bounds.size.height - frame.size.height;
	}
	else if( displayOrigin.y < self.bounds.origin.y ) {
		displayOrigin.y = self.bounds.origin.y;
	}
	frame.origin = displayOrigin;
	self->accView.frame = frame;
}

-(void)showAccViewAt: (CGPoint)viewPoint
{
	[self moveAccViewTo: viewPoint];
	self->accView.hidden = NO;
	[self addSubview: self->accView];	
}

-(void)hideAccView
{
	self->accView.hidden = YES;
	[self->accView removeFromSuperview];
}

-(BOOL)touchHasStrayed: (UITouch*)touch
{
	CGPoint point = [touch locationInView: self];
	//If they go to far to the left or right, we stop tracking the touch.
	//Right is off the edge of the screen, left is out over the content.
	//We get a 'touchesEnded' if they go past the edge of the screen
	return point.x 
			> (self.bounds.size.width + self.bounds.origin.x) + 2 * SECTION_INSET
		|| point.x <= 1.0;
}

-(NTIScrubBarSectionView*)sectionForPoint: (CGPoint)viewPoint
{
	id hit = [self hitTest: viewPoint withEvent: nil];
	//Find the scrub section closest to the point, horizontally
	//(they're narrow)
	if( ![hit isKindOfClass: [NTIScrubBarSectionView class]] ) {
		viewPoint.x = SECTION_INSET;
		hit = [self hitTest: viewPoint withEvent: nil];
	}
	//Then vertically, in case of the inter-section gap
	//FIXME: This probably has an 
	while( ![hit isKindOfClass: [NTIScrubBarSectionView class]] 
		  &&	viewPoint.y < self.bounds.size.height ) {
		viewPoint.y++;
		hit = [self hitTest: viewPoint withEvent: nil];
	}
	if( ![hit isKindOfClass: [NTIScrubBarSectionView class]] ) {
		//Hmm. Total fail.
		return nil;
	}
	return hit;
}

-(void)updateAccViewForPoint: (CGPoint)viewPoint
{
	NTIScrubBarSectionView* section = [self sectionForPoint: viewPoint];
	NTINavigationItem* item = section.navItem;
	NSString* name = item.name;
	UILabel* label = self->accLabel;
	if( ![label.text isEqual: name] ) {
		label.text = name;	
	}
}

-(void)contextualMenuAction: (NSNotification*)not
{
	CGPoint windowPoint = [NTIWindow windowPointFromNotification: not];
	CGPoint viewPoint = [self.window convertPoint: windowPoint toView: self];
	
	UIView* hit = [self hitTest: viewPoint withEvent: nil];
	if( hit && ![self isShowingAccView]) {
		[self updateAccViewForPoint: viewPoint];
		[self showAccViewAt: viewPoint];
	}
}

//TODO: Can we replace this with OUILongPressGestureRecognizer? It 
//has a hysteris 

-(void)touchesMoved: (NSSet*)touches withEvent: (UIEvent*)event
{
	if( [self shouldTrackMoves: touches] ) {
		UITouch* touch = [touches anyObject];
		if( [self touchHasStrayed: touch] ) {
			[self hideAccView];
		}
		else {
			CGPoint viewPoint = [touch locationInView: self];
			[self updateAccViewForPoint: viewPoint];
			[self moveAccViewTo: viewPoint];
		}
	}
	[super touchesMoved: touches withEvent: event];
}


-(void)touchesCancelled: (NSSet*)touches withEvent: (UIEvent*)event
{
	if( [self shouldTrackMoves: touches] ) {
		[self hideAccView];
	}

	[super touchesCancelled: touches withEvent: event];
}


-(void)touchesEnded: (NSSet*)touches withEvent: (UIEvent*)event
{
	if( [self shouldTrackMoves: touches] ) {
		//Hooray, they made a selection!
		CGPoint viewPoint = [[touches anyObject] locationInView: self];
		NTIScrubBarSectionView* section = [self sectionForPoint: viewPoint];
		if(		section
		   &&	![self touchHasStrayed: [touches anyObject]]
		   &&	[self->delegate respondsToSelector: @selector(navigationItemSelected:percent:)] ) {
			self->ignoreScrollsUntilNextDisplay = YES;
			CGPoint sectionPoint = [section convertPoint: viewPoint fromView: self];
			CGFloat percentThrough = sectionPoint.y / section.bounds.size.height;
			[self->delegate navigationItemSelected: section.navItem percent: percentThrough];
		}
		[self hideAccView];
	}
	[super touchesEnded: touches withEvent: event];
}

-(void)dealloc
{
	self.delegate = nil;
	self.controller = nil;
	[self->accView release], self->accView = nil;
	
	[[NSNotificationCenter defaultCenter]
	 removeObserver: self];
	[self->currentItem release];
	
	[super dealloc];
}

@end

@implementation NTIScrubBarSectionView

@synthesize navItem;
@synthesize thumbHeight;
@synthesize pageSize, pageCount;
@synthesize controller;

#define MAX_PAGE_DRAW_SIZE 9
#define BOUND_HEIGHT 2
#define BOUND_PADDING 4

+(CGFloat)heightForDotDisplayOfPages: (CGFloat)numPages
{
	return BOUND_HEIGHT + BOUND_PADDING + (numPages * MAX_PAGE_DRAW_SIZE) + BOUND_PADDING;
}

-(id)initWithFrame: (CGRect)frame
{
	self = [super initWithFrame: frame];
	self.backgroundColor = [NTIScrubBarView dots] ? [UIColor clearColor] : [UIColor lightGrayColor];
	self.layer.cornerRadius = 2.0;
	
	[self setSelected: NO];
	self.clipsToBounds = NO;
	return self;
}

-(void)dealloc
{
	self.controller = nil;
	self.navItem = nil;
	[super dealloc];
}

-(BOOL)selected
{
	return self.layer.shadowOpacity > 0.0;
}

-(void)setSelected: (BOOL)selected
{
	if( selected ) {
		self.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
		self.layer.shadowOpacity = 0.5;
		self.layer.shadowOffset = CGSizeMake( 2, 2 );
		
		self->selectedPage = 0;
		self->scrollPercent = 0;
	}
	else {
		self.layer.shadowOpacity = 0.0;
		self->selectedPage = -1;
		self->scrollPercent = -1.0f;
	}
}

-(CGFloat)numPages
{
	return pageCount;
	//return floor( self.bounds.size.height / self.pageSize );
}

-(CGFloat)truePageSize
{
	CGFloat numPages = [self numPages];
	CGSize usableSpace = self.bounds.size;
	usableSpace.height -= 10; //four pixels above and below, plus two border pixels
	return usableSpace.height / numPages;	
}

-(CGFloat)trueNumPages
{
	return floor( self.bounds.size.height / [self truePageSize] );
}

-(CGColorRef)highlightColor
{
	return [[[self.controller toolbar] backgroundColor] CGColor];
}

-(void)drawRect: (CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	if( [NTIScrubBarView dots] ) {
	
		CGContextSetFillColorWithColor( context,  [self highlightColor] );
		CGRect bound = CGRectMake( 0, 0, self.bounds.size.width, BOUND_HEIGHT );
		CGContextFillRect( context, bound );

		CGFloat numPages = [self numPages];
		CGFloat y = bound.size.height + BOUND_PADDING;
		for( int i = 0; i < numPages; i++ ) {
			CGRect page = CGRectMake( 12.5, y, 5, 5 );
			if( i == self->selectedPage ) {
				CGRect border = CGRectMake( 10.5, y - 2, MAX_PAGE_DRAW_SIZE, MAX_PAGE_DRAW_SIZE );
				CGContextSaveGState( context );
				CGContextSetFillColorWithColor( context, [[UIColor darkGrayColor] CGColor] );
				CGContextFillRect( context, border );
				CGContextRestoreGState( context );
			}
			CGContextFillEllipseInRect( context,  page);
			y += MAX_PAGE_DRAW_SIZE;
		}
	}
	else {
		CGContextSetFillColorWithColor( context, [[self backgroundColor] CGColor]);
		CGContextFillRect( context, self.bounds );
		if( self->scrollPercent >= 0 ) {
			CGPoint top; top.x = 0;
			top.y = self->scrollPercent * self.bounds.size.height;
			//Don't let it exceed our bounds
			if( top.y + thumbHeight > self.bounds.size.height ) {
				top.y = self.bounds.size.height - thumbHeight;
			}
			else if( top.y < 0 ) {
				top.y = 0;
			}
			
			CGRect thumb; 
			thumb.origin = top;
			thumb.size = CGSizeMake( self.bounds.size.width, self->thumbHeight );
			CGContextSetFillColorWithColor( context, [self highlightColor] );
			CGContextFillRect( context,  thumb );
		}
	}
}

-(void)scrollToPercent: (CGFloat)percent maxPercent: (CGFloat)maxPercent
{
	if( !self.selected ) {
		return;
	}
	self->scrollPercent = percent;
	//Snap to the closest page
	CGFloat numPages = [self trueNumPages];
	NSInteger oldPage = self->selectedPage;
	self->selectedPage = (NSInteger)MIN( numPages, floor( maxPercent * numPages ) - 1 );
	if( self->selectedPage != oldPage  || ![NTIScrubBarView dots] ) {
		[self setNeedsDisplay];
	}
}

@end
