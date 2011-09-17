//
//  NTIWebContextFriendController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/15.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIWebContextFriendController.h"

#import "NTINavigationParser.h"
#import "NTINoteLoader.h"
#import "NTINoteView.h"
#import "NTIAppPreferences.h"
#import "NTINoteSavingDelegates.h"
#import "UINavigationController-NTIExtensions.h"
#import "NTIGravatars.h"
#import "NTIDraggableTableViewCell.h"
#import "OmniUI/OUIDragGestureRecognizer.h"
#import "OmniUI/OUIAppController.h"
#import "TestAppDelegate.h"
#import "NTIUtilities.h"
#import "NTIDraggingUtilities.h"
#import "NTIAppUser.h"
#import "NTIUserCache.h"

#import "NTIUrlScheme.h"
#import "NTISharingUtilities.h"
#import "NTINoteLoader.h"

#import "NTIFriendsListsViewController.h"


@implementation NTIWebContextFriendController
@synthesize presentsModalInsteadOfZooming, miniViewTitle, miniCreationAction, supportsZooming;
@dynamic view;
-(id)initWithStyle: (UITableViewStyle)style
{
	self = [super initWithStyle: style];
	self->miniViewTitle = @"Friends Lists";
	self->presentsModalInsteadOfZooming = NO;
	self->supportsZooming = YES;
	
	[super registerForDraggedTypes: 
	 [NSArray arrayWithObjects:
	  [NTIShareableUserData class],
	  [NSURL class],
	  nil]];
	self.predicate = [NTISharingTarget searchPredicate];
	self.collapseWhenEmpty = YES;
		
	[[NTIAppUser appUser] addObserver: self
						   forKeyPath: @"friendsLists"
							  options: NSKeyValueObservingOptionInitial
							  context: nil];
	return self;
}

-(void)observeValueForKeyPath: (NSString*)keyPath
					 ofObject: (id)object
					   change: (NSDictionary*)change
					  context: (void*)context
{
	[super setAllObjectsAndFilter: [NTIAppUser appUser].friendsLists 
					  reloadTable: self.isViewLoaded];
}

#pragma mark -
#pragma mark UITableViewController delegate


-(void)subset: (id)me 
configureCell: (UITableViewCell*)cell
	forObject: (id)friendList
{
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	[self.class configureCell: cell
			 forSharingTarget: friendList];
}

+(UITableViewCell*)configureCell: (UITableViewCell*)cell
				forSharingTarget: (NTISharingTarget*)target
{
	cell.imageView.image = [UIImage imageNamed: @"Avatar-MysteryMan.jpg"];
	cell.textLabel.text = target.prefDisplayName;
	
	static char* assoc_str="ObjectForCell";
	
	objc_setAssociatedObject(cell, assoc_str, target, OBJC_ASSOCIATION_ASSIGN);
	
#define isObjectAssoc() objc_getAssociatedObject(cell, assoc_str) == target

	
	if( (id)target == target.prefDisplayName ) {
		//We're dealing with strings. Need to pass this through the user resolution process
		[[NTIUserCache cache] resolveUser: target
									 then: ^(id user)
		 {
			 if( user && isObjectAssoc() ) {
			 	cell.textLabel.text = [user prefDisplayName];
			 }
		 }];
	}
	
	if( [target respondsToSelector: @selector(friends)] && cell.detailTextLabel ) {
		NSString* subtitle = [[target valueForKeyPath: @"friends.@unionOfObjects.prefDisplayName"]
							  componentsJoinedByComma];
		cell.detailTextLabel.text = subtitle;
	}
	
	[[NTIGravatars gravatars] fetchIconForUser: target
										  then: ^(UIImage* img) {
											  //This could finish in the future after
											  //we've moved on, so make sure not to overwrite
											  if( img && isObjectAssoc() ) {
												  cell.imageView.image = img;
												  cell.imageView.userInteractionEnabled = YES;
												  [cell setNeedsDisplay];
											  }
										  }];
#undef isObjectAssoc
	return cell;
}

#pragma mark -
#pragma mark NTIWebContextViewController


-(UIView*)miniView
{
	return nil;
}

-(UIViewController*)maximizedViewController
{
	if( !self->maxView ) {
		id f = [[[NTIFriendsListsViewController alloc] initWithNibName: nil bundle: nil] autorelease];
		UINavigationController* navCont = [[UINavigationController alloc] initWithRootViewController: f];
		navCont.navigationBarHidden = NO;
		self->maxView = navCont;
	}
	return self->maxView;
}

-(void)dealloc
{
	NTI_RELEASE( self->maxView );

	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[super dealloc];
}

-(id)shareableObjectForTableCell: (UITableViewCell*)cell
{
	id result = nil;
	NSIndexPath* indexPath = [self.tableView indexPathForCell: cell];
	if( indexPath ) {
		result = [self objectForIndexPath: indexPath];
	}
	return result;
}

-(id)objectForTableCell: (UITableViewCell*)cell
{
	id shared = [self shareableObjectForTableCell: cell];
	if( shared ) {
		return shared;
	}
	
	NSString* email = cell.textLabel.text;
	if( ![email containsString: @"@"] ) {
		email = [email stringByAppendingString: @"@nextthought.com"];
	}
	return email;
}

#pragma mark -
#pragma mark Drag Target

-(NSString*)actionStringForDragOperation:(id<NTIDraggingInfo>)info
								  toCell: (UITableViewCell*)cell
{
	return NTIShaerableUserDataActionStringForDrop( 
		[self shareableObjectForTableCell: cell],
		info );
}			  

-(BOOL)wantsDragOperation: (id<NTIDraggingInfo>)info
				   toCell: (UITableViewCell*)cell
{
	return NTIShareableUserDataObjectWantsDrop(
		[self objectForTableCell: cell],
		info );
}

-(BOOL)performDragOperation: (id<NTIDraggingInfo>)info
					 toCell: (UITableViewCell*)cell
{
	return NTIShareableUserDataObjectPerformDrop( 
		[self objectForTableCell: cell],  
		info );
}

@end
