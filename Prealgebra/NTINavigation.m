//
//  NTINavigation.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/02.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIApplicationViewController.h"
#import "NTINavigation.h"
#import "NTINavigationParser.h"
#import <QuartzCore/QuartzCore.h>
#import "WebAndToolController.h"
#import "NTITapCatchingGestureRecognizer.h"
#import "NTINavigationHistory.h"
#import "NTIScrubBarView.h"
#import "NTIWebView.h"

#pragma mark Private Classes
@interface NTIHistoryController : UITableViewController {
@private
	NTINavigationHistory* history;
	NSArray* data;
	WebAndToolController* controller;
}

-(id)initWithStyle: (UITableViewStyle)style
		   history: (NTINavigationHistory*)h
		controller: (WebAndToolController*)c;

-(void)fetchData: (NSString*)type;

@end

@class NTINavigationRowLabel;
@interface NTINavigationRowTableViewController : NSObject {
	@package
	NTINavigationRowTableViewController* right;
	NTINavigationRowLabel* showing;
	NTINavigationItem* item;
	WebAndToolController* controller;
}
@property(readonly,nonatomic) NTINavigationRowLabel* selectedCell;


- (id)initWithItem: (NTINavigationItem*)item
		controller: (WebAndToolController*)c;

- (void)rowController: (NTINavigationRowController*)c didSelectItem: (UIView*)showing;

@end

@interface NTINavigationRowController()
- (void)pushViewController: (NTINavigationRowTableViewController*) cont animated: (BOOL)a;
@end


static NSArray* findPathToID( NTINavigationItem* root, NSString* theId )
{
	return [root pathToID: theId];
}


#pragma mark Navigation 

static void removeAllGestureRecognizers( UIView* view ) 
{
	for( id r in view.gestureRecognizers ) {
		[view removeGestureRecognizer: r];	
	}
}

@interface NTINavigationTableViewController()
-(void)accViewTapped: (UITapGestureRecognizer*)t;
@end

@implementation NTINavigationTableViewController

- (id)initWithStyle: (UITableViewStyle)style 
			   item: (NTINavigationItem*)_item
		 controller: (WebAndToolController*)c
{
    self = [super initWithStyle:style];
    if( self ) {
        self->item = [_item retain];
		self->controller = c;
		[self setClearsSelectionOnViewWillAppear: NO];
		[[self navigationItem] setTitle: [item name]];
	}
    return self;
}

- (void)dealloc
{
	[item release];
    [super dealloc];
}

static UIGestureRecognizer* cellTapGestureRecognizer( id target )
{
	UIGestureRecognizer* result = nil;
	//Recall we must use a distinct gest rec for each view
	if( [target respondsToSelector: @selector(accViewTapped:)] ) {
		result = [[[NTITapCatchingGestureRecognizer alloc] 
				   initWithTarget: target
				   action: @selector(accViewTapped:)]
				autorelease];
	}
	return result;
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
	NSArray* pathToHref = findPathToID( item, self->controller.ntiPageId ); 
	if( pathToHref ) {// && [pathToHref containsObject: item] ) {
	   
		UITableView* tableView = [self tableView];
		NSInteger i = 0;
		for( id navItem in [item children] ) {
			if( [pathToHref containsObject: navItem] ) {
				//select
				[tableView selectRowAtIndexPath: [NSIndexPath indexPathForRow: i inSection: 0] 
									   animated: NO
								 scrollPosition: UITableViewScrollPositionTop];
				break;
			}
			i++;
		}
	}
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
{
	return [[item children] count];
}

-(NTINavigationItem*) navItemForPath: (NSIndexPath*)indexPath
{
	return [[item children] objectAtIndex: [indexPath row]];
}

/**
 * Subclasses override to specify a cell reuse id.
 */
-(NSString*)reuseId
{
	static NSString* CELL_ID = @"CellId";
	return CELL_ID;
}

/**
 * subclasses override to specify a view controller that 
 * responds to @selector(pushViewController:animated:).
 */
-(id)_navController
{
	return [self navigationController];	
}

+(void)configureTableViewCell: (UITableViewCell*)cell 
			forNavigationItem: (id)navItem
				 actionTarget: (id)actionTarget
{

	removeAllGestureRecognizers( cell.imageView );
	[[cell textLabel] setText: [navItem name]];

	if( [navItem count] > 0 ) {
		[cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
		[[cell accessoryView] setUserInteractionEnabled: YES];
	}
	else {
		[cell setAccessoryType: UITableViewCellAccessoryNone];
	}
	
	if( [navItem objectForKey: kNTINavigationPropertyIcon] ) {
		[[cell imageView] setImage: [navItem objectForKey: kNTINavigationPropertyIcon]];
		id gestRec = cellTapGestureRecognizer( actionTarget );
		if( gestRec ) {
			[[cell imageView] addGestureRecognizer: gestRec];
		}
		[[cell imageView] setUserInteractionEnabled: YES];
	}
	else {
		[[cell imageView] setImage: nil];
	}
}

- (UITableViewCell*)tableView: (UITableView*)tableView cellForRowAtIndexPath: (NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: [self reuseId]];
    if( cell == nil ) {
        cell = [[[UITableViewCell alloc]
				 initWithStyle: UITableViewCellStyleSubtitle
				 reuseIdentifier: [self reuseId]] autorelease];
    }
    
	id navItem = [self navItemForPath: indexPath];
    [[self class] configureTableViewCell: cell 
					   forNavigationItem: navItem
							actionTarget: self];
    return cell;
}

#pragma mark - Table view delegate

-(BOOL)shouldAnimateNavigation
{
	return YES;	
}

- (NTINavigationTableViewController*)createNavigationTo: (NSUInteger)row
{
	NTINavigationTableViewController* table = nil;
	if( [[[[item children] objectAtIndex: row] children] count] ) {
		table = [[[[self class] alloc] 
				  initWithStyle: self.tableView.style
				  item: [[item children] objectAtIndex: row]
				  controller: self->controller] autorelease];
	}
	return table;
}

- (id)navigateTo: (NSUInteger)row
{
	NTINavigationTableViewController* table = [self createNavigationTo: row];
	if( table ) {
		//NOTE: If we animate this, and do so several times in sequence,
		//we get console messages about bad animation states
		//and the right views don't show. You can't animate "nested" pushes.
		//Hence the navigateToItem: method does the pushes in bulk.
		[[self _navController] pushViewController: table animated: [self shouldAnimateNavigation]];
	}
	return table;
}

- (void)prepareToDisplayNavigationToPageID: (NSString*)page
{
	if( [self->item.ntiid isEqual: page] ) {
		return;
	}

	NSArray* pathToHref = findPathToID( self->item, page );
	if( pathToHref && [pathToHref count] > 1 ) {
		NTINavigationTableViewController* cont = self;
		NSMutableArray* mutablePath = [NSMutableArray arrayWithArray: pathToHref];
		[mutablePath removeObjectAtIndex: 0];
		
		NSMutableArray* controllers = [NSMutableArray arrayWithCapacity: [mutablePath count]];
		[controllers addObject: cont];
		
		while( [mutablePath count] && cont ) {
			NTINavigationItem* nextSegment = [mutablePath objectAtIndex: 0];
			NSInteger index = [[cont->item children] indexOfObject: nextSegment];
			cont = [cont createNavigationTo: index];
			if( cont ) {
				[controllers addObject: cont];
			}
			[mutablePath removeObjectAtIndex: 0];
			if( [nextSegment.ntiid isEqual: page] ) {
				break;
			}
		}
		//Note that we're doing this in bulk to avoid animation problems.
		//See navigateTo:
		[[self _navController] setViewControllers: controllers animated: NO];
	}
}

-(void)goToPageForItem: (NTINavigationItem*)navItem
{
	[self->controller navigateToItem: navItem];
	//FIXME: EWW
	[self->controller dismissPopover];
}

-(void)goToPageForPath: (NSIndexPath*)indexPath
{
	[self goToPageForItem: [self navItemForPath: indexPath]];
}

- (void)tableView: (UITableView*)tableView didSelectRowAtIndexPath: (NSIndexPath*)indexPath
{
	//When we touch a row that has children, display the children
	//Otherwise, go to the page.
	id navItem = [self navItemForPath: indexPath];
	if( [navItem count] ) {
		[self navigateTo: [indexPath row]];
	}
	else {
		[self goToPageForItem: navItem];
	}
}

-(void)accViewTapped: (UITapGestureRecognizer*)sender
{
	//When we hit an image, go to that page
	if( [sender state] == UIGestureRecognizerStateEnded ) {
		UIView* hit = [[self tableView] 
						hitTest: [sender locationInView: [self tableView]] 
						withEvent: nil];
		while( hit && ![hit isKindOfClass: [UITableViewCell class]] ) {
			hit = [hit superview];
		}
		[self goToPageForPath:
			[[self tableView] indexPathForCell: (UITableViewCell*)hit]];
	}
}

- (UITableViewCell*) selectedCell
{
	return [self.tableView cellForRowAtIndexPath: [self.tableView indexPathForSelectedRow]];
}

@end

@interface NTINavigationRowLabel : UILabel
@property (nonatomic,assign) BOOL drawArrow;
@end

@implementation NTINavigationRowLabel
@synthesize drawArrow;
-(void)drawRect: (CGRect)rect
{
	[super drawRect: rect];
	if( !self.drawArrow ) {
		return;
	}
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath( context );
	UIColor* color = [UIColor whiteColor];//[UIColor colorWithWhite: 1.0 alpha: 0.5];
	
	CGContextSetFillColorWithColor( context, [color CGColor] );
	CGContextSetStrokeColorWithColor( context, [color CGColor] );
	//CGContextSetLineJoin( context, kCGLineJoinRound );
	//CGContextSetLineCap( context,  kCGLineCapRound );
	//TODO: An arc at the end?
	/*
	CGContextMoveToPoint( context, self.bounds.size.width - 5, 10 );
	CGContextAddLineToPoint( context, self.bounds.size.width, self.bounds.size.height / 2);
	CGContextAddLineToPoint( context, self.bounds.size.width - 5, self.bounds.size.height - 10 );
	CGContextClosePath( context );
	*/
	CGContextMoveToPoint( context, self.bounds.size.width - 3, 7 );
	CGContextAddLineToPoint( context, self.bounds.size.width - 3,  self.bounds.size.height - 7 );
	CGContextClosePath( context );
	CGContextDrawPath( context, kCGPathFillStroke );
}

-(void)sizeToFit
{
	[super sizeToFit];
	CGRect bounds = self.bounds;
	bounds.size.width += 7;
	self.bounds = bounds;
}

@end

@implementation NTINavigationRowTableViewController

- (id)initWithItem: (NTINavigationItem*)_item
		controller: (WebAndToolController*)c
{
	self = [super init];
	self->item = [_item retain];
	self->controller = c;
	{
	NTINavigationRowLabel* label = [[NTINavigationRowLabel alloc] init];
	label.text = [item name];//[[item name] stringByAppendingString: @" >>"];
	label.font = [UIFont fontWithName: @"Open Sans" size: 12.0];
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor];
	label.textAlignment = UITextAlignmentLeft;
	label.userInteractionEnabled = YES;
	self->showing = label;
	}
	return self;
}

-(NTINavigationRowLabel*) selectedCell
{
	return showing;	
}

-(void)dealloc
{
	[self->item release];	
	[super dealloc];
}

- (void)rowController: (NTINavigationRowController*)c didSelectItem: (UIView*)selItem
{
	//We want to navigate through siblings
	//TODO: How to handle the root node?
	if( ![item parent] ) {
		[[self->controller ancestorViewControllerWithClass: [NTIApplicationViewController class]] goHome];
	}
	else {
		[self->controller showNavigationTo: [item parent]
													at: [selItem frame]
												inView: [selItem superview]
												sender: self];
	}
}

@end


@implementation NTIHistoryController

-(id)initWithStyle:(UITableViewStyle)style
		   history: (NTINavigationHistory*)_history
		controller: (WebAndToolController*)c
{
	self = [super initWithStyle: style];
	self->history = [_history retain];
	self->controller = c;
	return self;
}

-(void)fetchData: (NSString*)type
{
	if( data ) {
		[data release];
	}
	
	data = [[[[self->history valueForKey: type] reverseObjectEnumerator] allObjects] retain];
	self.title = type;
	[self.tableView reloadData];
}

-(NSInteger)tableView: (id)tv numberOfRowsInSection: (NSInteger)section
{
	return [data count];
}

- (UITableViewCell*)tableView: (UITableView*)tableView cellForRowAtIndexPath: (NSIndexPath*)indexPath
{
	static NSString* CELL = @"NTIHistoryCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: CELL];
    if( cell == nil ) {
        cell = [[[UITableViewCell alloc]
				 initWithStyle: UITableViewCellStyleDefault
				 reuseIdentifier: CELL] autorelease];
    }
    
	id navItem = [data objectAtIndex: indexPath.row];
	[[cell textLabel] setText: [navItem name]];
	[cell setAccessoryType: UITableViewCellAccessoryNone];
    
    return cell;
}

-(CGSize)contentSizeForViewInPopover
{
	return CGSizeMake( 320, 320 );
}

- (void)tableView: (UITableView*)tableView didSelectRowAtIndexPath: (NSIndexPath*)indexPath
{
	NTINavigationHistoryItem* object = [data objectAtIndex: indexPath.row];
	
	[self->controller navigateToItem: object.navigationItem];
	[self->controller dismissPopover];
}

-(void)dealloc
{
	[self->history release];
	[self->data release];
	[super dealloc];
}
@end

@interface NTINavigationRowController()
-(void)handleTap: (UITapGestureRecognizer*)t;
-(void)backButtonPressed: (id)sender;
-(void)backButtonTapped: (id)sender;
-(void)forwardButtonPressed: (id)sender;
-(void)forwardButtonTapped: (id)sender;
@end

@implementation NTINavigationRowController
@synthesize root;
@synthesize backButton;
@synthesize forwardButton;
@synthesize scrubBar;
@synthesize controller;

- (void)awakeFromNib
{
	UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(handleTap:)];
	[[self view] addGestureRecognizer: tap];
	[tap release];
	[backButton setEnabled: NO];
	id lp = [[UILongPressGestureRecognizer alloc] 
	 initWithTarget: self 
	 action: @selector(backButtonPressed:)];
	[backButton addGestureRecognizer: lp];
	[lp release];
	lp = [[UITapGestureRecognizer alloc] 
		  initWithTarget: self	
		  action: @selector(backButtonTapped:)];
	[backButton addGestureRecognizer: lp];
	[lp release];
	
	[forwardButton setEnabled: NO];
	lp = [[UILongPressGestureRecognizer alloc] 
			 initWithTarget: self 
			 action: @selector(forwardButtonPressed:)];
	[forwardButton addGestureRecognizer: lp];
	[lp release];
	lp = [[UITapGestureRecognizer alloc] 
		  initWithTarget: self	
		  action: @selector(forwardButtonTapped:)];
	[forwardButton addGestureRecognizer: lp];
	[lp release];

	
	NTINavigationHistory* wv = [self->controller history];
	[wv addObserver: self forKeyPath: @"backEmpty" 
			options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
			context: NULL];
	[wv addObserver: self forKeyPath: @"forwardEmpty" 
			options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
			context: NULL];
	
	[self->controller.webview addScrollDelegate: self];
	
	scrubBar.delegate = self;
}

-(void)observeValueForKeyPath: (NSString *)keyPath
					 ofObject: (id)object
					   change: (NSDictionary *)change
					  context: (void *)context
{
	if( [@"backEmpty" isEqual: keyPath] ) {
		[backButton setEnabled: ![[change objectForKey: NSKeyValueChangeNewKey] boolValue]];
	}
	else {
		[forwardButton setEnabled: ![[change objectForKey: NSKeyValueChangeNewKey] boolValue]];
	}
}

-(void)didRotateFromInterfaceOrientation: (UIInterfaceOrientation)_
{
	[scrubBar setNeedsRedisplay];
	[[self view] setNeedsDisplay];
}

-(void)handleTap: (UITapGestureRecognizer*)sender
{
	if( [sender state] == UIGestureRecognizerStateEnded ) {
		UIView* wants = [[self view] hitTest: [sender locationInView: [self view]] withEvent: nil];
		if( wants && wants != [self view] && self->leftmost ) {
			NTINavigationRowTableViewController* prev = self->leftmost;
			while( prev ) {
				if( wants == prev->showing || [wants isDescendantOfView: prev->showing] ) {
					break;
				}
				prev = prev->right;
			}
			if( prev ) {
				[prev rowController: self didSelectItem: prev->showing];
			}
		}
	}
}

-(NTIHistoryController*) historyController
{
	if( backForwardTVC == nil ) {
		backForwardTVC = [[NTIHistoryController alloc]
						  initWithStyle: UITableViewStylePlain 
						  history: [self->controller history]
						  controller: self.controller];
	}
	return backForwardTVC;
}

-(void)showHistory: (NSString*)type button: (UIButton*)button sender: (UIGestureRecognizer*)sender
{
	sender.enabled = NO;
	NTIHistoryController* c = [self historyController];
	[c fetchData: type];
	CGRect r = button.frame;
	[self->controller 
	 showPopoverFrom: button
	 at: &r
	 inView: self.view
	 controller: c];
	sender.enabled = YES;

}

-(void)backButtonPressed: (id)sender
{
	if( [sender state] == UIGestureRecognizerStateBegan ) {
		[self showHistory: @"backHistory" button: backButton sender: sender];
	}
}

-(void)backButtonTapped: (id)sender
{
	[self->controller goBack];	
}

-(void)forwardButtonPressed: (id)sender
{
	if( [sender state] == UIGestureRecognizerStateBegan ) {
		[self showHistory: @"forwardHistory" button: forwardButton sender: sender];
	}
}

-(void)forwardButtonTapped: (id)sender
{
	[self->controller goForward];	
}

-(void)scrollViewDidScroll: (id)_
{
	CGFloat percent = [self->controller.webview htmlScrollVerticalPercent];
	CGFloat maxPercent = [self->controller.webview htmlScrollVerticalMaxPercent];
	[self.scrubBar scrollSelectedToPercent: percent maxPercent: maxPercent];
}

-(void)navigationItemSelected: (NTINavigationItem*)navItem percent: (CGFloat)f
{
	self->percentThroughForNav = f;
	[self->controller navigateToItem: navItem];	
}

-(void)releaseAllSubviews
{
	for( UIView* v in [self.view subviews] ) {
		if( [v isKindOfClass: [UIButton class]] ) {
			continue;
		}
		[v removeFromSuperview];
	}
	NTINavigationRowTableViewController* path = self->leftmost;
	while( path ) {
		id next = path->right;
		[path release];
		path = next;
	}
	self->leftmost = nil;	
}

-(void)displayNavigationToPageID: (NSString*)page
{	
	//TODO: Optimize this to only remove things that aren't on the
	//path anymore
	[self releaseAllSubviews];
	[scrubBar displayItem: nil];
	
	NSArray* pathToHref = findPathToID( self->root, page );
	
	if( pathToHref ) {
		NTINavigationRowTableViewController* cont
			= [[[NTINavigationRowTableViewController alloc] 
				initWithItem: root
				controller: self.controller] autorelease];
		[self pushViewController: cont animated: NO];

		NSMutableArray* mutablePath = [NSMutableArray arrayWithArray: pathToHref];
		[mutablePath removeObjectAtIndex: 0];
		while( [mutablePath count] ) {
			NTINavigationItem* next = [mutablePath objectAtIndex: 0];
			cont = [[[NTINavigationRowTableViewController alloc] 
					 initWithItem: next
					 controller: self.controller] autorelease];
			[self pushViewController: cont animated: NO];
			[mutablePath removeObjectAtIndex: 0];
		}
		
		[scrubBar displayItem: [pathToHref lastObject]];
		if( self->percentThroughForNav > 0.0 ) {
			//TODO: Who should do this?
			//Notice that we cannot loop, calling for HTML offsets. We're in 
			//the main run loop, and those won't change until the next time through
			NTIWebView* web = [self->controller webview];
			[web scrollToPercent: self->percentThroughForNav];
			self->percentThroughForNav = 0.0;
		}
	}
	else {
		//This is bad. Force at least the library to be present.	
		NTINavigationRowTableViewController* cont
		= [[[NTINavigationRowTableViewController alloc] 
			initWithItem: root
			controller: self.controller] autorelease];
		[self pushViewController: cont animated: NO];
	}
}
#define HEADER_PAD 20
- (void)pushViewController: (NTINavigationRowTableViewController*)cont animated: (BOOL)a
{
	NTINavigationRowLabel* selected = cont.selectedCell;
	//[selected setSelected: NO];
	selected.autoresizingMask = UIViewAutoresizingNone; //UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	
	CGRect oldFrame = selected.frame;
	//[[selected textLabel] sizeToFit];
	//[[selected imageView] sizeToFit];
	[selected sizeToFit];
	//oldFrame.size.width = selected.textLabel.frame.size.width + selected.imageView.frame.size.width + HEADER_PAD;
	oldFrame.size.width = selected.frame.size.width;
	
	if( !self->leftmost ) {
		selected.frame = CGRectMake( 60, 0, oldFrame.size.width, self.view.frame.size.height );
		self->leftmost = [cont retain];
	}
	else {
		NTINavigationRowTableViewController* prev = self->leftmost;
		while( prev->right ) {
			prev.selectedCell.drawArrow = YES;
			prev = prev->right;
		}
		prev.selectedCell.drawArrow = YES;
		selected.frame = CGRectMake( 
									prev.selectedCell.frame.origin.x + prev.selectedCell.frame.size.width + 4, 0,
									oldFrame.size.width, self.view.frame.size.height );
		prev->right = [cont retain];
	}
	[[self view] addSubview: selected];
	[[self view] setNeedsLayout];
}

-(void)dealloc
{
	[forwardButton release];
	[backButton release];
	[self releaseAllSubviews];	
	[super dealloc];
}

@end
