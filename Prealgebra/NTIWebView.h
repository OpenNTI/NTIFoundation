//
//  NTIWebView.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/21.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NTIWindow.h"
#import "UIWebView-NTIExtensions.h"
#import "NTINoteSavingDelegates.h"
#import "NTIWebOverlayedFormController.h"
#import "NTIOSCompat.h"

@class NTIMiniNoteView;
@class NTINote;
@class OQColor;

@interface NSObject(NTIWebViewActions)
-(void)removeHighlight:(id)sender;
-(void)define:(id)sender;
-(void)createNewNote:(id)sender;
-(void)replyToInlineNote:(id)sender;
-(void)highlight:(id)sender;
-(void)editInlineNote:(id)sender;
@end

//NWA: NTI Web Action
#define NWA_CREATE_NOTE @selector(createNewNote:)
#define NWA_CREATE_HIGHLIGHT @selector(highlight:)

/**
 * The name of the notification sent when font size
 * or font changes and the page re-lays out. The userinfo
 * dictionary is undefined.
 */
extern NSString* const NTINotificationWebViewFontDidChangeName;


/**
 * Installs a context menu including the Note
 * operation tied to the createNewNote: selector. Someone 
 * in the responder chain should implement that to enable
 * note taking.
 */
@interface NTIWebView : UIWebView {
	//Things for the dictionary popover
	UIWebView* popoverView;
    UIViewController* popoverViewController;
	UIPopoverController* popoverController;
	
	NSMutableArray* overlayedFormControllers;
	
	//Scroll delegates
	NSMutableArray* scrollDelegates;
	CGPoint overlayBeginOffset;
	CGFloat overlayBeginZoom;
}

/**
 * Overlaied form controllers are automatically also scroll delegates.
 */
-(void)overlayFormController: (NTIWebOverlayedFormController*) formController;

-(void)clearOverlayedFormControllers;

/**
 * The relative href for the next section, or empty/nil.
 */
-(NSString*)ntiNextHref;

/**
 * The relative href for the previous section, or empty/nil.
 */
-(NSString*)ntiPrevHref;

//-(BOOL)wantsEvent: (UIEvent*) event atPoint: (CGPoint)point;
-(BOOL)wantsTapAtPoint: (CGPoint)point;
-(BOOL)wantsTapAtPointToIntercept: (CGPoint)point;
-(void)interceptTapAtPoint: (CGPoint)localPoint;

/**
 * Adds the given object to act as an observer of scroll events, using
 * the same methods specified by UIScrollViewDelegate. The object is retained.
 * Currently only some of the events are repeated.
 * @return this object 
 */
-(id)addScrollDelegate: (id)delegate;

-(void)removeScrollDelegate: (id)delegate;


-(void)didRotateFromInterfaceOrientation: (UIInterfaceOrientation)old;

/**
 * @return An autoreleased string usable with #setFontSize.
 */
- (NSString*)increaseFontSize;

/**
 * @return An autoreleased string usable with #setFontSize.
 */
- (NSString*)decreaseFontSize;

- (void)setFontSize: (NSString*)size;

/**
 * @return An autoreleased string usable with #setFontFace.
 */
- (NSString*)serifFont;

/**
 * @return An autoreleased string usable with #setFontFace.
 */
- (NSString*)sansSerifFont;

- (NSString*)setFontFace: (NSString*)size;

-(void)setHighlightColor: (OQColor*)color;

-(id)showHighlights;
-(id)hideHighlights;
-(id)shouldUseMathFace: (BOOL)use;
-(BOOL)touchWasOnInlineNote;
@end
