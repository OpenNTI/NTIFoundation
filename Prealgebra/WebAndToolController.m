//
//  AppViewController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/02.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "WebAndToolController.h"
#import "TestAppDelegate.h"
#import "NTIApplicationViewController.h"
#import "NTIWebView.h"
#import "NTITapCatchingGestureRecognizer.h"
#import "NTIInlineSettingController.h"
#import "NTINavigationParser.h"
#import "NTINavigation.h"
#import "NTINavigationHistory.h"
#import "NTINoteLoader.h"
#import "NTINoteView.h"
#import "LibraryView.h"
#import "Library.h"
#import "NTIWebContextTableController.h"
#import "NTIAppPreferences.h"
#import "OmniUI/UIView-OUIExtensions.h"
#import "NTIDraggableImageView.h"
#import <QuartzCore/QuartzCore.h>
#import <OmniFoundation/OmniFoundation.h>
#import "NTIWebOverlayedFormController.h"
#import "NTIDraggingUtilities.h"
#import "NTIUtilities.h"
#import "NTIUrlScheme.h"
#import "NSArray-NTIExtensions.h"
#import "NTISharingController.h"
#import "NSDictionary-NTIJSON.h"
#import "NSArray-NTIJSON.h"
#import "NTIUserData.h"
//Remote Notification overlays
#import "OmniUI/OUIOverlayView.h"

NSString* WebAndToolControllerWillLoadPageId 
	= @"WebAndToolControllerWillLoadPageId";
NSString* WebAndToolControllerWillLoadPageIdKeyNavigationItem
	= @"WebAndToolControllerWillLoadPageIdKeyNavigationItem";

@interface WebAndToolController(Private)
@property (nonatomic,copy) NSString* ntiPageId;
@property (nonatomic,readonly) NTINavigationItem* nextNavigationItem;
@property (nonatomic,readonly) NTINavigationItem* previousNavigationItem;

-(void)postWillLoadNotification: (NTINavigationItem*)navItem;
//-(void)postDidLoadNotification: (NTINavigationItem*)navItem;

//These are internal use only. Our public interface
//is the navigation items.
-(id)_navigateRelativeToRoot: (NSString*)href;
-(id)_navigateRelative: (NSString*)href;

@end

@implementation WebAndToolController
@synthesize searchButton;


@synthesize settingButton;
@synthesize actionButton;
@synthesize navHeaderController;
@synthesize tapZoneLower, tapZoneUpper;
@synthesize ntiButton;
@synthesize toolbar;
@synthesize history = navigationHistory;
@synthesize rootView;
@synthesize feedbackButton;
@synthesize versionLabel;
@synthesize navBar;
@synthesize noteIndicator;

@synthesize prevButton, nextButton;

+(UISplitViewController*) createSplitViewController
{
	WebAndToolController* detail = [[[WebAndToolController alloc]
									initWithNibName: @"WebAndToolContainer"
									bundle: nil] autorelease];
	NTIWebContextTableController* master = [[[UINib nibWithNibName: @"WebContextTableView" bundle: nil]
									  instantiateWithOwner: detail
									  options: nil] objectAtIndex: 0];
	detail->master = master;
	UISplitViewController* split = [[UISplitViewController alloc] init];
	split.viewControllers = [NSArray arrayWithObjects: master, detail, nil];
	return [split autorelease];
}

-(id)initWithNibName: (NSString*)nibNameOrNil bundle: (NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];

    if( self ) {
		self->navigationHistory = [[NTINavigationHistory alloc] init];
		self->cachePolicy = NSURLRequestReturnCacheDataElseLoad;
		self->noteIndicator = [[NTINotesInPageIndicatorController alloc] init];
	}
	return self;
}

-(void)afterViewDidLoadThenLoadID: (NSString*)request
{
	if( self->navHeaderController.root ) {
		NSArray* path = [self->navHeaderController.root pathToID: request];
		if( ![NSArray isEmptyArray: path] ) {
			[self navigateToItem: [path lastObject]];
		}
	}
	else {
		self->afterViewDidLoad = [request retain];
	}
}

-(void)viewDidLoad
{
#ifdef DEBUG
	[self.feedbackButton addTarget: [TestAppDelegate sharedDelegate]
							action: @selector(sendFeedback:)
				  forControlEvents: UIControlEventTouchDown];
	self.versionLabel.text = [[[NSBundle mainBundle] infoDictionary]
							  objectForKey: @"CFBundleShortVersionString"];
#else
	self.feedbackButton.hidden = YES;
#endif
	[ntiButton addGestureRecognizer: [[[UITapGestureRecognizer alloc]
									   initWithTarget: self
									   action: @selector(handleNTIButton:)] autorelease]];

	[settingButton addGestureRecognizer: [[[UITapGestureRecognizer alloc]
										   initWithTarget: self
										   action: @selector(handleSettingButton:)] autorelease]];

	[actionButton addGestureRecognizer: [[[UITapGestureRecognizer alloc]
										  initWithTarget: self
										  action: @selector(handleActionButton:)] autorelease]];


	//Tapping
	//We have a single tap and a double tap; naturally the single tap
	//requires the double tap to fail. See notes in handleTap for 
	//the implications of that.
	NTITapCatchingGestureRecognizer* doubleTapGesture = [[[NTITapCatchingGestureRecognizer alloc] 
												 initWithTarget: self
												 action: @selector(handleDoubleTap:)] autorelease];
	
	doubleTapGesture.numberOfTapsRequired = 2;
	[_webview addGestureRecognizer: doubleTapGesture];

	[self->_webview addGestureRecognizer: 
	 tapGesture = [[NTITapCatchingGestureRecognizer alloc] initWithTarget: self action: @selector(handleTap:)]];

	
	//TODO: We used to have a long tap that single tap also 
	//required to fail. Why was that? It doesn't seem to do anything
	/*
	UIGestureRecognizer* longTapInWeb = nil;
	[_webview addGestureRecognizer:
	 longTapInWeb = [[[NTILongPressCatchingGestureRecognizer alloc] initWithTarget: self action: @selector(noOp:)]autorelease]];
	[tapGesture requireGestureRecognizerToFail: longTapInWeb];
	[tapGesture canBePreventedBy: longTapInWeb];
	*/

	[tapGesture requireGestureRecognizerToFail: doubleTapGesture];	
	[tapGesture canBePreventedBy: doubleTapGesture];
	[doubleTapGesture canPrevent: tapGesture];

	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(menuShowing:)
	 name: UIMenuControllerWillShowMenuNotification
	 object: nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(menuHiding:)
	 name: UIMenuControllerDidHideMenuNotification
	 object: nil];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(keyboardShowing:)
	 name: UIKeyboardWillShowNotification
	 object: nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(keyboardHiding:)
	 name: UIKeyboardDidHideNotification
	 object: nil];

	
	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(defaultsChanged:)
	 name: NSUserDefaultsDidChangeNotification
	 object:nil];
	 
	 [[NSNotificationCenter defaultCenter]
	  addObserver: self
	  selector: @selector(remoteNotification:)
	  name: NTINotificationRemoteNotificationRecvName
	  object: nil];
	
	[searchButton addGestureRecognizer:
	 [[[NTITapCatchingGestureRecognizer alloc] initWithTarget: self
													   action: @selector(handleSearchButton:)] autorelease]];

	
	[prevButton addGestureRecognizer:
	 [[[NTITapCatchingGestureRecognizer alloc] initWithTarget: self
													   action: @selector(prevButton:)] autorelease]];
	[nextButton addGestureRecognizer:
	 [[[NTITapCatchingGestureRecognizer alloc] initWithTarget: self
													   action: @selector(nextButton:)] autorelease]];

	[NTIWindow addTapAndHoldObserver: self
							selector: @selector(contextualMenuAction:)
							  object: nil];

	//Load navigation. This could block, so do it in the background.
	dispatch_async( dispatch_get_global_queue(0, 0), ^{
	Library* localLibrary = [Library sharedLibrary];
	id rootNavItem = [localLibrary rootNavigationItem];
	//But then finish manipulating our views in the main thread.
	dispatch_async( dispatch_get_main_queue(), ^{
	//NTINavigationItem* rootNavItem = localLibrary.rootNavigationItem;
	NTINavigationTableViewController* tableCont
	= [[NTINavigationTableViewController alloc]
	   initWithStyle: UITableViewStylePlain
	   item: rootNavItem
	   controller: self];
	actionViewController = [[UINavigationController alloc]
							initWithRootViewController: tableCont];
	[actionButton setEnabled: YES];
	[tableCont release];
	[navHeaderController setRoot: rootNavItem];

	[_webview addScrollDelegate: self];
	[self addChildViewController: self->navHeaderController animated: NO];
		
	[self addChildViewController: self->noteIndicator animated: NO];
	CGRect webViewFrame = [self webview].frame;
	CGRect indicatorFrame = [self->noteIndicator view].frame;
	indicatorFrame.origin.x = 0;
	indicatorFrame.origin.y = webViewFrame.origin.y;
	self->noteIndicator.view.frame = indicatorFrame;
	[self.rootView addSubview: self->noteIndicator.view];

	if( self->afterViewDidLoad ) {
		//FIXME: Sometimes the library hasn't really loaded yet?
		//We get back empty paths when we shouldn't. We force the barrier through
		//the Library again to help.
		NSArray* path = [[[Library sharedLibrary] rootNavigationItem] pathToID: self->afterViewDidLoad];
		if( ![NSArray isEmptyArray: path] ) {
			[self navigateToItem: [path lastObject]];
		}
		else {
			NSLog( @"WARN: Failed to restore location %@; race?", self->afterViewDidLoad );
			[(NTIApplicationViewController*)[[TestAppDelegate sharedDelegate] topViewController] goHome];	
		}
		NTI_RELEASE( self->afterViewDidLoad );
	}
	else if( self.ntiPageId ) {
		[navHeaderController displayNavigationToPageID: self.ntiPageId];
	}
	});});

}
#define TAG_GUTTER 748
-(UIScrollView*)gutter
{
	[self view];
	return (UIScrollView*)[self.rootView viewWithTag: TAG_GUTTER];
}

-(NTIWebView*)webview
{
	[self view];
	return self->_webview;
}

-(void)setWebview: (NTIWebView*)v
{
	[v retain];
	[self->_webview release];
	self->_webview = v;
}

-(void)addSubviewOnTopOfWeb: (UIView*)view
{
	[self.rootView insertSubview: view aboveSubview: self->_webview];	
}

-(void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[_webview release];

	[tapGesture release];
	[ntiButton release];
	[settingButton release];

	[settingViewController release];
	[actionViewController release];
	[popoverController release];

	[actionButton release];

	[navHeaderController release];

	[rootView release];
	[tapZoneLower release];
	[tapZoneUpper release];

	[prevButton release];
	[nextButton release];

	[self setFeedbackButton:nil];
	[self setSearchButton:nil];
	[super viewDidUnload];
}

-(void)didReceiveMemoryWarning
{
	if( self->settingViewController ) {
		if( ![self->settingViewController isViewLoaded] ) {
			NTI_RELEASE( self->settingViewController );
		}
		else if( !self->settingViewController.view.window ) {
			NTI_RELEASE( self->settingViewController );
		}
	}
    [super didReceiveMemoryWarning];
}

static bool menuShowing;
-(void)menuShowing: (id)_
{
	menuShowing = YES;
}
-(void)menuHiding: (id)_
{
	menuShowing = NO;
}

static bool keyboardShowing;
-(void)keyboardShowing: (id)_
{
	keyboardShowing = YES;	
}

-(void)keyboardHiding: (id)_
{
	keyboardShowing = NO;	
}

-(void)defaultsChanged: (id)_
{
	//When the defaults change, we may need to fetch updated
	//CSS that match. Thus, switch the policy. When we fetch new data,
	//we'll reset this.
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];
	if(		[self->fontFace isEqual: prefs.fontFace]
	   &&	[self->fontSize isEqual: prefs.fontSize]
	   &&	[self->highlightColor isEqual: prefs.highlightColor]
	   &&	self->notesEnabled == prefs.notesEnabled
	   &&	self->highlightsEnabled == prefs.highlightsEnabled ) {
		return;
	}
	BOOL firstTime = self->fontFace == nil;
	NTI_RELEASE( self->fontFace );
	NTI_RELEASE( self->fontSize );
	NTI_RELEASE( self->highlightColor );
	self->fontFace = [prefs.fontFace retain];
	self->fontSize = [prefs.fontSize retain];
	self->notesEnabled = prefs.notesEnabled;
	self->highlightsEnabled = prefs.highlightsEnabled;
	self->highlightColor = [prefs.highlightColor retain];
	if( !firstTime ) {
		self->cachePolicy = NSURLRequestReloadRevalidatingCacheData;
	}
	
}

-(void)noOp: (id)_
{}

-(void)postWillLoadNotification: (NTINavigationItem*)navItem
{
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName: WebAndToolControllerWillLoadPageId
	 object: self
	 userInfo: [NSDictionary dictionaryWithObject: navItem 
										   forKey: WebAndToolControllerWillLoadPageIdKeyNavigationItem]];
}

-(id)navigateToItem: (NTINavigationItem*)navItem
{
	if( !navItem ) {
		return self;
	}
	//Close any popover opened for this page.
	[[TestAppDelegate sharedDelegate] dismissPopoverAnimated: NO];
	
	if( !navItem.parent ) {
		//Trying to go to the root nav item is the same
		//as going to the library.
		[[[TestAppDelegate sharedDelegate] topViewController] goHome];
		return self;
	}
	[self postWillLoadNotification: navItem];
	
	NSString* localRoot = [navItem objectForKey: kNTINavigationPropertyRoot];

	if( localRoot && ![[navItem href] hasPrefix: localRoot] ) {
		//If the href is fully qualified, e.g., file://localhost/path/
		//then leave it alone.
		if( [[NSURL URLWithString: navItem.href] host] ) {
			localRoot = [navItem href];
		}
		else {
			//If we tried to append a FQ URL here, the double-slashes
			//would get tromped on.
			localRoot = [localRoot stringByAppendingPathComponent: [navItem href]];
		}
	}
	else {
		localRoot = [navItem href];
	}
	id overrideRoot = [navItem objectForKey: kNTINavigationPropertyOverrideRoot];
	if( overrideRoot ) {
		[self _navigateRelative: [[NSURL URLWithString: localRoot relativeToURL: overrideRoot] absoluteString]];
	}
	else {
		[self _navigateRelativeToRoot: localRoot];
	}
	return self;
}

- (void)enableActionButton
{
	[actionButton setEnabled: YES];
}

static void flash( UIView* v )
{
	v.hidden = NO;
	v.alpha = 0.0;

	id animateIn = ^{
		v.backgroundColor = [UIColor lightGrayColor];
		v.alpha = 0.3;
	};
	id animateOut = [^{
		v.alpha = 0.0;
	} copy];
	id complete = nil;
	complete = [^(BOOL b){
		v.hidden = YES;
		[animateOut release];
		[complete release];
	} copy];

	[UIView animateWithDuration: 0.3 delay: 0.0
						options: UIViewAnimationOptionCurveEaseIn
					 animations: animateIn
					 completion: ^(BOOL b){
						 [UIView animateWithDuration: 0.2 delay: 0.0
											 options: UIViewAnimationOptionCurveEaseOut
										  animations: animateOut
										  completion: complete ]; } ];
}

//The complicated point conversion seems necassary when rotation
//is involved
#define POINTS_IN_TZS \
CGPoint ptInView = [tap locationInView: self->_webview]; \
CGPoint ptInWindow = [self->_webview convertPoint: ptInView toView: self->_webview.window]; \
CGPoint ptInUpper = [self->_webview.window convertPoint: ptInWindow toView: tapZoneUpper]; \
CGPoint ptInLower = [self->_webview.window convertPoint: ptInWindow toView: tapZoneLower];

- (void)handleTap: (UITapGestureRecognizer*)tap
{
	if( tap.state != UIGestureRecognizerStateEnded  || menuShowing ) {
		return;
	}
	//Because the context (edit) menu depends on which thing was the
	//first responder last, we need to make sure the webview is when
	//its tapped on. Normally, it wouldn't automatically take it. (If we
	//don't, then the OUIEditableFrame can steal our menus permanently.)
	//We don't do this if the keyboard is showing because there's a useful 
	//first responder already
	//FIXME: This interacts badly with overlaid text fields, you
	//cant unfocus them by tapping outside.
	if( !keyboardShowing ) {
		[self->_webview becomeFirstResponder];
	}
	CGPoint webPoint = [tap locationInView: self->_webview];
	if( ![self->_webview wantsTapAtPoint: webPoint] ) {

		//Was it in a tap zone?
		//Notice we don't scroll if the menu is showing: the tap could be to clear
		//the menu and we don't want to jerk the user around
		POINTS_IN_TZS
		if( [tapZoneUpper pointInside: ptInUpper withEvent: nil] ) {
			[_webview scrollUp];
			flash( tapZoneUpper );
		}
		else if( [tapZoneLower pointInside: ptInLower withEvent: nil] ) {
			[_webview scrollDown];
			flash( tapZoneLower );
		}
		
		//Here is where we would toggle the chrome (if we didn't hide notes)
		//if we wanted to
	}
	//This tap recognizer requires the double-tap to fail. This
	//gets it involved in the failure chain of the view's own
	//recognizers, which means that the view won't get the hitTest:
	//and touchesEnded: events it wants to intercept, so we manually forward them on
	//Note that we don't do this for arbitrary points it wants; it seems
	//that points it wants, which include links, still get passed to it
	else if( [self->_webview wantsTapAtPointToIntercept: webPoint] ) {
		[self->_webview interceptTapAtPoint: webPoint];
	}
}

-(void)prevButton: (UITapGestureRecognizer*)tap
{
	[self navigateToItem: self.previousNavigationItem];
}

-(void)nextButton: (UITapGestureRecognizer*)tap
{
	[self navigateToItem: self.nextNavigationItem];
}


-(void)handleDoubleTap: (UITapGestureRecognizer*)tap
{
	if( tap.state != UIGestureRecognizerStateEnded ) {
		return;
	}
	POINTS_IN_TZS
	BOOL webviewRejects = ![self->_webview wantsTapAtPoint: ptInView];
	id prev = self->_webview.ntiPrevHref;
	id next = self->_webview.ntiNextHref;
	if( webviewRejects ) {
		//FIXME: Doing this only at the top or bottom. The current
		//'heuristics' suck so bad they are worthless.
		if(	[tapZoneUpper pointInside: ptInUpper withEvent: nil] ) {
			if( prev /*&& self->_webview.htmlScrollVerticalPercent < 20 */ ) {
				flash( tapZoneUpper );
				[self prevButton: tap];
			}
		}
		else if( [tapZoneLower pointInside: ptInLower withEvent: nil] ) {
			if( next /*&& self->_webview.htmlScrollVerticalMaxPercent > 50 */) {
				flash( tapZoneLower );
				[self nextButton: tap];
			}
		}
	}
}
#undef POINTS_IN_TZS

- (void)showPopoverFrom: (id)sender
					 at: (CGRect*)at
				 inView: (UIView*)view
			 controller: (UIViewController*)controller
{

	if( popoverController == nil ) {
		popoverController = [[UIPopoverController alloc]
							 initWithContentViewController: controller];
		[popoverController setDelegate: self];
	}
	if( sender == lastShownPopoverFrom && [popoverController isPopoverVisible] ) {
		[self dismissPopover];
	}
	else {
		//FIXME: Should be using different popover controller objects for
		//each distinct controller. That's the pattern, and OUI gritches if we don't
		//and we wind up leaking objects. To counteract this, we first dismiss
		//the popover before moving it.
		if( [popoverController isPopoverVisible] ) {
			[[TestAppDelegate sharedDelegate] dismissPopover: popoverController animated: NO];
		}
		if( controller != [popoverController contentViewController] ) {
			[popoverController setContentViewController: controller
											   animated: YES];

			[popoverController setPopoverContentSize: [controller contentSizeForViewInPopover]];
		}
		[popoverController setPassthroughViews: nil];

		if( at != NULL ) {
			//And interact with that view. We're using it like a toolbar
			[popoverController setPassthroughViews: [NSArray arrayWithObject: view]];
			[[TestAppDelegate sharedDelegate]
			 presentPopover: self->popoverController
			 fromRect: *at
			 inView: view
			 permittedArrowDirections: UIPopoverArrowDirectionAny
			 animated: YES];
			lastShownPopoverFrom = sender;
		}
		else if( [sender isKindOfClass: [UIGestureRecognizer class]] ) {
			[popoverController setPassthroughViews: [NSArray arrayWithObject: toolbar]];
			[[TestAppDelegate sharedDelegate]
			 presentPopover: self->popoverController
			 fromRect: [[sender view] frame]
			 inView: toolbar
			 permittedArrowDirections: UIPopoverArrowDirectionAny
			 animated: YES];
			lastShownPopoverFrom = sender;
		}
		else {
			NSLog( @"Don't know how to present popover!" );
		}

	}

}


-(void)showPopoverFrom: (id)sender
			controller: (UIViewController*)controller
{
	[self showPopoverFrom: sender at: NULL inView: nil controller: controller];
}

-(id)dismissPopover
{
	[[TestAppDelegate sharedDelegate] dismissPopover: self->popoverController animated: YES];
	return self;
}

-(UINavigationController*)settingViewController
{
	if( settingViewController == nil ) {
		settingViewController = [[UINavigationController alloc] 
								  initWithRootViewController: [[[NTIInlineSettingController alloc]
															   initWithNibName: @"InlineSettingView"
															   bundle: [NSBundle mainBundle]
														   webView: self] autorelease]];
	}
	return (id)[[settingViewController retain] autorelease];
}

-(void) handleSettingButton: (id)sender
{
	[self showPopoverFrom: sender 
			   controller: self.settingViewController];
}

-(void) handleNTIButton: (id)sender
{
	[self showPopoverFrom: sender
			   controller: self->master];
}

-(void)handleSearchButton: (id)sender
{
	NTIStackedSearchController* search = [[[NTIStackedSearchController alloc] init]autorelease];
	NTISearchContentController* content = [[[NTISearchContentController alloc] init] autorelease];
	NTISearchUserDataController* ugd = [[[NTISearchUserDataController alloc] init] autorelease];
	content.navigationItem.title = @"Content Search Results";
	ugd.navigationItem.title = @"User Search Results";
	content.webController = self;
	ugd.webController = self;
	search.searchBar.delegate = content;
	[content setNext: ugd];									   
																				 
	NTIStackedSubviewViewController* stack = [[[NTIStackedSubviewViewController alloc]
	  initWithSearchController: search
	  controllers: [NSArray arrayWithObjects: content, ugd, nil]]
	 autorelease];
	CGRect at = [[sender view] frame];
	[self showPopoverFrom: sender
					   at: &at
				   inView: [[sender view] superview]
			   controller: stack];
}

-(void)showNavigationTo: (NTINavigationItem*)item
					 at: (CGRect)location
				 inView: (UIView*)view
				 sender: (id)sender
{
	[actionViewController popToRootViewControllerAnimated: NO];
	[(NTINavigationTableViewController*)[actionViewController topViewController]
	  prepareToDisplayNavigationToPageID: item.ntiid];
	[self showPopoverFrom: sender at: &location inView: view controller: actionViewController];
}

-(void)handleActionButton: (id)sender
{
	[actionViewController popToRootViewControllerAnimated: NO];
	[(NTINavigationTableViewController*)[actionViewController topViewController]
	 prepareToDisplayNavigationToPageID: self.ntiPageId];
	[self showPopoverFrom: sender controller: actionViewController];
}

#pragma mark WebViewDelegate methods
//The page ID is publically readonly, but we declare it writable
//we must use the setter to be sure KVO works
@synthesize ntiPageId;

-(void)setNtiPageId: (NSString*)pid
{
	id gnu = [pid copy];
	[self->ntiPageId release];
	self->ntiPageId = gnu;
}

//We co-operate with the server to request resources that have the font
//face already set. This means we don't need to set them after load.
/**
 * @return YES if we adjusted the URL and started loading a new request.
 * NO otherwise.
 */
static BOOL transformUrlForFontFace( WebAndToolController* self, id v,
									NSMutableURLRequest* request,
									UIWebViewNavigationType navigationType)
{
	BOOL transformed = NO;
	//Naturally this only works if we're hitting a server
	if( [request.URL.scheme isEqual: @"file"] ) {
		//Our local CSS file may have changed. Because of the way the webview works,
		//we can't do anything about that now, wait until the view 
		//finishes loading. See comments in webViewDidFinishLoad. 
		return NO;
	}
	
	NSString* fontSize = self->fontSize;
	NSString* fontFace = self->fontFace;

	if( fontSize && fontFace && ![[[request URL] absoluteString] containsString: @"?face="]  ) {
		if( [fontSize characterAtIndex: [fontSize length] - 1] == '%' ) {
			fontSize = [fontSize substringToIndex: [fontSize length] - 1];
		}
		fontFace = [fontFace stringByReplacingOccurrencesOfString: @" " withString: @"%20"];
		NSURL* url = [NSURL URLWithString: [NSString stringWithFormat:
											@"%@?face=%@&size=%@",
											[request URL],
											fontFace, fontSize]];
		if( !url ) {
			NSLog( @"Unable to transform URL" );
			transformed = NO;
		}
		else {
			request = [[request mutableCopy] autorelease];
			[request setHTTPShouldUsePipelining: YES];
			[request setCachePolicy: self->cachePolicy];
			self->cachePolicy = NSURLRequestReturnCacheDataElseLoad;
			[request setURL: url];
			[request setMainDocumentURL: url];
			[v loadRequest: request];
			transformed = YES;
		}
	}
	return transformed;
}

/**
 * @return YES if we adjusted the URL and started loading a new request.
 * NO otherwise.
 */
static BOOL transformUrlForCID( WebAndToolController* self,
							   NSMutableURLRequest* request ) 
{
	BOOL transformed = NO;
	if( NTIUrlCanHandleScheme( request.URL ) ) {
		transformed = YES;
		NTINavigationItem* item = NTIUrlFindNavigationItem( request.URL, self.navHeaderController.root);
		if( item ) {
			[self navigateToItem: item];
		}
		//otherwise, present a warning?
	}
	return transformed;
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
	OUILogPerformanceMetric( @"Start load" );
	[[TestAppDelegate sharedDelegate] showActivityIndicatorInView: webView];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: YES];
	//Broadcast NIL to observers. Notice we don't do this at the time we 
	//post the "will load" message. The ID stays valid until the current 
	//page has started to change.
	self.ntiPageId = nil;
	[self removeChildViewControllersWithClass: [NTIWebOverlayedFormController class]];
	[[self webview] clearOverlayedFormControllers];
}

- (void)webView: (UIWebView*)view didFailLoadWithError: (NSError *)error
{
	NTI_PRESENT_ERROR( error );
	[[TestAppDelegate sharedDelegate] hideActivityIndicator];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: NO];
	self.ntiPageId = nil;
	//For bad URLs, make sure we don't save them
	if(		[[error domain] isEqual: NSURLErrorDomain]
	   &&	[error code] == NSURLErrorBadURL ) {
		[NTIAppPreferences prefs].lastViewedNTIID = nil;
	}
	//If we can go back, do so
	if( [self->_webview canGoBack] ) {
		[self goBack];
	}
	//Otherwise, boot out to the library
	else {
		[(NTIApplicationViewController*)[[TestAppDelegate sharedDelegate] topViewController] goHome];
	}
}

-(void)displayHighlights: (NSArray*)objects
{
	//We create two lists here.  One is highlights the rest are things that are "notes"
	NSArray* highlights = [objects filteredArrayUsingPredicate: 
						   [NSPredicate predicateWithBlock: 
							^BOOL(id evaluatedObject, NSDictionary* bindings){
								return [evaluatedObject isKindOfClass: [NTIHighlight class]];
							}]];
	
	//Serialize these to json and pass them into javascript.
	NSArray* dictionaries = [highlights arrayByPerformingBlock: ^id(id object){
		return [object toPropertyListObject];
	}];
	
	NSString* json = [dictionaries stringWithJsonRepresentation];
	
//	NSLog(@"Will Load highlights with json ");
//	NSLog(@"%@", json);
	
	[[self webview] callFunction: @"NTIShowHighlightsFromArray" withJson: json];
}

//FIXME copied from NTIUserDataTableModel
//To quiet the analyzer, we call this function
static void _quiet_retain( id o NS_CONSUMED )
{
	return;
}

-(void)loadThenDisplayHighlightsForPage
{
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];
	NTIUserDataLoader* loader = [NTIUserDataLoader
								 dataLoaderForDataserver: prefs.dataserverURL
								 username: prefs.username
								 password: prefs.password
								 page: self.ntiPageId
								 type: kNTIUserDataLoaderTypeGeneratedData
								 delegate: self];
	_quiet_retain( [loader retain] );

}

-(void)dataLoader: (NTIUserDataLoader*)loader didFinishWithResult: (NSArray*)result
{
	[self displayHighlights: result];
	[loader release];
}


-(void)dataLoader: (NTIUserDataLoader*)loader didFailWithError: (NSError*)error
{
	NSLog(@"Error loading highlights. %@", error);
	[loader release];
}


-(void)webViewDidFinishLoad: (UIWebView*)webView
{
	if( self->cachePolicy != NSURLRequestReturnCacheDataElseLoad ) {
		//In order to notice the stylesheet has changed in the local case, we must force
		//a reload. This is disruptive to the user, though,
		//so we only do that when we change pages. We do so by allowing
		//the current load to to through, but as soon as it finishes
		//we do a reload. This causes the new page to flash just once, 
		//but very quickly, as the fonts change, similar to how Safari
		//can sometimes behave. If we try any combination of reloading
		//and stopping the load, we get errors.
		//By doing this before we begin any injection activity, 
		//or read and update the page ID, we avoid double-work by some
		//observers interested in our state.
		self->cachePolicy = NSURLRequestReturnCacheDataElseLoad;
		[self.webview reload];
		return;
	}
	
	
    [[TestAppDelegate sharedDelegate] hideActivityIndicator];

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: NO];
	self->contentOffset = CGPointMake( 0, 0 );
	
	NSLog( @"Begin injection" );

	//The default context menu, document.body.style.webkitTouchCallout,
	//is disabled in CSS.
	//The edit menu, document.body.style.webkitUserSelect, we are customizing
	//in other ways and so leave enabled.

	//Make our injections
	NSString* path = [[NSBundle mainBundle] pathForResource: @"NTIJSInjection" ofType:@"js"];
	OBASSERT( path );
	NSString* jsCode = [NSString stringWithContentsOfFile: path
												 encoding: NSUTF8StringEncoding
													error: nil];
	OBASSERT( jsCode );													
	NSString* result = [self->_webview stringByEvaluatingJavaScriptFromString: jsCode];
	if( OFNOTEQUAL( result,  @"NTIJSInjection_DONE" ) ) {
		OBASSERT_NOT_REACHED("NTIJSInjection not loaded.");
#ifdef DEBUG_NTIJSINJECTION
		abort();
#endif
		//Check for javascript errors
	}
	
	
	//Broadcast page change to observers
	self.ntiPageId = self->_webview.ntiPageId;
	[[NTIAppPreferences prefs] setLastViewedNTIID: self.ntiPageId];
	//FIXME Dirty, nasty, terrible hack but the darn submit button still disappears occasionally
	[[self webview] stringByEvaluatingJavaScriptFromString:@"$('#submit').width()"];

	NTIWebOverlayedFormController* ofController = [[[NTIWebOverlayedFormController alloc]
												   initWithInputsSelector: @"input"
												   submitSelector: @"#submit"] autorelease];
	[self addChildViewController:ofController animated:NO];

	[self->_webview overlayFormController: ofController];

	//We are co-operating with the server (and/or local disk) to avoid
	//having to change fonts after the page is loaded. This helps us avoid
	//a flash of content.
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];

	NSLog( @"Initiating highlight load" );
	[self loadThenDisplayHighlightsForPage];
	
	NSLog( @"Enable notes/hl" );
	//We are currently always using new-style notes, loading them ourself
	[self->_webview stringByEvaluatingJavaScriptFromString: @"NTISuppressNotes = true;"];
	//Highlights we still need to load here.
	if( self->highlightsEnabled ) {
		//Highlights are hidden by default
		[self->_webview showHighlights];
	}

	NSLog( @"On state set" );
	
	[self->_webview stringByEvaluatingJavaScriptFromString: 
	 [NSString stringWithFormat: @"NTIOnStateSet(\"%@\",\"%@\",\"%@\");",
	  [[[NTIAppPreferences prefs] dataserverURL] absoluteString],
	  [prefs username],
	  [prefs password]]];

	if( [navHeaderController root] ) {
		[navHeaderController displayNavigationToPageID: self.ntiPageId];
	}

	//TODO: This belongs in the navigation controller!
	prevButton.enabled = self.previousNavigationItem != nil;
	nextButton.enabled = self.nextNavigationItem != nil;
	NSLog( @"End injection" );
}


//History is managed as two stacks. The current page
//is not on any stack, it's invisibly in the middle

-(BOOL)webView: (UIWebView*)v 
shouldStartLoadWithRequest: (NSMutableURLRequest*)request
navigationType: (UIWebViewNavigationType)navigationType
{
	if( !request ) {
		return NO;
	}

	BOOL shouldStart = NO;
	//If we're going to transform the request, we
	//don't need to load this one, and we don't need to
	//record history.
	if( transformUrlForCID( self, request ) ) {
		shouldStart = NO;	
	}
	else if( navigationType == UIWebViewNavigationTypeLinkClicked ) {
		//If we got a click, the user has touched something inside
		//the page. We would prefer to go through our navigation, if we
		//can find it
		NSURL* url = [request URL];
		if( OFISEQUAL( url.path, v.request.URL.path ) ) {
			//A fragment on the same page, doesn't change anything
			shouldStart = YES;
		}
		else if( [navHeaderController root]
				//TODO: This fails when there are multiple identical
				//file names. We should be looking for a path to the full
				//URL.
				&&	![NSArray isEmptyArray: [[navHeaderController root] pathToHref: url.lastPathComponent]]) {
			NTINavigationItem* item = [[navHeaderController root] pathToHref: url.lastPathComponent].lastObject;
			[self navigateToItem: item];
			shouldStart = NO;
		}
		else if( transformUrlForFontFace( self, v, request, navigationType ) ) {
			//If they click a link and it's not something
			//we control, see if we can at least transform it
			shouldStart = NO;
		}
		else {
			//Nark. We couldn't find what we wanted, no choice but to 
			//let it go through.
			shouldStart = YES;
		}
	}
	else if( transformUrlForFontFace( self, v, request, navigationType ) ) {
		shouldStart = NO;
	}	
	else {
		shouldStart = YES;

		if( navigationType == UIWebViewNavigationTypeBackForward ) {
			//No need to do anything with history, already covered.
		}
		else if( [[v request] URL] ) {
			//OK, have to save current location on the back stack,
			//if we are somewher
			[navigationHistory pushBackItem: self.selectedNavigationItem];
		}
	}
	return shouldStart;
}

#pragma mark WebView Query and Manip Methods


-(void)goBack
{
	if( [_webview canGoBack] ) {
		NTINavigationHistoryItem* destination = [navigationHistory popBackItem];
		[navigationHistory pushForwardItem: self.selectedNavigationItem];
		[self postWillLoadNotification: destination.navigationItem];
		[self->_webview goBack];
	}
}

-(void)goForward
{
	if( [_webview canGoForward] ) {
		NTINavigationHistoryItem* destination = [navigationHistory popForwardItem];
		[navigationHistory pushBackItem: self.selectedNavigationItem];
		[self postWillLoadNotification: destination.navigationItem];
		[self->_webview goForward];
	}
}

-(id)_navigateRelative: (NSString*)href
{
	NSURL* current = [[self->_webview request] URL];
	NSURL* next = [NSURL URLWithString: href relativeToURL: current];
	[self->_webview loadRequest: [NSURLRequest requestWithURL: next]];
	return self;
}

-(id)_navigateRelativeToRoot: (NSString*)href 
{
	NSURL* next = [NSURL URLWithString: href relativeToURL: [[NTIAppPreferences prefs] rootURL]];
	[self->_webview loadRequest: [NSURLRequest requestWithURL: next]];
	return self;
}

-(NSURL*)currentURL
{
	return [[self->_webview request] URL];
}

-(NTINavigationItem*)selectedNavigationItem
{
	NSArray* path = [[navHeaderController root] pathToID: self.ntiPageId];
	NTINavigationItem* result = [path lastObject];
	return result;
}

-(NTINavigationItem*)nextNavigationItem
{
	NTINavigationItem* next = nil;
	NTINavigationItem* selected = [self selectedNavigationItem];
	//If we have children, we want our first child. Otherwise, 
	//within a level, we want the next sibling. If we're at the end of the
	//group, then we want to begin stepping into the parent's next sibling
	NSArray* selectedKids = selected.children;
	if( ![NSArray isEmptyArray: selectedKids] ) {
		next = [selectedKids firstObject];
	}
	else {
		next = selected.nextSibling;
		if( !next ) {
			next = selected.parent.nextSibling;
		}
	}
	return next;
}

-(NTINavigationItem*)previousNavigationItem
{
	NTINavigationItem* selected = [self selectedNavigationItem];
	//Within a group, we want the previous sibling. If we're at the end of the
	//group, then we want to go back to the parent.
	//TODO: Do we want to go to the previous sibling's last child? That would
	//make us consistent with next, but it seems that previous 
	//might actually want to navigate at the same level.
	NTINavigationItem* prev = selected.previousSibling;
	if( !prev ) {
		prev = selected.parent;
	}
	return prev;	
}

- (void)openContextualMenuForHTMLTouchAt: (CGPoint)pt
{
	//get the Tags at the touch location
	NSString* tags = [self->_webview
					  stringByEvaluatingJavaScriptFromString:
					  [NSString stringWithFormat: @"NTIGetHTMLElementsAtPoint(%i,%i);",
					   (NSInteger)pt.x, (NSInteger)pt.y]];

	//create the UIActionSheet and populate it with buttons related to the tags
	UIActionSheet* sheet = [[UIActionSheet alloc]
							initWithTitle: @"Contextual Menu"
							delegate: (id)self
							cancelButtonTitle: @"Cancel"
							destructiveButtonTitle: nil
							otherButtonTitles:nil];

	//If a link was touched, add link-related buttons
	if( [tags rangeOfString:@",A,"].location != NSNotFound) {
		[sheet addButtonWithTitle:@"Open Link"];
		[sheet addButtonWithTitle:@"Open Link in Tab"];
		[sheet addButtonWithTitle:@"Download Link"];
	}
	//If an image was touched, add image-related buttons
	if( [tags rangeOfString:@",IMG,"].location != NSNotFound) {
		[sheet addButtonWithTitle: @"Save Picture"];
	}

	//Add buttons which should be always available
	[sheet addButtonWithTitle: @"Save Page as Bookmark"];
	[sheet addButtonWithTitle: @"Open Page in Safari"];

	[sheet showInView: self->_webview];
	[sheet release];
}

-(void)contextualMenuAction: (NSNotification*)notification
{
#ifdef DEBUG_POINT_CONVERSION
	CGPoint pt = [NTIWindow windowPointFromNotification: notification];
	CGPoint webPt = [self->_webview convertPoint: pt
										fromView: notification.object];
	if( ![self->_webview pointInside: webPt withEvent: nil] ) {
		NSLog( @"Long touch at %@ not inside webview",
			NSStringFromCGPoint( pt ) );
		return;
	}
	CGPoint docpt = [self->_webview htmlDocumentPointFromWindowPoint: pt];
	NSLog( @"Ignoring context menu action at %@/%@",
		  NSStringFromCGPoint( pt ), NSStringFromCGPoint( docpt ) );
	NSArray* tags = [self->_webview htmlElementNamesAtWindowPoint: pt];
	NSLog( @"Tags at point %@", tags );
#endif
}

-(void)remoteNotification: (NSNotification*)notification
{
	if( !self.isViewLoaded || self.view.hidden || !self.view.window ) {
		return;
	}
	
	NSDictionary* userInfo = notification.userInfo;
	
	NSDictionary* aps = [userInfo objectForKey: @"aps"];
	if( [aps objectForKey: @"alert"] ) {
		//TODO: Handling the advanced versions of alert
		OUIOverlayView* overlay = [[[OUIOverlayView alloc] 
									initWithFrame: CGRectMake(300, 100, 200, 26)]
								   autorelease];
		overlay.text = [aps objectForKey: @"alert"];
		CGPoint topCenter = CGPointMake( self.view.bounds.size.width / 2, 0 );
		[overlay centerAtPoint: topCenter
					withOffset: CGPointMake( 0, 10 )
				  withinBounds: self.view.bounds];
		[overlay displayTemporarilyInView: self.view];
	}
	

}

#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)hideChromeWithDuration: (NSTimeInterval)duration
{
	[UIView animateWithDuration: duration
					 animations: ^(void) 
	 				{
						[toolbar setAlpha: 0.0];
						CGRect f = toolbar.frame;
						f.origin.y = 0 - f.size.height;
						toolbar.frame = f;
						f = navBar.frame;
						f.origin.y = 0;
						navBar.frame = f;
						
						f = _webview.frame;
						f.origin.y = navBar.frame.size.height;
						_webview.frame = f;
						
						f = tapZoneUpper.frame;
						f.origin.y = _webview.frame.origin.y;
						tapZoneUpper.frame=f;
	
						f = self.gutter.frame;
						f.origin.y = _webview.frame.origin.y;
						f.size.height = _webview.frame.size.height;
						self.gutter.frame = f;
						
						f = [self->noteIndicator view].frame;
						f.origin.y = _webview.frame.origin.y;
						[self->noteIndicator view].frame=f;
						
					}
					 completion: nil];
}

-(void)showChromeWithDuration: (NSTimeInterval)duration
{
	[UIView animateWithDuration: duration 
						  delay: 0.0 
						options: UIViewAnimationOptionAllowUserInteraction
							 & UIViewAnimationOptionCurveEaseIn
							 & UIViewAnimationOptionTransitionNone
					 animations: ^(void) 
					{
						[toolbar setAlpha: 1.0];
						CGRect f = toolbar.frame;
						f.origin.y = 0 ;
						toolbar.frame = f;
						
						f = navBar.frame;
						f.origin.y = toolbar.frame.size.height;
						navBar.frame = f;
						
						
						f = _webview.frame;
						f.origin.y = toolbar.frame.size.height + navBar.frame.size.height;
						//f.size.height = 1024 - 66;
						_webview.frame = f;
						
						f = tapZoneUpper.frame;
						f.origin.y = _webview.frame.origin.y;
						tapZoneUpper.frame=f;
						
						f = self.gutter.frame;
						f.origin.y = _webview.frame.origin.y;
						f.size.height = _webview.frame.size.height;
						self.gutter.frame = f;
						
						f = [self->noteIndicator view].frame;
						f.origin.y = _webview.frame.origin.y;
						[self->noteIndicator view].frame=f;
					 }
					 completion: nil];	
}

-(void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)orientation
							   duration: (NSTimeInterval)duration
{
	UIInterfaceOrientation old = self.interfaceOrientation;
	if( self.splitViewController ) {
		//Transfer the clutter to the side panel in landscape.
		if(		UIInterfaceOrientationIsLandscape( orientation )
		   &&	UIInterfaceOrientationIsPortrait( old) ) {
			[self hideChromeWithDuration: duration];
		}
		else if( 	UIInterfaceOrientationIsPortrait( orientation )
				&&	UIInterfaceOrientationIsLandscape( old) ) {
			[self showChromeWithDuration: duration];
		}
	}
	[super willRotateToInterfaceOrientation: orientation duration: duration];

}

-(BOOL)canPerformAction: (SEL)action withSender: (id)sender
{
	if(	[master respondsToSelector: action] ) {
		return [master canPerformAction: action withSender: sender];
	}
	//TODO: If we let the super enable copy: (the only action it would enable),
	//then we can get AT MOST one item in the menu (and if two are possible, we
	//get a 'more...' menu). OTOH, if we disable
	//copy:, then we can have several actions at the top level
	return [super canPerformAction: action withSender: sender];
}

-(id)forwardingTargetForSelector:(SEL)aSelector
{
	if( [master respondsToSelector: aSelector] ) {
		return master;
	}
	
	return [super forwardingTargetForSelector: aSelector];
}

#pragma mark -
#pragma mark NTIWebContextViewController methods

@synthesize miniCreationAction, miniViewTitle, miniView, presentsModalInsteadOfZooming;

-(BOOL)supportsZooming
{
	return YES;
}

-(NSString*)miniViewTitle
{
	return self->_webview.title;
}

-(CGFloat)miniViewHeight
{
	return self->miniView.bounds.size.height;
}

-(UIView*)view
{
	return [super view];
}

-(UIView*)miniView
{
	return miniView;
}

/**
 * Draws the layers of the view and its subviews. 
 * Note that this doesn't take tiled layers into account so things like
 * the UIWebView won't draw their entire contents: just the first screen.
 */
static void drawRecurse( CGContextRef ctx, UIView* view, CGPoint offset )
{
	CGContextSaveGState( ctx );
	CGContextTranslateCTM( ctx, view.frame.origin.x, view.frame.origin.y );
	[view.layer renderInContext: ctx];
	CGContextRestoreGState( ctx );
	for( UIView* subview in view.subviews ) {
		drawRecurse( ctx, subview, offset );
	}
}

-(void)willBeZoomedByController: (id)c
{
	if( self->miniView ) {
		//Currently minimized, going to maximize
		NTI_RELEASE( self->miniView );
		
	}
	else {
		//Currently maximized, going to minimize.
		
		//Maintain aspect ratio. Our width is fixed, so scale
		//the height (up)
		CGSize destSize = CGSizeMake( 300, 209 );
		CGSize rootSize = self.rootView.bounds.size;
		CGFloat rootRatio = rootSize.width / rootSize.height;
		destSize.height = destSize.width / rootRatio;
		
		UIGraphicsBeginImageContextWithOptions( destSize, NO, 0.0 );
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		CGContextScaleCTM( ctx, destSize.width / rootSize.width,  destSize.height/rootSize.height );
		drawRecurse( ctx, self.rootView, self.rootView.frame.origin );
		UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		NTIDraggableImageView* view = [[NTIDraggableImageView alloc] 
									   initWithImage: image
									   dragResponder: self];
		
		view.userInteractionEnabled = YES;
		//FIXME: This code is basically in two places
		CGRect bounds;
		bounds.origin = CGPointZero;
		bounds.size = destSize;
		view.frame = bounds;
		[miniView release];
		miniView = view;
	}
}

#pragma mark -
#pragma mark Drag Source
-(id)dragOperation: (id<NTIDraggingInfo>)drag objectForDestination: (id)destination
{
	//Our URL is draggable. We dispense internal URLs
	return NTIUrlFromContentID( self.ntiPageId );
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	NTI_RELEASE( self->fontSize );
	NTI_RELEASE( self->fontFace );
	NTI_RELEASE( self->highlightColor );
	NTI_RELEASE( self->noteIndicator );
    [_webview release];
	[tapGesture release];
	[ntiButton release];
	[settingButton release];

	[settingViewController release];
	[actionViewController release];
	[popoverController release];

	[actionButton release];

	[navHeaderController release];

	[navigationHistory release];

	[rootView release];
	[tapZoneLower release];
	[tapZoneUpper release];

	[prevButton release];
	[nextButton release];

	self.feedbackButton = nil;
	self.versionLabel = nil;
	
	[feedbackButton release];
	[searchButton release];
	[super dealloc];
}

@end
