//
//  NTISharingUtilities.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/10.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

typedef enum {
	NTISharingTypePublic,
	NTISharingTypePrivate,
	NTISharingTypeLimited
} NTISharingType;

NSString* NSStringFromNTISharingType( NTISharingType type );
NTISharingType NTISharingTypeForTargets( NSArray* targets );

BOOL NTISharingTargetsContainsTarget( NSArray* targets, NSString* target );

//Utility functions for working with shared objects.

//Answers YES if the object is an object that can have its sharing
//updated. Useful in DnD operations and button enable states.
BOOL NTIShareableUserDataCanUpdateSharing( id object );

//Attempts to update the sharing of the object to contain
//the given NSString. Returns YES if this is possible, NO if not.
BOOL NTIShareableUserDataUpdateSharing( id object, NSString* toShareWith );


#pragma mark -
#pragma mark DnD

//The array of classes that these methods can handle
NSArray* NTIShareableUserDataRegisteredDropArray();

//Can we drop the drag on this object?
@protocol NTIDraggingInfo;
BOOL NTIShareableUserDataObjectWantsDrop( id object, id<NTIDraggingInfo>dragInfo );

//Do the drop on this object
BOOL NTIShareableUserDataObjectPerformDrop( id object, id<NTIDraggingInfo>dragInfo );

//Display a title string for the drop
NSString* NTIShaerableUserDataActionStringForDrop( id object, id<NTIDraggingInfo>dragInfo );
