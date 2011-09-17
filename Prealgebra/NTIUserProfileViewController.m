//
//  NTIUserProfileViewController.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/03.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIUtilities.h"

#import "NTIUserProfileViewController.h"
#import "NTIInspector.h"
#import "NTIUserProfileInspectorSlice.h"
#import "NTIUserProfileUserListInspectorSlice.h"
#import "NTIAppUser.h"
#import "NTIAppPreferences.h"
#import "NTIUserData.h"
#import "NTIUserDataLoader.h"
#import "NTISelectedObjectsStackedSubviewViewController.h"

@interface _NTIUserProfileViewAppUserMutater : NTIUserDataMutaterBase
@end

@implementation _NTIUserProfileViewAppUserMutater
+(NSString*)requestMethodForObject:(NTIUserData *)object
{
	return @"PUT";
}
+(NSData*)httpBodyForObject: (NTIUserData*)object
{
	return [object toPropertyListData];
}

@end

@interface _NTIUserCommunityDetailInspectorSlice : OUIDetailInspectorSlice
@end

@implementation _NTIUserCommunityDetailInspectorSlice

+(OUIInspectorTextWellStyle)textWellStyle
{
	return OUIInspectorTextWellStyleSeparateLabelAndText;
}

-(BOOL)isAppropriateForInspectedObject: (id)object
{
	return [object isKindOfClass: [NTIAppUser class]];
}
@end

@implementation NTIUserProfileViewController

-(id)initWithPresentingViewController: (id)s
{
	self = [super init];
	self->nr_presenting = s;
	self.modalPresentationStyle = UIModalPresentationFormSheet;
	self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	self.title = @"Account";
	return self;
}

-(void)inspectFromBarButtonItem: (id)s
{
	NTI_RELEASE( self->inspector );
	self->inspector = [NTINavigableInspector alloc];
	[self->inspector initWithMainPane: self
							   height: 620
			navgationController: self.navigationController];
	//Inspect a copy so Undo is easy, commit is explicit
	NTIAppUser* appUser = [[[NTIAppUser appUser] copyWithZone: nil] autorelease];
	[super setAvailableSlices: [NSArray arrayWithObjects: 
								[[[NTIUserProfileInspectorSlice alloc] init] autorelease],
								[[[NTIUserProfileUserListInspectorSlice alloc]
								  initWithTitle: @"Communities"
								  key: @"Communities"
								  editable: NO] autorelease],
								[[[NTIUserProfileUserListInspectorSlice alloc]
								  initWithTitle: @"Following"
								  key: @"following"] autorelease],
								[[[NTIUserProfileUserListInspectorSlice alloc]
								  initWithTitle: @"Accepting"
								  key: @"accepting"] autorelease],
								[[[NTIUserProfileUserListInspectorSlice alloc]
								  initWithTitle: @"Ignoring"
								  key: @"ignoring"] autorelease],
								nil														  
								]];
	[self->inspector inspectObjects: [NSArray arrayWithObject: appUser]
				  fromBarButtonItem: s];
}

#pragma mark - Actions
-(void)done: (id)s
{
	//The Done button is only on the top level, so the topVisiblepane
	//will be the pane we set up in inspectFromBarButtonItem:.
	NTIAppUser* currentUser = [NTIAppUser appUser];
	NTIAppUser* inspectedUser = [[self->inspector topVisiblePane] inspectedObjects].firstObject;
	NTI_RELEASE( self->inspector );
	
	NSArray* properties = [NSArray arrayWithObjects: @"alias", @"password", @"following", @"accepting", @"ignoring", nil];
	NSDictionary* currentDict = [currentUser dictionaryWithValuesForKeys: properties];
	NSDictionary* inspectedDict = [inspectedUser dictionaryWithValuesForKeys: properties];
	
	if( ![inspectedDict isEqualToDictionary: currentDict] ) {
		//We have changes to make.
		//We could be a little bit more efficient and send only the changes
		//that were actually made, but its much easier to
		//send the whole thing.
		NTIAppPreferences* prefs = [NTIAppPreferences prefs];
		[[_NTIUserProfileViewAppUserMutater updateObject: inspectedUser
										   onDataserver: prefs.dataserverURL
											   username: prefs.username
											   password: prefs.password complete: ^(id obj)
		{
			NSLog( @"Complete!");
			//Depending on whether or not the password changed,
			//the appuser may or may not need to update itself
			prefs.password = inspectedUser.password;
			//we always update it from what we sent
			NSArray* properties = [[obj toPropertyListObject] allKeys];
			[currentUser setValuesForKeysWithDictionary: [obj dictionaryWithValuesForKeys: properties]];
			[currentUser cache]; //Refresh the cache

		}] scheduleInCurrentRunLoop];
	}
	
	
	[self->nr_presenting dismissModalViewControllerAnimated: YES];
}

-(void)cancel: (id)s
{
	NTI_RELEASE( self->inspector );
	[self->nr_presenting dismissModalViewControllerAnimated: YES];
}

#pragma mark - View lifecycle

-(void)viewWillAppear: (BOOL)animated
{
	//TODO: Enable/disable the cancel button based on whether 
	//there have been changes.
	self.navigationItem.rightBarButtonItem 
		= [[[UIBarButtonItem alloc] 
			initWithBarButtonSystemItem: UIBarButtonSystemItemDone
			target: self
			action: @selector(done:)] autorelease];
	self.navigationItem.leftBarButtonItem 
	= [[[UIBarButtonItem alloc] 
		initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
		target: self
		action: @selector(cancel:)] autorelease];			
	self.navigationItem.title = @"Account";

	[super viewWillAppear: animated];	
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)dealloc
{
	NTI_RELEASE( self->inspector );
	[super dealloc];
}

@end
