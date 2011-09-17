//
//  NTIUserProfileInspectorSlice.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/03.
//  Copyright (c) 2011 NextThought. All rights reserved.
//
#import "NTIUtilities.h"
#import "NSArray-NTIExtensions.h"

#import "NTIUserProfileInspectorSlice.h"
#import "NTIUserProfileAliasInspectorSlice.h"
#import "NTIUserProfilePasswordInspectorSlice.h"
#import "NTIAppUser.h"
#import "NTIGravatars.h"



@implementation NTIUserProfileInspectorSlice
@synthesize realName, userName, lastLogin, gravatarBorder, gravatar;

#pragma mark - Inspector Slice Subclass

+(NSString*)nibName
{
	return @"NTIUserProfileInspectorSlice";
}

-(BOOL)isAppropriateForInspectedObject: (id)o
{
	return [o isKindOfClass: [NTIAppUser class]];
}

-(void)updateInterfaceFromInspectedObjects: (OUIInspectorUpdateReason)reason
{
	NTIAppUser* user = [self.containingPane inspectedObjects].firstObject;
	
	self.realName.text = user.realname;
	self.userName.text = user.Username;
	self.lastLogin.text = user.lastLoginDateShortStringNL;
	[[NTIGravatars gravatars] fetchIconForUser: user
										  then: ^(UIImage* img) {
											  if( img  ) {
												  self.gravatar.image = img;
												  [self.gravatar setNeedsDisplay];
											  }
										  }];
}

#pragma mark - Actions

-(void)userProfileInspectorSliceTouched: (id)s
{
	OUIStackedSlicesInspectorPane* pane = [[OUIStackedSlicesInspectorPane alloc] init];
	
	NTIUserProfileInspectorSlice* userSlice = [[NTIUserProfileInspectorSlice alloc] init];
	userSlice->elideNavigation = YES;
	
	NTIUserProfileAliasInspectorSlice* aliasSlice 
		= [[[NTIUserProfileAliasInspectorSlice alloc] initWithTitle: @"Alias"] autorelease];
															
															
	NTIUserProfilePasswordInspectorSlice* passwordSlice
		= [[[NTIUserProfilePasswordInspectorSlice alloc] initWithTitle: @"Password"] autorelease];
	pane.availableSlices = [NSArray arrayWithObjects: userSlice, aliasSlice, passwordSlice, nil];
	pane.title = @"Edit Profile";
	[self.inspector pushPane: pane];
}

-(void)aliasAction: (id)s
{
	NSLog( @"%@", s );
}

-(void)viewDidLoad
{
	OUIInspectorWell* well = (id)self.view;
	//Make the well touchable
	if( !self->elideNavigation ) {
		[well setNavigationTarget: nil action: @selector(userProfileInspectorSliceTouched:)];
	}
	//pretty up the well.
	[well setRounded: YES];
	//Add a nice shadow to our framed photo
	self->gravatarBorder.layer.shadowOpacity = 0.3;
	self->gravatarBorder.layer.shadowOffset = CGSizeMake( 3, 4 );
}

-(void)viewDidUnload
{
	NTI_RELEASE( self->realName );
	NTI_RELEASE( self->userName );
	NTI_RELEASE( self->lastLogin );
	NTI_RELEASE( self->gravatar );
	NTI_RELEASE( self->gravatarBorder );
	[super viewDidUnload];
}

-(void)dealloc 
{
	NTI_RELEASE( self->realName );
	NTI_RELEASE( self->userName );
	NTI_RELEASE( self->lastLogin );
	NTI_RELEASE( self->gravatar );
	NTI_RELEASE( self->gravatarBorder );
	[super dealloc];
}
@end


#pragma mark - Slices and wells




