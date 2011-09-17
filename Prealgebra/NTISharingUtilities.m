//
//  NTISharingUtilities.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/10.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTISharingUtilities.h"
#import "NTIUserData.h"
#import "NTIUserDataLoader.h"
#import "NTIAppPreferences.h"
#import "NTIAppUser.h"

//DnD
#import "NTIDraggingUtilities.h"
#import "NTIUrlScheme.h"
#import "NTINoteLoader.h"

NSString* NSStringFromNTISharingType( NTISharingType type ){
	switch (type) {
		case NTISharingTypePublic :
			return @"Public";
		case NTISharingTypeLimited :
			return @"Limited";
		case NTISharingTypePrivate :
			return @"Private";
		default:
			return @"Unknown";
	}
}

NTISharingType NTISharingTypeForTargets( NSArray* targets ){
	//FIXME Public username hardcode in two places.
	if( NTISharingTargetsContainsTarget(targets, @"Everyone") ){
		return NTISharingTypePublic;
	}

	return [targets count] > 0 ? NTISharingTypeLimited : NTISharingTypePrivate;	

}

BOOL NTIShareableUserDataCanUpdateSharing( id object )
{
	BOOL result = NO;
	if( [object isKindOfClass: [NTIShareableUserData class]] ) {
		//If it's a shared object that we own, we can update the sharing
		NTIShareableUserData* shared = object;
		result = [shared.Creator isEqual: [NTIAppUser appUser].Username];
	}
	
	return result;
}

BOOL NTIShareableUserDataUpdateSharing( id object, NSString* toShareWith )
{
	if( !toShareWith || !NTIShareableUserDataCanUpdateSharing( object ) ) {
		return NO;
	}
	NTIShareableUserData* shared = object;
	if( [shared isSharedWith: toShareWith] ) {
		return NO;	
	}
	
	//TODO: When should we do this? If we don't do it now, 
	//we have to take pains to update UIs later (async). If we do it now,
	//and there's a problem, we will be out of sync.
	shared.sharedWith = [shared.sharedWith arrayByAddingObject: toShareWith];
	
	NTIAppPreferences* prefs = [NTIAppPreferences prefs];
	[NTIShareableUserDataUpdater updateSharingOf: shared
									onDataserver: prefs.dataserverURL
										username: prefs.username
										password: prefs.password
										complete: ^(NTIShareableUserData* complete)
	 {
		 //Running this through the data server will have the side-effect
		 //up updating our local cache. We just have to force our way
		 //in to update the existing object
		 [shared setValue: complete.sharedWith forKey: @"sharedWith"];
	 }];
	 
	return YES;
}

BOOL NTISharingTargetsContainsTarget( NSArray* targets, NSString* target )
{
	BOOL result = [targets indexOfObject: target] != NSNotFound;
	if( !result ) {
		//In case a non-string comes in
		result = [targets indexOfObject: target.Username] != NSNotFound;
	}
	if( !result ) {
		//If we don't find it by name, check friends lists. The answer is 
		//YES if we are shared with a friend list that contains other
		for( NSString* shared in targets ) {
			//this will return nil if not found, and a bool message to nil is NO
			//Notice that we access the username explicitly. We may not actually have
			//strings.
			NTIFriendsList* friendsList = [[NTIAppUser appUser] friendsListNamed: shared.Username];
			
			NSArray* friends = friendsList.friends;
			for( id friend in friends ) {
				result = ([friend respondsToSelector: @selector(Username)] &&
						  [[friend Username] isEqual: target.Username])
				|| [friend isEqual: target];
				if( result ) {
					break;
				}
			}
		}
	}
	return result;
}

static BOOL isUrl( id<NTIDraggingInfo>info )
{
	id underDrag = [info objectUnderDrag];
	return 	[underDrag isKindOfClass: [NSURL class]]
	&&	NTIUrlCanHandleScheme( underDrag );
}

BOOL NTIShareableUserDataObjectWantsDrop( id object, id<NTIDraggingInfo>info )
{
	NSString* username = [object Username];
	id underDrag = [info objectUnderDrag];
	BOOL result = NO;
	if( isUrl( info ) ) {
		result = YES;
	}
	else {
		result = 	NTIShareableUserDataCanUpdateSharing( underDrag )
		&&	![underDrag isSharedWith: username];
	}
	return result;
}

BOOL NTIShareableUserDataObjectPerformDrop( id object, id<NTIDraggingInfo>info )
{
	id underDrag = [info objectUnderDrag];
	NSString* username = [object Username];
	
	BOOL result = NO;
	if( isUrl( info ) ) {
		result = YES;
		NTINote* note = [[[NTINote alloc] init]autorelease];
		NSString* text = @"<html><body><p><b>Let's start a discussion!</b>";
		UIImage* image = [info draggedImage];
		if( image ) {
			NSData* pngData = UIImagePNGRepresentation( image );
			text = [NSString stringWithFormat: 
				@"%@<a href='%@'><img src='data:image/png;base64,%@' /></a></p></body></html>",
				text, [underDrag resourceSpecifier], [pngData base64String]];
		}
		else {
			text = [NSString stringWithFormat: @"%@</p></body></html>", text];
		}
		note.text = text;
		note.sharedWith = [NSArray arrayWithObject: username];
		NTIAppPreferences* prefs = [NTIAppPreferences prefs];
		//TODO: Display a modal note editor for the user to add
		//comments?
		[NTINoteSaver saveNote: note
				  toDataserver: prefs.dataserverURL 
					  username: prefs.username
					  password: prefs.password
						  page: [underDrag resourceSpecifier]
					  complete: nil];
	}
	else {
		result = NTIShareableUserDataUpdateSharing( underDrag, username);
	}
	return result;
}

NSString* NTIShaerableUserDataActionStringForDrop( id object, id<NTIDraggingInfo>info )
{
	NSString* name = [object realname];
	NSString* result = @"Share";
	if( isUrl( info ) ) {
		result = @"Discuss";	
	}

	if( name ) {
		result = [NSString stringWithFormat: @"%@ with %@", result, name];
	}
	
	return result;
}


