//
//  NTIRemoteSearchControllers.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/14.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIRemoteSearchControllers.h"

#import "NTIUtilities.h"
#import "NTIAppPreferences.h"
#import "NTIUserDataLoader.h"
#import "NTIWebContextFriendController.h"
#import "NTIAppUser.h"
#import "NTIUserDataLoader.h"
#import "NTIRTFDocument.h"
#import "NSArray-NTIExtensions.h"

//Content search
#import "WebAndToolController.h"
#import "NTINavigation.h"
#import "NTINavigationParser.h"


@implementation NTIAbstractRemoteSearchController

-(id)init
{
	self = [super initWithAllObjects: [NSArray array]];
	self.collapseWhenEmpty = YES;
	return self;
}

-(NTIAbstractRemoteSearchController*)setNext: (NTIAbstractRemoteSearchController*)next
{
	self->nr_next = next;
	return next;
}

-(void)subset: (id)me performSearchWithString: (NSString*)theSearchString
{
	self->lastLoader = [self createDataLoaderForString: theSearchString];
	if( self->lastLoader == nil ) {
		NSLog(@"An error occured trying to make the search request");
	}
	[self->nr_next subset: me performSearchWithString: theSearchString];
}

-(NTIUserDataLoader*)createDataLoaderForString: (NSString*)theSearchString
{
	OBRequestConcreteImplementation( self,  _cmd );
	return nil;
}

-(void)dataLoader: (NTIUserDataLoader*)loader didFinishWithResult: (NSArray*)result
{
	if( loader == lastLoader ) {
		[self setFilteredSubset: result andReloadTable: YES];
	}
	else {
		//NSLog(@"Ignoring out of order search response");
	}
}

-(void)dataLoader: (NTIUserDataLoader*)loader didFailWithError: (NSError*)error
{
	NSLog(@"Data load failed with error %@", error);
}

-(void)dealloc
{
	[super dealloc];
}

@end

@implementation NTISearchUsersController

-(void)subset: (id)_ configureCell: (UITableViewCell*)cell forObject: (id)object
{
	[NTIWebContextFriendController configureCell: cell forSharingTarget: object];
}

-(NTIUserDataLoader*)createDataLoaderForString: (NSString*)theSearchString
{
	//NSLog(@"Initiating user search");
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];
	
	NTIUserSearchDataLoader* loader = [NTIUserSearchDataLoader 
									   dataLoaderForDataserver: prefs.dataserverURL 
									   username: prefs.username
									   password: prefs.password 
									   searchString: theSearchString
									   delegate: self];
	
	
	return loader;
}

-(void)subset: (id)me performSearchWithString: (NSString*)theSearchString
{
	if( [NSString isEmptyString: theSearchString] ){
		[self setFilteredSubset: self->sourceArray andReloadTable: YES];
	}
	else{
		[super subset: me performSearchWithString: theSearchString];
	}
}

-(void)dealloc
{
	[super dealloc];
}

@end

static void configureCellForObject( UITableViewCell* cell, id object )
{
	if( [object respondsToSelector: @selector(Title)] ) {
		//Got a NTIChange
		if( ![NSString isEmptyString: [object Title]] ) {
			cell.textLabel.text = [object Title];
			cell.detailTextLabel.text = [object Snippet];
		}
		else {
			cell.textLabel.text = [object Snippet];
			cell.detailTextLabel.text = [object lastModifiedDateShortStringNL];
		}
		
		NSString* color = @"Yellow";
		UIColor* lcolor = [UIColor darkTextColor];
		if( [object shared] ) {
			color = @"Blue";
			lcolor = [UIColor blueColor];
		}
		NSString* type = [object Type];
		NSString* imgName = [NSString stringWithFormat: @"%@-%@.mini.png",
							 type, color];
		
		cell.textLabel.textColor = lcolor;
		cell.imageView.image = [UIImage imageNamed: imgName];
	}
	
}

@implementation NTIAbstractContentSearchController
@synthesize webController;


-(void)subset: (id)_ configureCell: (UITableViewCell*)cell forObject: (id)object
{
	configureCellForObject( cell, object );	
}

-(void)tableView: (UITableView*)tableView didSelectRowAtIndexPath: (NSIndexPath*)indexPath
{
	id hit = [self objectForIndexPath: indexPath];
	id navItem = [self.webController.navHeaderController.root pathToID: [hit ContainerId]];
	[self.webController navigateToItem: [navItem lastObjectOrNil]];
}

-(void)dealloc
{
	self.webController = nil;
	[super dealloc];
}

@end

@implementation NTISearchUserDataController
-(NTIUserDataLoader*)createDataLoaderForString: (NSString*)theSearchString
{
	//NSLog(@"Initiating user search");
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];
	
	id loader = [NTIUserDataSearchDataLoader 
				 dataLoaderForDataserver: prefs.dataserverURL 
				 username: prefs.username
				 password: prefs.password 
				 searchString: theSearchString
				 delegate: self];
	
	
	return loader;
}

@end


@implementation NTISearchContentController
-(NTIUserDataLoader*)createDataLoaderForString: (NSString*)theSearchString
{
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];
	//TODO: Get the root URL by using the navigation items.
	NSURL* url = [prefs URLRelativeToRoot: @"/prealgebra/"];
	return [NTIContentSearchDataLoader dataLoaderForContent: url
												   username: prefs.username
												   password: prefs.password
											   searchString: theSearchString
												   delegate: self];
}
@end
