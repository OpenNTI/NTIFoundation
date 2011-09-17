//
//  NTIDnDEnabledTableViewController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/17.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTIDraggingUtilities.h"

/**
 * A base class for tables who wish to use their cells and 
 * drag sources/targets.
 */
@interface NTIDnDEnabledTableViewController : UITableViewController
{
	@private
	UITableViewCell* nr_lastDragCell;
	NSArray* draggedTypes;
}
/**
 * Call this with an array of classes you want to accept drops of.
 */
-(void)registerForDraggedTypes: (NSArray*)types;

/**
 * Implement this to actually pefrom the drag operation.
 */
-(BOOL)performDragOperation: (id<NTIDraggingInfo>)info
					 toCell: (UITableViewCell*)cell;

/**
 * Override this to include more conditions in wanting.
 */
-(BOOL)wantsDragOperation: (id<NTIDraggingInfo>)info
				   toCell: (UITableViewCell*)cell;

/**
 * Called during drag tracking. If this returns non-nil,
 * then a temporary overlay view will be displayed
 * showing the action string to the user.
 */
-(NSString*)actionStringForDragOperation:(id<NTIDraggingInfo>)info
								  toCell: (UITableViewCell*)cell;

@end
