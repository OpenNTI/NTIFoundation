//
//  NTINavigationParser.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/31.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"

extern NSString* const kNTINavigationPropertyIcon;
extern NSString* const kNTINavigationPropertyRoot;
extern NSString* const kNTINavigationPropertyOverrideRoot;

@interface NTINavigationItem : OFObject {
	NSMutableDictionary* properties;
	NSMutableArray* children;
	@public
	NTINavigationItem* nr_parent;
}

@property (retain,nonatomic,readonly) NSString* name;
@property (retain,nonatomic) NSString* href;
@property (retain,nonatomic,readonly) NSString *icon, *ntiid;
/**
 * An indicator of this content item's relative size, compared
 * to the other items is this tree. 
 */
@property (nonatomic,assign,readonly) NSInteger relativeSize;

/**
 * An indicator of this content item's relative size, including
 * its children, relative to other items at this same
 * level in its tree.
 */
@property (nonatomic,readonly) NSInteger recursiveRelativeSize;

/**
 * A collection of NTIRelatedNavigationItem that are the destinations of any outgoing
 * links for this page
 */
@property (nonatomic, readonly) NSArray* related;

/**
 * An array of NTINavigationItem.
 */
@property (retain,nonatomic,readonly) NSArray* children;

+(id)itemWithItem: (NTINavigationItem*)item
			 href: (NSString*)href;

-(id)initWithName: (NSString*)name
			 href: (NSString*)href
			 icon: (NSString*)icon
			ntiid: (NSString*)ntiid
	 relativeSize: (NSInteger)size;

/**
 * Return the path of NavigationItem objects from this object down
 *, or nil if path not found.
 */
-(NSArray*)pathToHref: (NSString*)href;

/**
 * Return the path of NavigationItem objects from this object down
 *, or nil if path not found.
 */
-(NSArray*)pathToID: (NSString*)ntiid;

/**
 * How many children this has.
 */
- (NSUInteger)count;

/**
 * @return The new childe.
 */
-(NTINavigationItem*)addChildNamed: (NSString*)name
							  href: (NSString*)ref
							  icon: (NSString*)icon
							 ntiid: (NSString*)ntiid
					  relativeSize: (NSInteger)size;

-(void)adoptChild: (NTINavigationItem*) item;
-(id)adoptChild: (NTINavigationItem*)child replacingIndex: (NSUInteger)ix;

/**
 * Returns the parent of this node if there is one and if the
 * tree has not been deallocated.
 */
@property (nonatomic,readonly) NTINavigationItem* parent;

/**
 * Returns the next sibling to this node. The next sibling
 * is the next node at the same level. If this is the last
 * node at a level, returns nil.
 */
@property (nonatomic,readonly) NTINavigationItem* nextSibling;

/**
 * Returns the previos sibling of this node, the node
 * that preceeds this node in the children of the parent. If this is 
 * the first node in a level, returns nil.
 */
@property (nonatomic,readonly) NTINavigationItem* previousSibling;

-(void)setObject: (id)o forKey: (id)k;
-(void)setObject: (id)o forKey: (id)k recursive: (BOOL)recursive;
-(id)objectForKey: (id)k;

@end


@interface NTIRelatedNavigationItem : NTINavigationItem 


-(id)initWithName: (NSString*)name
			 href: (NSString*)href
			 icon: (NSString*)icon
			ntiid: (NSString*)_ntiid
	 relativeSize: (NSInteger)size
	  relatedType: (NSString*)relatedType 
 relatedQualifier: (NSString*)relatedQualifier;

@property (nonatomic,readonly) NSString *type, *qualifier;
@end


@interface NTINavigationParser : NSObject<NSXMLParserDelegate> {
	NTINavigationItem* root; 
	NTINavigationItem* nr_current;
	NSString* hrefPrefix;
    
}
- (NTINavigationParser*) initWithContentsOfURL: (NSURL*)url;
- (NTINavigationParser*) initWithContentsOfURL: (NSURL*)url hrefPrefix: (NSString*)pfx;
- (NTINavigationItem*) root;
@end


@interface NTINavigationParserLoader : NSObject {
@private
//	dispatch_semaphore_t sema;
//	NTINavigationParser* navigationData;
}
//@property (readonly, nonatomic) NTINavigationParser* parser;

+(NTINavigationItem*)prepareForNavigation: (NTINavigationItem*)item rootURL: (NSURL*)url;

+(void) loadFromString: (NSString*)string
		 relativeToURL: (NSURL*)url
			hrefPrefix: (NSString*)prefix
			  callback: (void(^)(NTINavigationParser*)) callback;
+(void) loadFromString: (NSString*)string
		 relativeToURL: (NSURL*)url
			hrefPrefix: (NSString*)prefix
			  callback: (void(^)(NTINavigationParser*)) callback
				 queue: (dispatch_queue_t)queue;


@end


