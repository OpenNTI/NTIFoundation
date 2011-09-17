//
//  NTIUserData.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/06.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"

/**
 * The name of the notification emitted when an object is cached.
 * The userInfo dictionary will have a key containing the object that was cached.
 */
extern NSString* const NTINotificationUserDataDidCache;

/**
 * The name of the key in the user info for the cached data containing the
 * cached object.
 */
extern NSString* const NTINotificationUserDataDidCacheKey;


/**
 * The base interface for all types of user generated data. 
 */
@interface NTIUserData : OFObject<NSCopying> {
	
}

#pragma mark Loading and Saving
/**
 * Returns a new instance of the appropriate class from the given
 * property list representation.
 */
+(id)objectFromPropertyListObject: (id)representation;
/**
 * Returns a representation of this instance a property list data
 * that can be saved on the server. This class's implementation
 * returns a mutable dictionary; subclasses may do otherwise.
 */
-(id)toPropertyListObject;
/**
 * A version of the property list object as NSData.
 */
-(NSData*)toPropertyListData;

/**
 * Requests that this object be cached for future retreival.
 */
-(id)cache;

//By convention, the capital properties are only set
//by the server.

//ID is unique within a user and container. It MAY be set on save (by PUTting
//to the correct location) OID is globally unique.
@property (nonatomic,retain) NSString* ID, *OID;

//The name of the user that created this item. Nil means an 
//unsaved object.
@property (nonatomic,readonly) NSString* Creator;

//The NTIID of the entity that most directly contains us. 
//Set on save.
@property (nonatomic,readonly) NSString* ContainerId;

//In seconds since 1970. Set on save and modification.
//May be 0 for unsaved, temporary, or partial objects
@property (nonatomic,assign) NSInteger LastModified;


#pragma mark Derived Data

@property (nonatomic,readonly) NSDate* lastModifiedDate;
//NL == non-localized
@property (nonatomic,readonly) NSString* lastModifiedDateShortStringNL;
@property (nonatomic,readonly) NSString* lastModifiedDateString;
@property (nonatomic,readonly) BOOL shared;
//The classname in the external representation, such as Note or Highlight
@property (nonatomic,readonly) NSString* externalClassName;
@end

#pragma mark Changes
#define kNTIChangeTypeShared  @"Shared"
#define kNTIChangeTypeCreated @"Created"
#define kNTIChangeTypeEdited  @"Modified"
#define kNTIChangeTypeDeleted @"Deleted"
#define kNTIChangeTypeCircled @"Circled"

/**
 * A notice that a change has been applied.
 * Currently, a Change will respond to anything that
 * the underlying item will respond to and so can
 * be used in its place.
 */
@interface NTIChange : NTIUserData
@property (nonatomic,readonly) NSString* ChangeType;

//The item to which the change occurred.
@property (nonatomic,readonly) NTIUserData* Item;

#pragma mark Derived Data
@property (nonatomic,readonly) NSString* summary;
+(NSPredicate*)searchPredicate;
@end

#pragma mark Hits
/**
 * A search hit. These are not exactly user data, but
 * they fit nicely in the framework.
 */
@interface NTIHit : NTIUserData
@property (nonatomic,readonly) NSString *Snippet, *Title, *Type, *TargetOID, *CollectionID;
@end

#pragma mark Entity
@interface NTIEntity : NTIUserData /* Not quite, but mostly */
@property (nonatomic,readonly) NSString* Username;
@property (nonatomic,copy) NSString* avatarURL, *realname, *alias;

#pragma mark Derived Data
@property (nonatomic,readonly) NSString* prefDisplayName;
//A predicate that searches these objects on name.
//Assumes an argument of $VALUE
+(NSPredicate*) searchPredicate;
@end

@interface NTICommunity : NTIEntity
@end

#pragma mark SharingTarget
@interface NTISharingTarget : NTIEntity
@end

#pragma mark Users and Friends

@interface NTIUser : NTISharingTarget
//List of names of communities we are in.
@property (nonatomic,readonly) NSArray* Communities;
@property (nonatomic,readonly) NSInteger NotificationCount;
@property (nonatomic,assign) NSInteger lastLoginTime;
//List of names of others we follow.
@property (nonatomic,retain) NSArray* following;
//...we accept shared data from.
@property (nonatomic,retain) NSArray* accepting;
//...we ignore shared data from.
@property (nonatomic,retain) NSArray* ignoring;

#pragma mark Derived Data

@property (nonatomic,assign) NSDate* lastLoginDate;
@property (nonatomic,readonly) NSString* lastLoginDateShortStringNL;
@end

@interface NTIUnresolvedFriend : NTISharingTarget
@end

@interface NTIFriendsList : NTIEntity
/**
 * An array of NTIUsers, NTIUnresolvedFrieds, or base strings.
 */
@property (nonatomic,copy) NSArray* friends;
@end

@interface NSString(NTIUserDataLike)
-(NSString*)Username;
-(NSString*)realname;
-(NSString*)prefDisplayName;
-(NSString*)alias;
@end


#pragma mark NTIShareableUserData

/**
 * A type of user data that can be shared. In general, 
 * posting just the sharedWith property to the data's location will
 * update sharing information without changing the object.
 */
@interface NTIShareableUserData : NTIUserData

//An array of strings or (NTISharingTarget-like objects) 
//of other user names or friend lists 
//that this is shared with. These objects will all 
//respond to Username, realname and prefDisplayName.
@property (nonatomic,copy) NSArray* sharedWith;

//Answers whether this object is shared with the given object. 
//Note that an answer of NO might not be entirely reliable in the case
//of friends lists that are not loaded in memory.
-(BOOL)isSharedWith: (NSString*)other;

@end

#pragma mark - NTINote and NTIHighlight

@interface NTIHighlight : NTIShareableUserData {
	
}
+(NSPredicate*)searchPredicate;

@property (nonatomic,copy) NSString* startHighlightedText;
@property (nonatomic,copy) NSString* startHighlightedFullText;
@property (nonatomic,assign) NSInteger startOffset, endOffset;
@property( nonatomic,copy) NSString* startAnchor;

//Derived data
@property (nonatomic,readonly) NSString* text; //For compatibility with NTINote
@property (nonatomic,readonly) NSString* anchorPoint; // ""
@property (nonatomic,readonly) NSString* anchorType;  // ""
@property (nonatomic,readonly) BOOL hasText;          // ""
@property (nonatomic,readonly) NSArray* references;   // "", always empty
@property (nonatomic,readonly) NSString* inReplyTo;   // "", always nil 
@end

@interface NTINote : NTIShareableUserData {
	
}
+(NSPredicate*)searchPredicate;

@property (nonatomic,copy) NSString* text;

//An array of other OIDs that we refer to directly or indirectly
//through the reply chain
@property (nonatomic,retain) NSArray* references;

//The OID of the item we are a direct reply to.
@property (nonatomic,retain) NSString* inReplyTo;

//For notes that are anchored in space, gives the coordinates in HTML document space.
@property (nonatomic,assign) NSInteger left, top, zIndex;

//For notes that are anchored to the page, records an anchor
//id and anchor type.
@property( nonatomic,retain) NSString* anchorPoint, *anchorType;

//Derived data
@property (nonatomic,readonly) BOOL hasText;
@end

//Quizzes

@interface NTIQuizResult : NTIShareableUserData

@property (nonatomic,readonly) NSString* QuizID;
@property (nonatomic,readonly) NSArray* Items; 

//Derived data
@property (nonatomic,readonly) NSString* text; //For compatibility with NTINote
@property (nonatomic,readonly) NSString* anchorPoint; // ""
@property (nonatomic,readonly) NSString* anchorType;  // ""
@property (nonatomic,readonly) BOOL hasText;          // ""
@property (nonatomic,readonly) NSArray* references;   // "", always empty
@property (nonatomic,readonly) NSString* inReplyTo;   // "", always nil 

@end

@interface NTIQuizQuestion : NTIUserData
@property (nonatomic,readonly) NSString* Text;
@property (nonatomic,readonly) NSArray* Answers;
@end

@interface NTIQuizQuestionResponse : NTIUserData
@property (nonatomic,readonly) NTIQuizQuestion* Question;
@property (nonatomic,readonly) NSString* Response;
@property (nonatomic,readonly) BOOL Assessment;
@end


