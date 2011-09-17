//
//  NTIWebView.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/21.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import <UIKit/UIKit.h>
#import "NTIOSCompat.h"

@interface NTIHTMLObject : OFObject {
}
/**
 * The frame in the coordinate space of the view.
 */
@property (nonatomic,assign) CGRect frame;
@property (nonatomic,retain) NSString* htmlId;
@end

@interface UIWebView(NTIExtensions)

#pragma mark HTML Page Info

/**
 * The title of the loaded content, or the empty string.
 */
@property (nonatomic,readonly) NSString* title;
/**
 * The page ID if there is one, or nil.
 */
@property (nonatomic,readonly) NSString* ntiPageId;

#pragma mark HTML Position Info
-(CGSize)htmlWindowSize;
-(CGPoint)htmlScrollOffset;
-(CGFloat)htmlScrollVerticalPercent;
-(CGRect)htmlVisibleRect;
-(CGRect)htmlContentRect;
-(CGFloat)htmlScrollVerticalMaxPercent;
-(CGSize)viewSizeFromHTMLSize:(CGSize)size;

#pragma mark Selection Info
-(NSString*)selectedText;
-(NSString*)selectedToken;
-(NSInteger)selectionWidth;
-(NSInteger)selectionHeight;


#pragma mark Event Handling
//These all return the point taking into account the scroll offset,
//which means they are absolute points in the document. These are
//NOT the points you want to give to document.getElementFromPoint.
- (CGPoint)htmlDocumentPointFromWindowPoint: (CGPoint)windowPoint;
- (CGPoint)htmlDocumentPointFromViewPoint: (CGPoint)viewPoint;
- (CGPoint)viewPointFromHTMLDocumentPoint: (CGPoint)htmlPoint;


//These functions return a point in the current visible
//rectangle converted to HTML coordinates. These are what you want
//to give to document.getElementFromPoint.
- (CGPoint)htmlWindowPointFromWindowPoint: (CGPoint)windowPoint;
- (CGPoint)htmlWindowPointFromViewPoint: (CGPoint)viewPoint;
- (CGPoint)viewPointFromHTMLWindowPoint: (CGPoint)htmlPoint;



#pragma mark Scrolling

-(void)scrollUp;
-(void)scrollDown;
-(void)scrollToPercent: (CGFloat)percent;

#pragma mark JavaScript
-(NSString*)callFunction: (NSString*)functionName;
-(NSString*)callFunction: (NSString*)functionName
			  withString: (NSString*)string;
-(NSString*)callFunction: (NSString*)functionName
			  withString: (NSString*)string
			   andString: (NSString*)s2;
-(NSString*)callFunction: (NSString*)functionName
				withJson: (NSString*)string
			   andString: (NSString*)s2;
-(NSString*)callFunction: (NSString*)functionName
			  withString: (NSString*)string
			   andString: (NSString*)string2
			   andString: (NSString*)string3;
-(NSString*)callFunction: (NSString*)functionName
			  withString: (NSString*)string
				  andInt: (NSInteger)int1
				  andInt: (NSInteger)int2;

-(NSString*)callFunction: (NSString*)functionName
				withJson: (NSString*)json
			   andString: (NSString*)string2
			   andString: (NSString*)string3;

-(NSString*)callFunction: (NSString*)functionName
				withJson: (NSString*)string
				  andInt: (NSInteger)i2
				  andInt: (NSInteger)i3;

-(NSString*)callFunction: (NSString*)functionName 
				withBool: (BOOL)thebool;
-(NSString*)callFunction: (NSString*)functionName
				withJson: (NSString*)json;
-(NSString*)callFunction: (NSString*)functionName
				 withInt: (NSInteger)i
				  andInt: (NSInteger)i2;

-(NSString*)callFunctionNeedingHTMLWindowPoint: (NSString*)function
							   withWindowPoint: (CGPoint)windowPoint;

#pragma mark Elements and Objects
-(BOOL)hideAndMakeZeroSizeObjects: (NSString*)selector;
-(void)disableAndMakeTransparentObjects: (NSString*)selector;
-(void)disableAndHideSubmit: (NSString*)selector;
/**
 * An NSArray of NTIHTMLObjects.
 */
-(NSArray*)htmlObjects: (NSString*)selector;

//An array of strings
-(NSArray*)htmlElementNamesAtViewPoint: (CGPoint)point;
-(NSArray*)htmlElementNamesAtWindowPoint: (CGPoint)point;
-(NSArray*)htmlElementNamesAtHTMLPoint: (CGPoint)point;

@end
