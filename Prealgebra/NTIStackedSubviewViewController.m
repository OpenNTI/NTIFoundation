//
//  NTIWebContextTableController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIStackedSubviewViewController.h"
#import "NTIParentViewController.h"

#import "NTIAppPreferences.h"

#import "UINavigationController-NTIExtensions.h"
#import "NSArray-NTIExtensions.h"

#import "NTIUtilities.h"
#import "UITableViewCell-NTIExtensions.h"
#import "NTIOSCompat.h"


@class NTIStackedSubviewControllerEntry;
@interface NTIStackedSubviewViewController()
-(void)zoom:(id)sender;
-(void)windowShade:(id)sender;
-(void)zoomEntry: (NTIStackedSubviewControllerEntry*) ent section: (NSInteger)section;
@end


@implementation NTIStackedSearchController
@synthesize view=field, miniView, presentsModalInsteadOfZooming, miniViewTitle, miniCreationAction, supportsZooming, miniViewHidden;
@synthesize searchBar;

-(id)init
{
	return [self initWithSearchBar: nil];
}

-(id)initWithSearchBar: (UISearchBar*)sb
{
	self = [super init];
	self->miniViewTitle = @"Search";
	self->presentsModalInsteadOfZooming = NO;
	self->supportsZooming = NO;
	
	if( sb ) {
		self->searchBar = [sb retain];
	}
	else {
		self->searchBar = [[UISearchBar alloc] init];
	}
	self->field = self->searchBar.subviews.lastObject;

	CGRect bounds = self->field.frame;
	bounds.size.height = 30;
	self->field.frame = bounds;
	self->field.backgroundColor = [UIColor darkGrayColor];

	return self;
}

-(CGFloat)miniViewHeight
{
	CGRect bounds = self->field.frame;
	bounds.size.height = 30;
	self->field.frame = bounds;
	return 30;
}

-(void)dealloc
{
	NTI_RELEASE( self->searchBar );
	[super dealloc];
}

@end

@interface NTIStackedSubviewControllerEntry : OFObject {
	@private 
	id nr_owner;
}

@property (nonatomic,retain) id<NTITwoStateViewControllerProtocol> controller;
@property (nonatomic,readonly) UIView* headerView;
//These are all contained in and retained by the headerView.
@property (nonatomic,readonly) UILabel* label;
@property (nonatomic,readonly) UIButton* shadeButton;
@property (nonatomic,readonly) UIButton* zoomButton;
@property (nonatomic,readonly) UIButton* addButton;

@property (nonatomic,readonly) UIView* miniView;
//-1 unless the controller specifically defines it.
@property (nonatomic,readonly) CGFloat miniViewHeight;
@property (nonatomic,readonly) NSString* miniViewTitle;
@property (nonatomic,readonly) SEL miniCreationAction;
@property (nonatomic,readonly) BOOL supportsZooming, presentsModalInsteadOfZooming;
@property (nonatomic,readonly) BOOL miniViewHidden, hidesSectionHeader;
@property (nonatomic,readonly) UIViewController* maximizedViewController;
@property (nonatomic,assign) BOOL visible, minimized;
+(id)entryWithController: (id)c owner: (id)o;
-(id)initWithController: (id)c owner: (id)o;
@end


@implementation NTIStackedSubviewControllerEntry
@synthesize controller, visible, minimized, shadeButton, zoomButton, addButton, label;
@synthesize headerView;

+(id)entryWithController: (id)c owner: (id)o
{
	return [[[self alloc] initWithController: c owner: o] autorelease];
}

-(id)initWithController: (id)c owner: (id)o
{
	self = [super init];
	self->nr_owner = o;
	self.controller = c;
	self.visible = YES;
	self.minimized = YES;
	
	if( [c respondsToSelector: @selector(miniViewHidden)] ) {
		[c addObserver: self
			forKeyPath: @"miniViewHidden"
			   options: NSKeyValueObservingOptionNew
			   context: nil];	
	}

	if( [c respondsToSelector: @selector(miniViewCollapsed)] ) {
		[c addObserver: self
			forKeyPath: @"miniViewCollapsed"
			   options: NSKeyValueObservingOptionNew
			   context: nil];	
	}
	
	return self;
}

-(void)observeValueForKeyPath: (NSString*)keyPath
					 ofObject: (id)object 
					   change: (NSDictionary*)change 
					  context: (void*)context
{
	if( [keyPath isEqual: @"miniViewHidden"] ) {
		[self->nr_owner updateHiddenControllers];
	}
	else {
		[self->nr_owner windowShadeController: self.controller];
	}
}

-(void)setVisible: (BOOL)value
{
	self->visible = value;
	if( !value ) {
		[self->shadeButton setImage: [UIImage imageNamed: @"OICollapsed.png"]
						   forState: UIControlStateNormal];
	}
	else {
		[self->shadeButton setImage: [UIImage imageNamed: @"OIExpanded.png"]
						   forState: UIControlStateNormal];
	}
}

-(UIView*)headerView
{
	if( self->headerView ) {
		return self->headerView;
	}
	
	UIView* view = [[[UINib nibWithNibName: @"WebContextHeaderView" bundle: nil]
					 instantiateWithOwner: nil
					 options: nil] objectAtIndex: 0];
	self->headerView = [view retain];
	
	
	UILabel* viewLabel = (id)[view viewWithTag: 1];
	UIButton* zoomBox = (id)[view viewWithTag: 2];
	UIButton* windowShade = (id)[view viewWithTag: 3];
	UIButton* add = (id)[view viewWithTag: 4];
	
	self->shadeButton = windowShade;
	//Ensure our triangle matches
	self.visible = self.visible;
	self->addButton = add;
	self->zoomButton = zoomBox;	
	self->label = viewLabel;
	
	
	self.label.text = self.miniViewTitle;
	if( self.miniCreationAction ) {
		add.hidden = NO;
		[add addTarget: self.controller action: self.miniCreationAction
	  forControlEvents: UIControlEventTouchUpInside];
	}
	else {
		add.hidden = YES;
	}
	
	if( self.supportsZooming ) {
		[zoomBox addTarget: self->nr_owner
					action: @selector(zoom:)
		  forControlEvents: UIControlEventTouchDown];
	}
	else {
		zoomBox.hidden = YES;
	}
	
	[windowShade addTarget: self->nr_owner
					action: @selector(windowShade:)
		  forControlEvents: UIControlEventTouchDown];
	
	if( [self->controller respondsToSelector: @selector(longPressInMiniViewHeader:)] ) {
		UIGestureRecognizer* gest = [[[UILongPressGestureRecognizer alloc]
									  initWithTarget: self action: @selector(longPressInMiniViewHeader:)] autorelease];
		[self->headerView addGestureRecognizer: gest];
	}
	
	return self->headerView;
}

-(void)longPressInMiniViewHeader: (id)sender
{
	[self->controller longPressInMiniViewHeader: sender];	
}

-(UIViewController*)maximizedViewController
{
	UIViewController* viewController = nil;
	if( [controller respondsToSelector: @selector(maximizedViewController)] ) {
		viewController = [controller maximizedViewController];
	}
	else {
		viewController = (id)controller;
	}	
	return viewController;
}

-(UIView*)miniView
{
	UIView* result = nil;
	if( [self->controller respondsToSelector: @selector(miniView)] ) {
		result = [self->controller miniView];
	}
	if( !result ) {
		result = [self->controller view];
	}
	return result;
}
//Answers YES if the miniView is actually the controllers main (only)
//view. In this case, the size will likely need to be forced on it.
-(BOOL)miniViewIsMainView
{
	return	![self->controller respondsToSelector: @selector(miniView)]
		||	[self->controller miniView] == nil;
}

-(NSString*)miniViewTitle
{
	NSString* result = nil;
	if( [self->controller respondsToSelector: _cmd] ) {
		result = [self->controller performSelector: _cmd];
	}
	if( !result && [self->controller respondsToSelector: @selector(navigationItem)] ) {
		UINavigationItem* nav = [(UIViewController*)self->controller navigationItem];
		result = nav.title;
	}
	
	
	if( !result && [self->controller respondsToSelector: @selector(topViewController)] ) {
		UINavigationItem* nav = [(UIViewController*)[(id)self->controller topViewController] 
								 navigationItem];
		result = nav.title;
	}
	
	return result;
}

#define forward(type,action,def) \
-(type)action \
{\
	type result = def; \
	if( [self->controller respondsToSelector: _cmd] ) { \
		result = (type)[self->controller action]; \
	} \
	return result; \
} 

forward(SEL,miniCreationAction,nil)
forward(BOOL,supportsZooming,NO)
forward(BOOL,presentsModalInsteadOfZooming,NO)
forward(BOOL,miniViewHidden,NO)
forward(CGFloat,miniViewHeight,-1.0f)
forward(BOOL,hidesSectionHeader,NO)

#undef forward

-(void)searchBar: (UISearchBar*)searchBar textDidChange: (NSString*)searchText
{
	if( [self->controller respondsToSelector: _cmd] ) {
		[(id)self->controller searchBar: searchBar textDidChange: searchText];
	}
}

-(void)dealloc
{
	[self->headerView release];
	[(id)self.controller removeObserver: self forKeyPath: @"miniViewHidden"];
	[(id)self.controller removeObserver: self forKeyPath: @"miniViewCollapsed"];	
	self.controller = nil;
	[super dealloc];
}
@end


@implementation NTIStackedSubviewViewController

@synthesize searchController;

static id commonInit( NTIStackedSubviewViewController* self,
					 NTIStackedSearchController* searchController,
					 NSArray* otherControllers )
{
	NTI_RELEASE( self->allControllers );
	self->allControllers = [[NSMutableArray alloc] init];
	
	if( searchController ) {
		self->searchController = [searchController retain];
		self->searchController.searchBar.delegate = self;
		self.tableView.tableHeaderView = self->searchController.view;
	}
	for( id c in otherControllers ) {
		[self->allControllers addObject: 	
		 [NTIStackedSubviewControllerEntry entryWithController: c
														 owner: self]];
	}
	
	[self updateHiddenControllers];

	//For ios5, make these all our children
	if( [self respondsToSelector: @selector(addChildViewController:)] ) {
		for( id c in self->controllers ) {
			if( [c isKindOfClass: [UIViewController class]] ) {
				[self addChildViewController: c];	
			}
		}
	}
	
	UIPinchGestureRecognizer* pincher = [[[UIPinchGestureRecognizer alloc]
										  initWithTarget: self
										  action: @selector(pinched:)] autorelease];
	pincher.cancelsTouchesInView = YES;
	[self.tableView addGestureRecognizer: pincher];
	self.contentSizeForViewInPopover = CGSizeMake( 320, 768 );
	return self;	
}

-(id)initWithStyle: (UITableViewStyle)style
{
	self = [super initWithStyle: style];
	commonInit( self, nil, [NSArray array] );
	return self;
}

-(void)awakeFromNib
{
	commonInit( self, nil, [NSArray array] );
}

-(id)initWithControllers: (NSArray*)other
{
	return [self initWithSearchController: [[[NTIStackedSearchController alloc] init] autorelease]
							  controllers: other];
}

-(id)initWithSearchController: (NTIStackedSearchController*)nsearchController
				  controllers: (NSArray*)other
{
	self = [super initWithStyle: UITableViewStyleGrouped];
	return commonInit( self, nsearchController, other );	
}

-(void)dealloc
{
	[self->currentMaximizedEntry release];
	[self->searchController release];
	[self->controllers release];
	[self->allControllers release];
	[super dealloc];
}

-(NSArray*)allSubviewControllers
{
	return [self->allControllers arrayByPerformingSelector: @selector(controller)];
}

-(void)updateHiddenControllers
{
	NSUInteger lastCount = [self->controllers count];
	NTI_RELEASE( self->controllers );
	NSMutableArray* ar = [[NSMutableArray alloc] init];
	for( id ent in self->allControllers ) {
		if( ![ent miniViewHidden] ) {
			[ar addObject: ent];	
		}
	}
	BOOL shouldReload = self.isViewLoaded && ar.count != lastCount;
	self->controllers = ar;
	if( shouldReload ) {
		[self.tableView reloadData];
	}
}

#pragma mark -
#pragma mark SearchBar Delegate

-(void)searchBar: (UISearchBar*)searchBar textDidChange: (NSString*)searchText
{
	for( NTIStackedSubviewControllerEntry* ent in self->allControllers ) {
		[ent searchBar: searchBar textDidChange: searchText];
	}
}

-(NSInteger)tableView: (UITableView*)tableView numberOfRowsInSection: (NSInteger)section
{
	NSInteger result = 0;
	NTIStackedSubviewControllerEntry* ent = [self->controllers objectAtIndex: section];
	if( ent.visible ) {
		result = 1;
	}
	return result;
}

-(CGFloat)tableView: (UITableView*)tv heightForRowAtIndexPath: (NSIndexPath*)indexPath
{
	NTIStackedSubviewControllerEntry* ent = [self->controllers objectAtIndex: indexPath.section];
	CGFloat result = ent.miniViewHeight;
	if( result < 0 ) {
		UIView* view = ent.miniView;
		if( view ) {
			result = view.bounds.size.height;
		}
		else {
			result = tv.rowHeight;
		}
	}
	return result;
}

static UITableViewCell* addMiniViewToCell(	NTIStackedSubviewControllerEntry* ent,
										  	UITableViewCell* result )
{
	UIView* theContentView = ent.miniView;
	CGFloat height = ent.miniViewHeight;
	BOOL resize = height < 0 || [ent miniViewIsMainView];
	[result setContentViewRoundingCornersForGroup: theContentView
										   resize: resize];
	return result;
}

-(UITableViewCell*) tableView: (UITableView*)tableView 
		cellForRowAtIndexPath: (NSIndexPath*)indexPath
{
	static id REUSEID = @"NTIWebContextTableControllerContentCell";
	NSInteger section = indexPath.section;
	NTIStackedSubviewControllerEntry* ent = [self->controllers objectAtIndex: section];
	UITableViewCell* result = [tableView dequeueReusableCellWithIdentifier: REUSEID];
	if( !result ) {
		result = [[[UITableViewCell alloc] 
				   initWithStyle: UITableViewCellStyleDefault
				   reuseIdentifier: REUSEID] autorelease];
		result.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	return addMiniViewToCell( ent,  result );
}

#undef USES_OUR_TABLE

-(NTIStackedSubviewControllerEntry*) entryForRowAtPoint: (CGPoint)center
{
	NTIStackedSubviewControllerEntry* ent = nil;
	NSIndexPath* path = [self.tableView indexPathForRowAtPoint: center];
	if( path ) {
		ent = [self->controllers objectAtIndex: path.section];
	}
	return ent;
}

#define ZOOM_SCALE_THRESHOLD 1.7
#define ZOOM_VELOCITY_THRESHOLD 0.2
-(void)pinched:(UIPinchGestureRecognizer*)pincher
{
	if(		pincher.state == UIGestureRecognizerStateChanged
	   &&	pincher.scale > ZOOM_SCALE_THRESHOLD
	   &&	pincher.velocity > ZOOM_VELOCITY_THRESHOLD ) {
		CGPoint center = [pincher locationInView: self.tableView];
		NSIndexPath* path = [self.tableView indexPathForRowAtPoint: center];
		if( path ) {
			id ent = [self->controllers objectAtIndex: path.section];
			//TODO: If the zooming is modal, and we've already zoomed one thing
			//to the content view,
			//we lose track of what should go where. So for now, don't allow that.
			if(		[[ent controller] supportsZooming]
			   &&	![[ent controller] presentsModalInsteadOfZooming]) {
				[self zoomEntry: ent section: path.section];
				//Once we zoom, stop recognizing. Otherwise, queued events
				//could cause us to re-zoom the object we put in place of
				//this one.
				pincher.enabled = NO;
				pincher.enabled = YES;
			}
		}
		
	}
}

-(NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
	return [self->controllers count];
}

-(NSString*)tableView: (UITableView*)tableView titleForHeaderInSection: (NSInteger)section
{
	//On iOS 5, this isn't called because we implement
	//tableView:viewForHeaderInSection...(unless we are hiding the section.
	//In that case, we want an empty title)
	//However, in iOS 4.3, this is called (and then ignored) so it
	//must run successfully
	NSString* result = @"";
	NTIStackedSubviewControllerEntry* ent = [self->controllers objectAtIndex: section];
	if( ent.hidesSectionHeader ) {
		result = @"";
	}
	else {
		result = ent.miniViewTitle;
	}
	return result;
}

static void toggleRows( NTIStackedSubviewViewController* self, NSInteger section )
{
	//The table view is very picky about having the number of rows
	//in the data delegate correct. The number after the rows change
	//must match the number before the change +- the delta.
	NTIStackedSubviewControllerEntry* ent = [self->controllers objectAtIndex: section];
	BOOL newVisibleValue = !ent.visible;
	ent.visible = YES;
	NSInteger count =  [self tableView: nil numberOfRowsInSection: section];
	ent.visible = newVisibleValue;
	NSMutableArray* paths = [NSMutableArray arrayWithCapacity: count];
	for( int i = 0; i < count; i++ ) {
		[paths addObject: [NSIndexPath indexPathForRow: i inSection: section]];
	}
	[self.tableView beginUpdates];
	if( newVisibleValue == NO ) {
		[self.tableView deleteRowsAtIndexPaths: paths
							  withRowAnimation: UITableViewRowAnimationLeft];
	}
	else {
		[self.tableView insertRowsAtIndexPaths: paths
							  withRowAnimation: UITableViewRowAnimationLeft];
	}
	[self.tableView endUpdates];	
}

static void windowShade( NTIStackedSubviewViewController* self, NSInteger section )
{
	toggleRows( self, section );
}

-(void)windowShade: (id)s
{
	NSInteger section = 0;
	for( id ent in self->controllers ){
		if( s == [ent shadeButton] ) {
			windowShade( self, section );
			break;
		}
		section++;
	}
}

-(void)windowShadeController: (id)controller
{
	NSInteger section = 0;
	for( id ent in self->controllers ){
		if( controller == [ent controller] ) {
			windowShade( self, section );
			break;
		}
		section++;
	}
}

-(void)zoomEntry: (NTIStackedSubviewControllerEntry*) ent section: (NSInteger)section
{
	if( [ent.controller respondsToSelector: @selector(willBeZoomedByController:)] ) {
		[ent.controller willBeZoomedByController: self];
	}
	
	if( ent.controller.presentsModalInsteadOfZooming ) {
		if( ent.minimized ) {
			UIViewController* viewController = ent.maximizedViewController;
			self->nr_modalEntry = ent;
			
			//Going modal, we need a way to get back. So give it a button.
			//Only need to do this here.
			UIBarButtonItem* returnButton = [[[UIBarButtonItem alloc] 
											  initWithBarButtonSystemItem: UIBarButtonSystemItemDone
											  target: self
											  action: @selector(unzoom:)] autorelease];
			if( [ent.controller respondsToSelector:
				 @selector(zoomController:willZoomWithBarButtonItem:)] ) {
				[ent.controller zoomController: self willZoomWithBarButtonItem: returnButton];
			}
			else if( [viewController respondsToSelector: @selector(rootViewController)] ) {
				UIViewController* display = [(id)viewController rootViewController];
				display.navigationItem.rightBarButtonItem = returnButton;
			}
			
			
			if( ent.controller.miniView ) {
				//Take it out of the cell
				[ent.controller.miniView removeFromSuperview];
			}
			//Animate the appearance of the new view
			[self.view.window.rootViewController presentModalViewController: viewController
																   animated: YES];
			[ent.controller.view sizeToFit];
			ent.minimized = NO;
		}
		else {
			[self.view.window.rootViewController dismissModalViewControllerAnimated: YES];
			UITableViewCell* stuffCell = [self.tableView 
										  cellForRowAtIndexPath: 
										  [NSIndexPath indexPathForRow: 0 inSection: section]];
			addMiniViewToCell( ent, stuffCell );
			ent.minimized = YES;
			self->nr_modalEntry = nil;
		}
	}
	else if( self.splitViewController ) {
		OBASSERT(ent.minimized);
		//By definition, it's minimized. We want to swap it with the maximized
		//view. If we have a prior entry, that's the one to max. Otherwise,
		//we assume the current max is a NTIWebContextViewController.
		NTIStackedSubviewControllerEntry* theMaxEntry = nil;
		CGRect miniFrameToZoomTo = [self.tableView rectForSection: section];
		UIView* maxiView = [self.splitViewController.viewControllers.secondObject view]; 
		CGRect maxiFrameToZoomFrom = [maxiView frame];
		if( self->currentMaximizedEntry ) {
			theMaxEntry = self->currentMaximizedEntry;
		}
		else {
			UIViewController* theMaxController = self.splitViewController.viewControllers.secondObject;
			theMaxEntry = [NTIStackedSubviewControllerEntry
						   entryWithController: theMaxController
						   owner: self];
		}
		//We'll float the cell over to the new position by putting it 
		//in the window and transforming it to match.
		UITableViewCell* cell2 = [self.tableView cellForRowAtIndexPath:
						[NSIndexPath indexPathForRow: 0 inSection: section]];
		UIView* contentView = [cell2.contentView subviews].firstObject;
		CGAffineTransform origCellTf = contentView.transform;
		CGRect origContentFrame = contentView.frame;
		[contentView removeFromSuperview];
		[maxiView.window addSubview: contentView];
		//Since it's in the window, we must match the transform
		contentView.transform = maxiView.window.rootViewController.view.transform;
		miniFrameToZoomTo = [maxiView.window convertRect: miniFrameToZoomTo
												fromView: self.tableView];
		contentView.frame = miniFrameToZoomTo;
		maxiFrameToZoomFrom = [maxiView.window convertRect: maxiFrameToZoomFrom
												  fromView: maxiView.superview];

		
		[UIView animateWithDuration: 0.2 delay: 0.0
							options: UIViewAnimationCurveEaseInOut
						 animations: ^{
							 
							 contentView.frame = maxiFrameToZoomFrom;
							 //Tell the old thing it was being minimized if it wants to know
							 //Let it do its processing while we're animating.
							 if( [theMaxEntry.controller respondsToSelector: @selector(willBeZoomedByController:)] ) {
								 [theMaxEntry.controller willBeZoomedByController: self];
							 }
							 if( [theMaxEntry.controller respondsToSelector: @selector(miniView)] ) {
								 
								 [theMaxEntry.controller miniView];
							 }
						 }
						 completion: ^(BOOL _) {
							 [contentView removeFromSuperview];
							 [cell2.contentView addSubview: contentView];	
							 contentView.transform = origCellTf;
							 contentView.frame = origContentFrame;
		NSArray* newViews = [NSArray arrayWithObjects:
							 [self.splitViewController.viewControllers firstObject],
							 ent.maximizedViewController,
							 nil ];
		//Reparent the VC
		if( [((UIViewController*)[newViews secondObject]).parentViewController 
			 respondsToSelector: @selector(removeChildViewController:animated:)] ) {
			//NTI
			[(id)((UIViewController*)[newViews secondObject]).parentViewController
			 removeChildViewController: [newViews secondObject]
			 animated: NO];
		}
		else if( [[newViews secondObject] respondsToSelector: @selector(removeFromParentViewController)] ) {
			//iOS 5 views
			[[newViews secondObject] removeFromParentViewController];
		}
		//And the views must be out of the view hierarchy in iOS5 before
		//the VCs cad be added
		[ent.maximizedViewController.view removeFromSuperview];
		self.splitViewController.viewControllers = newViews;
		
		//in our mini view, swap the previously maximized version with
		//the new minimized version of what had been maximized, and note
		//the new maximized value.

		id futureEntry = [ent retain];
		[self->controllers replaceObjectAtIndex: section
									 withObject: theMaxEntry];
		[self->currentMaximizedEntry release];
		self->currentMaximizedEntry = futureEntry;
		
		 [self.tableView reloadSections: [NSIndexSet indexSetWithIndex: section]
					   withRowAnimation: UITableViewRowAnimationLeft];
		}];
	}
}

-(void)unzoom: (id)_
{
	[self zoomEntry: self->nr_modalEntry 
			section: [self->controllers indexOfObject: self->nr_modalEntry]];
}

-(void)zoom: (id)s
{
	NSInteger section = 0;
	NTIStackedSubviewControllerEntry* ent = nil;
	for( id e in self->controllers ) {
		if( s == [e zoomButton] ) {
			ent = e;
			break;
		}
		section++;
	}
	
	[self zoomEntry: ent section: section];
}

-(UIView*)tableView: (UITableView*)tv viewForHeaderInSection: (NSInteger)section
{
	NTIStackedSubviewControllerEntry* ent = [self->controllers objectAtIndex: section];
	if( ent.hidesSectionHeader ) {
		return nil;
	}
	
	return ent.headerView;
}

-(CGFloat)tableView: (UITableView*)tv heightForHeaderInSection: (NSInteger)section
{
	NTIStackedSubviewControllerEntry* ent = [self->controllers objectAtIndex: section];
	if( ent.hidesSectionHeader ) {
		return 0.0;
	}
	
	return 32;
}

-(UIView*)tableView: (UITableView*)tv viewForFooterInSection: (NSInteger)section
{
	return nil;
}

-(CGFloat)tableView: (UITableView*)tv heightForFooterInSection: (NSInteger)section
{
	return 0.0;
}


-(void)observeValueForKeyPath: (NSString*)key 
					 ofObject: (id)object 
					   change: (NSDictionary*)change
					  context: (void*)ctx
{
	if( [change objectForKey: NSKeyValueChangeNewKey] ) {
		[self.tableView reloadData];
	}
}

//Forwarding: We can pass some messages on to some of our internal objects

//-(BOOL)canPerformAction: (SEL)action withSender: (id)sender
//{
//	//TODO: This forwarding list is repated too many places
//	if( [self->nr_stuffcontroller respondsToSelector: action] ) {
//		return [self->nr_stuffcontroller canPerformAction: action withSender: sender];
//	}
//	return [super canPerformAction: action withSender: sender];
//}
//
//-(BOOL)respondsToSelector: (SEL)sel
//{
//	//TODO: Is this an abuse? WebAndToolController likes to use
//	//us as if we were the note controller.
//	return [super respondsToSelector: sel] || [self->nr_stuffcontroller respondsToSelector: sel];	
//}
//
//-(id)forwardingTargetForSelector:(SEL)aSelector
//{
//	if( [self->nr_stuffcontroller respondsToSelector: aSelector] ) {
//		return self->nr_stuffcontroller;
//	}
//	return [super forwardingTargetForSelector:aSelector];
//}

@end
