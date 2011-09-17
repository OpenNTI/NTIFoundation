//
//  NTIArraySubsetTableViewController.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/10.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniBase/OmniBase.h"
#import "NTIDnDEnabledTableViewController.h"

//We are a search bar delegate so that we can filter ourselves based on searches.
@interface NTIArraySubsetTableViewController : NTIDnDEnabledTableViewController<UISearchBarDelegate> {
@protected
	NSMutableArray* sourceArray;
	NSMutableArray* filteredSubset;
	
	NSString* searchString;
	
	BOOL inDelegate; //For re-entrant delegate methods.
}
//We offer these two properties to support being used in a
//StackedSubviewViewController.
@property (nonatomic,assign) BOOL miniViewHidden, miniViewCollapsed;
//This property determines whether we collapse automatically
//when a search results in 0 results
@property (nonatomic,assign) BOOL collapseWhenEmpty;

@property (nonatomic,readonly) NSArray* allObjects;
@property (nonatomic,readonly) NSArray* displayedObjects;

@property (nonatomic,retain) id delegate;
//Must contain a $VALUE variable
@property (nonatomic,retain) NSPredicate* predicate;

-(id)initWithAllObjects: (NSArray*)objects;

-(id)initWithStyle: (UITableViewStyle)style
		allObjects: (NSArray*)theSourceArray;


//For convenience, allows toggling the accessory view
//between none and a checkmark.
-(void)markObject: (id)target withCheckmark: (BOOL)yesOrNo;

//Adds the given object to the set maintained by 
//this object. If it passes the current filter, it is added
//to the table as well. Returns whether the object was 
//added to the table. Updates the UI.
-(BOOL)prependObject: (id)object;

//Removes the given object from the set maintained by this
//object, including the visible set. Returns whether the
//object was visible. Updates the UI.
-(BOOL)removeObject: (id)object;

//Queries again for the accessory type for the object and updates
//the corresponding cell if there is one. Returns whether we
//updated.
-(BOOL)updateAccessoryTypeForObject: (id)object;

//Search bar delegate
-(void)searchBar: (UISearchBar*)searchBar textDidChange: (NSString*)searchText;

//For subclasses or the delegate.  NOTE: Unless otherwise
//documented by this or a subclass, it is not safe for a delegate
//to call one of these methods on the instance passed to it.

//defaults to none
-(UITableViewCellAccessoryType)subset: (id)me
			   accessoryTypeForObject: (id)object;

//defaults to Subtitle
-(UITableViewCellStyle)subset: (id)me
			   styleForObject: (id)object;

-(void)subset: (id)me
configureCell: (UITableViewCell*)cell
	forObject: (id)object;

//Our default implementation will update the 
//accessory view 
-(void)subset: (id)me
didSelectObject: (id)object;

-(BOOL)setFilteredSubset: (NSArray*)newData andReloadTable: (BOOL)reload;
-(void)setAllObjectsAndFilter: (NSArray*)newSourceArray reloadTable: (BOOL)reload;
-(void)addToAllObjects: (NSArray*)incomingData;
-(void)clearAllObjects;

//The string may be null or empty to go back to
//all objects.
-(void)subset: (id)me filterWithString: (NSString*)string;
-(BOOL)doesObject: (id)target matchString: (NSString*)string;

//Called froum our implementation of subset:filterWithString:
-(void)subset: (id)me performSearchWithString: (NSString*)theSearchString;

-(void)sortUsingDescriptors: (NSArray*)array;

//Lets the delegate or subclass filter the entire source array. 
//Useful to apply additional criteria. This method is re-entrant.
-(NSArray*)subset: (id)me filterSource: (NSArray*)array;

//All paths refer to the displayed subset


-(id)objectForIndexPath: (NSIndexPath*)path;
-(NSIndexPath*)indexPathForObject: (id)object;
//Removes the object from the model AND updates the UI
-(void)removeObjectAtIndexPath: (NSIndexPath*)path;

//Updates the object in the model AND updates the UI
-(void)updateObject: (id)object atIndexPath: (NSIndexPath*)path;
@end

@interface NSObject(NTIArraySubsetTableViewControllerDelegate)
//defaults to none
-(UITableViewCellAccessoryType)subset: (id)me
			   accessoryTypeForObject: (id)object;

//defaults to Subtitle
-(UITableViewCellStyle)subset: (id)me
			   styleForObject: (id)object;

-(void)subset: (id)me
configureCell: (UITableViewCell*)cell
	forObject: (id)object;

//Our default implementation will update the 
//accessory view 
-(void)subset: (id)me
didSelectObject: (id)object;
//Lets the delegate or subclass filter the entire source array. 
//Useful to apply additional criteria. This method is re-entrant.
-(NSArray*)subset: (id)me filterSource: (NSArray*)array;
@end

