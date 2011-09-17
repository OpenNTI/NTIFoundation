//
//  NTIDnDEnabledTableViewController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/17.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIDnDEnabledTableViewController.h"
#import "NTIUtilities.h"

#import "OmniBase/OmniBase.h"
#import "OmniUI/OUIOverlayView.h"

@implementation NTIDnDEnabledTableViewController

-(void)registerForDraggedTypes: (NSArray*)types
{
	NTI_RELEASE(self->draggedTypes);
	self->draggedTypes = [[NSArray alloc] initWithArray: types];
}

#pragma mark -
#pragma mark Drag Target

-(BOOL)wantsDragOperation: (id<NTIDraggingInfo>)info
				   toCell: (UITableViewCell*)cell
{
	for( id class in self->draggedTypes ) {
		if( [info.objectUnderDrag isKindOfClass: class] ) {
			return YES;
		}
	}
	return NO;
}

-(UITableViewCell*)cellForDrag: (id<NTIDraggingInfo>)info
{
	NSIndexPath* path = [self.tableView 
						 indexPathForRowAtPoint: [self.tableView convertPoint: info.draggingLocation
																	 fromView: self.tableView.window]];
	if( path ) {
		return [self.tableView cellForRowAtIndexPath: path];
	}
	return nil;
	
}

-(BOOL)wantsDragOperation: (id<NTIDraggingInfo>)info
{
	return [self wantsDragOperation: info
							 toCell: [self cellForDrag: info]];
}

-(BOOL)prepareForDragOperation: (id<NTIDraggingInfo>)info
{
	return [self wantsDragOperation: info];
}


-(BOOL)performDragOperation: (id<NTIDraggingInfo>)info
					 toCell: (UITableViewCell*)cell
{
	OBRequestConcreteImplementation( self, _cmd );
	return NO;
}

-(BOOL)performDragOperation: (id<NTIDraggingInfo>)info
{
	UITableViewCell* cell = [info.draggingDestination cellForDrag: info];
	BOOL result = NO;
	if( cell ) {
		result = [self performDragOperation: info toCell: cell];
	}
	[self draggingExited: info];
	return result;
}

-(NSString*)actionStringForDragOperation:(id<NTIDraggingInfo>)info
								  toCell: (UITableViewCell*)cell
{
	return nil;	
}

-(void)showOverlayForDragOperation: (id<NTIDraggingInfo>)info
							  cell: (UITableViewCell*)cell
{	
	NSString* action = [self actionStringForDragOperation: info
												   toCell: cell];
	
	NTIDraggingShowTooltipInView( info, action, self.tableView );	
}

-(void)draggingEntered: (id<NTIDraggingInfo>)info
{
	UITableViewCell* cell = [info.draggingDestination cellForDrag: info];
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	[cell setSelected: YES];
	self->nr_lastDragCell = cell;
	[self showOverlayForDragOperation: info
								 cell: cell];
}

-(void)draggingUpdated: (id<NTIDraggingInfo>)info
{
	UITableViewCell* cell = [info.draggingDestination cellForDrag: info];
	if( cell != self->nr_lastDragCell ) {
		self->nr_lastDragCell.selectionStyle = UITableViewCellSelectionStyleNone;
		self->nr_lastDragCell.selected = NO;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		[cell setSelected: YES];
		self->nr_lastDragCell = cell;
		[self showOverlayForDragOperation: info
									 cell: cell];
	}
}


-(void)draggingExited: (id<NTIDraggingInfo>)info
{
	UITableViewCell* cell = [info.draggingDestination cellForDrag: info];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	[cell setSelected: NO];
	self->nr_lastDragCell.selectionStyle = UITableViewCellSelectionStyleNone;
	self->nr_lastDragCell.selected = NO;
	self->nr_lastDragCell = nil;

	[[OUIOverlayView sharedTemporaryOverlay] hideAnimated: NO];
}

-(void)dealloc
{
	NTI_RELEASE( self->draggedTypes );
	[super dealloc];
}

@end
