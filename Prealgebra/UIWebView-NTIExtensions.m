//
//  NTIWebView.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/21.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "UIWebView-NTIExtensions.h"
#import "TestAppDelegate.h"
#import "NTINoteView.h"
#import "NTINoteLoader.h"
#import "NSString-NTIJSON.h"
#import "NSArray-NTIExtensions.h"
#import <math.h>

@implementation NTIHTMLObject
@synthesize frame, htmlId;
-(void)dealloc
{
	self.htmlId = nil;
	[super dealloc];
}
@end

@implementation UIWebView(NTIExtensions)

#pragma mark Selection Info

- (NSString*) selectedText
{
	return [[self stringByEvaluatingJavaScriptFromString: @"window.getSelection().toString();"]
			stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/**
 * If there is one word selected, returns it. Otherwise, returns nil.
 */
- (NSString*) selectedToken
{
	NSString* result = nil;
	NSString* selected = [self selectedText];
	if( [selected length] > 0 ) {
		NSArray* tokens = [selected componentsSeparatedByCharactersInSet:
							[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if( [tokens count] == 1 ) {
			result = [tokens objectAtIndex: 0];
		}
	}
	return result;
}

static NSInteger selectionProperty( UIWebView* self, NSString* name )
{
	return [[self stringByEvaluatingJavaScriptFromString:
			 [NSString stringWithFormat:
			  @"window.getSelection().getRangeAt(0).getBoundingClientRect().%@", name]]
			integerValue];
}

- (NSInteger) selectionHeight
{
	return selectionProperty( self, @"height" );
}

- (NSInteger) selectionWidth
{
	return selectionProperty( self, @"width" );
}


#pragma mark HTML Position Info
- (CGSize)htmlWindowSize
{
	CGSize size;
	size.width = [[self stringByEvaluatingJavaScriptFromString: @"window.innerWidth"] integerValue];
	size.height = [[self stringByEvaluatingJavaScriptFromString: @"window.innerHeight"] integerValue];
	return size;
}

- (CGPoint)htmlScrollOffset
{
	CGPoint pt;
	pt.x = [[self stringByEvaluatingJavaScriptFromString: @"window.pageXOffset"] integerValue];
	pt.y = [[self stringByEvaluatingJavaScriptFromString: @"window.pageYOffset"] integerValue];
	return pt;
}

-(CGRect)htmlVisibleRect
{
	CGRect result;
	result.size = [self htmlWindowSize];
	result.origin = [self htmlScrollOffset];
	return result;
}

-(CGRect)htmlContentRect
{
	NSInteger height = [[self stringByEvaluatingJavaScriptFromString:
						 @"document.documentElement.scrollHeight"] integerValue];
	NSInteger width = [[self stringByEvaluatingJavaScriptFromString:
						@"document.documentElement.scrollWidth"] integerValue];
	CGRect result;
	result.origin.x = 0;
	result.origin.y = 0;
	result.size = CGSizeMake( width, height );
	return result;
}

- (CGFloat)htmlScrollVerticalPercent
{
	//To compensate for the height of the viewing area, we approximate
	NSInteger height = [[self stringByEvaluatingJavaScriptFromString: @"document.documentElement.scrollHeight"] integerValue];
	return [self htmlScrollOffset].y / (CGFloat)height;
}

-(CGFloat)htmlScrollVerticalMaxPercent
{
	NSInteger height = [[self stringByEvaluatingJavaScriptFromString: @"document.documentElement.scrollHeight"] integerValue];
	return ([self htmlVisibleRect].size.height + [self htmlScrollOffset].y)/(CGFloat)height;
}

-(NSString*)title
{
	return [self stringByEvaluatingJavaScriptFromString: @"document.title"];	
}

-(NSString*)ntiPageId
{
	//this api likes to return the empty string on errors, we'd prefer
	//to return NIL
	NSString* result = [self callFunction: @"NTIGetPageID"];
	return [NSString isEmptyString: result] ? nil : result;
}


-(CGSize)htmlSizeFromViewSize: (CGSize)localSize
{
	CGSize viewSize = [self frame].size;
	CGSize windowSize = [self htmlWindowSize];
	
	CGFloat f = windowSize.width / viewSize.width;	
	//CGSize viewSize;
	localSize.width = localSize.width * f; // - offset.x;
	localSize.height = localSize.height * f;// - offset.y;	
	return localSize;
}

- (CGPoint)htmlDocumentPointFromViewPoint: (CGPoint)localPoint
{
	//convert point from view to HTML coordinate system
	CGSize viewSize = [self frame].size;
	CGSize windowSize = [self htmlWindowSize];
	CGFloat f = windowSize.width / viewSize.width;
	//TODO: Why would this be taking scroll into account? 
	//Shouldn't this be symmetrical with viewPointFromHTMLDocumentPoint?
	CGPoint htmlOffset  = [self htmlScrollOffset];
	CGPoint scaledOffset;
	scaledOffset.x = htmlOffset.x * f;
	scaledOffset.y = htmlOffset.y * f;
	
	CGPoint htmlPoint;
	htmlPoint.x = localPoint.x * f + scaledOffset.x;
	htmlPoint.y = localPoint.y * f + scaledOffset.y;
#ifdef DEBUG_POINT_CONVERSION
	NSLog( @"%@", [self callFunction: @"NTIDebugEltAtPt"
							 withInt: htmlPoint.x
							  andInt: htmlPoint.y] );
#endif
	return htmlPoint;
}

-(CGSize)viewSizeFromHTMLSize: (CGSize)htmlSize
{
	CGSize viewSize = [self frame].size;
	CGSize windowSize = [self htmlWindowSize];
	
	CGFloat f = viewSize.width / windowSize.width;
	
	//CGSize viewSize;
	viewSize.width = htmlSize.width * f; // - offset.x;
	viewSize.height = htmlSize.height * f;// - offset.y;	
	return viewSize;
}

-(CGPoint)viewPointFromHTMLDocumentPoint: (CGPoint)htmlPoint
{
	//convert point from HTML to view coordinate system	
	//Notice that scroll offset isn't considered. The view coordinates are
	//constant.
	CGSize viewSize = [self frame].size;
	CGSize windowSize = [self htmlWindowSize];

	CGFloat f = viewSize.height / windowSize.height;
	CGPoint viewPoint;
	viewPoint.x = htmlPoint.x * f;
	viewPoint.y = htmlPoint.y * f;
	
	//TODO: Implement me
	return viewPoint;
}

-(CGPoint)htmlDocumentPointFromWindowPoint: (CGPoint)windowPoint
{
	return [self htmlDocumentPointFromViewPoint: [self.window convertPoint: windowPoint
															toView: self]];
}

-(CGPoint)htmlWindowPointFromViewPoint: (CGPoint)localPoint
{
	CGSize viewFrameSize = [self bounds].size;
	CGSize htmlWindowSize = [self htmlWindowSize];

	
	CGFloat widthScale = htmlWindowSize.width / viewFrameSize.width;
	CGFloat heightScale = htmlWindowSize.height / viewFrameSize.height;
	CGAffineTransform scale = CGAffineTransformMakeScale( widthScale,  heightScale );
	CGPoint htmlPoint = CGPointApplyAffineTransform( localPoint,  scale );
	
	//NOTE: The behaviour of the DOM is different on iOS 5 vs 4.3.
	//5 gets it right, 4 gets it wrong. 4 really wants absolute
	//position instead of offset. Hacky workaround here.
	if( [[[UIDevice currentDevice] systemVersion] hasPrefix: @"4"] ) {
		CGPoint offset = [self htmlScrollOffset];
		htmlPoint.x += offset.x;
		htmlPoint.y += offset.y;	
	}
#ifdef DEBUG_POINT_CONVERSION
	NSLog( @"At point: %@/%@ %@",
		NSStringFromCGPoint( localPoint ), NSStringFromCGPoint( htmlPoint ),
		[self callFunction: @"NTIDebugEltAtPt"
				   withInt: htmlPoint.x
					andInt: htmlPoint.y] );
#endif
	return htmlPoint;
}

- (CGPoint)htmlWindowPointFromWindowPoint: (CGPoint)windowPoint
{
	return [self htmlWindowPointFromViewPoint: [self.window convertPoint: windowPoint
																  toView: self]];
}

-(CGPoint)viewPointFromHTMLWindowPoint: (CGPoint)htmlPoint
{
	OBFinishPortingLater( "View point from window point not implemented" );
	return htmlPoint;
}

#pragma mark JavaScript
-(NSString*)_ntiDoJS: (NSString*)s
{
#if DEBUG_NTIWEB_JS
	NSLog( @"Eval JS: %@", s );
#endif
	return [self stringByEvaluatingJavaScriptFromString: s];
}

static NSString* _ntiEscapeJS( id s )
{
	//Due to the vagueness of plists and JSON, we sometimes get here with
	//NSNumbers or NSStrings
	id result = s;
	if( [s respondsToSelector: @selector(stringByReplacingOccurrencesOfString:withString:)] ) {
		result = [s stringByReplacingOccurrencesOfString: @"\"" withString: @"\\\""];	
	}
	else if( [s respondsToSelector: @selector(stringValue)] ) {
		result = _ntiEscapeJS( [s stringValue] );	
	}
	return result;
}

- (NSString*)callFunction: (NSString*)function
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@()", function]];
}

-(NSString*)callFunction: (NSString*)functionName
			  withString: (NSString*)string
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@(\"%@\")", functionName, string]];
}

-(NSString*)callFunction: (NSString*)functionName
			  withString: (NSString*)string 
			   andString: (NSString*)s2
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@(\"%@\",\"%@\")", 
			 functionName, string, s2]];
}

-(NSString*)callFunction: (NSString*)functionName
			  withString: (NSString*)string
			   andString: (NSString*)s2
			   andString: (NSString*)s3
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@(\"%@\",\"%@\",\"%@\")", 
			 functionName, _ntiEscapeJS(string), _ntiEscapeJS(s2), _ntiEscapeJS(s3)]];
}

-(NSString*)callFunction: (NSString*)functionName
			  withString: (NSString*)string
				  andInt: (NSInteger)int1
				  andInt: (NSInteger)int2;
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@(\"%@\",%i,%i)", 
			 functionName, _ntiEscapeJS(string), int1, int2]];
}

-(NSString*)callFunction: (NSString*)functionName
				withJson: (NSString*)string
			   andString: (NSString*)s2
			   andString: (NSString*)s3
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@(%@,\"%@\",\"%@\")", 
			 functionName, string, s2, s3]];
}

-(NSString*)callFunction: (NSString*)functionName
				withJson: (NSString*)string
			   andString: (NSString*)s2
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@(%@,\"%@\")", 
			 functionName, string, s2]];
}

-(NSString*)callFunction: (NSString*)functionName
				withJson: (NSString*)string
				  andInt: (NSInteger)i2
				  andInt: (NSInteger)i3
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@(%@,\"%i\",\"%i\")", 
			 functionName, string, i2, i3]];
}

-(NSString*)callFunction: (NSString*)functionName
				withBool: (BOOL)thebool
{
	return [self _ntiDoJS:
			[NSString stringWithFormat: @"%@(%@)", functionName, thebool ? @"true" : @"false"]];	
}

-(NSString*)callFunction: (NSString*)functionName
				 withInt: (NSInteger)i
				  andInt: (NSInteger)i2
{
	return [self _ntiDoJS: 
			[NSString stringWithFormat: @"%@(%i,%i);",
			 functionName,
			 i, i2]];
}

-(NSString*)callFunction: (NSString*)functionName
				withJson: (NSString*)json
{
	return [self _ntiDoJS: 
			[NSString stringWithFormat: @"%@(%@);",
			 functionName, json]];
}

-(NSString*)callFunctionNeedingHTMLWindowPoint: (NSString*)function
							   withWindowPoint: (CGPoint)windowPoint
{
	CGPoint lastWinTouch = [self htmlWindowPointFromWindowPoint: windowPoint];
	NSString* jsTruth = [self callFunction: function
								   withInt: lastWinTouch.x 
									andInt: lastWinTouch.y];
#ifdef DEBUG_POINT_CONVERSION
	NSLog( @"%@", [self callFunction: @"NTIDebugEltAtPt"
							 withInt: lastWinTouch.x
							  andInt: lastWinTouch.y] );

#endif
	return jsTruth;
}


#pragma mark Scrolling
static CGPoint sanitizeOffset( UIView* self, CGPoint offset, UIScrollView* subview )
{
	if( offset.y >= [subview contentSize].height - self.bounds.size.height) {
		offset.y = [subview contentSize].height - self.bounds.size.height;
	}
	else if( offset.y <= 0 ) {
		offset.y = 0;
	}

	return offset;
}

static UIScrollView* findScrollView( id self )
{
	//TODO: Figure out how to do this. If we're adding a category, it doesn't
	//work.
	/*
	if( [[UIWebView class] instancesRespondToSelector: @selector(scrollView)] ) {
		IMP imp = [[UIWebView class] instanceMethodForSelector: @selector(scrollView)];
		return imp( self, @selector(scrollView) );
	}
	 */

	for( id subview in [self subviews] ) {
		if( [subview isKindOfClass: [UIScrollView class]] ) {
			return subview;
		}
	}
	return nil;
}

-(UIScrollView*)scrollView
{
	return findScrollView( self );
}


#define CHECK_SCROLLVIEW(v) if( !v ) { NSLog( @"No scrollview" ); return; }
#define GET_SCROLLVIEW() UIScrollView* subview = findScrollView(self); CHECK_SCROLLVIEW(subview);

-(void)scrollToPercent: (CGFloat)percent
{
	//UIScrollView* subview = findScrollView( self ); CHECK_SCROLLVIEW(subview);
	GET_SCROLLVIEW();
	CGPoint offset = [subview contentOffset];
	CGSize contentSize = [subview contentSize];
	offset.y = contentSize.height * percent;
	[subview setContentOffset: sanitizeOffset(self, offset, subview)
					 animated: NO];
}

-(void)scrollDown
{
	GET_SCROLLVIEW();
	CGPoint offset = [subview contentOffset];
	offset.y += self.bounds.size.height;
	[subview setContentOffset: sanitizeOffset(self, offset, subview)
					 animated: YES];
			
}

-(void)scrollUp
{
	GET_SCROLLVIEW();
	CGPoint offset = [subview contentOffset];
	offset.y -= self.bounds.size.height;
	[subview setContentOffset: sanitizeOffset(self, offset, subview)
					 animated: YES];
}

#undef GET_SCROLLVIEW
#undef CHECK_SCROLLVIEW

#pragma mark Elements and Objects
-(NSArray*)htmlObjects: (NSString*)selector
{
	NSString* json = [self callFunction: @"NTIGetHTMLElementPositionsAndIds" 
							 withString: selector];
	NSArray* parts = [json jsonObjectValue];
	NSMutableArray* objects = [NSMutableArray arrayWithCapacity: [parts count]];
	for( NSArray* part in parts ) {
		if(		[NSArray isEmptyArray: part]
		   ||	[part count] < 5 ) {
			continue;
		}
		
		NSInteger x = [[part objectAtIndex: 0] integerValue];
		NSInteger y = [[part objectAtIndex: 1] integerValue];
		NSInteger w = [[part objectAtIndex: 2] integerValue];
		NSInteger h = [[part objectAtIndex: 3] integerValue];
		NSString* htmlId = [[part objectAtIndex: 4] 
							stringByTrimmingCharactersInSet: [NSCharacterSet punctuationCharacterSet]];
		NTIHTMLObject* obj = [[[NTIHTMLObject alloc] init] autorelease];
		CGRect bounds = CGRectMake( x, y, w, h );
#ifdef DEBUG_POINT_CONVERSION
		NSLog( @"HTML Object %@ has HTML origin %@ view origin %@",
			htmlId,
			NSStringFromCGPoint( bounds.origin ),
			NSStringFromCGPoint( [self viewPointFromHTMLDocumentPoint: bounds.origin] ) );
#endif
		bounds.origin = [self viewPointFromHTMLDocumentPoint: bounds.origin];
		bounds.size = [self viewSizeFromHTMLSize: bounds.size];
		obj.frame = bounds;
		obj.htmlId = htmlId;
		[objects addObject: obj];
	}
	return objects;
}

-(NSArray*)htmlElementNamesAtWindowPoint: (CGPoint)point
{
	NSString* tags = [self callFunctionNeedingHTMLWindowPoint: @"NTIGetHTMLElementsAtPoint"
											  withWindowPoint: point];
	
	return [tags jsonObjectValue];
}

-(NSArray*)htmlElementNamesAtViewPoint: (CGPoint)point
{
	CGPoint lastWinTouch = [self convertPoint: point toView: nil];
	return [self htmlElementNamesAtWindowPoint: lastWinTouch];
}

-(NSArray*)htmlElementNamesAtHTMLPoint: (CGPoint)point
{
	return [[self callFunction: @"NTIGetHTMLElementsAtPoint"
					  withInt: point.x
					   andInt: point.y] jsonObjectValue];
}

-(BOOL)hideAndMakeZeroSizeObjects: (NSString*)selector
{
	return [[self callFunction: @"NTIHideAndMakeZeroSizeElements" withString: selector] 
			javascriptBoolValue];
}

-(void)disableAndMakeTransparentObjects: (NSString*)selector
{
	[self callFunction: @"NTIDisableAndMakeTransparentElements" withString: selector];
}

-(void)disableAndHideSubmit: (NSString*)selector
{
	[self callFunction: @"NTIDisableAndHideSubmit" withString: selector];
}

@end
