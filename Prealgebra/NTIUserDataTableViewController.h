//
//  NTIUserDataTableViewController.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/06.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIDnDEnabledTableViewController.h"
#import "NTIUserDataLoader.h"
#import "NTIUserDataTableModel.h"
#import "NTIArraySubsetTableViewController.h"
#import "OmniFoundation/OmniFoundation.h"

@class WebAndToolController;

/**
 * A table controller for user data scoped within a container.
 * Auto-updates when the viewed container changes.
 */
@interface NTIUserDataTableViewController : NTIArraySubsetTableViewController<NTIUserDataTableModelDelegate>
{
	@private
	NTIUserDataTableModel* dataModel;
}

@property (readonly) NSArray* userData;

-(id)initWithStyle: (UITableViewStyle)style
		 dataModel: (NTIUserDataTableModel*) model;

-(id)detailViewControllerForObject: (id)object;
-(BOOL)hasDetailViewControllerForObject: (id)object;

-(void)refreshDataForCurrentPage;
-(NSString*)sortDescriptorKey;
@end

@interface NSObject(NTIUserDataTableViewExtension)
//Return nil if there is no controller
-(id)detailViewController: (id)sender;
//Return NO if not handled.
-(BOOL)didSelectObject: (id)sender;
@end
