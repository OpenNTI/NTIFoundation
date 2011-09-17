
//
//  NTINoteController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/12.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTINoteLoader.h"
#import "NTINoteView.h"
#import "NTIEditableNoteViewController.h"
#import "NTINoteSavingDelegates.h"
#import "NTINoteController.h"
#import "NTIAppPreferences.h"
#import "NTIDraggableTableViewCell.h"
#import "NTIUtilities.h"
#import "NTIWebView.h"
#import "WebAndToolController.h"
#import "OmniFoundation/OFNull.h"
#import "NTIWindow.h"
#import "NTIDraggingUtilities.h"
#import "NSArray-NTIExtensions.h"
#import "NSArray-NTIJSON.h"
#import "NSString-NTIJSON.h"
#import "NTIRTFDocument.h"
#import "NTIRTFTextViewController.h"
#import "OmniUI/OUIEditableFrame.h"
#import "OmniUI/OUIInspector.h"

#import <OmniUI/OUIColorInspectorSlice.h>
#import <OmniUI/OUIDirectTapGestureRecognizer.h>
#import <OmniUI/OUIFontAttributesInspectorSlice.h>
#import <OmniUI/OUIFontInspectorSlice.h>
#import <OmniUI/OUIStackedSlicesInspectorPane.h>
#import <OmniUI/OUITextColorAttributeInspectorSlice.h>
#import <OmniUI/OUITextLayout.h>
#import "NTIInspector.h"
#import "NSDictionary-NTIJSON.h"
#import "UIWebView-NTIExtensions.h"
#import "NTINavigationParser.h"
#import "NTIUserDataTableModel.h"
#import "TestAppDelegate.h"
#import "NTIUserData.h"
#import "WebAndToolController.h"
#import "NTIApplicationViewController.h"
#import "NTINavigation.h"

@interface UIViewController(NTIOrientationExtensions)
-(void)setInterfaceOrientation: (UIInterfaceOrientation)o;
@end


@implementation NTINotesInPageIndicatorController
@synthesize image;

-(id)init
{
	self = [super initWithNibName: @"NotesInPageIndicator" bundle: nil];
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.image.alpha = .5;
}

-(void)viewDidUnload
{
    [self setImage: nil];
    [super viewDidUnload];
}

-(void)updateWithDataFromPage: (NSArray*)objects
{
	UIImage* theIcon = nil;
	if( [objects count] ) {
		theIcon = [UIImage imageNamed: @"UGDPageIndicator.Colored.png"];
	}
	else {
		theIcon = [UIImage imageNamed: @"UGDPageIndicator.Gray.png"];
	}
	
	if( image ){
		self.image.image = theIcon;
	}
}

-(void)dealloc
{
	NTI_RELEASE(image);
    [super dealloc];
}

@end

@interface NTINoteSummaryViewController()
-(id)_noteDetailViewForObject: (id)object viewClass: (Class)class;
-(id)_noteDetailViewForObject: (id)object;
@end


@interface NTIThreadedNoteContainerPart : NTIThreadedNoteContainer
@end

@implementation NTIThreadedNoteContainerPart

-(void)navigateToNote: (id)sender
{
	if( self.uan.note ){
		WebAndToolController* webController = [[TestAppDelegate sharedDelegate] topViewController].webAndToolController;
		id navItem = [webController.navHeaderController.root pathToID: [self.uan.note ContainerId]];
		[webController navigateToItem: [navItem lastObjectOrNil]];
	}
	
}

-(NSArray*)actionBarButtonItemsForTree: (NTIThreadedNoteContainer*)tree target: (id)target
{
	
	id gotoPage = [[[UIBarButtonItem alloc]
					initWithBarButtonSystemItem: UIBarButtonSystemItemAction
					target: self
					action: @selector(navigateToNote:)] autorelease];
	id space = [[[UIBarButtonItem alloc]
				 initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease];
	
	return [NSArray arrayWithObjects: space, gotoPage, nil];
}



@end


@implementation NTINote(NTIUserDataTableViewExtension)

-(id)detailViewController:(id)sender
{
	id result = nil;
	if( [sender respondsToSelector: @selector(_noteDetailViewForObject:)] ) {
		result = [sender _noteDetailViewForObject: self];
	}
	else {
		NTIThreadedNoteContainerPart* cont = [[[NTIThreadedNoteContainerPart alloc]
										   initWithNote: self] autorelease];
		NTIThreadedNoteInPageViewController* vc = [[NTIThreadedNoteInPageViewController alloc]
											   initWithThreadedNote: cont
											   onPage: nil
											   inContainer: nil];
	
		result = [vc autorelease];
	}
	return result;
}

@end

@implementation NTIThreadedNoteContainer(NTIUserDataTableViewExtension)
-(id)detailViewController:(id)sender
{
	id result = nil;
	//Only do this if we haven't been tricked into wrapping a non-note
	//object.
	
	//Notes whose root are deleted will have self.uan == nil.  If it has children
	//let it through
	if( [self.uan.note isKindOfClass: [NTINote class]] || ( [self respondsToSelector:@selector(children)] && [[self children] count] > 0 )) {
		if( [sender respondsToSelector: @selector(_noteDetailViewForObject:)] ) {
			result = [sender _noteDetailViewForObject: self];
		}
		else {
			NTIThreadedNoteInPageViewController* vc = [[NTIThreadedNoteInPageViewController alloc]
												   initWithThreadedNote: self
												   onPage: nil
												   inContainer: nil];
			result = [vc autorelease];
		}
		
		
	}
	return result;
}

-(BOOL)didSelectObject:(id)sender
{
	id detail = [self detailViewController: sender];
	if( detail ) {
		[[sender navigationController] pushViewController: detail
												 animated: YES];
	}
	
	return detail != nil;
}


@end

@implementation NTINoteSummaryViewController

-(id)initWithModel: (NTIThreadedNoteTableModel*)theModel
		 andParent: (id<NTIThreadedNoteViewControllerDelegate>)pc
{
	self = [super initWithStyle: UITableViewStylePlain dataModel: theModel];
	self->model = [theModel retain];
	self->nr_container = pc;

	//Search setup
	self.collapseWhenEmpty = YES;
	self.predicate = [NTIThreadedNoteContainer searchPredicate];

	return self;
}

-(CGSize)contentSizeForViewInPopover
{
	return CGSizeMake( 320, 400 );
}

-(void)removeObjectAtIndexPath: (NSIndexPath*)path
{
	[super removeObjectAtIndexPath: path];
}

-(void)updateObject: (id)toUpdate atIndexPath: (NSIndexPath*)path
{

}

-(void)removeObject:(NTIThreadedNoteContainer*)toRemove
{
	[super removeObject: toRemove];
}

-(void)updateObject:(NTIThreadedNoteContainer*)toUpdate
{
	//Look up the object
	NSUInteger idx = [self.displayedObjects indexOfObject: toUpdate];
	if( idx != NSNotFound ){
		[super updateObject: toUpdate
				atIndexPath: [NSIndexPath indexPathForRow: idx inSection: 0]];
	}
}

-(void)addObject: (NTIThreadedNoteContainer*)object
{
	[self prependObject: object];
}

-(NSString*)ntiPageId
{
	return [[[self->model containerId] copy] autorelease];
}

-(void)subset: (id)me
configureCell: (UITableViewCell*)cell
	forObject: (NTIThreadedNoteContainer*)tree
{

	NTIUserAndNote* uan = tree.uan;
	NSUInteger count = [tree count];

	if( uan ) {
		NTIRTFDocument* doc = uan.noteManager.document;
		if( !doc ) {
			doc = [[[NTIRTFDocument alloc] initWithString: tree.uan.note.text] autorelease];
		}
		cell.textLabel.text = doc.plainString;  //TODO: Smarter Truncation
		//Count includes the root.
		if( count > 1 ) {
			cell.detailTextLabel.text = [NSString
										 stringWithFormat: @"Last Modified %@,  %d Reply(s)",
										 uan.note.lastModifiedDateShortStringNL, count - 1];
		}
		else {
			cell.detailTextLabel.text = uan.note.lastModifiedDateShortStringNL;
		}

	}
	else {
		cell.textLabel.text = @"<Deleted by Owner>";
		//Count includes the root.
		if( count > 1 ) {
			cell.detailTextLabel.text = [NSString stringWithFormat: @"%d Reply(s)",
										 count - 1];
		}
	}


	NSString* color = @"Yellow";
	UIColor* lcolor = [UIColor darkTextColor];
	if( uan.shared ) {
		color = @"Blue";
		lcolor = [UIColor blueColor];
	}
	NSString* type = uan.note.externalClassName;
	//Hacky to make deleted notes match there cohorts in the summary table
	if( !type && !uan.note ){
		type = @"Note";
	}
	
	NSString* imgName = [NSString stringWithFormat: @"%@-%@.mini.png",
							type, color];

	cell.textLabel.textColor = lcolor;
	cell.imageView.image = [UIImage imageNamed: imgName];
	cell.imageView.userInteractionEnabled = YES;
}

-(id)_noteDetailViewForObject: (id)object viewClass: (Class)class
{
	//TODO: See if super has something
	id result = nil;
	if( [object isKindOfClass: [NTIThreadedNoteContainer class]] ) {
		NTIThreadedNoteContainer* tree = object;
		NTIThreadedNoteInPageViewController* vc = [[class alloc]
												   initWithThreadedNote: tree
												   onPage: self.ntiPageId
												   inContainer: self->nr_container];
		result = [vc autorelease];
	}
	
	return result;
}

-(id)_noteDetailViewForObject: (id)object
{
	return [self _noteDetailViewForObject: object
								viewClass: [NTIThreadedNoteInPageViewController class]];
}

-(NSString*)sortDescriptorKey
{
	return @"uan.note.lastModifiedDate";
}

#pragma mark -
#pragma mark Drag source

//We have to implement this because we store NTIUserAndNote objects,
//or possible
-(id)dragOperation: (id<NTIDraggingInfo>)drag objectForDestination: (id)destination
{
	id result = [super dragOperation: drag objectForDestination: destination];
	if( [result respondsToSelector: @selector(uan)] ) {
		result = [result uan];
	}
	if( [result respondsToSelector: @selector(note)] ) {
		result = [result note];
	}

	return result;
}

-(void)dealloc
{
	NTI_RELEASE(self->model);
	[super dealloc];
}

@end

@interface NTINoteController()

-(void)createNewNote: (id)sender;
-(void)displayNoteInGutter: (NTIUserAndNote*)note;
-(void)redisplayGutter;
-(void)clearGutter;

@end


@interface NTINewNoteViewController : NTIEditableNoteInPageViewController {
@private
	UIPopoverController* popover;
}
@property (nonatomic,assign) CGPoint at, windowPoint;
-(void)presentInPopoverFrom: (CGRect)rect inView: (UIView*)view;

@end

@implementation NTINewNoteViewController
@synthesize at, windowPoint;

-(void)dealloc
{
	NTI_RELEASE( self->popover );
	[super dealloc];
}

-(void)presentInPopoverFrom: (CGRect)rect inView: (UIView*)view
{
	//FIXME: When we present in a popover, the inspector cannot also be
	//in the popover. We'd like to put it in our navigation controller.
	//There are some size issues or something with that (it's blank except
	//for a small strip) so we are back to the modal view.
	//When we take keyboard focus, we'd lose any DOM selection,
	//which is important since the points are unreliable
	//(TODO: This is probably fixed, verify.)
	/*
	 [self->web.webview callFunction: @"NTIInlineNoteSaveSelection"];
	 [self becomeFirstResponder];
	 [self.parent.window.rootViewController presentModalViewController: self animated: YES];
	 */
	//FIXME: Hack to get coordinates saved.
	//	self.miniNote.editView.frame = rect;

	UINavigationController* nav = [[[UINavigationController alloc]
									initWithRootViewController: self] autorelease];
	nav.delegate = self;

	self.modalInPopover = YES;
	self->noteManager.noteViewController.noteToolbar = (id)self.navigationItem.titleView;

	self->popover = [[UIPopoverController alloc] initWithContentViewController: nav];
	[self->popover setPopoverContentSize: CGSizeMake( 300, 300 )];
	[self becomeFirstResponder];
	self->noteManager.noteViewController.infoToolbarItem.target = self;


	//When we take keyboard focus, we'd lose any DOM selection,
	//which is important since the points are unreliable
	//(TODO: This is probably fixed, verify.)
	[self.web.webview callFunction: @"NTIInlineNoteSaveSelection"];
	[[TestAppDelegate sharedDelegate]
	 presentPopover: popover
	 fromRect: rect
	 inView: view
	 permittedArrowDirections: UIPopoverArrowDirectionAny
	 animated: YES];

}

-(void)dismiss
{
	//Force this because we're having weird issues with not being
	//able to get it back.
	//(TODO: This is probably fixed, verify).

	[UIMenuController sharedMenuController].menuVisible = NO;
	[self.web.webview becomeFirstResponder];
	[[TestAppDelegate sharedDelegate]
	 dismissPopover: self->popover
	 animated: YES];
	NTI_RELEASE( self->popover );

}

-(void)done: (id)_
{
	[self dismiss];
	[super done: _];
}

-(void)cancel: (id)sender
{
	[self dismiss];
	//No super
}

-(NTINote*)noteToCreate
{
	NTINote* note = [super noteToCreate];
	CGPoint htmlAt = at;
	note.top = htmlAt.y;
	note.left = htmlAt.x;
	note.sharedWith = self->noteManager.sharingTargets.sharingTargets;
#ifdef DEBUG_POINT_CONVERSION
	NSLog( @"Elements at point %@ %@",
		  NSStringFromCGPoint( htmlAt ),
		  [self.web.webview htmlElementNamesAtHTMLPoint: htmlAt] );
#endif


	if (note.inReplyTo == nil){
		//FIXME We still make this call (which has been changed to not actually
		//render the note inline) because we want to store anchor information.
		NSString* anchorAndTypeString
		= [self.web.webview callFunction: @"NTIInlineNoteMakeFromSelectionOrAt"
								withJson: [[[NTIUserAndNote objectWithNote: note] asDictionary] stringWithJsonRepresentation]
								  andInt: htmlAt.x
								  andInt: htmlAt.y];

		if( ![NSString isEmptyString: anchorAndTypeString] ) {
			//propagate this to the server
			NSArray* anchorAndType = [anchorAndTypeString jsonObjectValue];

			note.anchorType = [[anchorAndType secondObject] jsonObjectUnwrap];
			note.anchorPoint = [[anchorAndType firstObject] jsonObjectUnwrap];
		}
	}

	return note;
}

-(void)didCreateNote: (NTINote*)note
{
	//Now that we have actually created a note and stored
	//it in the NTINoteController, we have an ID for it.
	//The temporary note we have in the text has to go since it
	//doesnt'h have an ID and so could never be edited.

	//FIXME. Update the in memory note
	NSLog(@"didCreateNote");
}

-(void)note: (NTINote*)o didUpdateNote: (NTINote*)note
{

}


@end

//FIXME this shouldn't be note specific.  Really this is the UGD controller.  
//There are more than just notes that are controlled here.
@implementation NTINoteController

-(id)initWithWebController: (WebAndToolController*)theWebController;
{
	NTIThreadedNoteTableModel* theModel = [[[NTIThreadedNoteTableModel alloc]
											initWithWebController: theWebController] autorelease];

	self = [super initWithModel: theModel andParent: self];
	self->model.delegate = self;
	self->controller = [theWebController retain];
	[theWebController.webview addScrollDelegate: self];

	self->indicatorSummary = [[NTINoteSummaryViewController alloc] initWithModel: model andParent: self];
	
	//Note just notes.
	self->indicatorSummary.navigationItem.title = @"My Stuff"; //Named for consistency with context column.  At least "Stuff" is better than Kno's WTF.
	self->indicatorSummary.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
																 initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
																 target: self
																 action: @selector(addNewNote:)] autorelease];


	//Search setup (predicate comes from super.)
	self.collapseWhenEmpty = YES;

	UITapGestureRecognizer* indicatorTap = [[[UITapGestureRecognizer alloc]
											 initWithTarget: self
											 action: @selector(showNotesInPage:)] autorelease];
	[[self->controller noteIndicator].view addGestureRecognizer: indicatorTap];

	return self;
}

-(void)setDelegate:(id)d
{
	[super setDelegate: d];
	self->indicatorSummary.delegate = d;
}

-(void)refreshDataForCurrentPage
{
	[self->model refreshDataForCurrentPage];
}

-(void)showNotesInPage:(id)_
{

	//This gets released by the magical popover delegate when the popover goes away.
	UINavigationController* nav = [[[UINavigationController alloc]
								   initWithRootViewController: self->indicatorSummary] autorelease];

	self.modalInPopover = YES;

	UIPopoverController* popover = [[[UIPopoverController alloc] initWithContentViewController: nav] autorelease];

	//Work around an apparent IOS 4 bug in which the nav self->indicatorSummary has no navigationController
	//after the popover has been shown and hidden once despite being added to a new uinavigationcontroller each time.
	//
	//NOTE:  This style seems a bit strange.  For example when running in instruments the below line
	//does not fix the issue.  However, running in the simulator and on my ipad2 it seems to function as expected.
	objc_setAssociatedObject( popover, @"AssociateNavController", nav, OBJC_ASSOCIATION_RETAIN);

	[[TestAppDelegate sharedDelegate]
	 presentPopover: popover
	 fromRect: [self->controller noteIndicator].view.frame
	 inView: self->controller.view
	 permittedArrowDirections: UIPopoverArrowDirectionAny
	 animated: YES];

}

-(void)addNewNote: (id)s
{
	NTINoteViewControllerManager* newManager = [NTINoteViewControllerManager managerForNote: nil inReplyTo: nil];

	NTIEditableNoteInPageViewController* cont = [NTIEditableNoteInPageViewController controllerForNewNote: newManager
																								   inPage: self.ntiPageId
																								container: self];

	id nav = self->indicatorSummary.navigationController;
	[nav
	 pushViewController: cont
	 animated: YES];
	[cont becomeFirstResponder];
}

-(void)dealloc
{
	[self->miniNotePopoverController release];
	[self->controller.webview removeScrollDelegate: self];
	NTI_RELEASE(self->controller);
	NTI_RELEASE(self->indicatorSummary);
	[super dealloc];
}

//-(NSString*)pageId
//{
//	return [[self->controller.selectedNavigationItem.ntiid retain] autorelease];
//}

#pragma mark -
#pragma mark Note Loading

-(UIScrollView*)gutter
{
	return [self->controller gutter];
}

-(UIWindow*)window
{
	id w = self->controller.webview.window;
	return (NTIWindow*)w;
}

- (CGPoint)lastWindowTouchPoint
{
	return [((NTIWindow*)[self->controller.webview window]) tapLocation];
}

- (CGPoint)lastTouchPoint
{
	UIView* view = self->controller.webview;
	return [view convertPoint: [self lastWindowTouchPoint]
					 fromView: [self->controller.webview window]];
}

-(NSString*)ntiPageId
{
	//This property is declared in a protocol we implement, and 
	//we get warnings if we just inherit the implementation
	return [super ntiPageId];
}

#pragma mark -
#pragma mark ScrollView Delegate
-(void)scrollViewDidScroll: (UIScrollView*)sv
{
	if( sv == self.tableView ) {
		//We scrolled. Don't move the gutter.
	}
	else {
		//The web view scrolled. Scroll the gutter
		CGPoint newOffset = [sv contentOffset];
		[[self gutter] setContentOffset: newOffset animated: NO];
		self->contentOffset = newOffset;
#ifdef DEBUG_GUTTER
		NSLog(@"Gutter bounds %@", NSStringFromCGRect([self gutter].bounds	));
		NSLog(@"Gutter offset %@", NSStringFromCGPoint([[self gutter] contentOffset]));
#endif
	}
}

#pragma mark -
#pragma mark Orientation

-(UIInterfaceOrientation)interfaceOrientation
{
	return self->interfaceOrientation;
}

-(void)setInterfaceOrientation: (UIInterfaceOrientation)o
{
	self->interfaceOrientation = o;
	if( [[super class] instancesRespondToSelector: _cmd] ) {
		[super setInterfaceOrientation: o];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)orientation
							   duration: (NSTimeInterval)duration
{
	/* Considering this...
	//Transfer the clutter to the side panel in landscape.
	//Note that testing the "old" or "current" orientation using self.interfaceOrientation
	//is unreliable.
	if(	UIInterfaceOrientationIsLandscape( orientation ) ) {
		[self gutter].hidden = YES;
	}
	else if( UIInterfaceOrientationIsPortrait( orientation ) ) {
		[self gutter].hidden = NO;
		//It doesn't track its scroll position
		[[self gutter] setContentOffset: [self->controller.webview.scrollView contentOffset]
						animated: NO];
		//And we may need to add new notes
		for( id view in [self gutter].subviews ) {
			[view removeFromSuperview];
		}
		for( NTIUserAndNote* uan in self.notes ) {
			[self displayNoteInGutter: uan.note
							   shared: uan.shared];
		}
	}
	*/
	//We must always set our orientation, though, so we know which
	//view to create notes in.
	[super willRotateToInterfaceOrientation: orientation duration: duration];
	if( self.interfaceOrientation !=  orientation ) {
		if( [self respondsToSelector: @selector(setInterfaceOrientation:)] ) {
			[self setInterfaceOrientation: orientation];
		}
	}
	
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//We need to adjust the scroll offset of the gutter to match the scrolloffset of us
	//TODO this feels/looks a little strange.
	[self gutter].contentOffset = [[self->controller webview] scrollView].contentOffset;
	
}

-(id)_noteDetailViewForObject: (id)object
{
	return [self _noteDetailViewForObject: object
								viewClass: [NTIThreadedNoteViewController class]];
}

-(void)clearGutter
{
	for( id view in [[self gutter] subviews] ) {
		[view removeFromSuperview];
	}
}

-(void)redisplayGutter
{
	[self clearGutter];
	//At one point we only redisplayed the notes in the gutter if
	//[self gutter].window  existed.  This meant that removing notes
	//when the content view was minimized resulted in the gutter being
	//empty when the content was later maximized.  It now seems like
	//the gutter view stays around so we remove that conditional.
	
	//We want only the visible filtered objects
	for( NTIThreadedNoteContainer* tree in self.displayedObjects ) {
		//If we've removed the gutter, it can cause problems
		//trying to maniuplate its view hierarchy
		[self displayNoteInGutter: tree.uan];
	}
	[self->controller.noteIndicator updateWithDataFromPage: [self allObjects]];

}

-(BOOL)setFilteredSubset: (NSArray*)filtered andReloadTable: (BOOL)reload
{
	BOOL result = [super setFilteredSubset: filtered andReloadTable: reload];
	[self redisplayGutter];
	[self->indicatorSummary setFilteredSubset: filtered andReloadTable: reload];
	[[self->controller noteIndicator] updateWithDataFromPage: filtered];
	return result;
}

#pragma mark -
#pragma mark Note Creation and Editing

-(BOOL)canPerformAction: (SEL)action withSender: (id)sender
{
	BOOL touchWasNote = [self->controller.webview touchWasOnInlineNote];
	//Creating a note and editing one are exclusive
	if(		action == NWA_CREATE_NOTE
	   &&	touchWasNote ) {
		return NO;
	}

	if( [self respondsToSelector: action] ) {
		return YES;
	}

	return [super canPerformAction: action withSender: sender];
}

-(void)createEmptyAnchoredNoteAt: (CGPoint)at
									 inReplyTo: (NTINote*)note
{
	at = [self->controller.webview htmlDocumentPointFromWindowPoint: at];

#ifdef DEBUG_GUTTER
	NSLog(@"Creating note with stored location %@", NSStringFromCGPoint(at));
#endif
	
	NTINoteViewControllerManager* newManager = [NTINoteViewControllerManager managerForNote: nil inReplyTo: note];

	NTINewNoteViewController* viewController
	= [NTINewNoteViewController
	   controllerForNewNote: newManager
	   inPage: self.ntiPageId
	   container: self];
	viewController.noteDelegate = (id)self;
	if (note == nil){
		viewController.at = at;
	}
	viewController.web = self->controller;
	CGRect rect;
	rect.origin = [self lastWindowTouchPoint];
	rect.size = CGSizeMake( 10, 10 );
	[viewController presentInPopoverFrom: rect
								  inView: self.window];
}

-(void)updateViews
{
	//This does not always refresh the table.  It only refreshes if the rows change, not what the rows would look like.
	//We forgo letting it reload the table and just do it ourself since we know something has changed.
	[self setAllObjectsAndFilter: self->model.objects reloadTable: NO];
	[super sortUsingDescriptors:
	 [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: [self sortDescriptorKey]
															 ascending: NO]]];
	//Gets called in our setFilteredSubset method.
	//[self redisplayGutter];
	[self.tableView reloadData];
}


-(void)removeObjectAtIndexPath: (NSIndexPath*)path
{
	[super removeObjectAtIndexPath: path];
	[self->indicatorSummary removeObjectAtIndexPath: path];
	[self redisplayGutter];
}

-(void)updateObject: (id)toUpdate
		atIndexPath: (NSIndexPath*)path
{
	[super updateObject: toUpdate atIndexPath: path];
	[self->indicatorSummary updateObject: toUpdate atIndexPath: path];
	[self redisplayGutter];
}

-(void)updateObject: (NTIThreadedNoteContainer*)toUpdate
{
//	if( [self->miniNotePopoverController isPopoverVisible] && toUpdate.note == nil) {
//		[[TestAppDelegate sharedDelegate] dismissPopover: self->miniNotePopoverController
//												animated: YES];
//	}
	NSLog(@"NTINoteController updating %@", toUpdate);
	[super updateObject: toUpdate];
	[self->indicatorSummary updateObject: toUpdate];
	[self redisplayGutter];
}

-(void)removeObject: (id)toRemove
{
	//If we have been asked to remove an object and the miniview is up
	//Then it needs to be dismissed
	if( [self->miniNotePopoverController isPopoverVisible] ) {
		[[TestAppDelegate sharedDelegate] dismissPopover: self->miniNotePopoverController
												animated: YES];
	}
	[super removeObject: toRemove];
	[self->indicatorSummary removeObject: toRemove];
	[self redisplayGutter];
}

-(void)addObject: (NTINote*)toAdd
{
	//This should be a new note
	NTIThreadedNoteContainer* tree = [NTIThreadedNoteContainer
									  threadNotes: [NSArray arrayWithObject: toAdd]].firstObject;
	[super addObject: tree];
	[self->indicatorSummary addObject: tree];
	[self redisplayGutter];
}

-(void)model: (NTIUserDataTableModel*)m didAddObjects: (NSArray*)added
{
	[self updateViews];
	[self->indicatorSummary model: m didAddObjects: added];

}

-(void)model: (NTIUserDataTableModel*)m didRemoveObjects: (NSArray*)removed
{
	[self updateViews];
	[self->indicatorSummary model: m didRemoveObjects: removed];

}

-(void)model: (NTIUserDataTableModel*)m didUpdateObjects: (NSArray*)updated
{
	[self updateViews];
	[self->indicatorSummary model: m didUpdateObjects: updated];

}

-(void)model: (NTIUserDataTableModel*)m didRefreshDataForPage: (NSString*)page
{
	[self updateViews];
	[self->indicatorSummary model: m didRefreshDataForPage: page];

}

-(void)model: (NTIUserDataTableModel*)m didLoadDataForPage: (NSString*)page
{
	[self updateViews];
	[self->indicatorSummary model: m didLoadDataForPage: page];

}

-(void)hideMiniNotePopover
{
	if( self->miniNotePopoverController.popoverVisible ) {
		[self->miniNotePopoverController dismissPopoverAnimated: YES];
	}
}

-(void)createEmptyNoteInTableInReplyTo: (NTINote*)note
{
	if( ![self.navigationController.topViewController isKindOfClass: [NTIEditableNoteViewController class]] ) {

		NTINoteViewControllerManager* newManager = [NTINoteViewControllerManager managerForNote: nil inReplyTo: note];


		//Don't allow double editing, that breaks the stack badly
		NTIEditableNoteViewController* cont = [NTIEditableNoteViewController
											   controllerForNewNote: newManager
											   inPage: self.ntiPageId
											   container: self];
		cont.noteDelegate = (id)self;
		id nav = self.navigationController;
		[nav
		 pushViewController: cont
		 animated: YES];
		[cont becomeFirstResponder];
	}
}

-(BOOL)gutterFreeForMiniNoteAt: (CGRect)rect
{
	for( UIView* miniNote in [[self gutter] subviews] ) {
		CGRect intersection = CGRectIntersection(miniNote.frame, rect);
		if( !CGRectIsNull(intersection) ) {
			return NO;
		}
	}
	return YES;
}

-(CGPoint)resolveLocationFromAnchor: (NTIUserAndNote*)uan
{
	CGPoint pointFromAnchor = CGPointMake( -1, -1);
	
	if( [uan.note respondsToSelector: @selector(anchorType)] &&  uan.note.anchorType &&
	   [uan.note respondsToSelector: @selector(anchorPoint)] && uan.note.anchorPoint ){
		//We prefer to use the anchor to put our notes in the gutter
		NSString* result = [self->controller.webview callFunction:@"NTIDocumentPointAtAnchor"
													   withString: [uan.note anchorPoint]
														andString: [uan.note anchorType]];
		NSArray* arrayResult = [result jsonObjectValue];
		
		if( arrayResult ){
			
			pointFromAnchor.x = [[arrayResult objectAtIndex: 0] floatValue];
			pointFromAnchor.y = [[arrayResult objectAtIndex: 1] floatValue];
			
		}
	}
	
	return pointFromAnchor;
}

//FIXME Ocassionally (especially in the simulator) we encounter a race condition
//in which we layout the notes before the webview has actually loaded the new page.
//This causes some inconsistenices with the htmlpoint given to us from the webview and
//therefore where we lay the note out.  Unfortunately b/c the view and model are still 
//fairly tightly coupled there is not an easy way to fix this.
-(void)displayNoteInGutter: (NTIUserAndNote*)uan
						at:(CGPoint)point
{

//We can resolve the point from the anchor but we must wait for the page to load first
//	CGPoint pointFromAnchor = [self resolveLocationFromAnchor: uan];
//	if( pointFromAnchor.x >= 0 && pointFromAnchor.y >= 0 ){
//		point = pointFromAnchor;
//	}


#ifdef DEBUG_GUTTER
	NSLog(@"Will display note in gutter. %@", uan.note);
	NSLog(@"At stored document point %@", NSStringFromCGPoint(point));
#endif
	CGPoint htmlNotePoint = point;
	CGPoint viewNotePoint = [self->controller.webview viewPointFromHTMLDocumentPoint: htmlNotePoint];
#ifdef DEBUG_GUTTER
	NSLog(@"In webview coordinates %@", NSStringFromCGPoint(viewNotePoint));
#endif	
	CGPoint gutterPoint = viewNotePoint;
	gutterPoint.x = 0;

	//Notes that are unanchored currently have top/left that are 0,0.  We bump them down slightly so
	//they don't end up right next to the ugdi.
	if( gutterPoint.y < 30 ) {
		gutterPoint.y = 30;
	}
	NTIMiniNoteView* miniView = uan.noteManager.miniNoteViewController.miniNoteView;
	uan.miniTapRecognizer = [[[UITapGestureRecognizer alloc]
							  initWithTarget: self
							  action: @selector(miniNoteTapped:)] autorelease];
	[miniView addGestureRecognizer: uan.miniTapRecognizer];
	CGRect miniViewFrame = CGRectMake( 0, gutterPoint.y, miniView.frame.size.width, miniView.frame.size.height );


	//if things overlap move it down the arbitrary amout of half the miniview height and try again
	//This is somewhat temporary until we decide how we want to stack them.
	while( ![self gutterFreeForMiniNoteAt:miniViewFrame ]) {
		miniViewFrame.origin.y += miniViewFrame.size.height / 2.0;
	}
	miniView.frame = miniViewFrame;

#ifdef DEBUG_GUTTER
	NSLog(@"Adding miniview %@", miniView);
#endif
	[[self gutter] addSubview: miniView];
}

-(void)createNewNote: (id)s
{
	NTINoteType type = NTINoteTypeContextual;
	BOOL triggeredByContextMenu = [s isKindOfClass: [UIMenuController class]];

	if( triggeredByContextMenu ) {
		type = NTINoteTypeAnchored;
	}

	[self createNewNoteOfType: type];
}

-(void)createNewNoteOfType: (NTINoteType)type
{
	[self createNewNoteOfType: type inReplyTo: nil];
}

-(void)createNewNoteOfType: (NTINoteType)type inReplyTo: (NTINote*) note
{
	switch (type) {

		case NTINoteTypeContextual:
			[self createEmptyNoteInTableInReplyTo: note];
		break;
		case NTINoteTypeAnchored:
			[self createEmptyAnchoredNoteAt: [self lastWindowTouchPoint] inReplyTo: note];
		break;
		default:
			[self createEmptyNoteInTableInReplyTo: note];
		break;
	}
}

-(void)displayNoteInGutter: (NTIUserAndNote*)uan
{
	//Some notes may not want to be in the gutter. Some note-like
	//things may not want to be in the gutter.
	//FIXME: These things are highlights and we should do something
	//in the gutter for them?
	NSInteger left = -1, top = -1;
	id note = uan.note;
	if(		[note respondsToSelector: @selector(left)]
		 &&	[note respondsToSelector: @selector(top)] ) {
		left = [note left];
		top = [note top];
	}
	//We are just going to line things up on the y axis.  The point
	//conversion is still slightly messed up in that we occasionally get negative
	//left values.
	if( top >= 0 ) {
		CGPoint htmlNotePoint = CGPointMake( left, top );
		[self displayNoteInGutter: uan at: htmlNotePoint];
	}
}
-(void)miniNoteTapped: (UIGestureRecognizer*)sender
{
	if( [sender state] == UIGestureRecognizerStateEnded ) {
		//Here we would decide how we want to display it, based
		//on orientation or whatnot.
		/*
		if( [self.delegate respondsToSelector: @selector(miniNote:shouldZoomAfterTouch:)] ) {
			zoom = [self.delegate miniNote: self shouldZoomAfterTouch: sender];
		}
		 */

		NTIThreadedNoteContainer* foundTree = nil;
		NSUInteger i = 0;
		for( NTIThreadedNoteContainer* tree in self.displayedObjects ) {
			if( tree.uan.miniTapRecognizer == sender ) {
				foundTree = tree;
				break;
			}
			i++;
		}

		if( foundTree ) {

			NTIThreadedNoteInPageViewController* notes
				= [[[NTIThreadedNoteInPageViewController alloc]
					initWithThreadedNote: foundTree
					onPage: self.ntiPageId
					inContainer: self] autorelease];
			//notes.delegate = self;

			UINavigationController* nav = [[[UINavigationController alloc]
											initWithRootViewController: notes] autorelease];
			nav.view.bounds = notes.tableView.bounds;
			nav.navigationBarHidden = NO; //The inspector depends on the nav bar.

			self.modalInPopover = YES;

			if( self->miniNotePopoverController == nil ) {
				self->miniNotePopoverController
					= [[UIPopoverController alloc] initWithContentViewController: nav];
			}
			else {
				[self->miniNotePopoverController setContentViewController: nav];
			}


			[[TestAppDelegate sharedDelegate]
			 presentPopover: self->miniNotePopoverController
			 fromRect: foundTree.uan.noteManager.miniNoteViewController.view.frame
			 inView: self->controller.gutter
			 permittedArrowDirections: UIPopoverArrowDirectionAny
			 animated: YES];
		}
	}
}


-(CGPoint)htmlDocumentPointFromWindowPoint: (CGPoint)p
{
	//Delegate method
	return [self->controller.webview htmlDocumentPointFromWindowPoint: p];
}

@end
