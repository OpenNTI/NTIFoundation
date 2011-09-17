//
//  NTINoteLoader.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/14.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIUserData.h"
#import "NTIUtilities.h"
#import "NTIAppPreferences.h"
#import "NSArray-NTIExtensions.h"
#import "NSString-NTIExtensions.h"
#import "NTIAppUser.h"
#import "NTISharingUtilities.h"

#import "OmniFoundation/NSDictionary-OFExtensions.h"
#import "OmniFoundation/NSMutableDictionary-OFExtensions.h"
#import <objc/objc.h>

NSString* const NTINotificationUserDataDidCache = @"NTINotificationUserDataDidCache";
NSString* const NTINotificationUserDataDidCacheKey = @"NTINotificationUserDataDidCacheKey";

static NSString* shortDateStringNL( NSDate* date )
{
	static NSDateFormatter* dateFormatter;
	if( !dateFormatter  ) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat: @"yyyy-MM-dd"];
	}
	return [dateFormatter stringFromDate: date];
}

static BOOL isLastModifiedPersistenceKey( NSString* string )
{
	return [@"Last Modified" isEqualToString: string];
}

static NSCache* oidCache()
{
	static NSCache* result = nil;
	if( result == nil ) {
		result = [[NSCache alloc] init];
		[result setName: @"OID Cache"];
	}
	return result;
}

static id cachedVersionOf( NSCache* cache, NSDictionary* dict )
{
	id result = nil;
	id oid = [dict objectForKey: @"OID"];
	result = [cache objectForKey: oid];
	if( result ) {
		//If they give us mod info, respect it.
		//TODO: If there's no info, assume incoming is more recent?
		NSNumber* dictLastMod = [dict objectForKey: @"Last Modified"];
		
		if( [dictLastMod longValue] > [result LastModified] ) {
			//If no last mod info, longValue is 0
			result = nil;	
			[cache removeObjectForKey: oid];
		}

	}
	return result;
}

static void cacheObjectForKey( NSCache* cache, id object, id key )
{
	[cache setObject: object forKey: key];
	NSDictionary* info = [NSDictionary dictionaryWithObject: object 
													 forKey: NTINotificationUserDataDidCacheKey];
	NSNotification* note = [NSNotification notificationWithName: NTINotificationUserDataDidCache
														 object: cache
													   userInfo: info];
	[[NSNotificationCenter defaultCenter]
		postNotification: note];												   
}

@interface NTIUserData()
-(NSMutableDictionary*)class: (Class)staticSelfClass
toPropertyListObjectWithKeys: (NSString*)key,... NS_REQUIRES_NIL_TERMINATION;
@end

@interface NSObject(NTIUserData)
//To make the super call work
-(NSMutableDictionary*)toPropertyListObject;
@end


@implementation NSObject(NTIUserData)
-(NSMutableDictionary*)toPropertyListObject
{
	return [NSMutableDictionary dictionary];
}
@end

@implementation NTIUserData

@synthesize ID, OID, LastModified;
@synthesize Creator, ContainerId;

static Class classForPropertyListObject( id representation )
{
	NSString* className = [representation objectForKey: @"Class"];
	className = [NSString stringWithFormat: @"NTI%@", className];
	Class theClass = objc_getClass( [className UTF8String] );
	if( !theClass ) {
		NSLog( @"WARN Attempt to create unknown class %@", className );
	}
	return theClass;
}

+(id)_objectOrPListFromPropertyListObject: (id)representation
								 oidCache: (NSCache*)cache
{	
	id result = representation;
	if(		[representation respondsToSelector: @selector(objectForKey:)]
	   &&	[[representation objectForKey: @"Class"] isKindOfClass: [NSString class]] ) {
		//A dictionary representing an object. Is it cached?
		id oid = [representation objectForKey: @"OID"];
		Class const theClass = classForPropertyListObject( representation );
		BOOL useCache = YES;
		if( (result = cachedVersionOf( cache,  representation)) && theClass ) {
			//Yay, got it. To help avoid cache bugs (if the server messes up and
			//sends an improper OID) make sure that the class matches. That has
			//happened before. If it does, we want to remove the object altogether
			//from the cache because we don't know which is the right one. We also
			//don't want to cache it, but we still want to return a parsed result
			//for this data.
			if(		theClass != [result class]
				//We might have manually cached a subclass.
				 &&	![[result class] isSubclassOfClass: theClass] ) {
				NSLog( @"WARN Cache conflict for OID %@ current %@ new %@",
					oid, [result class], theClass );
				result = nil;
				//We recurse, and we still want to use child
				//object caching, just not this one, so it's not as 
				//simple as setting the cache itself to nil.
				useCache = NO;
				[cache removeObjectForKey: oid];

			}
		}
		
		//Not cached (or invalid), must construct.
		if( !result && theClass ) {
			//We use reflection to locate the class to create. 
			//To prevent security holes, we only return objects
			//that are our descendents.
			id theInstance = [theClass alloc];
			if( ![theInstance isKindOfClass: [NTIUserData class]] ) {
				//Either we didn't find it, or it was not part of
				//the heirarchy. Either is bad.
				NSLog( @"WARN Attempt to create illegal class %@ for OID %@",
						 theClass, oid );
				[theInstance release];
			}
			else {
				NSMutableDictionary* dict = [NSMutableDictionary dictionary];
				//Probably a temporary hack to remove
				//bad keys that crept in
				[dict removeObjectForKey: @"LastModified"];
				
				for( id key in representation ) {
					//Transform and replace.
					id value = [representation objectForKey: key];
					value = [self _objectOrPListFromPropertyListObject: value
															  oidCache: cache];
					if( value ) {
						[dict setObject: value
								 forKey: key];	
					}
				}
				
				theInstance = [theInstance init];
				[theInstance setValuesForKeysWithDictionary: dict];	
				[theInstance autorelease];
				result = theInstance;
				if( oid && useCache ) {
					cacheObjectForKey( cache, result, oid );
				}
			}
		}
	}
	//Could it be an array?
	else if(	[representation respondsToSelector: @selector(objectAtIndex:)]
			&&	[representation respondsToSelector: @selector(count)] 
			&&	![NSArray isEmptyArray: representation] ) {
		//Do the same to each object
		NSMutableArray* copy = [NSMutableArray arrayWithCapacity: [representation count]];
		for( id value in representation ) {
			value = [self _objectOrPListFromPropertyListObject: value
													  oidCache: cache];
			if( value ) {
				[copy addObject: value];
			}
		}
		result = copy;
	}
	//Anything else, goes as-is
	return result;
}

+(id)objectFromPropertyListObject: (id)representation
{
	id result = [self _objectOrPListFromPropertyListObject: representation
												  oidCache: oidCache()];
	if( result == representation ) {
		//If we didn't transform it, then we failed. Epic.
		result = nil;
	}
	return result;
}

-(id)cache
{
	if( self.OID ) {
		cacheObjectForKey( oidCache(), self, self.OID );
	}
	return self;
}

-(NSDate*)lastModifiedDate
{
	return [NSDate dateWithTimeIntervalSince1970: self.LastModified];
}

-(NSString*)lastModifiedDateShortStringNL
{
	return shortDateStringNL( self.lastModifiedDate );
}

-(NSString*)lastModifiedDateString
{
	return [NSDateFormatter localizedStringFromDate: self.lastModifiedDate
										  dateStyle: NSDateFormatterMediumStyle
										  timeStyle: NSDateFormatterShortStyle];
}

-(BOOL)shared
{
	return self.Creator && ![self.Creator isEqual: [[NTIAppPreferences prefs] username]];
}

static NSMutableDictionary* stripNSNull( NSMutableDictionary* parent )
{
	//PLists don't deal with NSNull
	[parent performSelector: @selector(removeObjectForKey:)
		withEachObjectInSet: [parent keysOfEntriesPassingTest: ^BOOL(id key, id obj, BOOL*stop) {
		return [obj isNull];	
	}]];
	return parent;
}

-(id)toPropertyListObject
{
	//We can't use toPropertyListObjectWithKeys in our implementation
	//as its quite possible a subclass has overridden it to call us
	//and we infinite recurse.
	NSDictionary* dict = [self dictionaryWithValuesForKeys: 
						  [NSArray arrayWithObjects: @"ID",
						   @"OID", @"Creator", @"ContainerId", nil]];
	
	//PLists don't deal with NSNull
	NSMutableDictionary* copy = [NSMutableDictionary dictionaryWithDictionary: dict];
	[copy setObject: [NSNumber numberWithInteger: self.LastModified] forKey: @"Last Modified"];
	return stripNSNull( copy );
}

//As an convenience when implementing toPropertyListObject, 
//subclasses can implement this method. It will call [self toPropertyListObject]
//and then add the values of the given KVC keys to the dictionary, taking
//nil into account.
-(NSMutableDictionary*)class: (Class)staticSelfClass 
toPropertyListObjectWithKeys: (NSString*)key,...
{
	NSMutableArray* keys = [NSMutableArray array];
	va_list varg;
	va_start(varg, key);
	id theKey = key;
	while( theKey != nil ) {
		[keys addObject: theKey];
		theKey = va_arg( varg, id );
	}
	va_end( varg );

	//depending on where we are, we want either self or super
	IMP imp = [[staticSelfClass superclass] instanceMethodForSelector: @selector(toPropertyListObject)];
	
	
	NSMutableDictionary* parent = imp( self, _cmd );
	NSDictionary* dict = [self dictionaryWithValuesForKeys: keys];
	NSMutableDictionary* mdict = [[dict mutableCopy] autorelease];
	//Recurse through arrays.
	for( id key in dict ) {
		id obj = [dict objectForKey: key];
		if( [obj isKindOfClass: [NSArray class]] ) {
			NSMutableArray* plArray = [NSMutableArray array];
			for( id i in obj ) {
				//Use class check because the method is added to NSObject
				if( [i isKindOfClass: [NTIUserData class]] ) {
					[plArray addObject: [i toPropertyListObject]];	
				}
				else {
					[plArray addObject: i];
				}
			}
			[mdict setObject: plArray forKey: key];
		}
	}
	[parent addEntriesFromDictionary: mdict];

	return stripNSNull( parent );
}

-(NSMutableDictionary*)debugDictionary
{
	NSMutableDictionary* parent = [super debugDictionary];
	[parent addEntriesFromDictionary: [self toPropertyListObject]];
	return parent;
}


-(NSData*)toPropertyListData
{
	return [NSPropertyListSerialization dataWithPropertyList: [self toPropertyListObject]
													  format: NSPropertyListXMLFormat_v1_0
													 options: 0
													   error: NULL];
}

-(NSString*)externalClassName
{
	const char* className = object_getClassName( self );
	//We assume class names are at least three characters long.
	if( className && className[0] == 'N' && className[1] == 'T' && className[2] == 'I' ) {
		className = className + 3; //Skip over
	}
	return [NSString stringWithUTF8String: className];
}

-(void)setValue: (id)value forUndefinedKey: (NSString*)key
{
	if( isLastModifiedPersistenceKey( key ) ) {
		[self setValue: value forKey: @"LastModified"];
	}
	else if( [key isEqual: @"Class"] && [value isEqual: [self externalClassName]] ) {
		//ignored
	}
	else {
		NSLog( @"WARN: Ignoring unsupported key: %@ value: %@", key, value );
	}
}

-(id)valueForUndefinedKey: (NSString *)key
{
	if( isLastModifiedPersistenceKey( key ) ) {
		return [self valueForKey: @"LastModified"];
	}
	return [super valueForUndefinedKey: key];
}

#pragma mark -
#pragma mark Use in sets

-(id)copyWithZone: (NSZone*)z
{
	NTIUserData* result = [[[self class] allocWithZone: z] init];
	result.ID = self.ID;
	result.OID = self.OID;
	result.LastModified = self.LastModified;
	return result;
}


-(BOOL)isEqual: (id)obj
{
	if( ![obj isKindOfClass: [NTIUserData class]] ) {
		return NO;
	}
	if( obj == self ) {
		return YES;
	}
	
	if( self->OID ) {
		//If we've been saved, then we're only 
		//equal to the identically saved object.
		return [self->OID isEqual: [obj OID]];
	}
	
	if( [obj OID] ) {
		//It's saved and we're not: never equal
		return NO;
	}
	
	//Two unsaved object are equal. All our other fields
	//are set by the server so we have nothing to compare to.
	//Subclasses might improve upon this.
	return YES;
}

-(void)dealloc
{
	self.ID = nil;
	self.OID = nil;
	NTI_RELEASE( self->Creator );
	NTI_RELEASE( self->ContainerId );
	[super dealloc];
}

@end;

@implementation NTIChange

@synthesize ChangeType, Item;

+(NSPredicate*)searchPredicate
{
	return [NSPredicate predicateWithFormat: @"summary CONTAINS[cd] $VALUE"];
}

-(NSString*)summary
{
	NSString* type = @"edited";
	id class = self.Item.class;
	if( [self.ChangeType isEqual: kNTIChangeTypeCreated] ) {
		type = @"created";
	}
	else if( [self.ChangeType isEqual: kNTIChangeTypeShared] ) {
		type = @"shared";
	}
	else if( [self.ChangeType isEqual: kNTIChangeTypeCircled] ) {
		type = @"added you to";
		class = @"friends list";
	}
	
	NSString* text = [NSString stringWithFormat:
					  @"%@ %@ a %@",
					  self.Creator, type, class];
	return text;
}

-(id)toPropertyListObject
{
	NSMutableDictionary* parent = [super toPropertyListObject];
	[parent setObject: self.ChangeType forKey: @"ChangeType"];
	if( [self.Item respondsToSelector: @selector(toPropertyListObject)] ) {
		[parent setObject: [self.Item toPropertyListObject] forKey: @"Item"];
	}
	else {
		[parent setObject: self.Item forKey: @"Item"];
	}
	return parent;
}

//We proxy to our item
-(id)forwardingTargetForSelector:(SEL)aSelector
{
	if( [self->Item respondsToSelector: aSelector] ) {
		return self->Item;
	}
	return [super forwardingTargetForSelector:aSelector];
}

-(id)copyWithZone: (NSZone*)z
{
	NTIChange* copy = [super copyWithZone: z];
	copy->ChangeType = [self.ChangeType retain];
	copy->Item = [self.Item retain];
	return copy;
}

-(void)dealloc
{
	NTI_RELEASE( self->ChangeType );
	NTI_RELEASE( self->Item );
	[super dealloc];
}

@end

#pragma mark Hits

@implementation NTIHit

@synthesize Snippet, Title, Type, TargetOID, CollectionID;

-(id)toPropertyListObject
{
	return [self class: [NTIHit class]
			toPropertyListObjectWithKeys: @"Snippet", @"Title", @"Type",
			 @"TargetOID", @"CollectionID", nil];
}

-(id)copyWithZone: (NSZone*)z
{
	NTIHit* copy = [super copyWithZone: z];
	copy->Snippet = [self->Snippet retain];
	copy->Title = [self->Title retain];
	copy->Type = [self->Type retain];
	copy->TargetOID = [self->TargetOID retain];
	copy->CollectionID = [self->CollectionID retain];
	return copy;
}

-(void)dealloc
{
	NTI_RELEASE( self->Snippet );
	NTI_RELEASE( self->Type );
	NTI_RELEASE( self->Title );
	NTI_RELEASE( self->TargetOID );
	NTI_RELEASE( self->CollectionID );
	[super dealloc];
}

@end


#pragma mark Users and Friends

@implementation NTIEntity

@synthesize Username, realname, alias, avatarURL;

-(NSString*)prefDisplayName
{
	return self.realname ? self.realname : self.Username;	
}

+(NSPredicate*)searchPredicate
{
	return [NSPredicate predicateWithFormat:
			@"Username CONTAINS[cd] $VALUE OR realname CONTAINS[cd] $VALUE OR alias CONTAINS[cd] $VALUE"];
}

-(id)toPropertyListObject
{
	return [self class: [NTIEntity class]
			toPropertyListObjectWithKeys: 
			@"Username", @"realname", @"alias", @"avatarURL", nil];
}

-(id)copyWithZone: (NSZone*)z
{
	NTIEntity* copy = [super copyWithZone: z];
	copy->Username = [self->Username copy];
	copy->avatarURL = [self->avatarURL copy];
	copy->realname = [self->realname copy];
	copy->alias = [self->alias copy];
	return copy;
}

-(void)dealloc
{
	NTI_RELEASE( self->Username );
	self.avatarURL = nil;
	self.realname = nil;
	self.alias = nil;
	[super dealloc];
}

@end

@implementation NTISharingTarget
@end

@implementation NTICommunity
@end

@implementation NTIUser
@synthesize Communities, NotificationCount, lastLoginTime;
@synthesize following, accepting, ignoring;

-(NSDate*)lastLoginDate
{
	return [NSDate dateWithTimeIntervalSince1970: self.lastLoginTime];
}

-(void)setLastLoginDate: (NSDate*)date
{
	self.lastLoginTime = [date timeIntervalSince1970];
}

-(NSString*)lastLoginDateShortStringNL
{
	return shortDateStringNL( self.lastLoginDate );
}

-(id)toPropertyListObject
{
	return [self class: [NTIUser class]
			toPropertyListObjectWithKeys:
			@"Communities", @"NotificationCount", @"lastLoginTime",
			@"lastLoginTime", @"following", @"accepting", @"ignoring", nil];
}

-(id)copyWithZone: (NSZone*)z
{
	NTIUser* copy = [super copyWithZone: z];
	copy->Communities = [self->Communities copy];
	copy->NotificationCount = self->NotificationCount;
	copy->lastLoginTime = self->lastLoginTime;
	copy->following = [self->following copy];
	copy->accepting = [self->accepting copy];
	copy->ignoring = [self->ignoring copy];
	return copy;
}

-(void)dealloc
{
	NTI_RELEASE( self->Communities );
	self.following = nil;
	self.accepting = nil;
	self.ignoring = nil;
	[super dealloc];
}

@end

@implementation NTIUnresolvedFriend
@end

@implementation NTIFriendsList

@synthesize friends;

-(id)toPropertyListObject
{
	NSMutableDictionary* parent = [super toPropertyListObject];
	if( self.friends ) {
		[parent setObject: [self valueForKeyPath: @"friends.@distinctUnionOfObjects.Username"]
				   forKey: @"friends"];
	}
	
	return parent;
}

-(id)copyWithZone: (NSZone*)z
{
	NTIFriendsList* copy = [super copyWithZone: z];
	copy->friends = [self->friends copy];
	return copy;
}

-(void)dealloc
{
	self.friends = nil;
	[super dealloc];
}

@end

@implementation NSString(NTIUserDataLike)
-(NSString*)Username
{
	return self;
}
-(NSString*)realname
{
	return self;	
}
-(NSString*)prefDisplayName
{
	return self;	
}
-(NSString*)alias
{
	return self;	
}
@end

#pragma mark -
#pragma mark NTIShareableUserData

@implementation NTIShareableUserData

@synthesize sharedWith;

-(BOOL)isSharedWith: (NSString*)other
{
	return NTISharingTargetsContainsTarget( self.sharedWith, other );
}


-(id)toPropertyListObject
{
	NSMutableDictionary* parent = [super toPropertyListObject];
	if( self.sharedWith ) {
		//We could have a mix of different types here, but
		//we have a category on NSSTring to provide Username.
		[parent setObject: [self valueForKeyPath: @"sharedWith.@distinctUnionOfObjects.Username"]
				   forKey: @"sharedWith"];
	}
	return parent;
}

-(id)copyWithZone: (NSZone*)z
{
	NTIShareableUserData* copy = [super copyWithZone: z];
	copy->sharedWith = [self->sharedWith copy];
	return copy;
}

-(void)dealloc
{
	self.sharedWith = nil;
	[super dealloc];
}

@end

@implementation NTIHighlight

@synthesize startHighlightedText, startHighlightedFullText;
@synthesize startOffset, endOffset;
@synthesize startAnchor;

+(NSPredicate*)searchPredicate
{
	return [NSPredicate predicateWithFormat: @"text CONTAINS[cd] $VALUE"];
}

-(NSString*)text
{
	if( ![NSString isEmptyString: self.startHighlightedFullText] ) {
		return self.startHighlightedFullText;
	}
	return self.startHighlightedText;
}

-(NSString*)anchorPoint
{
	return self.startAnchor;
}

-(NSString*)anchorType
{
	return @"previousName"; //is this always right?
}

-(BOOL)hasText
{
	return ![NSString isEmptyString: self.text];	
}

-(NSArray*)references
{
	return [NSArray array];
}

-(NSString*)inReplyTo
{
	return nil;
}

-(id)toPropertyListObject
{
	return [self class: [NTIHighlight class]
			toPropertyListObjectWithKeys: 
			@"startHighlightedText", @"startHighlightedFullText",
			@"startOffset", @"endOffset",
			@"startAnchor", nil];
}


-(id)copyWithZone: (NSZone*)z
{
	NTIHighlight* result = [super copyWithZone: z];
	result.startHighlightedFullText = self.startHighlightedFullText;
	result.startHighlightedText = self.startHighlightedText;
	result.startOffset = self.startOffset;
	result.endOffset = self.endOffset;
	result.startAnchor = self.startAnchor;
	return result;
}


-(BOOL)isEqual: (NTIHighlight*)object
{
	if( ![super isEqual: object] ) {
		return NO;
	}
	
	return	self.startOffset == object.startOffset
		&&	self.endOffset == object.endOffset
		&&	OFISEQUAL( self.startHighlightedText, object.startHighlightedText );
}

-(void)dealloc
{
	self.startHighlightedText = nil;
	self.startHighlightedFullText = nil;
	self.startAnchor = nil;
	[super dealloc];
}

@end;


@implementation NTINote

@synthesize text;
@synthesize anchorPoint, anchorType, left, top, zIndex;
@synthesize references, inReplyTo;

+(NSPredicate*)searchPredicate
{
	return [NSPredicate predicateWithFormat: @"text CONTAINS[cd] $VALUE"];
}

-(BOOL)hasText
{
	return ![NSString isEmptyString: self.text];	
}

-(id)toPropertyListObject
{
	return [self class: [NTINote class]
			toPropertyListObjectWithKeys: 
			@"text", @"left", @"top", 
			@"anchorPoint", @"anchorType", @"inReplyTo", @"references", nil];
}

-(void)setValue: (id)value forUndefinedKey: (NSString*)key
{
	if( [key isEqual: @"in-reply-to"] ) {
		[self setValue: value forKey: @"inReplyTo"];	
	}
	else {
		[super setValue: value forUndefinedKey: key];
	}
}

-(id)copyWithZone: (NSZone*)z
{
	NTINote* result = [super copyWithZone: z];
	result.text = self.text;
	result.left = self.left;
	result.top = self.top;
	result.zIndex = self.zIndex;
	result.anchorPoint = self.anchorPoint;
	result.anchorType= self.anchorType;
	return result;
}


-(BOOL)isEqual: (NTINote*)object
{
	if( ![super isEqual: object] ) {
		return NO;
	}
	
	return ((self.text == nil && object.text == nil) || [self.text isEqual: object.text])
	&&		self.left == object.left
	&&		self.top == object.top;
}

-(void)dealloc
{
	self.text = nil;
	self.references = nil;
	self.inReplyTo = nil;
	self.anchorType = nil;
	self.anchorPoint = nil;
	[super dealloc];
}

@end;

@implementation NTIQuizResult

@synthesize QuizID;
@synthesize Items;

-(id)toPropertyListObject
{
	return [self class: [NTIQuizResult class]
toPropertyListObjectWithKeys: 
			@"QuizID", @"Items", nil];
}


+(NSPredicate*)searchPredicate
{
	return [NSPredicate predicateWithFormat: @"text CONTAINS[cd] $VALUE"];
}

-(NSString*)text
{
	float percent = 1.0;
	int right = 0;
	for( NTIQuizQuestionResponse* rsp in self->Items ) {
		if( rsp.Assessment ) {
			right++;
		}
	}
	percent = (float)right/(float)self->Items.count;
	percent *= 100.0;
	NSString* result = [NSString stringWithFormat: @"Attempt %2.1f%%", percent];
	return result;
}

-(NSString*)anchorPoint
{
	return nil;
}

-(NSString*)anchorType
{
	return nil;
}

-(BOOL)hasText
{
	return ![NSString isEmptyString: self.text];	
}

-(NSArray*)references
{
	return [NSArray array];
}

-(NSString*)inReplyTo
{
	return nil;
}

-(id)copyWithZone: (NSZone*)z
{
	NTIQuizResult* result = [super copyWithZone: z];
	result->QuizID = [self->QuizID copy];
	result->Items = [self->Items retain];
	return result;
}


-(void)dealloc
{
	NTI_RELEASE( self->QuizID );
	NTI_RELEASE( self->Items );
	[super dealloc];
}

@end;

@implementation NTIQuizQuestionResponse
@synthesize Question, Response, Assessment;

-(id)toPropertyListObject
{
	return [self class: [NTIQuizQuestionResponse class]
toPropertyListObjectWithKeys: 
			@"Question", @"Response", @"Assessment", nil];
}

-(id)copyWithZone: (NSZone*)z
{
	NTIQuizQuestionResponse* result = [super copyWithZone: z];
	result->Question = [self->Question retain];
	result->Response = [self->Response copy];
	result->Assessment = self->Assessment;
	return result;
}


-(void)dealloc
{
	NTI_RELEASE( self->Question );
	NTI_RELEASE( self->Response );
	[super dealloc];
}
@end



@implementation NTIQuizQuestion
@synthesize Text, Answers;

-(id)toPropertyListObject
{
	return [self class: [NTIQuizResult class]
toPropertyListObjectWithKeys: 
			@"Text", @"Answers", nil];
}

-(id)copyWithZone: (NSZone*)z
{
	NTIQuizQuestion* result = [super copyWithZone: z];
	result->Text = [self->Text copy];
	result->Answers = [self->Answers retain];
	return result;
}


-(void)dealloc
{
	NTI_RELEASE( self->Text );
	NTI_RELEASE( self->Answers );
	[super dealloc];
}
@end
