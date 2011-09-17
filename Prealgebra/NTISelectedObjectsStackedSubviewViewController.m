//
//  NTISelectedObjectsStackedSubviewViewController.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/04.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTISelectedObjectsStackedSubviewViewController.h"

#import "NTISharingController.h"
#import "NTIUtilities.h"
#import "NTIAppPreferences.h"
#import "NTIUserDataLoader.h"
#import "NTIWebContextFriendController.h"
#import "NTIAppUser.h"
#import "NTIUserDataLoader.h"

#import "NSArray-NTIExtensions.h"

@implementation NTISelectedObjectsStackedSubviewViewController

@synthesize delegate;

+(NSString*)selectedObjectsTitle
{
	return @"Selected";
}

+(NSPredicate*)selectedObjectsPredicate
{
	return nil;
}

+(Class)searchControllerClass
{
	return [NTISearchUsersController class];
}

+(NSString*)searchControllerTitle
{
	return @"Users";
}

-(id)initWithSelectedObjects: (NSArray*)theSelectedObjects
		   prefixControllers: (NSArray*)prefixControllers
		  postfixControllers: (NSArray*)postfixControllers;

{
	NSMutableArray* theSharedWith = theSelectedObjects 
		? [theSelectedObjects mutableCopy]
		: [[NSMutableArray alloc] init];
	
	self->selectedObjectsPane 
		= [[NTIArraySubsetTableViewController alloc] 
		   initWithAllObjects: theSharedWith];
	self->selectedObjectsPane.navigationItem.title = [[self class] selectedObjectsTitle];
	
	self->selectedObjectsPane.predicate = [[self class] selectedObjectsPredicate];
	self->selectedObjectsPane.collapseWhenEmpty = YES;
	
	self->remoteSearchPane = [[[[self class] searchControllerClass] alloc] init];
	self->remoteSearchPane.navigationItem.title = [[self class] searchControllerTitle];
	
	NSMutableArray* controllers;
	if( ![NSArray isEmptyArray: prefixControllers] ) {
		controllers = [[prefixControllers mutableCopy] autorelease];	
	}
	else {
		controllers = [NSMutableArray array];
	}
	[controllers addObjects: self->remoteSearchPane, self->selectedObjectsPane, nil];
	[controllers addObjectsFromArray: postfixControllers];
	
	self = [super initWithControllers: controllers];
	
	self->selectedObjects = theSharedWith;
	
	self->selectedObjectsPane.delegate = self;
	self->remoteSearchPane.delegate = self;
	
	for( id o in controllers ) {
		//We do a class check instead of responds-to setDelegate:
		//because that message is so common.
		if( [o isKindOfClass: [NTIArraySubsetTableViewController class]] ) {
			[o setDelegate: self];
		}
	}
	
	return self;
}

#pragma mark -
#pragma mark Subset Delegate

-(void)subset: (id)_ configureCell: (UITableViewCell*)cell forObject: (id)object
{
	[NTIWebContextFriendController configureCell: cell forSharingTarget: object];
}

-(UITableViewCellAccessoryType)subset: (id)_ accessoryTypeForObject: (NTISharingTarget*)target
{
	UITableViewCellAccessoryType result = UITableViewCellAccessoryNone;
	if( [self->selectedObjects containsObjectIdenticalTo: target] ) {
		result = UITableViewCellAccessoryCheckmark;
	}
	return result;
}

-(void)subset: (id)me didSelectObject: (id)object
{
	//No matter where it was selected, we toggle the state of it
	if( [self->selectedObjects containsObjectIdenticalTo: object] ) {
		//It was shared, now it is not, so update the model
		[self->selectedObjects removeObjectIdenticalTo: object];
		//and take it out of the list
		[self->selectedObjectsPane removeObject: object];
		
		//And uncheck it everywhere.
		for( id o in self.allSubviewControllers ) {
			if( [o respondsToSelector: @selector(updateAccessoryTypeForObject:)] ) {
				[o updateAccessoryTypeForObject: object];
			}
		}
	}
	else {
		//It wasn't shared, now it is. So update the model
		[self->selectedObjects addObject: object];
		//add it to the list.
		[self->selectedObjectsPane prependObject: object];
		
		//and check it everywhere
		for( id o in self.allSubviewControllers ) {
			if( [o respondsToSelector: @selector(updateAccessoryTypeForObject:)] ) {
				[o updateAccessoryTypeForObject: object];
			}
		}
	}
	if( [self.delegate respondsToSelector: @selector(controller:selectedObjectsDidChange:)] ) {
		[self.delegate controller: self selectedObjectsDidChange: self.selectedObjects];
	}
}

-(NSArray*)selectedObjects
{
	return [[self->selectedObjects copy] autorelease];
}

-(void) dealloc
{
	NTI_RELEASE(self->selectedObjectsPane);
	NTI_RELEASE(self->remoteSearchPane);
	NTI_RELEASE(self->selectedObjects);
	[super dealloc];
}

@end

