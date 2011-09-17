//
//  NTIWebContextTableController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"
#import <UIKit/UIKit.h>
#import "NTITwoStateViewControllerProtocol.h"

//@class WebAndToolController;

@class NTIStackedSearchController;

/**
 * Manages a list of controllers in a stack (a table). Passes
 * certain DnD messages through. Manages zooming if we are in a split
 * view controller (or zoom is modal), otherwise only the mini view is presented.
 * Initially sets itself up as the SeachBarDelegate of the search controller 
 * given and will forward some search bar messages through to any controllers
 * that implement them.
 */
@interface NTIStackedSubviewViewController : UITableViewController
						<UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate> 
{
	@private
	NSMutableArray* allControllers; //Of entries. Including the inactive (hidden) ones.
	NSMutableArray* controllers; //Of entries.
	id currentMaximizedEntry;
	id nr_modalEntry;
}

@property (nonatomic,readonly) NTIStackedSearchController* searchController;
@property (nonatomic,readonly) NSArray* allSubviewControllers;

//Can pass nil to disable the search controller
-(id)initWithSearchController: (NTIStackedSearchController*)searchController
				  controllers: (NSArray*)other;
				  
//Creates one with the given controllers and a search controller
-(id)initWithControllers: (NSArray*)other;				  

/**
 * Called to force a refresh of which controllers
 * are "miniViewHidden."
 */
-(void)updateHiddenControllers;

/**
 * Called with a controller this object manages to toggle the
 * state of its expansion.
 */
-(void)windowShadeController: (id)controller;

@end

@interface NTIStackedSearchController : OFObject<NTITwoStateViewControllerProtocol> {
@private
	UISearchBar* searchBar;
	UIView* field;
}

//Access to the search bar we use. You can set its delegate.
@property (readonly,nonatomic) UISearchBar* searchBar;

//Lets you configure a search bar, including its delegate. We will
//control its size. If you don't specify a search bar one will
//be created.
-(id)initWithSearchBar: (UISearchBar*)searchBar;

@end
