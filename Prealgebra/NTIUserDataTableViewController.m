//
//  NTIUserDataTableViewController.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/06.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIUserDataTableViewController.h"
#import "NTIUtilities.h"
#import "WebAndToolController.h"
#import "NTIAppPreferences.h"
#import "NTIDraggableTableViewCell.h"
#import "NTIRTFDocument.h"
#import "NTIEditableNoteViewController.h"
#import "NTINavigationParser.h"
#import "NTIUserDataTableModel.h"

@implementation NSObject(NTIUserDataTableViewExtension)
//Return nil if there is no controller
-(id)detailViewController: (id)sender { return nil; }
//Return NO if not handled.
-(BOOL)didSelectObject: (id)sender 
{
	BOOL result = NO;
	id detail = [self detailViewController: sender];
	if( detail && [sender respondsToSelector: @selector(navigationController)]) {
		[[sender navigationController] pushViewController: detail
												 animated: YES];
		result = YES;
	}
	
	return result;
}
@end

@implementation NTIUserDataTableViewController

-(id)initWithStyle: (UITableViewStyle)style
		 dataModel: (NTIUserDataTableModel*) model;
{
	self = [super initWithStyle: style];
	self->dataModel = [model retain];
	//For convenience we will be the datamodels delegate if it does not have one.
	if(!self->dataModel.delegate){
		self->dataModel.delegate = self;
	}
	return self;
}

-(void)refreshDataForCurrentPage
{
	[self->dataModel refreshDataForCurrentPage];
}

-(NSArray*)userData
{
	return [super allObjects];
}



-(void)dealloc
{
	NTI_RELEASE( self->dataModel );
	[super dealloc];
}

#pragma mark -
#pragma mark NTIArraySubsetTableViewController Subclass

-(UITableViewCellAccessoryType)subset: (id)me accessoryTypeForObject: (id)object
{
	UITableViewCellAccessoryType result = UITableViewCellAccessoryNone;
	if( [self hasDetailViewControllerForObject: object] ) {
		result = UITableViewCellAccessoryDisclosureIndicator;
	}
	return result;
}

//FIXME: Notice these two methods are assuming note-like things. 
//This needs to be fixed, but only when there's a general architecture in
//place and this doesn't break the activity stream view. This can
//be generalized.

-(void)subset: (id)me
configureCell: (UITableViewCell*)cell
	forObject: (NTIThreadedNoteContainer*)tree
{
	//TODO: We're breaking the delegate. We should call it if it wants
	//this method.
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
	NSString* imgName = [NSString stringWithFormat: @"%@-%@.mini.png",
						 type, color];
	
	cell.textLabel.textColor = lcolor;
	cell.imageView.image = [UIImage imageNamed: imgName];
	//Notice these cells cannot be used as drag sources.
	cell.imageView.userInteractionEnabled = NO;
}


-(id)detailViewControllerForObject: (id)object
{
	id result = nil;
	if( [object respondsToSelector: @selector(detailViewController:)] ) {
		result = [object detailViewController: self];
	}
	//Do we need to unwrap it?
	if( !result && [object respondsToSelector: @selector(Item)] ) {
		object = [object Item];
		if( [object respondsToSelector: @selector(detailViewController:)] ) {
			result = [object detailViewController: self];
		}
	}
//	
//	//TODO: Generalize this. A registery or categories...generalization in progress
//	//with categories
//	if( !result && [object isKindOfClass: [NTINote class]] ) {
//		NTIThreadedNoteContainer* cont = [[[NTIThreadedNoteContainer alloc] initWithNote: object] autorelease];
//		NTIThreadedNoteInPageViewController* vc = [[NTIThreadedNoteInPageViewController alloc]
//												   initWithThreadedNote: cont
//												   onPage: nil
//												   inContainer: nil];
//
//		result = [vc autorelease];
//	}
	return result;
}

-(void)subset: (id)me didSelectObject: (id)object
{
	//TODO: We're breaking the delegate. We should call it if it wants
	//this method.
	
	if(		[object respondsToSelector: @selector(didSelectObject:)]
	   &&	[object didSelectObject: self] ) {
	   return;
	}
	
	//Do we need to unwrap it?
	if( [object respondsToSelector: @selector(Item)] ) {
		object = [object Item];
		if(		[object respondsToSelector: @selector(didSelectObject:)]
		   &&	[object didSelectObject: self] ) {
			return;
		}
	}
	
	//The object itself didn't want to handle it. Nuts.
	
//	if( ![self hasDetailViewControllerForObject: object] ){
//		return;
//	}
//	
//	id detail = [self detailViewControllerForObject: object];
//	if( detail ) {
//		[self.navigationController pushViewController: detail
//											 animated: YES];
//	}
}

-(BOOL)hasDetailViewControllerForObject: (id)object
{
	return [self detailViewControllerForObject: object] != nil;
}

#pragma mark - 
#pragma mark Drag Target

-(BOOL)performDragOperation: (id<NTIDraggingInfo>)info
					 toCell: (UITableViewCell*)cell
{
	return YES;
}


#pragma mark -
#pragma mark Drag Source
-(id)dragOperation: (id<NTIDraggingInfo>)drag objectForDestination: (id)destination
{
	id result = nil;
	id from = drag.draggingSource;
	NSIndexPath* path = [self.tableView indexPathForCell: from];
	
	if( path ) {
		result = [self objectForIndexPath: path];
	}
	return result;
}

-(void)refreshDataAndTable
{	
	//This does not always refresh the table.  It only refreshes if the rows change, not what the rows would look like.
	//We forgo letting it reload the table and just do it ourself since we know something has changed.
	[self setAllObjectsAndFilter: self->dataModel.objects reloadTable: NO];
	[super sortUsingDescriptors: 
	 [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: [self sortDescriptorKey]
															 ascending: NO]]];
	[self.tableView reloadData];
}

//Do this more gracefully
-(void)model: (NTIUserDataTableModel*)model didAddObjects: (NSArray*)added
{
	[self refreshDataAndTable];
}

-(void)model: (NTIUserDataTableModel*)model didRemoveObjects: (NSArray*)removed
{
	[self refreshDataAndTable];
}

-(void)model: (NTIUserDataTableModel*)model didUpdateObjects: (NSArray*)updated
{
	[self refreshDataAndTable];
}

-(void)model: (NTIUserDataTableModel*)model didRefreshDataForPage: (NSString*)page
{
	[self refreshDataAndTable];
}

-(void)model: (NTIUserDataTableModel*)model didLoadDataForPage: (NSString*)page
{
	[self refreshDataAndTable];
}

-(NSString*)sortDescriptorKey
{
	return @"lastModifiedDate";	
}

@end

