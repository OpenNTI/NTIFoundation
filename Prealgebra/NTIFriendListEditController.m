//
//  NTIFriendListEditController.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIFriendListEditController.h"
#import "NTIUtilities.h"
#import "TestAppDelegate.h"
#import "NTIUserData.h"
#import "NTISharingController.h"
#import "NTIWebContextFriendController.h"
#import "NTIAppPreferences.h"
#import "NTIAppUser.h"

@interface NTIFriendEditListMetaController : UIViewController<UITextViewDelegate> {
	NSString* title;	
}

-(id)initWithTitle: (NSString*)title;
@end

@implementation NTIFriendEditListMetaController

-(id)initWithTitle: (NSString*)theTitle
{
	self = [super initWithNibName: @"NTIFriendEditListMetaController" bundle: nil];
	self->title = [theTitle copy];
	return self;
}

-(void)viewDidLoad
{
	self.view.bounds = CGRectMake( 0, 0, 320, 44 );
	//self.view.layer.masksToBounds = YES;
	//self.view.layer.cornerRadius = 9.0;
	
	UITextView* editable = self.view.subviews.lastObject;
	editable.textColor = [UIColor blueColor];
	editable.delegate = self;
	
	if( self->title ) {
		[editable setText: self->title];	
	}
	
	//TODO Want to display validity indicator (empty not valid)
	//need to have that hooked up to enabled state of done button.
}

-(void)textViewDidChange: (UITextView*)textView
{
	NTI_RELEASE( self->title );
	self->title = [textView.text copy];
}

-(NSString*)title
{
	//Returning this because it seems the text delegate
	//is not firing
	return [self.view.subviews.lastObject text];
}

-(CGFloat)miniViewHeight
{
	return 44;
}

-(BOOL)hidesSectionHeader
{
	return YES;	
}

-(void)dealloc
{
	NTI_RELEASE( self->title );
	[super dealloc];
}

@end

@implementation NTIFriendListEditController

+(NSString*)selectedObjectsTitle
{
	return @"Members";
}

-(id)initWithFriendsList: (NTIFriendsList*)list
{
	id theMC = [[NTIFriendEditListMetaController alloc] initWithTitle: list.prefDisplayName];
	self = [super initWithSelectedObjects: list.friends
							  controllers: [NSArray arrayWithObject: theMC]];
	
	self->friendsList = [list retain];
	self->metaController = theMC;
	self.navigationItem.title = @"Edit Friends List";
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
											  initWithBarButtonSystemItem: UIBarButtonSystemItemDone
											  target: self
											   action: @selector(done:)] autorelease];

		
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.view.bounds = CGRectMake( 0, 0, 310, 600 );	
}

-(void)viewWillAppear: (BOOL)animated
{
	[super viewWillAppear: animated];
	[self.view	becomeFirstResponder];
}

-(void)done: (id)_
{
	if( self->friendsList ) {
		//TODO: Make this add and remove specific objects so that play
		//better with the KVO done by the view
		self->friendsList.friends = self.selectedObjects;
		NTIFriendsList* captured = self->friendsList;
		NTIAppPreferences* prefs = [NTIAppPreferences prefs];
		[NTIFriendsListFriendUpdater updateFriendsOf: self->friendsList
										onDataserver: prefs.dataserverURL
											username: prefs.username
											password: prefs.password
											complete: ^(NTIFriendsList* updated)
		{
			if( updated ) {
				//Copy values into captured object.
				captured.friends = updated.friends;
				[captured setValue: [NSNumber numberWithInteger: updated.LastModified]
							forKey: @"Last Modified"];
				 
			}
		}];
	}
	else {
		//Creating a new one
		//TODO: Validation.
		//TODO: The username/realname thing is funky. We should do better.
		NTIFriendsList* newList = [[[NTIFriendsList alloc] init] autorelease];
		NSString* username = [self->metaController title];
		username = [username stringByReplacingAllOccurrencesOfString: @" " withString: @"."];
		username = [username stringByAppendingString: @"@nextthought.com"];
		
		[newList setValue: username forKey: @"Username"];
		newList.friends = self.selectedObjects;
		
		NTIAppPreferences* prefs = [NTIAppPreferences prefs];
		[NTIFriendsListSaver save: newList
					 onDataserver: prefs.dataserverURL
						 username: prefs.username
						 password: prefs.password
						 complete: ^(NTIFriendsList* updated)
		 {
			 if( updated ) {
				 [[NTIAppUser appUser] didCreateFriendsList: updated];
			 }
		 }];
		
	}
	
	//TODO: Tight coupling. Assuming we're in a popover.
	[[TestAppDelegate sharedDelegate]
	 dismissPopoverAnimated: YES];
}

-(BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

-(void)dealloc
{
	NTI_RELEASE( self->friendsList );
	NTI_RELEASE( self->metaController );
	[super dealloc];
}

@end
