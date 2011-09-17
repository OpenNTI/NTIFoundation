//
//  NTISelectedObjectsStackedSubviewViewController.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/04.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIStackedSubviewViewController.h"
#import "NTIRemoteSearchControllers.h"

@protocol NTISelectedObjectsStackedSubviewViewControllerDelegate<NSObject>
@optional
-(void)controller: (id)c selectedObjectsDidChange: (NSArray*)selected;
@end

//A specialized stacked subview controller that holds array subset controllers.
//One of these controllers is the set of selected objects. Any other controllers
//are source locations that can be checked/unchecked to select them. 
//Searching is supported, both within the present objects and with a new view
//that shows additional objects from another source based on the search.
@interface NTISelectedObjectsStackedSubviewViewController : NTIStackedSubviewViewController<UISearchBarDelegate>{
@private
	NTIArraySubsetTableViewController* selectedObjectsPane;
	NTIAbstractRemoteSearchController* remoteSearchPane;
	
	NSMutableArray* selectedObjects;
}

+(NSString*)selectedObjectsTitle;
+(NSPredicate*)selectedObjectsPredicate;
+(Class)searchControllerClass;
+(NSString*)searchControllerTitle;

/**
 * @param prefixControllers: If given, an array of NTIArraySubsetTableView
 * controllers to be displayed BEFORE the selected objects pane. Should
 * use the same domain objects. This object will be the delegate of each
 * item in here that accepts us.
 * @param postfixControllers: Like prefix, but after.
 */
-(id)initWithSelectedObjects: (NSArray*)selectedObjects
		   prefixControllers: (NSArray*)prefixControllers
		  postfixControllers: (NSArray*)postfixControllers;

/**
 * The currently selected set of objects.
 */
@property (nonatomic,readonly) NSArray* selectedObjects;

@property (nonatomic,assign) id<NTISelectedObjectsStackedSubviewViewControllerDelegate>delegate;

@end
