//
//  NTIRemoteSearchControllers.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/14.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTIArraySubsetTableViewController.h"
#import "NTIUserDataLoader.h"

@interface NTIAbstractRemoteSearchController : NTIArraySubsetTableViewController<NTIUserDataLoaderDelegate>
{
@private
	NTIUserDataLoader* lastLoader;
	NTIAbstractRemoteSearchController* nr_next;
}

-(id)init;

//allows a one-way chain of these to be easily built up for searching
//across multiple domains. Does
//not take a reference.
//@return The parameter.
-(NTIAbstractRemoteSearchController*)setNext: (NTIAbstractRemoteSearchController*)next;

//Subclass responsibility
-(NTIUserDataLoader*)createDataLoaderForString: (NSString*)theSearchString;

@end

@class WebAndToolController;
@interface NTIAbstractContentSearchController: NTIAbstractRemoteSearchController<UISearchBarDelegate>

@property (nonatomic,retain) WebAndToolController* webController;

@end


//When used in a stacked view controller, starts off
//hidden and changes state to show itself when
//there are search results.
@interface NTISearchUsersController: NTIAbstractRemoteSearchController
@end

//When used in a stacked view controller, starts off
//hidden and changes state to show itself when
//there are search results.
@interface NTISearchUserDataController: NTIAbstractContentSearchController
@end


@interface NTISearchContentController: NTIAbstractContentSearchController
@end
