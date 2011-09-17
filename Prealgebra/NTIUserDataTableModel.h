//
//  NTIUserDataTableModel.h
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/31/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIUtilities.h"
#import <OmniFoundation/OmniFoundation.h>


@class WebAndToolController;
@class NTIUserDataTableModel;
@protocol NTIUserDataTableModelDelegate <NSObject>
-(void)model: (NTIUserDataTableModel*)model didAddObjects: (NSArray*)added;
-(void)model: (NTIUserDataTableModel*)model didRemoveObjects: (NSArray*)removed;
-(void)model: (NTIUserDataTableModel*)model didUpdateObjects: (NSArray*)updated;
-(void)model: (NTIUserDataTableModel*)model didRefreshDataForPage: (NSString*)page;
-(void)model: (NTIUserDataTableModel*)model didLoadDataForPage: (NSString*)page;
@end

/** Provides a model for user data that can be used by user data tables **/
//Data is populated automatically vie the WebAndToolControllerWillLoadPageID
//notification or via the add, remove, update methods.
@interface NTIUserDataTableModel : OFObject {
@private
	BOOL refreshing;
	NSDate* dataLoaderLastModified;
	id<NTIUserDataTableModelDelegate> delegate;
@protected
	NSMutableArray* objects;
}
-(id)initWithWebController: (WebAndToolController*)web;
@property (nonatomic, retain) id<NTIUserDataTableModelDelegate> delegate;
@property (nonatomic,readonly) NSArray* objects;
@property (nonatomic,readonly) NSString* containerId; //pageid
-(void)clearCurrentData;
-(void)loadAllDataForCurrentPage;
-(void)refreshDataForCurrentPage;
//-(BOOL)addObject: (id)object; //prepends an object to the model
-(BOOL)removeObject: (id)object;
-(BOOL)updateObjectAtIndex: (NSUInteger)index withObject: (id)object;

@end

@interface NTIThreadedNoteTableModel: NTIUserDataTableModel
@end

@interface NTIActivityTableModel: NTIUserDataTableModel
@end
