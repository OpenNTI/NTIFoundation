//
//  NTILibraryViewController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTILibraryViewController.h"
#import "LibraryView.h"
#import "Library.h"
#import "NTIUtilities.h"

#import "NTIUserProfileViewController.h"
#import "NTIInspector.h"

@implementation NTILibraryViewController

-(id)initWithNibName: (NSString*)nibNameOrNil 
			  bundle: (NSBundle*)nibBundleOrNil
			  target: (id)_target
			  action:(SEL)_action
{
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
	self->nr_target = _target;
	self->action = _action;
	[Library registerSyncProgressObserver: self selector: @selector(libraryDidProgress:)];
	return self;
}

-(IBAction)infoButtonTouched: (id)sender 
{
	NTIUserProfileViewController* userProf = [[NTIUserProfileViewController alloc] 
											  initWithPresentingViewController: self];
	UINavigationController* nav = [[[UINavigationController alloc]
								   initWithRootViewController: userProf] autorelease];

	nav.modalPresentationStyle = userProf.modalPresentationStyle;
	nav.modalTransitionStyle = userProf.modalTransitionStyle;
	
	[userProf inspectFromBarButtonItem: nil];
	[self presentModalViewController: nav
							animated: YES];
}

-(BOOL)canPerformAction: (SEL)a withSender: (id)sender
{
	return	a == @selector(infoButtonTouched:) 
		||	[super canPerformAction: a withSender: sender];
}

-(void)libraryDidProgress: (NSNotification*)note
{
	//This comes in on arbitrary threads. We can only manipulate the UI
	//from the main thread.
	dispatch_async( dispatch_get_main_queue(), ^{
	if( [note isSynchronizing] || [note isDownloading] ) {
		[self->synchronizingActivity startAnimating];
		[self->synchronizingLabel setHidden: NO];
		if( [note isDownloading] ) {
			[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		}
		else {
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		}
		
		NSString* progress = @"";
		if( [note progressPercent] ) {
#if defined (__LP64__) || defined(NS_BUILD_32_LIKE_64)
			progress = [NSString stringWithFormat: @" (%ld%%)", [note progressPercent]];
#else
			progress = [NSString stringWithFormat: @" (%d%%)", [note progressPercent]];
#endif
		}
		NSString* title = @"";
		
		if( [note title] ) {
			title = [@" " stringByAppendingString: note.title];
		}
		self->synchronizingLabel.text = [@"Synchronizing"
										 stringByAppendingFormat: @"%@%@",
										 title, progress];
	}
	else {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		[self->synchronizingActivity stopAnimating];
		[self->synchronizingLabel setHidden: YES];
	}
	[self.view setNeedsDisplay];});
}

-(void)viewDidLoad
{
	self.view.frame = CGRectMake( 0, 20, 
								 self.view.frame.size.width, self.view.frame.size.height );	
}

-(LibraryView*)libraryView
{
	return (id)[self.view viewWithTag: 1];
}

-(void)viewWillAppear: (BOOL)animated
{
	//This could block, do it in the background.
	dispatch_async( dispatch_get_global_queue( 0, 0 ), ^{
		id rootNavItem = [Library sharedLibrary].rootNavigationItem;
		//Finish manip in the main thread.
		[rootNavItem addObserver: self
					  forKeyPath: @"children"
						 options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
						 context: NULL];			
	});
	[super viewWillAppear: animated];
}


-(void)observeValueForKeyPath: (NSString*)keyPath
					 ofObject: (id)object
					   change: (NSDictionary*)change 
					  context: (void*)context
{
	if( [@"children" isEqual: keyPath] ) {
		dispatch_async( dispatch_get_main_queue(), ^{
			self.libraryView.toObserve = object;
			self.libraryView.keyPath = @"children";
			self.libraryView.tapAction = @selector(_libraryViewWasTapped:);
			self.libraryView.tapTarget = self;
			[self.libraryView populateGrid];
		});
		
	}
}

-(void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation 
							   duration: (NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation: toInterfaceOrientation duration: duration];
	if( !self.isViewLoaded ) {
		return;
	}
	
	if( UIInterfaceOrientationIsLandscape( toInterfaceOrientation ) ) {
		[self.libraryView setBackgroundColor: 
		 [UIColor colorWithPatternImage: [UIImage imageNamed: @"Default-Landscape.png"]]];
	}
	else {
		[self.libraryView setBackgroundColor:
		 [UIColor colorWithPatternImage: [UIImage imageNamed: @"Default-Portrait.png"]]];
	}

}

-(void)didRotateFromInterfaceOrientation: (UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.libraryView redrawAll];
}

-(void)_libraryViewWasTapped: (id)sender
{
	id navItem = ((NTIGridItemView*)[sender view])->nr_model;
	[self->nr_target performSelector: self->action
						  withObject: navItem];
}

-(void)viewDidUnload
{
	NTI_RELEASE( self->synchronizingLabel );
	NTI_RELEASE( self->synchronizingActivity );
}

-(void)dealloc
{
	NTI_RELEASE( self->synchronizingActivity );
	NTI_RELEASE( self->synchronizingLabel );
	[[NSNotificationCenter defaultCenter]
	 removeObserver: self];

	[super dealloc];
}

@end
