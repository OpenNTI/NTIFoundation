//
//  TestAppDelegate.h
//  Test
//
//  Created by Jason Madden on 2011/05/19.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OmniFoundation/OmniFoundation.h>
#import <dispatch/dispatch.h>
#import "OmniUI/OUIAppController.h"
#import "NTIParentViewController.h"
#import "NTIWebContextTableController.h"
#import "NTINoteController.h"

@class NTIWebView;
@class NTINavigationTableLoader;
@class NTINavigationItem;
@class NTINavigationRowController;
@class NTINavigationHistory;
@class NTITapCatchingGestureRecognizer;
@class LibraryView;
@class NTIScrubBarView;
@class NTIInlineSettingController;
@class NTIWebContextTableController;

/**
 * This is the key of the notification that's emmitted when
 * a WebAndToolController did start loading the next ntiid. This is a 
 * good time to begin fetching data to display for that page. The user info
 * for the notification has the NTINavigationItem of the new page
 * under WebAndToolControllerDidStartLoadKeyNavigationItem;
 */
extern NSString* WebAndToolControllerWillLoadPageId;
extern NSString* WebAndToolControllerWillLoadPageIdKeyNavigationItem;

@interface WebAndToolController : NTIParentViewController <UIPopoverControllerDelegate, NTITwoStateViewControllerProtocol> {
@private
	UIView* rootView;
	UIButton *feedbackButton;
	NTIWebView* _webview;
	UIButton* ntiButton;
	UIView* toolbar;
	UIButton* settingButton;
	UIButton *actionButton;
	NTINavigationRowController* navHeaderController;
	
	UIView* navBar;
	CGPoint contentOffset;
	
	NTITapCatchingGestureRecognizer* tapGesture;
	NTINotesInPageIndicatorController* noteIndicator;
	UIViewController* settingViewController;
	UINavigationController* actionViewController;
	UIPopoverController* popoverController;
	id lastShownPopoverFrom; //Weak reference
	
	UIView *tapZoneUpper;
	UIView* tapZoneLower;
	
	UIButton* prevButton;
	UIButton* nextButton;
	UIButton *searchButton;
	UIView *allPagesNotesView;

	
	NSURLRequestCachePolicy cachePolicy;
	NSString* afterViewDidLoad;
	
	NTIWebContextTableController* master;
	UIImageView* miniView;
	
	//Preferences cache
	BOOL notesEnabled, highlightsEnabled;
	id fontSize, fontFace, highlightColor;
}
@property(nonatomic,readonly) NTINavigationHistory* history;
@property (nonatomic, retain) IBOutlet UIView* rootView;
@property (nonatomic, retain) IBOutlet UIButton* feedbackButton;
@property (nonatomic, retain) IBOutlet UILabel* versionLabel;

/**
 * The page ID currently being viewed. We are KVO compliant for 
 * this. When we move to a new page, this will become NIL, and only
 * when the page is complete will it become non-nil.
 */
@property (nonatomic,readonly) NSString* ntiPageId;

@property (nonatomic, retain) IBOutlet NTIWebView *webview;
@property (nonatomic, retain) IBOutlet UIView* navBar;
@property (nonatomic, retain) IBOutlet UIView *toolbar;
@property (nonatomic, retain) IBOutlet UIButton* ntiButton;
@property (nonatomic, retain) IBOutlet UIButton* settingButton;
@property (nonatomic, retain) IBOutlet UIButton* actionButton;
@property (nonatomic, retain) IBOutlet NTINavigationRowController* navHeaderController;
@property (nonatomic, readonly) UIScrollView* gutter;
@property (nonatomic, readonly) NTINotesInPageIndicatorController* noteIndicator;
@property (nonatomic, retain) IBOutlet UIView* tapZoneLower;
@property (nonatomic, retain) IBOutlet UIView* tapZoneUpper;

//TODO: These should go in the navigation controller!
@property (nonatomic, retain) IBOutlet UIButton* prevButton;
@property (nonatomic, retain) IBOutlet UIButton* nextButton;
@property (retain, nonatomic) IBOutlet UIButton *searchButton;

@property(nonatomic,readonly) UINavigationController* settingViewController;
@property(nonatomic,readonly) NTINavigationItem* selectedNavigationItem;

+(UISplitViewController*) createSplitViewController;

-(NSURL*) currentURL;

-(id)dismissPopover;
-(id)navigateToItem: (NTINavigationItem*)item;
-(void)goBack;
-(void)goForward;
-(void)afterViewDidLoadThenLoadID:(NSString*)ntiid;

- (void)showPopoverFrom: (id)sender 
					 at: (CGRect*)at
				 inView: (UIView*)view
			 controller: (UIViewController*)controller;

-(void)showNavigationTo: (NTINavigationItem*)item
					 at: (CGRect)location
				 inView: (UIView*)view
				 sender: (id)sender;

-(void)addSubviewOnTopOfWeb: (UIView*)view;

@end


