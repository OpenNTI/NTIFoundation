//
//  NTIFriendsListsViewController.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/09.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTILabeledGridListView.h"
#import "NTIFriendsListsViewController.h"
#import "NTIUtilities.h"
#import "NTIGravatars.h"
#import "NTIUserData.h"
#import "NTIAppUser.h"
#import "NSArray-NTIExtensions.h"
#import "NTIDraggingUtilities.h"
#import "NTIUserData.h"
#import "NTIUserDataLoader.h"
#import "NTIAppPreferences.h"
#import "NTISharingUtilities.h"
#import "NTIFriendListEditController.h"
#import "TestAppDelegate.h"

#import "OmniUI/OUIOverlayView.h"


@implementation NTIFriendsListsGridView

-(id)initWithFrame: (CGRect)frame
{
	//We're happy with the default 112x112 paths
	self = [super initWithFrame: frame
					  observing: [NTIAppUser appUser]
					 forKeyPath: @"friendsLists"];
	OBASSERT( self.itemSize.width == 112 );
	OBASSERT( self.itemSize.height == 112 );	
	return self;
}

-(id)viewForModel: (id)friendsList withFrame: (CGRect)frame
{	
	id view = [[[NTIFriendsListGridItemView alloc] initWithFrame: frame
													 friendsList: friendsList]
								autorelease];
	return view;
}

-(NSString*)labelForModel: (id)model
{
	return [model prefDisplayName];	
}


@end

@implementation NTISharingTargetGridItemView

-(void)drawRect: (CGRect)rect
{
	[super drawRect: rect];
	UIRectFrame( self.bounds );
}

#pragma mark -
#pragma mark Drop Target

-(BOOL)wantsDragOperation: (id<NTIDraggingInfo>)info
{
	return NTIShareableUserDataObjectWantsDrop(
											   self->nr_model,
											   info );
}

-(BOOL)prepareForDragOperation: (id<NTIDraggingInfo>)info
{
	return [self wantsDragOperation: info];
}

-(BOOL)performDragOperation: (id<NTIDraggingInfo>)info
{
	[self draggingExited: info];
	return NTIShareableUserDataObjectPerformDrop( 
												 self->nr_model,
												 info );
}

-(void)draggingEntered: (id<NTIDraggingInfo>)info
{
	[self setBackgroundColor: [UIColor lightGrayColor]];
	
	NSString* action = NTIShaerableUserDataActionStringForDrop( 
															   self->nr_model,
															   info );
	NTIDraggingShowTooltipInViewAboveTouch( info, action, self.superview );
}

-(void)draggingExited: (id<NTIDraggingInfo>)info
{
	[self setBackgroundColor: [UIColor blackColor]];
}

-(void)dealloc
{
	[super dealloc];
}

@end

#define AVATAR_DIMENSION 44
#define AVATAR_SIZE CGSizeMake( 44, 44 )

#define MINI_INSET 8
#define MINI_AVATAR_DIMENSION AVATAR_DIMENSION
#define MINI_AVATAR_SIZE CGSizeMake( MINI_AVATAR_DIMENSION, MINI_AVATAR_DIMENSION )


@implementation NTIFriendsListGridItemView

-(id)initWithFrame: (CGRect)frame
	   friendsList: (NTIFriendsList*)_friendsList
{
	self = [super initWithFrame: frame];
	self->nr_model = _friendsList;
	[_friendsList addObserver: self
						forKeyPath: @"friends"
						   options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
						   context: nil];
	//For dragging.
	self.userInteractionEnabled = YES;
	self.backgroundColor = [UIColor whiteColor];
	return self;
}

-(void)observeValueForKeyPath: (NSString*)keyPath
					 ofObject: (id)object 
					   change: (NSDictionary*)change
					  context: (void*)context
{
	for( id subview in self.subviews ) {
		[subview removeFromSuperview];	
	}
	//Start fetching the images
	NTIFriendsList* friendsList = self->nr_model;
	for( NSUInteger i = 0; i < 4 && i < friendsList.friends.count; i++ ) {
		[[NTIGravatars gravatars] fetchIconForUser: [friendsList.friends objectAtIndex: i]
											  then: ^(UIImage* img) 
		 {
			 CGRect imgFrame = CGRectMake( 0,  0, MINI_AVATAR_DIMENSION, MINI_AVATAR_DIMENSION );
			 switch( i ) {
				 case 0:
					 imgFrame.origin.x = MINI_INSET;
					 imgFrame.origin.y = MINI_INSET;
					 break;
				 case 1:
					 imgFrame.origin.x = MINI_INSET + MINI_AVATAR_DIMENSION + MINI_INSET;
					 imgFrame.origin.y = MINI_INSET;
					 break;
				 case 2:
					 imgFrame.origin.x = MINI_INSET;
					 imgFrame.origin.y = MINI_INSET + MINI_AVATAR_DIMENSION + MINI_INSET;
					 break;
				 case 3:
					 imgFrame.origin.x = MINI_INSET + MINI_AVATAR_DIMENSION + MINI_INSET;
					 imgFrame.origin.y = MINI_INSET + MINI_AVATAR_DIMENSION + MINI_INSET;
					 break;
				 default:
					 OBASSERT_NOT_REACHED( "i < 4" );
			 }
			 UIImageView* imgView = [[[UIImageView alloc] initWithImage: img] autorelease];
			 imgView.frame = imgFrame;
			 imgView.userInteractionEnabled = YES;
			 imgView.autoresizingMask = 0x3F;
			 [self addSubview: imgView];
		 }];
	}	
}

@end

@implementation NTIFriendsListGridView

-(id)initWithFrame: (CGRect)frame friendsList: (NTIFriendsList*)list
{
	self = [super initWithFrame: frame
					  observing: list
					 forKeyPath: @"friends"];
	self.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"Default-Portrait.png"]];
	return self;
}

-(id)viewForModel: (id)user withFrame: (CGRect)frame
{	
	id view = [[[NTIFriendGridItemView alloc] initWithFrame: frame
													   user: user]
			   autorelease];
	return view;
}

-(NSString*)labelForModel: (id)model
{
	return [model prefDisplayName];	
}


@end


@implementation NTIFriendGridItemView

-(id)initWithFrame: (CGRect)frame
			  user: (id)user
{
	self = [super initWithFrame: frame];

	[[NTIGravatars gravatars] fetchIconForUser: user
										  then: ^(UIImage* img) 
	 {
		 CGRect imgFrame = CGRectMake( MINI_INSET, MINI_INSET, 
									  frame.size.width - 2 * MINI_INSET,
									  frame.size.height - 2* MINI_INSET  );
		 UIImageView* imgView = [[[UIImageView alloc] initWithImage: img] autorelease];
		 imgView.frame = imgFrame;
		 imgView.userInteractionEnabled = YES;
		 imgView.autoresizingMask = 0x3F;
		 [self addSubview: imgView];
	 }];
	//For dragging.
	self.userInteractionEnabled = YES;
	self.backgroundColor = [UIColor whiteColor];
	return self;
}

-(void)drawRect: (CGRect)rect
{
	[super drawRect: rect];
	UIRectFrame( self.bounds );
}

@end



#pragma mark -
#pragma mark NTIFriendsListViewController

@interface NTIFriendsListsViewController()<UIActionSheetDelegate>
-(void)editFriendsList: (NTIFriendsList*)list from: (id)sender;
@end

@implementation NTIFriendsListsViewController

-(id)init
{
	return [self initWithNibName: nil bundle: nil];
}

-(id)initWithNibName: (id)n bundle: (id)nn
{
	self = [super initWithNibName: n bundle: nn];
	
	self.navigationItem.title = @"Friends Lists";
	UIBarButtonItem* right = [[[UIBarButtonItem alloc] 
							   initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
							   target: self //FIXME: Use the responder chain.
							   action: @selector(createFriendsList:)] autorelease];
	self.navigationItem.rightBarButtonItem = right;
	//TODO: Why is this ignored?
	self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc]
											 initWithTitle: self.navigationItem.title
											 style: UIBarButtonItemStylePlain
											 target: self
											 action: @selector(popFriendsList:)] autorelease];
	
	return self;
}

-(void)loadView
{
	NTIFriendsListsGridView* friendsLists = [[[NTIFriendsListsGridView alloc]
											  initWithFrame: CGRectZero]
											 autorelease];
	friendsLists.longTapTarget = self;
	friendsLists.longTapAction = @selector(longPressFriendsList:);
	
	friendsLists.tapTarget = self;
	friendsLists.tapAction = @selector(tapFriendsList:);

	UIScrollView* scroller = [[[UIScrollView alloc] init] autorelease];
	[scroller addSubview: friendsLists];
	[scroller setBackgroundColor: [UIColor colorWithPatternImage: [UIImage imageNamed: @"Default-Portrait.png"]]];	
	self.view = scroller;
}

-(void)viewWillAppear: (BOOL)animated
{
	if( CGRectIsEmpty( self.view.frame  ) ) {
		//Give it a good width before it does layout.
		self.view.frame = CGRectMake(0, 0, 704, 980);
	}
	[self.view.subviews.firstObject populateGrid];
}

-(void)didReceiveMemoryWarning
{
	if( self.isViewLoaded && !self.view.window ) {
		//Can we drop the view because it's not showing?
		self.view = nil;
	}
}

#pragma mark -
#pragma mark Actions

-(void)tapFriendsList: (id)sender
{
	UIViewController* vc = [[UIViewController alloc] initWithNibName: nil
																bundle: nil];
	NTIFriendsList* list = ((NTIGridItemView*)[sender view])->nr_model;
	NTIFriendsListGridView* gv = [[[NTIFriendsListGridView alloc] 
								  initWithFrame: CGRectZero 
								  friendsList: list] autorelease];
								  

	vc.view = gv;
	vc.navigationItem.title = list.prefDisplayName;
	//TODO: self's backBarButtonItem is ignored for some reason,
	//so we must set it here. We're also customizing the animations
	//not just because it's cool but because the system back
	//button transitions the view really badly for some reason.
	vc.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
											  initWithTitle: self.navigationItem.title
											  style: UIBarButtonItemStyleDone
											  target: self
											  action: @selector(popFriendsList:)] autorelease];

	vc.navigationItem.rightBarButtonItem
		= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
														 target: self
														 action: @selector(editFriendsListFrom:)]
		   autorelease];

	[vc autorelease];
	UIView* from = [sender view];	
	self->currentFriendListViewFrame = from.frame;
	[self.view bringSubviewToFront: from]; //so the animation is on top TODO: Not working
	[self.view addSubview: gv];
	//Populate the grid before we draw. Important
	//to use the final frame during the layout process.
	gv.frame = self.view.bounds;
	[gv populateGrid];
	gv.frame = from.frame;
	[UIView animateWithDuration: 0.4
						  delay: 0.0
						options: UIViewAnimationCurveLinear
					 animations: ^{ gv.frame = self.view.bounds; }
					 completion: ^(BOOL c) {
						 //from.alpha = 1.0;
						 //from.frame = self->currentFriendListViewFrame;
						 
						 [gv removeFromSuperview];
						 [self.navigationController pushViewController: vc animated: NO];
					 }];
	

}

-(void)editFriendsListFrom: (id)sender
{
	NTIFriendsListGridView* top = (id)self.navigationController.topViewController.view;
	[self editFriendsList: top.toObserve from: sender];
}

-(void)popFriendsList: (id)sender
{
	UIViewController* top = [self.navigationController topViewController];
	UIView* oldView = top.view;
	UIView* oldSV = self.view.superview;
	top.view = self.view;
	[top.view addSubview: oldView];
	[UIView animateWithDuration: 0.3
					 animations: ^{ 
						 oldView.frame = self->currentFriendListViewFrame;
						 oldView.alpha = 0.0;
					 }
					 completion: ^(BOOL b){	
					 	[self.view removeFromSuperview];
						 if( oldSV ) {
						 	[oldSV addSubview: self.view];
						 }
						 [oldView removeFromSuperview];
						 [self.navigationController popViewControllerAnimated: NO]; 
					 } ];
}

#define IX_DELETE 0
#define IX_EDIT 1

-(void)editFriendsList: (NTIFriendsList*)list from: (id)sender
{
	UIViewController* editor = [[[NTIFriendListEditController alloc]
								 initWithFriendsList: list] autorelease];
	editor.modalInPopover = YES;
	editor.modalPresentationStyle = UIModalPresentationFormSheet;
	editor.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	editor.contentSizeForViewInPopover = CGSizeMake( 320, 600 );
	UINavigationController* navCont = [[[UINavigationController alloc] 
										initWithRootViewController: editor] 
									   autorelease];
	//TODO: We're showing in a popover primarily because 
	//there were size problems with the modal (taking whole screen). Since
	//all the UI fits in a popover, though, that's probably alright.
	//[self presentModalViewController: navCont animated: YES];
	UIPopoverController* pop = [[UIPopoverController alloc] 
								initWithContentViewController: navCont];
	[pop autorelease];
	if( sender == self->nr_currentFriendsListsViewInActionSheet ) {
		[[TestAppDelegate sharedDelegate] presentPopover: pop
											fromRect: [self->nr_currentFriendsListsViewInActionSheet frame]
											  inView: self.view
							permittedArrowDirections: UIPopoverArrowDirectionRight | UIPopoverArrowDirectionLeft
											animated: YES];
	}
	else {
		[[TestAppDelegate sharedDelegate] presentPopover: pop
									   fromBarButtonItem: sender
								permittedArrowDirections: UIPopoverArrowDirectionAny
												animated: YES];
	}
}

-(void)createFriendsList: (id)sender
{
	[self editFriendsList: nil from: sender];	
}

-(void)longPressFriendsList: (UILongPressGestureRecognizer*)sender
{
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle: nil
															 delegate: self
													cancelButtonTitle: nil //@"Cancel"
											   destructiveButtonTitle: @"Delete Friends List"
													otherButtonTitles: @"Edit Friends List", nil];
	[actionSheet autorelease];
	self->nr_currentFriendsListsViewInActionSheet = sender.view;

	[actionSheet showFromRect: sender.view.frame
					   inView: self.view
					 animated: NO];
}

-(void)actionSheet: (UIActionSheet*)sheet clickedButtonAtIndex: (NSInteger)index
{
	if( !self->nr_currentFriendsListsViewInActionSheet || index < 0 ) {
		//TODO: Why
		return;
	}
	//It claims that the sheet is automatically dismissed, that doesn't
	//really seem to be the case.
	//There's some indication this may be a bug as of iOS 4.2.1?
	//(At least with tabbars.) Tried showing in the view itself and in the
	//window and both have the same problem.

	NTIFriendsList* friendsList = ((NTIFriendsListGridItemView*)self->nr_currentFriendsListsViewInActionSheet)->nr_model;
	switch( index ) {
		case IX_DELETE:
			NSLog( @"Deleting %@", friendsList );
			NTIAppPreferences* prefs = [NTIAppPreferences prefs];
			[NTIUserDataDeleter deleteObject: friendsList
								onDataserver: prefs.dataserverURL
									username: prefs.username
									password: prefs.password
									complete: ^(NTIUserData* it) {
										if( it ) {
											//Update the model
											[[NTIAppUser appUser] didDeleteFriendsList: friendsList];
											//Redisplay handled by KVO
											[self.view setNeedsDisplay];
										}
									}];
		break;
			
		case IX_EDIT: {
			[self editFriendsList: friendsList from: self->nr_currentFriendsListsViewInActionSheet];
		}
		break;
	
		default:
#if defined (__LP64__) || defined(NS_BUILD_32_LIKE_64)
			NSLog( @"Unknown index %ld", index );
#else
			NSLog( @"Unknown index %d", index );
#endif
	}
	self->nr_currentFriendsListsViewInActionSheet = nil;
}

-(void)dealloc
{
	[super dealloc];
}

@end
