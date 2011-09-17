//
//  NTIWebContextTableController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIInlineSettingController.h"
#import "NTIWebContextTableController.h"

#import "NTIWebView.h"
#import "NTINavigationParser.h"
#import "NTINoteLoader.h"

#import "NTIAppPreferences.h"
#import "NTIParentViewController.h"
#import "UINavigationController-NTIExtensions.h"
#import "NSArray-NTIExtensions.h"
#import "NTIGravatars.h"
#import "TestAppDelegate.h"
#import "NTIUtilities.h"
#import "NTIWebContextFriendController.h"
#import "NTIWebContextRelatedController.h"
#import "NTINoteController.h"
#import "NTIAppUser.h"
#import "NTIArraySubsetTableViewController.h"
#import "NTIViewController.h"
#import "NTINoteView.h"
#import "NTIUserCache.h"
#import <stdlib.h>

@class WebAndToolController;

@interface NTIWebContextSettingsController : NTIInlineSettingController<NTITwoStateViewControllerProtocol>
@end
@implementation NTIWebContextSettingsController
@synthesize miniView, presentsModalInsteadOfZooming, miniViewTitle, 
			miniCreationAction, supportsZooming;
-(id)initWithNibName: (NSString *)nibName
			  bundle: (NSBundle *)bundle
			 webView: (WebAndToolController*)web
{
	self = [super initWithNibName: nibName bundle: bundle webView: web];
	self->supportsZooming = NO;
	self->miniViewTitle = @"Settings";
	self.navigationItem.title = self->miniViewTitle;
	return self;
}

-(CGFloat)miniViewHeight
{
	return 297;
}

-(UIView*)view
{
	return super.view;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	//We can't rely on this, because our subview gets
	//reparanted
	self->miniView = [[[super view] viewWithTag: 1] retain];
	CGRect frame = self->miniView.frame;
	frame.origin.y = 10;
	frame.origin.x = 10;
	self->miniView.frame = frame;
	self.view = self->miniView;
}

-(void)viewWillAppear:(BOOL)animated
{
	[self.navigationController setNavigationBarHidden: YES
											 animated: animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[self.navigationController setNavigationBarHidden: NO
											 animated: animated];

}

-(UIView*)miniView 
{
	NSLog( @"View: %@", super.view );
	[super view];
	return self->miniView;
}

@end

//This exists as an external object to workaround our weird problems
//with respondsToSelector in this module.
@interface NTIWebContextFilterDelegate : OFObject {
	@package
	NSMutableArray* selectedFilterGroups;
	NSArray* tablesToReload;
	NTIFriendsList* fakeEveryone;
}
@end

@implementation NTIWebContextFilterDelegate

-(id)init
{
	self = [super init];
	fakeEveryone = [[NTIFriendsList alloc] init];
	[fakeEveryone setValue: @"Everyone"
					forKey: @"Username"];

	fakeEveryone.realname = @"All";
	fakeEveryone.avatarURL = @"http://www.gravatar.com/avatar/dfa1147926ce6416f9f731dcd14c0260?s=44&d=retro";
	
	return self;
}

-(void)setSelectedFilterGroups: (NSArray*)incoming
{
	incoming = [incoming mutableCopy];
	NTI_RELEASE( self->selectedFilterGroups );
	self->selectedFilterGroups = (id)incoming;
	[self->selectedFilterGroups insertObject: self->fakeEveryone
									 atIndex: 0];
}

-(void)longPressInMiniViewHeader: (id)sender
{
	if( !self->selectedFilterGroups ) {
		[self setSelectedFilterGroups: [NTIAppUser appUser].friendsLists];
	}
	NTIArraySubsetTableViewController* vc
	= [[[NTIArraySubsetTableViewController alloc] 
		initWithAllObjects: [[NTIAppUser appUser].friendsLists arrayByAddingObject: self->fakeEveryone]] 
	   autorelease];
	vc.delegate = self;
	UIPopoverController* pop = [[[UIPopoverController alloc] initWithContentViewController: vc] autorelease];
	
	[[TestAppDelegate sharedDelegate] presentPopover: pop
											fromRect: [[sender view] bounds]
											  inView: [[sender view] superview]
							permittedArrowDirections: UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight
											animated: YES];
}

-(void)subset: (id)_ configureCell: (UITableViewCell*)cell forObject: (id)object
{
	[NTIWebContextFriendController configureCell: cell forSharingTarget: object];
}

-(void)subset: (id)me didSelectObject: (id)object
{
	//No matter where it was selected, we toggle the state of it
	if( [self->selectedFilterGroups containsObjectIdenticalTo: object] ) {
		//It was shared, now it is not, so update the model
		[self->selectedFilterGroups removeObjectIdenticalTo: object];
		[me markObject: object withCheckmark: NO];
	}
	else {
		//It wasn't shared, now it is. So update the model
		if( object == self->fakeEveryone ) {
			[self setSelectedFilterGroups: [NTIAppUser appUser].friendsLists];
			for( id o in self->selectedFilterGroups ) {
				[me markObject: o withCheckmark: YES];
			}
		}
		else {
			[self->selectedFilterGroups addObject: object];
			[me markObject: object withCheckmark: YES];
		}
	}

	for( id tableToReload in self->tablesToReload ) {
		NSArray* filtered = [tableToReload subset: tableToReload filterSource: [tableToReload allObjects]];
		[tableToReload setFilteredSubset: filtered andReloadTable: YES];
	}
}

-(NSArray*)subset: (id)me filterSource: (NSArray*)sourceArray
{
	if(		self->selectedFilterGroups == nil
	   ||	[self->selectedFilterGroups containsObjectIdenticalTo: self->fakeEveryone] ) {
		return [me subset: me filterSource: sourceArray];
	}
	
	//This filtering never applies to yourself
	NSArray* creatorStrings = [self->selectedFilterGroups valueForKeyPath:
							   @"@distinctUnionOfObjects.friends.@distinctUnionOfObjects.Username"];
	creatorStrings = [creatorStrings arrayByAddingObject: [NTIAppUser appUser].Username];
	
	NSArray* created = [sourceArray select: ^BOOL(id obj) {
		return [creatorStrings containsObject: [obj Creator]];	
	}];
	//Now see if there was a content search.
	return [me subset: me filterSource: created];
}


-(UITableViewCellAccessoryType)subset: (id)_ accessoryTypeForObject: (NTISharingTarget*)target
{
	UITableViewCellAccessoryType result = UITableViewCellAccessoryNone;
	if( [self->selectedFilterGroups containsObjectIdenticalTo: target] ) {
		result = UITableViewCellAccessoryCheckmark;
	}
	return result;
}

-(void)dealloc
{
	NTI_RELEASE( self->fakeEveryone );
	NTI_RELEASE( self->selectedFilterGroups );
	NTI_RELEASE( self->tablesToReload );
	[super dealloc];
}

@end


#import "NTIUserDataTableViewController.h"
@interface NTIWebContextUserDataNavController : UINavigationController<NTITwoStateViewControllerProtocol> {
@private
	
	id webController;
	BOOL maximized;
@package
	id nr_contextController;
	NTIUserDataTableViewController* tableController;
}
@end

@implementation NTIWebContextUserDataNavController
@synthesize miniView, presentsModalInsteadOfZooming, miniViewTitle, miniCreationAction, supportsZooming;


-(id)initWithWeb: (id)web
		miniTile: (NSString*)title
	  miniAction: (SEL)action
	   tableCont: (NTIUserDataTableViewController*)tableCont
{
	self = [super init];
	id noteCont = [tableCont retain];

	//The order is critical!
	[(NTIParentViewController*)web addChildViewController: noteCont animated: NO];
	[self pushViewController: noteCont animated: NO];
	
	self->tableController = noteCont;
	self->tableController.modalPresentationStyle = UIModalPresentationFormSheet;
	self->tableController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	
	self->miniViewTitle = title;
	self.rootViewController.navigationItem.title = self->miniViewTitle;
	self->miniCreationAction = action;
	self->presentsModalInsteadOfZooming = NO;
	self->supportsZooming = YES;
	
	self.navigationBarHidden = YES;
	self.modalInPopover = YES;
	self.modalPresentationStyle = UIModalPresentationFormSheet;
	self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	self->webController = [web retain];
	return self;
}


-(UIView*)view
{
	return [super view];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

-(void)willBeZoomedByController: (NTIWebContextTableController*)c
{	
	//Musn't try to animate these transitions, there are
	//other animations going on and if we do animate them, then
	//we wind up with a stale UINavigationTransitionView blocking
	//event delivery.
	if( self->maximized ) {
		if( self->tableController == self.topViewController ) {
			//If we're miniziming, and nothing has been pushed, then hide our toolbar.
			[self setNavigationBarHidden: YES animated: NO];
		}
	}
	else {
		//Show the TB when maximized
		[self setNavigationBarHidden: NO animated: NO];
	}
	self->maximized = !self->maximized;
}

-(void)zoomController: (NTIWebContextTableController*)c willZoomWithBarButtonItem: (UIBarButtonItem*)item
{
	if( self.presentsModalInsteadOfZooming ) {
		self.rootViewController.navigationItem.rightBarButtonItem = item;
	}
}


-(CGFloat)miniViewHeight
{
	return 209;
}

#pragma mark - 
#pragma mark Note Creation

-(BOOL)canPerformAction: (SEL)action withSender: (id)sender
{
	if( [self->tableController respondsToSelector: action] ) {
		return [self->tableController canPerformAction: action withSender: sender];
	}
	return [super canPerformAction: action withSender: sender];
}

-(BOOL)respondsToSelector: (SEL)sel
{
	//See notes in WebContextTableContr
	return [super respondsToSelector: sel]
		|| [self->tableController respondsToSelector: sel];	
}

-(id)forwardingTargetForSelector:(SEL)aSelector
{
	if( [self->tableController respondsToSelector: aSelector] ) {
		return self->tableController;
	}
	return [super forwardingTargetForSelector:aSelector];
}

-(void)addObserver: (NSObject*)observer 
		forKeyPath: (NSString*)keyPath
		   options: (NSKeyValueObservingOptions)options 
		   context: (void*)context
{
	if( [@"miniViewCollapsed" isEqual: keyPath] || [@"miniViewHidden" isEqual: keyPath] ) {
		[self->tableController addObserver: observer
								forKeyPath: keyPath
								   options: options
								    context: context];
	}
	else {
		[super addObserver: observer forKeyPath: keyPath options: options context: context];
	}
}

-(void)removeObserver: (NSObject*)observer forKeyPath: (NSString*)keyPath
{
	
	if( [@"miniViewCollapsed" isEqual: keyPath] || [@"miniViewHidden" isEqual: keyPath] ) {
		[self->tableController removeObserver: observer
								forKeyPath: keyPath];
	}
	else {
		[super removeObserver: observer forKeyPath: keyPath];
	}
}
//TODO: This is the new ios 5 api. Needs conditional

-(void)removeObserver: (NSObject*)observer 
		   forKeyPath: (NSString*)keyPath
			  context: (void*)context
{
	if( [@"miniViewCollapsed" isEqual: keyPath] || [@"miniViewHidden" isEqual: keyPath] ) {
		[self->tableController removeObserver: observer
								forKeyPath: keyPath
								   context: context];
	}
	else {
		[super removeObserver: observer forKeyPath: keyPath context: context];
	}
}

-(void)longPressInMiniViewHeader: (id)sender
{
	[self->nr_contextController longPressInMiniViewHeader: sender];
}

-(void)dealloc
{
	[(NTIParentViewController*)self->webController removeChildViewController: self->tableController animated: NO];
	NTI_RELEASE(self->webController);
	NTI_RELEASE(self->tableController);
	[super dealloc];
}

@end


#import "NTINoteController.h"
@interface NTIWebContextStuffNavController : NTIWebContextUserDataNavController<UINavigationControllerDelegate>

@end

@implementation NTIWebContextStuffNavController

-(id)initWithWeb: (id)web
{
	self = [super initWithWeb: web
					 miniTile: @"My Stuff"
				   miniAction: NWA_CREATE_NOTE
				   //FIXME: There are more kinds of user data than just notes!
				   //This class does a poor job of handling them. It mostly
				   //works because highlights mimic notes in many ways.
					tableCont: [[[NTINoteController alloc] 
								 initWithWebController: web] autorelease]];
	self.delegate = self;
	return self;
}

-(void)navigationController: (UINavigationController*)navigationController
	 willShowViewController: (UIViewController*)viewController 
				   animated: (BOOL)animated
{
	if( [viewController isKindOfClass: [NTIThreadedNoteViewController class]] ){
		[self setNavigationBarHidden: NO animated: YES];
	}
	else {
		[self setNavigationBarHidden: YES animated: YES];
	}
}

@end

@interface NTIActivityTableViewController : NTIUserDataTableViewController
@end

@implementation NTIActivityTableViewController

-(id)initWithStyle: (UITableViewStyle)style webController: (WebAndToolController*)controller
{
	self = [super initWithStyle: style 
					  dataModel: [[[NTIActivityTableModel alloc] 
								   initWithWebController: controller] autorelease]];
	//TODO: Better composition. Need to filter on the underlying item too?
	self.predicate = [NTIChange searchPredicate];
	self.collapseWhenEmpty = YES;
	return self;
}

-(void)subset: (id)me configureCell: (UITableViewCell*)cell forObject: (id)object
{	
	NTIChange* theData = object;
	
	NSString* text = theData.summary;
	cell.textLabel.text = text;

	static char* assoc_str="ObjectForCell";
	
	objc_setAssociatedObject(cell, assoc_str, object, OBJC_ASSOCIATION_ASSIGN);
	
#define isObjectAssoc() objc_getAssociatedObject(cell, assoc_str) == object

	
	if( [text containsString: theData.Creator] ) {
		[[NTIUserCache cache] resolveUser: theData.Creator
									 then: ^(id user)
		{
			if( user && isObjectAssoc() ) {
				cell.textLabel.text = [text stringByReplacingAllOccurrencesOfString: theData.Creator
																		withString: [user prefDisplayName]];
			}
		}];
	}
	cell.detailTextLabel.text = theData.lastModifiedDateShortStringNL;
	cell.imageView.image = [UIImage imageNamed: @"Avatar-MysteryMan.jpg"];
	[[NTIGravatars gravatars] fetchIconForEmail: theData.Creator
										   then: ^(UIImage* img) {
											   //This could finish in the future after
											   //we've moved on, so make sure not to overwrite
											   if( img && isObjectAssoc() ) {
												   cell.imageView.image = img;
												   cell.imageView.userInteractionEnabled = YES;
												   [cell setNeedsDisplay];
											   }
										   }];
#undef isObjectAssoc
}

@end

@interface NTIWebContextActivityNavController : NTIWebContextUserDataNavController<UINavigationControllerDelegate> {

}
@end

@implementation NTIWebContextActivityNavController

-(id)initWithWeb: (id)web
{
	self = [super initWithWeb: web
					 miniTile: @"Recent Activity"
				   miniAction: nil
					tableCont: [[[NTIActivityTableViewController alloc] 
								 initWithStyle: UITableViewStylePlain
								 webController: web] autorelease]];
	self.delegate = self;
	return self;
}

-(void)navigationController: (UINavigationController*)navigationController
	 willShowViewController: (UIViewController*)viewController 
				   animated: (BOOL)animated
{
	if( [viewController isKindOfClass: [NTIThreadedNoteViewController class]] ) {
		[self setNavigationBarHidden: NO animated: YES];
	}
	else {
		[self setNavigationBarHidden: YES animated: YES];
	}
}

@end


@implementation NTIWebContextTableController

@synthesize webController;

-(id)initWithCoder: (NSCoder*)aDecoder
{
	self = [super initWithCoder: aDecoder];
	
	return self;
}

-(void)awakeFromNib
{
	NSMutableArray* array = [NSMutableArray array];
	[array addObject: 
	 [[[NTIWebContextFriendController alloc] initWithStyle: UITableViewStylePlain] autorelease]];
	
	NTIWebContextFilterDelegate* filter = [[[NTIWebContextFilterDelegate alloc] init] autorelease];
	
	[array addObject: 
	  [[self->nr_stuffcontroller = [NTIWebContextStuffNavController alloc] 
		initWithWeb: self.webController] autorelease]];
	((NTIWebContextUserDataNavController*)self->nr_stuffcontroller)->nr_contextController = filter;
	((NTIWebContextUserDataNavController*)self->nr_stuffcontroller)->tableController.delegate = filter;

	NTIWebContextUserDataNavController* tmp;
	[array addObject:
	 [tmp = [[NTIWebContextActivityNavController alloc] 
	   initWithWeb: self.webController] autorelease]];
	tmp->nr_contextController = filter;
	tmp->tableController.delegate = filter;
	self->nr_activitycontroller = tmp;
	
	filter->tablesToReload = [[NSArray arrayWithObjects: self->nr_stuffcontroller, tmp, nil] retain];
	
	[array addObject:
	  [[[NTIWebContextRelatedController alloc] initWithStyle: UITableViewStylePlain
														 web: self.webController] autorelease]];
	
	NTIWebContextSettingsController* settings
	= [[[NTIWebContextSettingsController alloc] initWithNibName: @"InlineSettingView"
														 bundle: [NSBundle mainBundle]
														webView: self.webController] autorelease]; 
	UINavigationController* settingsNav = [[[UINavigationController alloc] 
											initWithRootViewController: settings] autorelease];
	settingsNav.view.bounds = CGRectMake( 0, 0, 320, 300 );
	[array addObject: settingsNav];
	
	[super initWithControllers: array];
	for( id i in self.allSubviewControllers ) {
		if( [i respondsToSelector: @selector(tableView)] ) {
			//The necassary header isn't exported for some reason
			Class c = objc_getClass( "OUIInspectorBackgroundView" );
			id bgView = [[c alloc] init];
			[[i tableView] setBackgroundView: bgView];
			[bgView release];
		}
	}
	
	[super windowShadeController: settingsNav];
	[self.webController addObserver: self
						 forKeyPath: @"ntiPageId"
							options: NSKeyValueObservingOptionNew
							context: nil];
	
	self->timer = [[NSTimer timerWithTimeInterval: 30.0 
							target: self
										 selector: @selector(refreshSelector:)
						  userInfo: nil
						   repeats: YES] retain];
	[[NSRunLoop currentRunLoop] addTimer: self->timer
								 forMode: NSDefaultRunLoopMode];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(refreshSelector:)
	 name: NTINotificationRemoteNotificationRecvName
	 object: nil];
	 
	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(didBecomeActive:)
	 name: UIApplicationDidBecomeActiveNotification
	 object: [UIApplication sharedApplication]];
	//Fires on tapping the home button or the power button
	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(willResignActive:)
	 name: UIApplicationWillResignActiveNotification
	 object: [UIApplication sharedApplication]];		 	 
	 
}

-(void)refreshSelector: (id)sender
{
	[self->nr_stuffcontroller refreshDataForCurrentPage];
	[self->nr_activitycontroller refreshDataForCurrentPage];
}

-(void)releaseTimer
{
	[self->timer invalidate];
	NTI_RELEASE( self->timer );
}

-(void)didBecomeActive: (id)sender
{
	[self releaseTimer];
	self->timer = [[NSTimer timerWithTimeInterval: 30.0 
										   target: self
										 selector: @selector(refreshSelector:)
										 userInfo: nil
										  repeats: YES] retain];
	[[NSRunLoop currentRunLoop] addTimer: self->timer
								 forMode: NSDefaultRunLoopMode];
}

-(void)willResignActive: (id)sender
{
	[self releaseTimer];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[self releaseTimer];
	[super dealloc];
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

-(BOOL)canPerformAction: (SEL)action withSender: (id)sender
{
	//TODO: This forwarding list is repated too many places
	if( [self->nr_stuffcontroller respondsToSelector: action] ) {
		return [self->nr_stuffcontroller canPerformAction: action withSender: sender];
	}
	return [super canPerformAction: action withSender: sender];
}

-(BOOL)respondsToSelector: (SEL)sel
{
	//TODO: Is this an abuse? WebAndToolController likes to use
	//us as if we were the note controller.
	return [super respondsToSelector: sel] || [self->nr_stuffcontroller respondsToSelector: sel];	
}

-(id)forwardingTargetForSelector:(SEL)aSelector
{
	if( [self->nr_stuffcontroller respondsToSelector: aSelector] ) {
		return self->nr_stuffcontroller;
	}
	return [super forwardingTargetForSelector:aSelector];
}

@end
