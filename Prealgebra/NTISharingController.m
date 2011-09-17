//
//  NTISharingController.m
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/9/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTISharingController.h"
#import "NTIUtilities.h"
#import "NTIAppPreferences.h"
#import "NTIUserDataLoader.h"
#import "NTIWebContextFriendController.h"
#import "NTIAppUser.h"
#import "NTIUserDataLoader.h"

#import "NSArray-NTIExtensions.h"

@implementation NTIThreePaneSharingTargetEditor

+(NSString*)selectedObjectsTitle
{
	return @"Selected";
}

+(NSPredicate*)selectedObjectsPredicate
{
	return [NTISharingTarget searchPredicate];
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
				 controllers: (NSArray*)headerControllers
{
	NTIArraySubsetTableViewController* friends 
		= [[NTIArraySubsetTableViewController alloc] 
		   initWithAllObjects: [NTIAppUser appUser].friendsLists];
	friends.navigationItem.title = @"Friends Lists";
	friends.predicate = [[self class] selectedObjectsPredicate];
	friends.collapseWhenEmpty = YES;


	self = [super initWithSelectedObjects: theSelectedObjects
						prefixControllers: headerControllers 
					   postfixControllers: [NSArray arrayWithObject: friends]];		
	return self;
}

#pragma mark -
#pragma mark Subset Delegate

-(void)subset: (id)_ configureCell: (UITableViewCell*)cell forObject: (id)object
{
	[NTIWebContextFriendController configureCell: cell forSharingTarget: object];
}


@end


@implementation NTISharingController
@synthesize delegate;

+(NSString*)selectedObjectsTitle
{
	return @"Shared With";
}

-(id)initWithSharableObject: (NTIShareableUserData*)sharableObject
{
	return self = [super initWithSelectedObjects: [sharableObject sharedWith]
									 controllers: nil];
}

-(id)initWithSharingTargets: (NSArray*)sharingTargets
{
	return self = [super initWithSelectedObjects: sharingTargets
									 controllers: nil];
}

-(void)subset: (id)me didSelectObject: (id)object
{
	[super subset: me didSelectObject: object];
	if( [delegate respondsToSelector:@selector(sharingTargetsChanged:)] ){
		[delegate sharingTargetsChanged: [self sharingTargets]];
	}
	
}

-(NSArray*)sharingTargets
{
	return [super selectedObjects];	
}

-(void)dealloc
{
	NTI_RELEASE(self->delegate);
	[super dealloc];
}

@end
