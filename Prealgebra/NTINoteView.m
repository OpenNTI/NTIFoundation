//
//  NTINoteView.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/13.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTINoteView.h"
#import "NTINoteLoader.h"
#import <QuartzCore/QuartzCore.h>
#import "NTIRTFTextViewController.h"
#import "NTIRTFDocument.h"
#import "NTIUtilities.h"
#import <OmniUI/OUIEditableFrame.h>
#import "NTIEditableFrame.h"
#import <OmniUI/OUIInspector.h>
#import <OmniUI/OUIEditableFrameDelegate.h>
#import <OmniUI/OUILoupeOverlaySubject.h>
#import <OmniUI/OUITextLayout.h>
#import "NTIAppPreferences.h"
#import "TestAppDelegate.h"
#import "NTIApplicationViewController.h"
#import "WebAndToolController.h"
#import "NTIEditableNoteViewController.h"
#import "NSArray-NTIExtensions.h"
#import "NSDictionary-NTIJSON.h"
#import "NTINoteTableCell.h"
#import "NTIEditableNoteViewController.h"
#import "NTISharingUtilities.h"
#import "NTIGravatars.h"
#import "NTIUserCache.h"

@implementation NSObject(NTIActionRowExtension)

-(UITableViewCell*)actionCell: (id)sender
{
	return nil;
}

-(BOOL)shouldShowActionCell:(id)sender
{
	return NO;
}

@end

@interface NSObject(NTIMiniNoteActions)
-(BOOL)miniNote:(id)n shouldZoomAfterTouch:(id)t;
@end

@interface NTINoteView ()
@end

#define MINI_NOTE_ALPHA 0.55f
#define MINI_NOTE_WIDTH 44
#define MINI_NOTE_HEIGHT 44

static UILabel* labelTitleWithText( NSString* text )
{
	UILabel* editLabel = [[[UILabel alloc] init] autorelease];
	editLabel.textAlignment = UITextAlignmentCenter;
	editLabel.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
	editLabel.text = text;
	editLabel.textColor = [UIColor darkTextColor];
	editLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth
	| UIViewAutoresizingFlexibleLeftMargin
	| UIViewAutoresizingFlexibleRightMargin;
	editLabel.hidden = NO;
	editLabel.alpha = 1.0;
	editLabel.numberOfLines = 1;
	[editLabel sizeToFit];
	editLabel.backgroundColor = [UIColor clearColor];
	return editLabel;
}

static UIBarButtonItem* itemWithText( NSString* text )
{
	UILabel* label = labelTitleWithText( text );
	UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView: label];
	[item autorelease];
	item.possibleTitles = [NSSet setWithObject: text];
	item.enabled = YES;
	return item;
}

static UIBarButtonItem* infoButton( id target, SEL action )
{
	//If we have a button on top of the button item, then
	//the button item never gets touch events. So we just use the image.

	UIBarButtonItem* info = [[UIBarButtonItem alloc]
							 initWithImage: [[UIButton buttonWithType: UIButtonTypeInfoDark]
											 imageForState: UIControlStateNormal]
							 style: UIBarButtonItemStylePlain
							 target: target action: action];

	info.enabled = YES;

	return info;
}

static void setEditToolbar( id<NTINoteToolbarDelegate> self, UIToolbar* tb )
{

	NSArray* items = [NSArray arrayWithObjects:
					  [[[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
						target: self
						action: @selector(cancel:)] autorelease],
					  [[[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
						target: nil
						action: NULL] autorelease],
					  itemWithText( @"Edit Note" ),
					  [[[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
						target: nil
						action: NULL] autorelease],
					  infoButton( self, @selector(showInspector:) ),
					  [[[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemDone
						target: self
						action: @selector(done:)] autorelease],
					  nil];

	[tb setItems: items];
}

static void setNewToolbar( id<NTINoteToolbarDelegate> self, UIToolbar* tb )
{
	NSArray* items = [NSArray arrayWithObjects:
					  [[[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
						target: self
						action: @selector(cancel:)] autorelease],
					  [[[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
						target: nil
						action: NULL] autorelease],
					  itemWithText( @"Add Note" ),
					  [[[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
						target: nil
						action: NULL] autorelease],
					  infoButton( self, @selector(showInspector:) ),
					  [[[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemDone
						target: self
						action: @selector(done:)] autorelease],
					  nil];

	[tb setItems: items];
}

@interface NTINoteTableCellBackgroundView : UIView {
@private
    UITableViewCell* backgroundOf;
	NSArray* colors;
}
-(id)initWithFrame:(CGRect)frame andCell:(UITableViewCell*)cell;
@end

@implementation NTINoteTableCellBackgroundView

-(id)initWithFrame:(CGRect)frame andCell:(UITableViewCell*)cell
{
	self = [super initWithFrame: frame];
	self->backgroundOf = [cell retain];
	self.contentMode = UIViewContentModeLeft;
	//TODO static somewhere?
	colors = [[NSArray arrayWithObjects: [UIColor redColor], [UIColor blueColor], [UIColor greenColor], nil] retain];
	return self;
}

-(void)drawRect:(CGRect)rect
{
	[super drawRect: rect];

	CGContextRef context = UIGraphicsGetCurrentContext();


	//Fill in the background white
	CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
	CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);

	CGContextFillRect(context, rect);

	CGContextStrokePath(context);

	UITableViewCell* cell = self->backgroundOf;
	if(	cell.indentationLevel < 1 ){
		return;
	}
	
//	//Draw a one point line across the top starting from the indentation point.
//	CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
//	//Set the width of the pen mark
//	CGContextSetLineWidth(context, 1.0);
//	
//	CGContextMoveToPoint(context, cell.indentationLevel*cell.indentationWidth, 0);
//	CGContextAddLineToPoint(context, rect.size.width, 0);
//	CGContextStrokePath(context);
	
	
	//Draw thread lines
	CGFloat x = cell.indentationWidth / 2;
	CGFloat h = rect.size.height;


	for( NSInteger i = 0; i < cell.indentationLevel; i+=1 ){
		CGPoint top = CGPointMake( x, 0 );
		CGPoint bottom = CGPointMake( x, h );

		UIColor* color = [self->colors objectAtIndex: i % [self->colors count] ];

		CGContextSetStrokeColorWithColor(context, color.CGColor);
		//Set the width of the pen mark
		CGContextSetLineWidth(context, 2.0);

		// Draw a line
		//Start at this point
		CGContextMoveToPoint(context, top.x, top.y);
		CGContextAddLineToPoint(context, bottom.x, bottom.y);

		//Draw it
		CGContextStrokePath(context);

		//Move over the indentation width
		x += cell.indentationWidth;
	}

}

-(void)dealloc
{
	NTI_RELEASE(self->colors);
	NTI_RELEASE(self->backgroundOf);
	[super dealloc];
}

@end

@implementation NTIThreadedNoteContainer(NTIActionRowExtension)

-(BOOL)shouldShowActionCell:(id)sender
{
	return self.uan != nil;
}

-(NSArray*)actionBarButtonItemsForTree: (NTIThreadedNoteContainer*)tree target: (id)target
{
	id reply = [[[UIBarButtonItem alloc]
				 initWithBarButtonSystemItem: UIBarButtonSystemItemReply
				 target: target
				 action: @selector(reply:)] autorelease];
	id edit = [[[UIBarButtonItem alloc]
				//Edit is text, but Compose is an image like the other two.
				//Since we can change sharing and such, compose doesn't make
				//much sense, though.
				initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
				target: target
				action: @selector(edit:)] autorelease];
	
	id delete = [[[UIBarButtonItem alloc]
				  initWithBarButtonSystemItem: UIBarButtonSystemItemTrash
				  target: target
				  action: @selector(deleteNote:)] autorelease];
	id space = [[[UIBarButtonItem alloc]
				 initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease];
	
	NSMutableArray* actions = [NSMutableArray array];
	//Minory hackery to support things that are only
	//note-like
	if( ![tree.uan shared] ) {
		[actions addObject: delete];
	}
	[actions addObject: space];
	if( [tree.uan.note isKindOfClass: [NTINote class]] ) {
		[actions addObject: reply];
	}
	if( ![tree.uan shared] ) {
		if( [tree.uan.note isKindOfClass: [NTINote class]] ) {
			[actions addObject: edit];
		}
	}
	
	return actions;
}


-(UITableViewCell*)actionCell:(id)sender
{
	static NSString* REUSE = @"NTINoteActionCell";
	NTINoteActionTableCell* cell = nil;
	
	if( [sender respondsToSelector: @selector(tableview)] ){
		//Not a safe cast?
		cell = (NTINoteActionTableCell*)[[sender tableView] dequeueReusableCellWithIdentifier: REUSE];
	}
	
	if( !cell ) {
		cell = [[[NTINoteActionTableCell alloc]
				 initWithStyle: UITableViewCellStyleDefault
				 reuseIdentifier: REUSE] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	[cell setActionItems: [self actionBarButtonItemsForTree: self target: sender]];

	cell.toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	return cell;
}

@end

@implementation NTIThreadedNoteViewController
@synthesize ntiPageId;

-(void)resetTitle
{
	self.navigationItem.title = [self->threadedNote lastUpdatedContainer].uan.note.lastModifiedDateString;
}

-(id)initWithThreadedNote: (NTIThreadedNoteContainer*)noteTree onPage:(NSString*)pageId
			  inContainer: (id<NTIThreadedNoteViewControllerDelegate>) parent;
{
	self = [super initWithStyle: UITableViewStylePlain];
	self->threadedNote = [noteTree retain];
	self->ntiPageId = [pageId retain];
	self->nr_container = parent;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self resetTitle];
	self.navigationItem.leftBarButtonItem.title = @"Back";
	return self;
}

-(void)forcePopoverSize {
    CGSize currentSetSizeForPopover = self.contentSizeForViewInPopover;
    CGSize fakeMomentarySize = CGSizeMake(currentSetSizeForPopover.width - 1.0f, currentSetSizeForPopover.height - 1.0f);
    self.contentSizeForViewInPopover = fakeMomentarySize;
    self.contentSizeForViewInPopover = currentSetSizeForPopover;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear: animated];
	[self forcePopoverSize];
}

-(CGSize)sizeOfContent
{
	[self.tableView layoutIfNeeded];
	return self.tableView.contentSize;
}

-(CGSize)contentSizeForViewInPopover
{
	return CGSizeMake( 320, [self sizeOfContent].height + 45); //45 for action row. TODO do something smarter.
}

-(NSIndexPath*) indexPathOfSelectedObject
{
	return [NSIndexPath indexPathForRow: [self->threadedNote indexOfObject: self->selected] inSection: 0];
}

-(NSIndexPath*) adjustedIndexPath: (NSIndexPath*)path
{
	if( self->selected == nil ){
		return path;
	}

	if( [self indexPathOfSelectedObject].row < path.row ){
		return [NSIndexPath indexPathForRow: path.row - 1 inSection: path.section];
	}

	return path;

}


-(NSIndexPath*)actionPathForIndexPath: (NSIndexPath*)path
{
	return [NSIndexPath indexPathForRow: path.row + 1 inSection: path.section];

}

-(void)removeObject:(id)toRemove
{

}

-(void)updateObject:(id)toUpdate
{

}

-(void)removeObjectAtIndexPath: (NSIndexPath*)path
{
	//Get the adjusted index path
	NSIndexPath* adjustedPath = [self adjustedIndexPath: path];

	NTIThreadedNoteContainer* toRemove = [self->threadedNote objectAtIndex: adjustedPath.row];

	if( toRemove ){
		[self->threadedNote removeThreadedNote: toRemove];		
		[self resetTitle];
		[self.tableView beginUpdates];
		[self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: adjustedPath] withRowAnimation: NO];
		[self.tableView endUpdates];

		if( [toRemove isRoot] ){
			[self->nr_container removeObject: toRemove];
		}else{
			[self->nr_container updateObject: toRemove.root];
		}
	}
}

-(void)updateObject: (NTINote*)toUpdate atIndexPath: (NSIndexPath*)path
{
	NSIndexPath* adjustedPath = [self adjustedIndexPath: path];

	NTIThreadedNoteContainer* treeToUpdate = [self->threadedNote objectAtIndex: adjustedPath.row];

	if( treeToUpdate ){
		treeToUpdate.uan.note = toUpdate;
		[self resetTitle];
		[self.tableView beginUpdates];
		[self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: adjustedPath] withRowAnimation: NO];
		[self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: adjustedPath] withRowAnimation: NO];
		[self.tableView endUpdates];

		[self->nr_container updateObject: treeToUpdate.root];
	}
}

-(void)addObject: (NTINote*)note
{
	//This better be a reply to a note that exists
	NTIThreadedNoteContainer* thread =  [[[NTIThreadedNoteContainer alloc] initWithNote: note] autorelease];
	NTIThreadedNoteContainer* addedTo = [self->threadedNote addThreadedNote: thread];

	if( addedTo )
	{
		//FIXME expensive
		NSUInteger index = NSNotFound;
		for(NSInteger i=0; i < [self tableView: self.tableView numberOfRowsInSection: 0]; i+=1)
		{
			if( [self->threadedNote objectAtIndex: i] == thread ){
				index = i;
				break;
			}
		}

		if( index != NSNotFound )
		{
			[self resetTitle];
			[self.tableView beginUpdates];
			[self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow: index inSection: 0]] withRowAnimation: NO];
			[self.tableView endUpdates];
			[self->nr_container updateObject: [addedTo root]];
		}
	}


}

-(void)hideActionRow
{
	if(self->selected == nil){
		return;
	}

	NSIndexPath* actionRow = [self actionPathForIndexPath: [self indexPathOfSelectedObject]];

	[self->selected release];
	self->selected = nil;

	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: actionRow] withRowAnimation: NO];
	[self.tableView endUpdates];
}

-(NTIEditableNoteViewController*)editorToEditNote: (NTINoteViewControllerManager*)manager
										   inPage: (NSString*)page
										   atPath: (NSIndexPath*)path
									  inContainer: (id)container
{

	return  [NTIEditableNoteViewController controllerForNewNote: manager
														 inPage: page
														 atPath: path
													  container: container];
}

-(NTIEditableNoteViewController*)editorToReplyToNote: (NTINoteViewControllerManager*)manager
											  inPage: (NSString*)page
											  atPath: (NSIndexPath*)path
										 inContainer: (id)container
{
	return  [NTIEditableNoteViewController controllerForNewNote: manager
														 inPage: page
														 atPath: path
													  container: container];
}

//TODO these may belong in a delegate?
-(void)edit:(id)sender
{
	NTIThreadedNoteContainer* note = self->selected;

	id vc =
	[self editorToEditNote: note.uan.noteManager
					inPage: self.ntiPageId
					atPath: [self indexPathOfSelectedObject]
			   inContainer: self];

	[self.navigationController pushViewController: vc animated: YES];
	[vc becomeFirstResponder];

	[self hideActionRow];

}

-(void)deleteNote: (id)sender
{
	NTIThreadedNoteContainer* note = [[self->selected retain] autorelease];
	[[NTINoteSaverDelegate saverForNote: note.uan.note
								 inPage: self]
	 deleteNote: note.uan.note];
	//Have to grab the selection before we hide the action row.
	//NSIndexPath* wasSelected = [[self->selected retain] autorelease];
	[self hideActionRow];

	//We have to snag the root before we go mucking in the tree
	NTIThreadedNoteContainer* root = note.root;

	[note deleteNote];

	//It has pruned down to nothing
	if( ![NTIThreadedNoteContainer pruneContainer: root] ){
		[self.navigationController popViewControllerAnimated: YES];
		[self->nr_container removeObject: root];
	}else{
		//Right now if we delete a note with replys those get deleted from the thread model.
		//We don't have an "easy" way to determine which cells those were so we just be lazy and reload the table


		//		[self.tableView beginUpdates];
		//		[self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: wasSelected] withRowAnimation: UITableViewRowAnimationBottom];
		//		[self.tableView endUpdates];
		[self->nr_container updateObject: root];
	}
	[self resetTitle];
	[self.tableView reloadData];

}

-(void)reply:(id)sender
{
	NTIThreadedNoteContainer* note = self->selected;
	NTINoteViewControllerManager* newManager = [NTINoteViewControllerManager managerForNote: nil inReplyTo: note.uan.note];


	id vc =
	[self editorToReplyToNote: newManager
					   inPage: self.ntiPageId
					   atPath: [self indexPathOfSelectedObject]
				  inContainer: self];

	id nav = self.navigationController;
	[nav
	 pushViewController: vc
	 animated: YES];
	[vc becomeFirstResponder];
	[self hideActionRow];
}


-(NSInteger)tableView: (UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger base = self->threadedNote.count;
	if( self->selected ) {
		base += 1;
	}
	return base;
}

//TODO IOS5 makes this a whole heck of alot easier
-(NTINoteTableCell*)newTableCellFromNIB: (NSString*)nibName ofClass: (Class)class
{
	NSArray* topLevelObjects = [[NSBundle mainBundle] loadNibNamed: nibName owner:nil options:nil];

	for(id currentObject in topLevelObjects) {
		if( [currentObject isKindOfClass: class] ) {
			return currentObject;
		}
	}
	return nil;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath: (NSIndexPath*)indexPath
{
	//FIXME expensive?
	UITableViewCell* cell = [self tableView: tableView cellForRowAtIndexPath: indexPath];

	return cell.bounds.size.height;
}


-(UITableViewCell*)tableView:(UITableView*)tableView
 actionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NTIThreadedNoteContainer* tree = [self->threadedNote objectAtIndex: indexPath.row];
	return [tree actionCell: self];
}

-(UITableViewCell*)tableView: (UITableView*)tableView
		deletedCellForObject: (NTIThreadedNoteContainer*)container
{
	static NSString* REUSE = @"NTIDeletedCell";
	UITableViewCell* cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier: REUSE];
	if( !cell ) {
		cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier:REUSE] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.indentationWidth = cell.indentationWidth * 2;
		cell.indentationLevel = [container level];
		cell.backgroundView = [[[NTINoteTableCellBackgroundView alloc] initWithFrame: cell.bounds andCell: cell] autorelease];
	}

	cell.textLabel.text = @"<Deleted by Owner>";

	return cell;
}

-(UITableViewCell*)tableView: (UITableView*)tableView
	   cellForRowAtIndexPath: (NSIndexPath*)indexPath
{
	if( self->selected  && [self actionPathForIndexPath: [self indexPathOfSelectedObject]].row == indexPath.row) {
		return [self tableView: tableView actionCellForRowAtIndexPath: [self indexPathOfSelectedObject]];
	}

	//static NSString* REUSE = @"NTINoteCell";

	NTIThreadedNoteContainer* tree = [self->threadedNote objectAtIndex:
									  [self adjustedIndexPath: indexPath].row];

	if( !tree.uan ) {
		return [self tableView: tableView deletedCellForObject: tree];
	}

	//FIXME  There are issues with the editable frame when reusing these cells
	//NTINoteTableCell* cell = (NTINoteTableCell*)[tableView dequeueReusableCellWithIdentifier: REUSE];
	NTINoteTableCell* cell = nil;
	if( !cell ) {
		cell = [self newTableCellFromNIB: @"NTINoteTableCell" ofClass: [NTINoteTableCell class]];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.indentationWidth = cell.indentationWidth * 2;
		cell.backgroundView = [[[NTINoteTableCellBackgroundView alloc]
								initWithFrame: cell.bounds
								andCell: cell] autorelease];
	}

	NTIUserAndNote* userAndNote = tree.uan;

	cell.indentationLevel = tree.level;
	cell.creatorLabel.text = userAndNote.user;
	__block id textToLookFor = userAndNote.user;
	//Get the prefDisplayName in the callback
	NTIObjectProcBlock prefDisplayName = ^(id user)
	{
		if(		user
			&&	OFISEQUAL( textToLookFor,  cell.creatorLabel.text) ) {
			textToLookFor = [user prefDisplayName];
			cell.creatorLabel.text = textToLookFor;
		}
	};
	[[NTIUserCache cache] resolveUser: userAndNote.user
								 then: prefDisplayName];

	NTISharingType sharingType = NTISharingTypeForTargets( tree.uan.noteManager.sharingTargets.sharingTargets );
	UIImage* sharingImage = nil;
	if( sharingType == NTISharingTypeLimited ){
		sharingImage = [UIImage imageNamed: @"Shared.Friends.png"];
	}
	else if(sharingType == NTISharingTypePublic){
		sharingImage = [UIImage imageNamed: @"Shared.Everyone.png"];
	}
	cell.sharingImage.image = sharingImage;
	
	cell.lastModifiedLabel.text = userAndNote.note.lastModifiedDateString;

	[[NTIGravatars gravatars] fetchIconForUser: userAndNote.user
										  then: ^(UIImage* img) {
											  //This could finish in the future after
											  //we've moved on, so make sure not to overwrite
											  if( img && OFISEQUAL( textToLookFor, cell.creatorLabel.text ) ) {
												  cell.avatarImage.image = img;
												  [cell setNeedsDisplay];
											  }
										  }];

	NTIRTFTextViewController* textViewController
		= [[[NTIRTFTextViewController alloc]
			initWithDocument: (id)userAndNote.noteManager.document] autorelease];
	
	textViewController.view.userInteractionEnabled = NO;
	
	CGRect origEditorBounds = textViewController.editor.bounds;
	origEditorBounds.size.width = cell.textContainer.bounds.size.width;
	textViewController.editor.bounds = origEditorBounds;

	[textViewController textViewContentsChanged: textViewController.editor];
	
	textViewController.view.frame = CGRectMake(0, 0,
									   textViewController.editor.bounds.size.width,
									   textViewController.editor.bounds.size.height);


	//cell.textContainer.bounds = controller.view.bounds;

	CGFloat heightDifference = textViewController.view.frame.size.height - cell.textContainer.frame.size.height;
	if( heightDifference > 0 ) {
		//For very small notes, the height we provide will be enough,
		//so don't "shrink" them too much. Only adjust size if
		//they need more space.
		CGRect cellBounds = cell.bounds;
		cellBounds.size.height = cellBounds.size.height + heightDifference;
		cell.bounds = cellBounds;
	}

	[cell.textContainer addSubview: textViewController.view];
	 return cell;

}

-(NSIndexPath*)tableView: (UITableView*)tableView
willSelectRowAtIndexPath: (NSIndexPath*)indexPath
{
	//Don't allow selecting the action row
	if(self->selected != nil && indexPath.row == [self actionPathForIndexPath: [self indexPathOfSelectedObject]].row){
		return nil;
	}
	return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NTIThreadedNoteContainer* tree = [self->threadedNote objectAtIndex: [self adjustedIndexPath: indexPath].row];
	
	//FIXME When data is refreshed our model gets updated underneath us and we never here about it.  It would be a fair amount of work
	//to be notified of said changes.  Moreover without a lot of extra work all we could do anyway is reload the tableview.
	//So we don't blow up we just reload the table here.  
	//It's not ideal but at least this elimnates a crashing booby trap without a ton of work
	[tableView reloadData];
	
	if ( ![tree shouldShowActionCell: self]){
		return;
	}

	if( self->selected == nil ){
		NSIndexPath* toAdd = [self actionPathForIndexPath: indexPath];
		self->selected = [tree retain];
		[tableView beginUpdates];
		[tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: toAdd] withRowAnimation:
		 UITableViewRowAnimationFade];
		[tableView endUpdates];
	}
	else if(  [self indexPathOfSelectedObject].row == indexPath.row){
		NSIndexPath* toRemove = [self actionPathForIndexPath: [self indexPathOfSelectedObject]];
		[self->selected release];
		self->selected = nil;
		[tableView beginUpdates];
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: toRemove] withRowAnimation:UITableViewRowAnimationFade];
		[tableView endUpdates];
		[tableView deselectRowAtIndexPath: indexPath animated:YES];
	}
	else if(  [self indexPathOfSelectedObject].row != indexPath.row){
		NSIndexPath* toRemove = [self actionPathForIndexPath: [self indexPathOfSelectedObject]];
		NSIndexPath* toAdd = [self actionPathForIndexPath: [self adjustedIndexPath: indexPath]];
		[tree retain];
		[self->selected release];
		self->selected = nil;
		self->selected = tree;

		[tableView beginUpdates];
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: toRemove] withRowAnimation: UITableViewRowAnimationFade];
		[tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: toAdd] withRowAnimation: UITableViewRowAnimationFade];
		[tableView endUpdates];
	}
	//TODO A little strange.
	if( self->selected != nil ){
		[tableView scrollToRowAtIndexPath: [self actionPathForIndexPath: [self indexPathOfSelectedObject]] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	}
}



-(void)dealloc
{
	NTI_RELEASE(self->selected);
	NTI_RELEASE(self->ntiPageId);
	NTI_RELEASE(self->threadedNote);
	[super dealloc];
}

@end

@implementation NTIThreadedNoteInPageViewController

-(id)initWithThreadedNote: (NTIThreadedNoteContainer*)noteTree 
				   onPage: (NSString*)pageId
			  inContainer: (id<NTIThreadedNoteViewControllerDelegate>)parent
{
	self = [super initWithThreadedNote: noteTree onPage: pageId inContainer: parent];
	self.navigationItem.titleView = nil;
	return self;
}

-(NTIEditableNoteViewController*)editorToEditNote: (NTINoteViewControllerManager*)manager inPage: (NSString*)page
										   atPath: (NSIndexPath*)path inContainer: (id)container
{

	return  [NTIEditableNoteInPageViewController controllerForNewNote: manager
															   inPage: page
															   atPath: path
															container: container];
}

-(NTIEditableNoteViewController*)editorToReplyToNote: (NTINoteViewControllerManager*)manager inPage: (NSString*)page
											  atPath: (NSIndexPath*)path inContainer: (id)container
{
	return  [NTIEditableNoteInPageViewController controllerForNewNote: manager
															   inPage: page
															   atPath: path
															container: container];
}

@end


@implementation NTIUserAndNote
@synthesize noteManager, miniTapRecognizer;
+(NTIUserAndNote*) objectWithUser: (id)u andNote: (id)n
{
	NTIUserAndNote* r = [[[NTIUserAndNote alloc] init] autorelease];
	r->noteManager = [[NTINoteViewControllerManager managerForNote: n] retain];
	return r;
}

+(NTIUserAndNote*) objectWithNote: (NTINote*)n
{
	return [self objectWithUser: n.Creator
						andNote: n];
}

-(BOOL)shared
{
	return self.noteManager.shared;
}

-(NTINote*)note
{
	return self.noteManager.note;
}

-(NSString*)user
{
	return self.noteManager.owner;
}

#pragma mark -
#pragma mark NTIUserData emulation

//Anything we don't recognize, we forward to the note

-(id)forwardingTargetForSelector: (SEL)aSelector
{
	return self.note;
}

-(id)valueForUndefinedKey: (NSString*)key
{
	return [self.note valueForKey: key];
}

-(void)setNote: (NTINote*)newNote
{
	NTINoteViewControllerManager* copy = [self->noteManager copyWithNote: newNote];
	NTI_RELEASE( self->noteManager );
	self->noteManager = copy;
}

-(NSString*)domID
{
	if( self.note.OID ) {
		return self.note.OID;
	}
	else {
		return @"new";
	}
}

-(NSString*)stringForDOM
{
	NSString* text = self.note.text;
	text = [text stringByReplacingOccurrencesOfString: @"<html><body>"
										   withString: @""];
	text = [text stringByReplacingOccurrencesOfString: @"</body></html>"
										   withString: @""];
	//A bit of whitespace normalization.
	text = [text stringByReplacingOccurrencesOfString: @" >"
										   withString: @">"];

	return text;
}

-(NSDictionary*)asDictionary
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: 2];

	NSString* escapedText = [[self stringForDOM] stringByReplacingAllOccurrencesOfString: @"\"" withString: @"\\\""];

	[dict setObject: [self domID] forKey: @"id"];
	[dict setObject: escapedText forKey: @"text"];

	return dict;
}


-(void)dealloc
{
	self.miniTapRecognizer = nil;
	NTI_RELEASE( self->noteManager );
	[super dealloc];
}

@end


@implementation NTIThreadedNoteContainer
@synthesize level, count, parent, uan, children;
-(id)init
{
	self = [super init];
	self->children = [[NSMutableArray arrayWithCapacity: 2] retain];
	return self;
}

-(id)initWithNote: (NTINote*)n
{
	self = [super init];
	self->children = [[NSMutableArray arrayWithCapacity: 2] retain];
	self->uan = [[NTIUserAndNote objectWithNote: n] retain];
	return self;
}

+(BOOL)container: (NTIThreadedNoteContainer*)theParent hasChild: (NTIThreadedNoteContainer*)child
{
	if( [theParent isEqual: child] ){
		return YES;
	}

	for( NTIThreadedNoteContainer* kid in theParent->children ){
		if( [self container: kid hasChild: child] ){
			return YES;
		}
	}

	return NO;
}

+(BOOL)shouldLinkContainer: (NTIThreadedNoteContainer*)theChild asChildOf: (NTIThreadedNoteContainer*)theParent
{
	//Don't change existing links
	if( theChild->parent != nil){
		return NO;
	}

	//Can we get to parent from child or child from parent
	if( [NTIThreadedNoteContainer container: theParent hasChild: theChild] || [NTIThreadedNoteContainer container: theChild hasChild: theParent]){
		return NO;
	}

	return YES;
}

+(void)linkContainer: (NTIThreadedNoteContainer*)theChild asChildOf: (NTIThreadedNoteContainer*)theParent
{
	//Set the parent
	theChild->parent = [theParent retain];

	//Add it as a child.  //We sort these at the end of construction
	[theParent->children addObject: theChild];
}

+(void)removeChild: (NTIThreadedNoteContainer*)child fromParent: (NTIThreadedNoteContainer*)theParent
{
	if(child->parent == nil || child->parent != theParent){
		return;
	}

	//Remove us from the parents child list
	[theParent->children removeObject: child];

	[child->parent release];
	child->parent = nil;
}

//Returns the pruned container or nil
+(NTIThreadedNoteContainer*)pruneContainer: (NTIThreadedNoteContainer*)container
{
	//prune the children
	for( NTIThreadedNoteContainer* kid in [NSArray arrayWithArray: container->children] ){
		[NTIThreadedNoteContainer pruneContainer: kid];
	}

	//root containers with no children just need to be removed
	if( [container isRoot] && [container isEmptyContainer] && [container->children count] == 0 ){
		return nil;
	}

	//If we are empty and we have no children remove ourselves from the parent
	if( [container isEmptyContainer] && [container->children count] == 0 ){
		[NTIThreadedNoteContainer removeChild: container fromParent: container->parent];
	}



	return container;
}

+(void)sortContainer: (NTIThreadedNoteContainer*)container sortDescriptor: (NSSortDescriptor*)desc
{
	//Sort my children
	[container->children sortUsingDescriptors: [NSArray arrayWithObject: desc]];

	//Sort the children recursively
	for( NTIThreadedNoteContainer* kid in container->children )
	{
		[NTIThreadedNoteContainer sortContainer: kid sortDescriptor: desc];
	}
}

//See http://www.jwz.org/doc/threading.html
//We *know*(?) the format and contents of inreplyto and references so we can make some assumptions
+(NSArray*)threadNotes: (NSArray*)notesToThread
{
	NSMutableDictionary* id_table = [NSMutableDictionary dictionaryWithCapacity: 5];
	for( NTINote* noteToThread in notesToThread){
		NTIThreadedNoteContainer* containerForNote = [id_table objectForKey: noteToThread.OID];
		if( containerForNote != nil && [containerForNote isEmptyContainer] ){
			containerForNote->uan = [[NTIUserAndNote objectWithNote: noteToThread] retain];
		}
		else{
			containerForNote = [[[NTIThreadedNoteContainer alloc] init] autorelease];
			containerForNote->uan = [[NTIUserAndNote objectWithNote: noteToThread] retain];
			[id_table setObject: containerForNote forKey: noteToThread.OID];
		}

		for( NSString* reference in noteToThread.references )
		{
			NTIThreadedNoteContainer* containerForReference = [id_table objectForKey: reference];
			if( containerForReference == nil){
				containerForReference = [[[NTIThreadedNoteContainer alloc] init] autorelease];
				[id_table setObject: containerForReference forKey: reference];
			}
		}

		NSUInteger count = [noteToThread.references count];
		if( count > 1){
			for( NSUInteger i = 0 ; i < count - 1; i+=1 )
			{
				NTIThreadedNoteContainer* theParent = [id_table objectForKey: [noteToThread.references objectAtIndex: i]];
				NTIThreadedNoteContainer* child = [id_table objectForKey: [noteToThread.references objectAtIndex: i + 1]];

				if( [NTIThreadedNoteContainer shouldLinkContainer: child asChildOf: theParent] ){
					[NTIThreadedNoteContainer linkContainer: child asChildOf: theParent];
				}
			}
		}

		NTIThreadedNoteContainer* myParent = [id_table objectForKey: [noteToThread.references lastObject]];

		if( myParent ){

			//If we already have a parent clean us up before we relink us
			if(containerForNote->parent){
				[NTIThreadedNoteContainer removeChild: containerForNote fromParent: containerForNote->parent];
			}

			[NTIThreadedNoteContainer linkContainer: containerForNote asChildOf: myParent];
		}
	}

	NSMutableArray* notes = [NSMutableArray arrayWithCapacity: 5];
	for( NTIThreadedNoteContainer* container in [id_table allValues] ){
		if( [container isRoot] ){
			[notes addObject: container];
		}
	}

	//Prune the conversations Note we leave off step 4 b.  It seems useful to see where things were deleted and note reparent children
	for( NTIThreadedNoteContainer* note in [NSArray arrayWithArray: notes] ){
		id result = [NTIThreadedNoteContainer pruneContainer: note];
		if(result == nil){
			[notes removeObject: note];
		}
	}


	//Note we also leave off step 5 as we don't have subects

	//Sort by last Modifed
	NSSortDescriptor* sortDescriptor = [[[NSSortDescriptor alloc]
										 initWithKey: @"uan.note.lastModifiedDate" ascending: YES] autorelease];

	for( NTIThreadedNoteContainer* note in notes ){
		[NTIThreadedNoteContainer sortContainer: note sortDescriptor: sortDescriptor];
	}

	return notes;
}

+(NSPredicate*)searchPredicate
{
	return [NSPredicate predicateWithFormat: @"uan.note.text contains $VALUE"];
}

-(BOOL)doesNote: (NTINote*)theNote reference: (NSString*)OID
{
	for(NSString* reference in theNote.references){
		if( [reference isEqualToString: OID ]){
			return YES;
		}
	}

	return NO;
}

-(void)deleteNote
{
	self->uan=nil;
}

-(NTIThreadedNoteContainer*)addThreadedNote: (NTIThreadedNoteContainer*)tree
{
	//Look recursively untill we find were we belong.
	if( [tree.uan.note.inReplyTo isEqual: self->uan.note.OID] ){
		[self retain];
		[tree->parent release];
		tree->parent = self;
		[self->children insertObject: tree atIndex: 0];
		//FIXME need to resort children
		return self;
	}

	//Look for a child whose OID is in our references list
	for( NTIThreadedNoteContainer* childTree in self->children) {
		if( [self doesNote: tree.uan.note reference: childTree.uan.note.OID ] ){
			return [childTree addThreadedNote: tree];
		}
	}
	return nil;
}

-(NTIThreadedNoteContainer*)removeThreadedNote: (NTIThreadedNoteContainer*)tree
{
	//Look for a child whose OID is in our references list
	if ([self->children containsObject: tree]){
		[self->children removeObject: tree];
		return self;
	}
	for( NTIThreadedNoteContainer* childTree in self->children) {
		NTIThreadedNoteContainer* result = [childTree removeThreadedNote: tree];
		if(result != nil){
			return result;
		}
	}
	return nil;
}

-(NTIThreadedNoteContainer*)updateThreadedNote: (NTIThreadedNoteContainer*)theNote
{
	NTIThreadedNoteContainer* removedFrom = [self removeThreadedNote: theNote];
	if(removedFrom == nil){
		return nil;
	}
	return [removedFrom addThreadedNote: theNote];
}


-(NTIThreadedNoteContainer*)findWithID: (NSString*)OID
{
	if( ![self isEmptyContainer] && [self->uan.note.OID isEqualToString: OID] ){
		return self;
	}

	NTIThreadedNoteContainer* result=nil;
	for( NTIThreadedNoteContainer* kid in self->children ){
		result = [kid findWithID: OID];
		if( result ){
			break;
		}
	}

	return result;
}

-(NTIThreadedNoteContainer*)searchForIndex: (NSInteger*)index{
	if( *index < 0 ){
		@throw( NSRangeException );
	}

	if( *index == 0 ){
		return self;
	}

	NTIThreadedNoteContainer* result = nil;
	for( NTIThreadedNoteContainer* child in self->children ){
		*index = *index - 1;
		result = [child searchForIndex: index];
		if( result ){
			return result;
		}
	}

	//Should never get here
	return nil;
}

-(NTIThreadedNoteContainer*)searchForObject: (NTIThreadedNoteContainer*)container  andCount: (NSUInteger*)c
{
	if( self == container ){
		return container;
	}
	
	NTIThreadedNoteContainer* result = nil;
	for( NTIThreadedNoteContainer* kid in self->children ){
		*c = *c + 1;
		result = [kid searchForObject: container andCount: c];
		if( result ){
			return result;
		}
	}
	return nil;
}

-(NSUInteger)indexOfObject:(NTIThreadedNoteContainer *)container
{
	if( !container ){
		return NSNotFound;
	}
	
	NSUInteger c = 0;
	
	[self searchForObject: container andCount: &c];
	
	return c;
}

/**
 *   This function should never return nil.  It may through an exception
 **/
-(NTIThreadedNoteContainer*) objectAtIndex: (NSUInteger)i
{
	NSUInteger index = i;

	if( index > self.count ){
		@throw( NSRangeException );
	}

	return [self searchForIndex: (NSInteger*)&index];
}



-(BOOL)containsNote: (NTINote*)theNote
{
	return [self findWithID: theNote.OID] != nil;
}

-(BOOL)containsThread: (NTIThreadedNoteContainer*)thread
{
	return [NTIThreadedNoteContainer container: self hasChild: thread];
}

-(BOOL)isEmptyContainer
{
	return self->uan == nil;
}

-(BOOL)isRoot
{
	return self->parent == nil;
}

-(NSUInteger)count
{
	NSUInteger i = 1;

	for( NTIThreadedNoteContainer* tree in self->children ){
		i += [tree count];
	}
	return i;
}

-(NSUInteger)level
{
	if ( [self isRoot] ){
		return 0;
	}

	return 1 + [self->parent level];
}

-(NTIThreadedNoteContainer*)root
{
	if( [self isRoot] ){
		return self;
	}

	return [self->parent root];
}

-(NSArray*)children
{
	return [NSArray arrayWithArray: self->children];
}


-(NSString*)Creator
{
	//If we are empty we don't know who created us
	if( [self isEmptyContainer] ){
		return nil;
	}
	return self->uan.note.Creator;
}

-(NTIThreadedNoteContainer*)lastUpdatedContainer
{
	//If we have no children lastUpdated is me
	if( [self->children count] == 0 ){
		return self;
	}
	
	NTIThreadedNoteContainer* lastModifiedOfAllChildren=nil;
	
	for( NTIThreadedNoteContainer* child in self->children ){
		if( !child.uan ){
			continue;
		}
		
		NTIThreadedNoteContainer* childsLast = [child lastUpdatedContainer];
		
		if( !lastModifiedOfAllChildren || childsLast.uan.note.LastModified > lastModifiedOfAllChildren.uan.note.LastModified ){
			lastModifiedOfAllChildren = childsLast;
		}
	}
	
	OBASSERT_NOTNULL(lastModifiedOfAllChildren);
	
	if( !lastModifiedOfAllChildren ){
		lastModifiedOfAllChildren = self;
	}
	else if( lastModifiedOfAllChildren.uan && self.uan && 
			self.uan.note.LastModified > lastModifiedOfAllChildren.uan.note.LastModified){
		lastModifiedOfAllChildren = self;
	}
	
	return lastModifiedOfAllChildren;
}

-(id)Item
{
	return self.uan.note;
}

-(void)dealloc
{
	NTI_RELEASE(self->uan);
	NTI_RELEASE(self->parent);
	NTI_RELEASE(self->children);
	[super dealloc];
}

@end


@implementation NTIMiniNoteView
@synthesize backgroundImage;

-(void)setValue: (id)value forUndefinedKey: (NSString*)key
{
	if( OFISEQUAL( @"background", key ) || OFISEQUAL( @"dateLine", key ) ) {
		NSLog( @"Attempting to set undefined key; loading from NIB on iOS5? Delete and re-install." );
	}
	else {
		[super setValue: value forUndefinedKey: key];
	}
}

-(void)dealloc
{
	self.backgroundImage = nil;
	[super dealloc];
}
@end

@implementation NTINoteView
@synthesize prefFrame;
-(BOOL)becomeFirstResponder
{
	//view -> scroll -> editor
	return [[self.textView.subviews.firstObject  subviews].firstObject becomeFirstResponder];
}

-(CGSize)preferredSize
{
	return CGSizeMake( 200, 200 );
}

-(UIView*) textView
{
	return (id)[self viewWithTag: 2];
}

-(UILabel*) dateLine
{
	return (id)[self viewWithTag: 3];
}

-(void)tapped: (id)sender
{
	self->tap.enabled = NO;
	[[self textView] setUserInteractionEnabled: YES];

	[self becomeFirstResponder];
}

-(void)dealloc
{
	NTI_RELEASE( self->background );
	NTI_RELEASE( self->tap );
	[super dealloc];
}

@end

@interface NTIBasicNoteViewController ()
-(id)initWithDocument: (NTIRTFDocument*)doc
				 note: (NTINote*)note
			  modDate: (id)m
			   shared: (BOOL)shared
			  nibName: (NSString*)nibName;
-(NSString*)shortDate;
-(NSString*)longDate;
@end

@implementation NTIBasicNoteViewController

-(id)initWithDocument: (NTIRTFDocument*)doc
				 note: (NTINote*)theNote
			  modDate: (id)m
			   shared: (BOOL)isShared
			  nibName: (NSString*)nibName
{
	self = [super initWithNibName: nibName bundle: nil];
	self->note = [theNote retain];
	self->document = doc; //[doc retain];
	self->modDateOrNote = [m retain];
	self->shared = isShared;
	return self;
}

-(NSString*)shortDate
{
	NSString* result = nil;
	if( [self->modDateOrNote isKindOfClass: [NSDate class]] ) {
		NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat: @"yyyy-MM-dd"];

		result = [dateFormatter stringFromDate: modDateOrNote];
	}
	else {
		result = [modDateOrNote lastModifiedDateShortStringNL];
	}
	return result;
}

-(NSString*)longDate
{
	NSString* result;
	if( [self->modDateOrNote isKindOfClass: [NSDate class]] ) {
		result = [NSDateFormatter localizedStringFromDate: self->modDateOrNote
												dateStyle: NSDateFormatterMediumStyle
												timeStyle: NSDateFormatterShortStyle];
	}
	else {
		result = [modDateOrNote lastModifiedDateString];
	}

	return result;
}

-(BOOL)hasText
{
	return [self->document.text length] > 0;
}

-(void)dealloc
{
	NTI_RELEASE( self->note );
	NTI_RELEASE( self->modDateOrNote );
	[super dealloc];
}

@end

@implementation NTIMiniNoteViewController

-(id)initWithDocument: (NTIRTFDocument*)doc
				 note: (NTINote*)n
			  modDate: (id)m
			   shared: (BOOL)s
{
	self = [super initWithDocument: doc
							  note: n
						   modDate: m
							shared: s
						   nibName: @"MiniNote"];
	return self;
}

-(NSString*)summaryTextFromText: (NSString*)fullText
{
	NSUInteger len = (6 >= [fullText length] ? [fullText length] : 6);
	return [fullText substringToIndex: len];
}

-(void)viewDidLoad
{
	NTIMiniNoteView* miniView = (id)self.view;
	miniView.hidden = NO;
	miniView.alpha = MINI_NOTE_ALPHA;
	if( self->shared ) {
		[miniView.backgroundImage setImage: [UIImage imageNamed: @"Note-Blue.mini.png"]];
		miniView.backgroundImage.bounds = CGRectMake(0, 0, 26, 26);
		UIImageView* avatarImage = [[[UIImageView alloc] initWithFrame: CGRectMake( 5, 5, 18, 18)] autorelease];
		avatarImage.image = [UIImage imageNamed: @"Avatar-MysteryMan.jpg"];
		avatarImage.opaque = YES;
	
		[miniView addSubview: avatarImage];

		[[NTIGravatars gravatars] fetchIconForUser: self->note.Creator
											  then: ^(UIImage* img) {
												  //This could finish in the future after
												  //we've moved on, so make sure not to overwrite
												  if( img ) {
													  avatarImage.image = img;
												  }
											  }];
	}
	else{
		UILabel* text = [[[UILabel alloc] initWithFrame: miniView.backgroundImage.frame] autorelease];
		text.adjustsFontSizeToFitWidth = YES;
		text.textAlignment = UITextAlignmentCenter;
		[text setText: [self summaryTextFromText: self->document.text.string]];
		[miniView addSubview: text];
	}
}

-(NTIMiniNoteView*)miniNoteView
{
	return (id)self.view;
}

@end

@interface NTINoteViewController()<NTINoteToolbarDelegate>
-(id)initWithDocument: (NTIRTFDocument*)doc
				 note: (NTINote*)note
			  modDate: (id)m
			   shared: (BOOL)shared;
@end

@implementation NTINoteViewController
@synthesize noteToolBarView;

@synthesize delegate, editViewController, noteToolbar;

-(id)initWithDocument: (NTIRTFDocument*)doc
				 note: (NTINote*)n
			  modDate: (id)m
			   shared: (BOOL)s
{
	self = [super initWithDocument: doc
							  note: n
						   modDate: m
							shared: s
						   nibName: @"ContextNote"];
	return self;
}

-(BOOL)infoEnabled
{
	NSArray* items = noteToolbar.items;
	UIBarItem* item = [items objectAtIndex: items.count - 2];
	return item.enabled;
}

-(void)setInfoEnabled: (BOOL)enabled
{
	NSArray* items =noteToolbar.items;
	return [(UIBarItem*)[items objectAtIndex: items.count - 2] setEnabled: enabled];
}

-(UIBarButtonItem*) leftToolbarItem
{
	return noteToolbar.items.firstObject;
}

-(UIBarButtonItem*) rightToolbarItem
{
	return noteToolbar.items.lastObject;
}

-(UIBarButtonItem*)infoToolbarItem
{
	NSArray* ar = noteToolbar.items;
	return 	[ar objectAtIndex: ar.count - 2];
}

-(void)noteViewDidLoad: (NTINoteView*)noteView
{
	if( self->note ) {
		setEditToolbar( self,  self->noteToolbar );
		noteView.prefFrame = CGRectMake( self->note.left, self->note.top,
										noteView.frame.size.width,
										noteView.frame.size.height );
	}
	else {
		setNewToolbar( self, self->noteToolbar );
	}

	if( self->shared ) {
		[noteView->background setImage: [UIImage imageNamed: @"Note-Blue.png"]];
		//Leave this here, but disabled so that we don't get taps
		//and also don't try to re-install it.
		noteView->tap.enabled = NO;
		//FIXME: Handling of this is broken, can bring up the kb on shared notes.
		//Also some issues showing the toolbar
		[noteView.textView setUserInteractionEnabled: NO];
		noteView.backgroundColor = [UIColor blueColor];
		[self leftToolbarItem].enabled = NO;
	}

	noteView.dateLine.text = [self longDate];
	[self setInfoEnabled: ![NSString isEmptyString: self->document.text.string]];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(storageDidEdit:)
												 name: OATextStorageDidProcessEditingNotification
											   object: self->editViewController.editor.textStorage];
}

-(void)viewDidLoad
{
	self->editViewController = [[NTIRTFTextViewController alloc]
								initWithDocument: (id)self->document];
	NTINoteView* cnoteView = (id)self.view;
	[cnoteView addSubview: self->editViewController.view];
	[self->editViewController.view setTag: 2];
	self->editViewController.view.frame = CGRectMake( 0, 44, 300, 165 );

	[self noteViewDidLoad: cnoteView];
}

-(NTINoteView*)noteView
{
	return (id)self.view;
}

-(void)viewDidUnload
{
	[self setNoteToolBarView:nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	NTI_RELEASE( self->editViewController );
	NTI_RELEASE( self->dateLine );
	NTI_RELEASE( self->noteToolbar );
}

#pragma mark -
#pragma mark NTINoteToolbarDelegate
//FIXME: Even if the inspector makes changes, we may only save it if the text
//content has changed. Fix that.
#define FORWARD(s) do { if( [self.delegate respondsToSelector: @selector(s)] ) { \
[self.delegate s sender]; return; } \
} while(0)

-(void)showInspector: (id)sender;
{
	if( [self.delegate class] != [NTINoteViewControllerManager class] ) {
		FORWARD(showInspector:);
	}

	self->willShowInspector = YES;
	//All of the actions in the inspector are hooked up to first responder.
	//In order for the inspector to take first responder, the editor
	//must resign it (which hides the keyboard)--it doesn't happen automatically
	//in the cases that we're showing the inspector in an additional
	//window. We set a flag that we're doing this to allow others
	//to take action (like not hide the toolbar)

	if( !self->inspector ) {
		self->inspector = [[NTINoteInspector createNoteInspector] retain];
	}
	[self->inspector inspectNoteEditor: self->editViewController.editor
							andSharing: self->nr_manager.sharingTargets
					 fromBarButtonItem: sender];

	OUIEditableFrame* editor = self.editViewController.editor;
	if( [editor isFirstResponder] ) {
		[editor resignFirstResponder];
	}
	self->willShowInspector = NO;
}

-(void)done: (id)sender
{
	[self->inspector dismissAnimated: YES];
	//Update our model by asking the responders to finish.
	if( [self->editViewController.editor isFirstResponder] ) {
		[self->editViewController.editor resignFirstResponder];
	}

	FORWARD(done:);
}

-(void)cancel: (id)sender
{
	FORWARD(cancel:);
}
#undef FORWARD

-(void)storageDidEdit: (NSNotification*)not
{
	[self setInfoEnabled: [self->editViewController.editor hasText]];
}


-(void)dealloc
{
	NTI_RELEASE( self->inspector );
	NTI_RELEASE( self->editViewController );
	NTI_RELEASE( self->dateLine );
	NTI_RELEASE( self->noteToolbar );
	[noteToolBarView release];
	[super dealloc];
}

@end

#pragma mark -
#pragma mark NTIMovableNoteViewController

@implementation NTIMovableNoteViewController

-(id)initWithDocument: (NTIRTFDocument*)doc
				 note: (NTINote*)n
			  modDate: (id)m
			   shared: (BOOL)s
{
	self = [super initWithDocument: doc
							  note: n
						   modDate: m
							shared: s
						   nibName: @"NoteEdit"];
	return self;
}

-(void)viewDidLoad
{
	NTIMovableNoteView* noteView = (id)self.view;
	self->editViewController = [[NTIRTFTextViewController alloc]
								initWithDocument: (id)self->document];
	[noteView addSubview: self->editViewController.view];
	[self->editViewController.view setTag: 2];
	self->editViewController.view.frame = CGRectMake( 10, 103, 190, 139 );
	noteView.hidden = NO;
	noteView.alpha = 0.0;
	//noteView->nr_manager = self->nr_manager;

	noteView.autoresizesSubviews = NO;
	self.noteToolbar.frame = CGRectMake( 0, 0, 200, 30 );
	self->dateLine.frame = CGRectMake( 1, 30, 199, 20 );

	[self noteViewDidLoad: noteView];
	//All of our cleanup is handled in super.
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(keyboardWasShown:)
												 name: UIKeyboardDidShowNotification
											   object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(keyboardWillBeHidden:)
												 name: UIKeyboardWillHideNotification
											   object: nil];

}

-(NTIMovableNoteView*)movableNoteView
{
	return (id)self.view;
}

#pragma mark -
#pragma mark NTINoteToolbarDelegate
//FIXME: Even if the inspector makes changes, we may only save it if the text
//content has changed. Fix that.
#define FORWARD(s) do { if( [self.delegate respondsToSelector: @selector(s)] ) { \
[self.delegate s sender]; return; } \
} while(0)

//FIXME Saving an edited floating note is note working
-(void)done: (id)sender
{
	//Update our model by asking the responders to finish.
	if( [self->editViewController.editor isFirstResponder] ) {
		[self->editViewController.editor resignFirstResponder];
	}

	FORWARD(done:);

	//	[self->nr_manager hideFloatingNote];
}

//-(void)reply: (id)sender
//{
//	[self cancel: sender];
//
//	FORWARD(reply:);
//}

-(void)cancel: (id)sender
{
	FORWARD(cancel:);

	//	[self->nr_manager hideFloatingNoteAndTellDelegate: NO
	//											 animated: YES];
}
#undef FORWARD

-(id)hideToolbar
{
	CGRect frame = self.noteToolbar.frame;
	frame.origin.y += 30;
	[UIView animateWithDuration: 0.4
					 animations: ^{ self.noteToolbar.frame = frame; }
					 completion: ^(BOOL b){ self.noteToolbar.hidden = YES; }];

	[self.movableNoteView prepareForDragging];
	return self;
}

-(id)showToolbar
{
	self.noteToolbar.hidden = NO;
	CGRect frame = self.noteToolbar.frame;
	if( frame.origin.y ) {
		frame.origin.y = 0;
		[UIView animateWithDuration: 0.4 animations: ^{
			self.noteToolbar.frame = frame;
		}];
	}
	return self;
}

-(void)keyboardWasShown: (NSNotification*)not
{
	if( [self->editViewController.editor isFirstResponder] ) {
		[self showToolbar];
	}
}

-(void)keyboardWillBeHidden: (NSNotification*)not
{
	if(		[self->editViewController.editor isFirstResponder]
	   &&	!self->willShowInspector ) {
		[self hideToolbar];
	}
}


-(BOOL)isNewToolbar
{
	return [[self.noteToolbar.items objectAtIndex: 0] action] == @selector(cancel:);
}

-(void)beginEditing
{
	if( [self isNewToolbar] ) {
		if( [self hasText] ) {
			setEditToolbar( self, self.noteToolbar );
			[self hideToolbar];
		}
		else if( [self isNewToolbar] ) {
			[self.movableNoteView becomeFirstResponder];
			[self showToolbar];
		}
	}
	else {
		[self hideToolbar];
	}

	if( self->nr_manager.shared ) {
		self.movableNoteView->tap.enabled = NO;
	}
}

-(void)didScrollBy: (CGPoint)diff
{
	//No more movableNotes to scroll by.
	//	if( self.isViewLoaded ) {
	//		[self.movableNoteView moveBy: diff];
	//	}
}

/**
 * Call this to avoid loading the note if not already.
 */
-(void)removeMovableNoteViewFromSuperview
{
	if( [self isViewLoaded] ) {
		[self.movableNoteView removeFromSuperview];
	}
}

@end

@implementation NTINoteViewControllerManager
@synthesize sharingTargets, inReplyTo, references;

+(NTINoteViewControllerManager*)managerForNote: (NTINote*)note inReplyTo: (NTINote*) replyTo
{
	NTINoteViewControllerManager* result = [[[NTINoteViewControllerManager alloc] init] autorelease];
	if( note ) {
		result->note = [note retain];
		result->modDateOrNote = [note retain];
		result->document = [[NTIRTFDocument alloc] initWithString: note.text];
		result->sharingTargets = [[NTISharingTargetsInspectorModel alloc] initWithTargets: note.sharedWith readOnly: note.shared];
		result->references = [[NSArray arrayWithArray: note.references] retain];
		result->inReplyTo = [note.inReplyTo copy];
	}
	else {
		result->note = nil;
		result->modDateOrNote = [[NSDate date] retain];
		result->document = [[NTIRTFDocument alloc] initWithAttributedString:
							[[[NSAttributedString alloc] init] autorelease]];

		if( replyTo ){
			result->inReplyTo = [[replyTo OID] retain];
			result->references = [[[replyTo references] arrayByAddingObject: [replyTo OID]] retain];
		}
		result->sharingTargets = [[NTISharingTargetsInspectorModel alloc] initWithTargets: [NSArray array] readOnly: NO];

	}
	result->delegate = result;

	return result;
}

+(NTINoteViewControllerManager*)managerForNote: (NTINote*)note
{
	return [NTINoteViewControllerManager managerForNote: note inReplyTo: nil];
}


-(BOOL)hasText
{
	return [self->document.text length] > 0;
}

-(NSString*)externalString
{
	return [self->document externalString];
}

-(NSString*)plainText
{
	return self->document.text.string;
}

-(BOOL)shared
{
	return ![self.owner isEqual: [[NTIAppPreferences prefs] username]];
}

-(NTIRTFDocument*)document
{
	return [[self->document retain] autorelease];
}

-(void)setDelegate: (id<NTINoteToolbarDelegate>)incoming
{
	[incoming retain];
	if( self->delegate != self ) {
		NTI_RELEASE( self->delegate );
	}
	self->delegate = incoming;
}

-(id<NTINoteToolbarDelegate>)delegate
{
	return [[self->delegate retain] autorelease];
}

-(NTINoteViewControllerManager*)copyWithNote: (NTINote*)newNote
{
	NTINoteViewControllerManager* newMan = [[self class] managerForNote: newNote];
	if( self->delegate != self ) {
		newMan.delegate = self.delegate;
	}
	[newMan retain];
	return newMan;
}

@synthesize note;

-(NSString*)owner
{
	return self->note.Creator ? self->note.Creator : [[NTIAppPreferences prefs] username];
}

-(NTIMiniNoteViewController*)miniNoteViewController
{
	if( !self->miniNoteViewController ) {
		self->miniNoteViewController = [[NTIMiniNoteViewController alloc]
										initWithDocument: self->document
										note: self->note
										modDate: self->modDateOrNote
										shared: self.shared];
		[self controllerDidLoad: self->miniNoteViewController];
	}
	return self->miniNoteViewController;
}

-(NTIMovableNoteViewController*)floatingNoteViewController
{
	if( !self->floatingNoteViewController ) {
		self->floatingNoteViewController = [[NTIMovableNoteViewController alloc]
											initWithDocument: self->document
											note: self->note
											modDate: self->modDateOrNote
											shared: self.shared];
		self->floatingNoteViewController.delegate = self.delegate;
		self->floatingNoteViewController->nr_manager = self;
		[self controllerDidLoad: self->floatingNoteViewController];
	}
	return self->floatingNoteViewController;
}

-(NTINoteViewController*)noteViewController
{
	if( !self->noteViewController ) {
		self->noteViewController = [[NTINoteViewController alloc]
									initWithDocument: self->document
									note: self->note
									modDate: self->modDateOrNote
									shared: self.shared];
		self->noteViewController.delegate = self.delegate;
		self->noteViewController->nr_manager = self;
		[self controllerDidLoad: self->noteViewController];
	}
	return self->noteViewController;
}

-(void)controllerDidLoad: (NTIBasicNoteViewController*)controller
{

}

#pragma mark -
#pragma mark NTINoteToolbarDelegate

-(void)showInspector: (id)sender;
{

}

-(void)done: (id)sender
{

}

-(void)cancel: (id)sender
{

}

-(void)dealloc
{
	if( self->delegate != self ) {
		NTI_RELEASE( self->delegate );
	}
	//If we animate while deallocating, we crash because we go away
	//before the animation completes.
	NTI_RELEASE( self->sharingTargetsModel );
	NTI_RELEASE( self->miniNoteViewController );
	NTI_RELEASE( self->noteViewController );
	NTI_RELEASE( self->note );
	NTI_RELEASE( self->modDateOrNote );
	NTI_RELEASE( self->document );
	NTI_RELEASE( self->inReplyTo );
	NTI_RELEASE( self->references );
	[super dealloc];
}

@end


