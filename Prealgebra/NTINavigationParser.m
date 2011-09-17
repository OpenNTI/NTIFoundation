//
//  NTINavigationParser.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/31.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTINavigationParser.h"
#import "NTIUtilities.h"

NSString* const kNTINavigationPropertyIcon = @"userData";
NSString* const kNTINavigationPropertyRoot = @"root";
NSString* const kNTINavigationPropertyOverrideRoot = @"overrideRoot";

@implementation NTINavigationItem
@synthesize name = _name;
@synthesize children;
@synthesize href;
@synthesize icon = _icon, ntiid = _ntiid;
@synthesize relativeSize;
@synthesize related;

+(id)itemWithItem: (NTINavigationItem*)item
			 href: (NSString*)href
{
	NTINavigationItem* newItem = [[[NTINavigationItem alloc]
								   initWithName: [item name] 
								   href: href
								   icon: [item icon]
								   ntiid: [item ntiid]
								   relativeSize: [item relativeSize]]
								  autorelease];
	[newItem->children addObjectsFromArray: item.children];
	newItem->properties = [item->properties copy];
	return newItem;
}

-(id)initWithName: (NSString*)name 
			 href: (NSString*)ref
			 icon: (NSString*)icon
			ntiid: (NSString*)ntiid
	 relativeSize: (NSInteger)size
{
	self = [super init];
	_name = [name retain];
	children = [[NSMutableArray alloc] init];
	href = [(ref ? ref : @"index.html") retain];
	_icon = [icon retain];
	_ntiid = [ntiid retain];
	relativeSize = size;
	return self;
}

- (NSUInteger)count
{
	return [children count];
}

-(NSInteger)recursiveRelativeSize
{
	NSInteger result = MAX( self.relativeSize, 0 );
	for( NTINavigationItem* kid in children ) {
		result += kid.recursiveRelativeSize;
	}
	return result;
}

-(NTINavigationItem*)addChildNamed: (NSString*)name 
							  href: (NSString*)ref 
							  icon: (NSString*)icon
							 ntiid: (NSString*)ntiid
					  relativeSize: (NSInteger)size
{
	NTINavigationItem* child = [[[NTINavigationItem alloc] 
								 initWithName: name
								 href: ref
								 icon: icon
								 ntiid: ntiid
								 relativeSize: size] autorelease];
	[self adoptChild: child];
	return child;
}

-(void)adoptChild: (NTINavigationItem*)child
{
	[children addObject: child];
	child->nr_parent = self;
}

-(id)adoptChild: (NTINavigationItem*)child replacingIndex: (NSUInteger)ix
{
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex: ix];
	[self willChange: NSKeyValueChangeReplacement
	 valuesAtIndexes: indexSet
			  forKey: @"children"];
	
	[children replaceObjectAtIndex: ix withObject: child];
	child->nr_parent = self;
	
	[self didChange: NSKeyValueChangeReplacement
	 valuesAtIndexes: indexSet
			  forKey: @"children"];
	
	return self;
}

-(NTINavigationItem*)parent
{
	return self->nr_parent;
}

-(NTINavigationItem*)nextSibling
{
	NTINavigationItem* result = nil;
	
	NSArray* parentsKids = self.parent.children;
	NSUInteger myIx = [parentsKids indexOfObjectIdenticalTo: self];
	//Stupid unsigned ints overflow to positive 
	if( myIx != NSNotFound ) {
		NSUInteger parentSize = parentsKids.count;
		//Make sure an object after me
		if( parentSize >= 2 && myIx <= parentSize - 2 ) {
			result = [parentsKids objectAtIndex: myIx + 1];
		}
	}
	return result;
}

-(NTINavigationItem*)previousSibling
{
	NTINavigationItem* result = nil;
	
	NSArray* parentsKids = self.parent.children;
	NSUInteger myIx = [parentsKids indexOfObjectIdenticalTo: self];
	if( myIx != NSNotFound && myIx >= 1 ) {
		result = [parentsKids objectAtIndex: myIx - 1];
	}
	return result;
}


-(NSArray*)pathToProperty: (NSString*)prop withValue: (NSString*)value
{
	if( [[self valueForKey: prop] isEqual: value] ) {
		return [NSMutableArray arrayWithObject: self];
	}
	for( NTINavigationItem* child in children ) {
		id path = [child pathToProperty: prop withValue: value];
		if( path != nil ) {
			[path addObject: self];
			//If we're the root we have to reverse
			if( !self->nr_parent ) {
				path = [[path reverseObjectEnumerator] allObjects];
			}
			return path;
		}
	}
	//Notice we don't consider the relateds since they don't figure in the tree
	return nil;

}

-(NSArray*)pathToHref: (NSString*)theHref
{
	return [self pathToProperty: @"href" withValue: theHref];
}

-(NSArray*)pathToID: (NSString*)theNTIID
{
	return [self pathToProperty: @"ntiid" withValue: theNTIID];
}

-(void)setRelatedNavigationItems: (NSArray*)relatedNavItems
{
	NSArray* newItems = [relatedNavItems copy];
	NTI_RELEASE( self->related );
	self->related = newItems;
}

-(void)setObject:(id)object forKey:(id)key recursive: (BOOL)recursive
{
	[self setObject: object forKey: key];
	if( recursive ) {
		for( id child in self->children ) {
			[child setObject: object forKey: key recursive: YES];
		}
		//We do copy these properties in since they tend to be global and that
		//helps us
		for( id child in self->related ) {
			[child setObject: object forKey: key recursive: YES];
		}
	}
}

-(void)setObject:(id)object forKey:(id)key
{
	if( object == nil ) {
		[self->properties removeObjectForKey: key];
	}
	else {
		if( !self->properties ) {
			[self willChangeValueForKey: @"properties"];
			self->properties = [[NSMutableDictionary alloc] initWithCapacity: 3];
			[self didChangeValueForKey: @"properties"];
		}
		[self->properties setObject: object forKey: key];
	}
}

-(id)objectForKey:(id)key
{
	return [self->properties objectForKey: key];
}

-(NSString*)description
{
	return [NSString stringWithFormat: @"<topic label='%@' ntiid='%@' href='%@' icon='%@' children='%d'/>",
			_name, _ntiid, href, _icon, [children count]];
}

-(void)dealloc
{
	NTI_RELEASE( self->properties );
	NTI_RELEASE( self->_name );
	NTI_RELEASE( self->children );
	NTI_RELEASE( self->href );
	NTI_RELEASE( self->_icon );
	NTI_RELEASE( self->_ntiid );
	NTI_RELEASE( self->related );	
	
	[super dealloc];
}

@end

@implementation NTIRelatedNavigationItem
@synthesize type, qualifier;

-(id)initWithName: (NSString*)name
			 href: (NSString*)h
			 icon: (NSString*)icon
			ntiid: (NSString*)n
	 relativeSize: (NSInteger)size
	  relatedType: (NSString*)relatedType 
 relatedQualifier: (NSString*)relatedQualifier
{
	self = [super initWithName: name
						  href: h
						  icon: icon
						 ntiid: n
				  relativeSize: 0];
	self->type = [relatedType copy];
	self->qualifier = [relatedQualifier copy];
	return self;
}

-(void) dealloc
{
	NTI_RELEASE( self->type );
	NTI_RELEASE( self->qualifier );
	[super dealloc];
}

@end



@implementation NTINavigationParser

- (NTINavigationParser*) initWithContentsOfURL: (NSURL*)url
{
	return [self initWithContentsOfURL: url hrefPrefix: @""];
}

- (NTINavigationParser*) initWithContentsOfURL: (NSURL*)url hrefPrefix: (NSString*)pfx
{
	if( (self = [super init]) ) {
		NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL: url];
		self->hrefPrefix = [pfx retain];
		[parser setDelegate: self];
		[parser parse];
		[parser release];
	}
	return self;
}

static NSInteger size( id dict )
{
	NSInteger result;
	id val = [dict objectForKey: @"NTIRelativeScrollHeight"];
	if( val ) {
		result = [val integerValue];
	}
	else {
		result = -1;
	}
	return result;
}

static NSString* href( NTINavigationParser* self, NSDictionary* dict )
{
	NSString* href = [dict objectForKey: @"href"];
	if( self->hrefPrefix ) {
		href = [self->hrefPrefix stringByAppendingPathComponent: href];
	}
	return href;
}

#define kRelatedTmp @"Related"

- (void)parser: (NSXMLParser*)parser 
didStartElement: (NSString*)elementName 
  namespaceURI: (NSString*)namespaceURI
 qualifiedName: (NSString*)qName
	attributes: (NSDictionary*)attributeDict
{
	if( [elementName isEqualToString: @"toc"] || [elementName isEqualToString: @"topic"] ) {
		if( root == nil ) {
			nr_current = root = [[NTINavigationItem alloc] 
							  initWithName: [attributeDict objectForKey: @"label"]
							  href: href( self, attributeDict )
							  icon: [attributeDict objectForKey: @"icon"]
							  ntiid: [attributeDict objectForKey: @"ntiid"]
							  relativeSize: size( attributeDict ) ];
		}
		else {
			nr_current = [nr_current addChildNamed: [attributeDict objectForKey: @"label"]
										href: href( self, attributeDict )
										icon: [attributeDict objectForKey: @"icon"]
									   ntiid: [attributeDict objectForKey: @"ntiid"]
								relativeSize: size( attributeDict )];
		}
		NSMutableArray* destinations = [[[NSMutableArray alloc] init] autorelease];
		[nr_current setObject: destinations forKey: kRelatedTmp];
	}
	else if( [elementName isEqualToString: @"page"] ) {
		NTIRelatedNavigationItem *related = [[[NTIRelatedNavigationItem alloc]
											  initWithName: nil
											  href: nil
											  icon: nil
											  ntiid: [attributeDict objectForKey: @"ntiid"]
											  relativeSize: 0
											  relatedType: [attributeDict objectForKey: @"type"]
											  relatedQualifier: [attributeDict objectForKey: @"qualifier"]]
											   autorelease];
		
		[[nr_current objectForKey: kRelatedTmp] addObject: related];
		related->nr_parent = nr_current;
	}
	else if( [elementName isEqualToString: @"video"] ) {
		NTIRelatedNavigationItem* related = [[[NTIRelatedNavigationItem alloc]
											  initWithName: [attributeDict objectForKey: @"title"]
											  href: href( self, attributeDict )
											  icon: [attributeDict objectForKey: @"icon"]
											  ntiid: href( self, attributeDict )
											  relativeSize: 0
											  relatedType: @"video"
											  relatedQualifier: [attributeDict objectForKey: @"qualifier"]]
											 autorelease];
		[[nr_current objectForKey: kRelatedTmp] addObject: related];
		related->nr_parent = nr_current;	
	}
	
}

-(void)parser: (NSXMLParser*)parser
didEndElement: (NSString*) elementName
 namespaceURI: (NSString*)namespaceURI
qualifiedName: (NSString*)qName
{	
	if( [elementName isEqualToString: @"toc"] || [elementName isEqualToString: @"topic"] ) {
		[nr_current setRelatedNavigationItems: [nr_current objectForKey: kRelatedTmp]];
		[nr_current setObject: nil forKey: kRelatedTmp];
		nr_current = [nr_current parent];
	}
}

- (NTINavigationItem*) root
{
	return root;
}

-(void)dealloc
{
	NTI_RELEASE( self->hrefPrefix );
	NTI_RELEASE( self->root );

	[super dealloc];
}

@end

#pragma mark Fetching navigation

static id fetchNavIcon( NSURL* rootUrl, NTINavigationItem* navItem )
{
	if( ![navItem icon] ) {
		return [UIImage imageNamed: @"Content-Yellow.mini.png"];
	}
	
	NSData* data = [NSData dataWithContentsOfURL:
					[NSURL URLWithString: [navItem icon]
						   relativeToURL: rootUrl]];
	id result = nil;
	if( data ) {
		result = [UIImage imageWithData: data];
		//[data release];
	}
	
	return result;
}

static void fetchAllNavIcons( NSURL* rootUrl, NTINavigationItem* navItem )
{
	[navItem setObject: fetchNavIcon( rootUrl, navItem ) forKey: @"userData"];
	for( NTINavigationItem* item in [navItem children] ) {
		fetchAllNavIcons( rootUrl, item );
	}
	for( NTINavigationItem* item in navItem.related ) {
		fetchAllNavIcons( rootUrl, item );
	}
}


@implementation NTINavigationParserLoader

+(NTINavigationItem*)prepareForNavigation: (NTINavigationItem*)item rootURL: (NSURL*)url
{
	fetchAllNavIcons( url, item );
	return item;
}

+(void) loadFromString: (NSString*)string
		 relativeToURL: (NSURL*)url
			hrefPrefix: (NSString*)prefix
			  callback: (void(^)(NTINavigationParser*)) callback
{
	[self loadFromString: string 
		   relativeToURL: url
			  hrefPrefix: prefix
				callback: callback
				   queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

+(void) loadFromString: (NSString*)string
		 relativeToURL: (NSURL*)url
			hrefPrefix: (NSString*)prefix
			  callback: (void(^)(NTINavigationParser*)) callback
				 queue: (dispatch_queue_t)queue
{
	callback = [callback copy];
	dispatch_async( queue, ^{	
		NSURL* rootURL = [NSURL URLWithString: string
								relativeToURL: url ];
		id navigationData = [[NTINavigationParser alloc] 
							 initWithContentsOfURL: rootURL
							 hrefPrefix: prefix ];
		
		[NTINavigationParserLoader prepareForNavigation: [navigationData root] rootURL: rootURL];
		if( callback ) {
			callback( navigationData );
			[callback release];
		}
		[navigationData release];
		
	});

}
@end


