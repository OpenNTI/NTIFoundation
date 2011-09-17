//
//  NTIApplicationViewController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NTIApplicationViewController.h"
#import "WebAndToolController.h"
#import "NTILibraryViewController.h"
#import "NTINavigationParser.h"
#import "NTIAppPreferences.h"
#import "TestAppDelegate.h"
#import "NTIUrlScheme.h"

@interface UISplitViewController(NTIWebControllerExtensions)
@property (readonly) WebAndToolController* webController;
@end

@implementation NTIApplicationViewController

@synthesize topViewController;

-(id)initWithNibName: (NSString*)nibNameOrNil bundle: (NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
	self->bookController = [WebAndToolController createSplitViewController];
	[self addChildViewController: self->bookController
						animated: NO];
	
	self->libraryController = [[NTILibraryViewController alloc]
							   initWithNibName: @"LibraryView"
							   bundle: nil
							   target: self
							   action: @selector(goToItem:)];
	
	[self addChildViewController: self->libraryController
						animated: NO];
	self->topViewController = self->libraryController;
	
	NSString* lastID = [[NTIAppPreferences prefs] lastViewedNTIID];
	if( lastID ) {
		self->topViewController = self->bookController;
		[[self->bookController.viewControllers objectAtIndex: 1]
		 afterViewDidLoadThenLoadID: lastID];
	}
	
    return self;
}

-(void)dealloc
{
	[self->libraryController release];
	[self->bookController release];
	[super dealloc];
}

-(WebAndToolController*)webAndToolController
{
	return [self->bookController.viewControllers objectAtIndex: 1];
}

-(WebAndToolController*)bookController
{
	return [self webAndToolController];
}

-(BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	//Let them know it's being asked
	[super shouldAutorotateToInterfaceOrientation: interfaceOrientation];
	//But force the answer
	return YES;
}

-(void)loadView
{
	self.view = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, 768, 1024)] autorelease];
	self.view.autoresizingMask = 0x1F;
	self.view.autoresizesSubviews = YES;
}

//Trying to do the view switching by changing out our .view property
//was buggy. It is better to manage a single view with child views that
//we add and remove or hide and show. Hiding and showing means we get
//rotation for free.
-(void)viewDidLoad
{
	self->bookController.view.frame = CGRectMake( 0, 0, 768, 1024 );
	self->libraryController.view.frame = CGRectMake( 0, 0, 768, 1024 );
	[self.view addSubview: self->bookController.view];	
	[self.view addSubview: self->libraryController.view];	
	self->bookController.view.hidden = self->topViewController != self->bookController;
	self->libraryController.view.hidden = self->topViewController != self->libraryController;
}

static void switchTo( NTIApplicationViewController* self, UIViewController* to )
{
	if( to == self->topViewController ) {
		return;
	}
	UIView* oldView = self.topViewController.view;
	UIView* newView = to.view;

	oldView.hidden = YES;
	newView.hidden = NO;
	[self.view bringSubviewToFront: newView];

	self->topViewController = to;
}

-(void)goHome
{
	switchTo( self, self->libraryController );
	[[NTIAppPreferences prefs] setLastViewedNTIID: nil];
	[[TestAppDelegate sharedDelegate] dismissPopoverAnimated: NO];
}

-(void)goWeb
{
	switchTo( self, self->bookController );
}

-(void)goToItem: (NTINavigationItem*)item
{
	if( ![item parent] ) {
		[self goHome];
	}
	else {
		[self goWeb];
		[[self bookController] navigateToItem: item];
	}
}

-(void)goToUrl: (NSURL*)url
{
	if( !NTIUrlCanHandleScheme( url ) ) {
		return;
	}
	
	[[self bookController] 
	 afterViewDidLoadThenLoadID: [url resourceSpecifier]];
}

@end
