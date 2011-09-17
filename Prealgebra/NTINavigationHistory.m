//
//  NTINavigationHistory.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/07.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTINavigationHistory.h"
#import "NTINavigationParser.h"
#import "NTIUtilities.h"
#import "NSMutableArray-NTIExtensions.h"

@implementation NTINavigationHistoryItem

@synthesize navigationItem;

-(id) initWithItem: (NTINavigationItem*)item
{
	self = [super init];
	self->navigationItem = [item retain];
	return self;
}

-(BOOL)isEqual: (id)object
{
	return	[object isKindOfClass: [NTINavigationHistoryItem class]]
		&&	(self->navigationItem == ((NTINavigationHistoryItem*)object)->navigationItem
			 || [self.navigationItem isEqual: [object navigationItem]]);
}

-(NSString*)description
{
	return [NSString stringWithFormat: @"<%@ name='%@' href='%@'>",
			[self class], self.name, self.navigationItem];
}

-(id)name
{
	return [self.navigationItem name];	
}

-(id)href
{
	return [self.navigationItem href];
}

-(void)dealloc
{
	NTI_RELEASE( self->navigationItem );
	[super dealloc];
}
@end

@implementation NTINavigationHistory

-(id)init
{
	self = [super init];
	backHistory = [[NSMutableArray alloc] init];
	forwardHistory = [[NSMutableArray alloc] init];
	return self;
}

-(id)pushItem: (NTINavigationItem*)navItem 
		   to: (NSMutableArray*)array
		empty: (NSString*)emptyKey
		depth: (NSString*)depthKey
{
	id item = [[[NTINavigationHistoryItem alloc]
				initWithItem: navItem] autorelease];	
	
	if( ![NSArray isEmptyArray: array] && [item isEqual: [array lastObject]] ) {
		return nil;
	}
	
	if( [NSArray isEmptyArray: array] ) {
		[self willChangeValueForKey: emptyKey];
	}
	[self willChangeValueForKey: depthKey];
	[array addObject: item];
	[self didChangeValueForKey: depthKey];
	
	if( [array count] == 1 ) {
		[self didChangeValueForKey: emptyKey];
	}
	return item;
}

-(NTINavigationHistoryItem*)popItemFrom: (NSMutableArray*)array
								  empty: (id)emptyKey
								  depth: (id)depthKey
{
	if( [NSArray isEmptyArray: array] ) {
		return nil;
	}
	if( [array count] == 1 ) {
		[self willChangeValueForKey: emptyKey];
	}
	[self willChangeValueForKey: depthKey];
	id result = [array removeAndReturnLastObject];
	[self didChangeValueForKey: depthKey];
	if( [NSArray isEmptyArray: array] ) {
		[self didChangeValueForKey: emptyKey];
	}
	return result;
}


-(id)pushBackItem: (NTINavigationItem*)item
{
	return [self pushItem: item 
					   to: backHistory
					empty: @"backEmpty" 
					depth: @"backDepth"];
}


-(id)pushForwardItem: (NTINavigationItem*)item
{
	return [self pushItem: item 
					   to: forwardHistory
					empty: @"forwardEmpty"
					depth: @"forwardDepth"];
}

-(NTINavigationHistoryItem*)popBackItem
{
	return [self popItemFrom: backHistory empty: @"backEmpty" depth: @"backDepth"];
}

-(NTINavigationHistoryItem*)popForwardItem
{
	return [self popItemFrom: forwardHistory empty: @"forwardEmpty" depth: @"forwardDepth"];
}

-(NSArray*)backHistory
{
	return [[backHistory copy] autorelease];	
}

-(NSArray*)forwardHistory
{
	return [[forwardHistory copy] autorelease];	
}

-(BOOL)isBackEmpty
{
	return [NSArray isEmptyArray: backHistory];
}

-(NSInteger)backDepth
{
	return [backHistory count];	
}

-(BOOL)isForwardEmpty
{
	return [NSArray isEmptyArray: forwardHistory];
}

-(NSInteger)forwardDepth
{
	return [forwardHistory count];	
}

-(NSString*)description
{
	return [NSString stringWithFormat: @"<%@: %@ %@>", [self class], backHistory, forwardHistory];
}

@end
