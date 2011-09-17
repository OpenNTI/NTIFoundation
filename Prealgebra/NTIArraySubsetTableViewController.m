//
//  NTIArraySubsetTableViewController.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/10.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIArraySubsetTableViewController.h"
#import "NTIUtilities.h"
#import "NSString-NTIExtensions.h"
#import "NSArray-NTIExtensions.h"
#import "NTIDraggableTableViewCell.h"

@implementation NTIArraySubsetTableViewController

@synthesize delegate, predicate;
@synthesize miniViewHidden, miniViewCollapsed;
@synthesize collapseWhenEmpty;

-(id)initWithAllObjects: (NSArray*)array
{
	return [self initWithStyle: UITableViewStylePlain allObjects: array];	
}

-(id)initWithStyle: (UITableViewStyle)style
{
	return [self initWithStyle: style allObjects: [NSArray array]];	
}

-(id)initWithStyle: (UITableViewStyle)style
		allObjects: (NSArray*)theSourceArray
{
	self = [super initWithStyle: UITableViewStylePlain];
	self->sourceArray = [[NSMutableArray arrayWithArray: theSourceArray] retain];
	self->filteredSubset = [self->sourceArray mutableCopy];
	self->searchString = nil;
	return self;
}

-(CGFloat)miniViewHeight
{
	return 209;
}

-(void)markObject: (id)target 
	withCheckmark: (BOOL)yesOrNo
{
	NSInteger index = [self->sourceArray indexOfObjectIdenticalTo: target];
	
	if( index != NSNotFound ) {
		
		NSIndexPath* path = [NSIndexPath indexPathForRow: index inSection: 0];
		
		[self.tableView cellForRowAtIndexPath: path].accessoryType
			= yesOrNo
			? UITableViewCellAccessoryCheckmark
			: UITableViewCellAccessoryNone;
	}
}

#pragma mark -
#pragma mark Search

-(BOOL)doesObject: (id)target matchString: (NSString*)string
{
	if( [NSString isEmptyString: string] || !self.predicate ) {
		return YES;
	}
	
	return [self.predicate evaluateWithObject: target
						substitutionVariables: [NSDictionary dictionaryWithObject: string forKey: @"VALUE"]];
}


-(void)sortUsingDescriptors: (NSArray*)array
{
	[self->sourceArray sortUsingDescriptors: array];
	[self->filteredSubset sortUsingDescriptors: array];
}

-(NSArray*)subset: (id)me filterSource: (NSArray*)array;
{
	if( [delegate respondsToSelector: _cmd] && !self->inDelegate ) {
		@try {
			self->inDelegate = YES;
			return [delegate subset: me filterSource: array];
		}
		@finally {
			self->inDelegate = NO;
		}
	}
	
	NSArray* newData = [array select: ^BOOL(id obj)
	{
		return [self doesObject: obj
					matchString: self->searchString];
	}];
	return newData;
}

-(void)subset: (id)me performSearchWithString: (NSString*)theSearchString
{
	if( [delegate respondsToSelector: _cmd] ) {
		[delegate subset: me performSearchWithString: theSearchString];	
	}
	else {
		[self setFilteredSubset: [self subset: self filterSource: self->sourceArray]
				 andReloadTable: YES];
	}
	
}

-(void)subset: (id)me filterWithString: (NSString*)search
{

	[search retain];
	NTI_RELEASE(self->searchString);
	self->searchString = search;
	[self subset: me performSearchWithString: self->searchString];

}

-(void)searchBar: (UISearchBar*)searchBar textDidChange: (NSString*)searchText
{
	NSString* trimmed = [searchText stringByTrimmingCharactersInSet: 
						 [NSCharacterSet whitespaceCharacterSet]];
	
	[self subset: self filterWithString: trimmed];
}

#pragma mark -
#pragma mark Data Manipulation

-(void)addToAllObjects: (NSArray*)incomingData
{
	[self->sourceArray addObjectsFromArray: incomingData];
	//update the filter
	[self setFilteredSubset: [self subset: self filterSource: self->sourceArray]
			 andReloadTable: NO];
	
}

-(void)setAllObjectsAndFilter: (NSArray*)newSourceArray reloadTable: (BOOL)reload
{
	//our own source array never escapes
	[self->sourceArray removeAllObjects];
	[self->sourceArray addObjectsFromArray: newSourceArray];
	[self setFilteredSubset: [self subset: self filterSource: self->sourceArray]
			 andReloadTable: reload];
}

-(void)clearAllObjects
{
	[self->filteredSubset removeAllObjects];
	[self->sourceArray removeAllObjects];
}

-(BOOL)setFilteredSubset: (NSArray*)newData andReloadTable: (BOOL)reload;
{
	BOOL result = NO;
	if( ! [self->filteredSubset isEqualToArray: newData] ) {
		newData = [newData mutableCopy];
		NTI_RELEASE(self->filteredSubset);
		self->filteredSubset = (id)newData;
		//NSLog(@"Reloading");
		if( reload ) {
			[self.tableView reloadData];
		}
		result = YES;
	}
	//Because of clearAllObjects, we need to do this outside of 
	//the array equals check.
	if(	self.collapseWhenEmpty && reload ) {
		//Be careful not to set the value unless it
		//changes to make it easier for KVO
		BOOL empty = [NSArray isEmptyArray: self->filteredSubset];
		if( 	empty
		   &&	!self.miniViewCollapsed ) {
			self.miniViewCollapsed = YES;
		}
		else if(	!empty
				&&	self.miniViewCollapsed ) {
			self.miniViewCollapsed = NO;		
		}
	}
	
	return result;
}

-(void)removeObjectAtIndexPath: (NSIndexPath*)path
{
	[self removeObject: [self objectForIndexPath: path]];	
}

#pragma mark -
#pragma mark Data Access

-(NSArray*)allObjects
{
	return [[self->sourceArray copy] autorelease];	
}

-(NSArray*)displayedObjects
{
	return [[self->filteredSubset copy] autorelease];	
}

-(id)objectForIndexPath: (NSIndexPath*)path
{
	return [self->filteredSubset objectAtIndex: path.row];	
}

-(NSIndexPath*)indexPathForObject: (id)object
{
	NSIndexPath* result = nil;
	NSUInteger ix = [self->filteredSubset indexOfObjectIdenticalTo: object];	
	if( ix != NSNotFound ) {
		result = [NSIndexPath indexPathForRow: ix inSection: 0];	
	}
	return result;
}


-(UITableViewCell*)cellForObject: (id)object
{
	id result = nil;
	NSUInteger ix = [self->filteredSubset indexOfObjectIdenticalTo: object];
	if( ix != NSNotFound ) {
		result = [self.tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: ix
																		   inSection: 0]];
	}
	return result;
}

#define forward(type,action,def) \
-(type)subset: (id)me action \
{\
type result = def; \
if( [self->delegate respondsToSelector: _cmd] ) { \
result = (type)[self->delegate subset: me action]; \
} \
return result; \
}

#define forward1(type,action,def) \
-(type)subset: (id)me action: (id)arg \
{\
type result = def; \
if( [self->delegate respondsToSelector: _cmd] ) { \
result = (type)[self->delegate subset: me action: arg]; \
} \
return result; \
}

forward1(UITableViewCellAccessoryType, accessoryTypeForObject, UITableViewCellAccessoryNone );
forward1(UITableViewCellStyle, styleForObject, UITableViewCellStyleSubtitle);

#undef forward
#undef forward1

-(BOOL)prependObject: (id)object
{
	if( [self->sourceArray indexOfObjectIdenticalTo: object] != NSNotFound ) {
		return NO;
	}
	BOOL result = NO;
	[self->sourceArray insertObject: object atIndex: 0];
	if( [self doesObject: object matchString: self->searchString] ) {
		[self->filteredSubset insertObject: object atIndex: 0];
		result = YES;
		
		[self.tableView beginUpdates];
		NSIndexPath* path = [NSIndexPath indexPathForRow: 0 inSection: 0];
		[self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: path]
							  withRowAnimation: UITableViewRowAnimationTop];
		[self.tableView endUpdates];
	}
	return result;
}

-(BOOL)removeObject: (id)object
{
	BOOL result = NO;
	if( [self->sourceArray indexOfObjectIdenticalTo: object] != NSNotFound ) {
		[self->sourceArray removeObjectIdenticalTo: object];
		NSUInteger ix = [self->filteredSubset indexOfObjectIdenticalTo: object];
		result = ix != NSNotFound;
		if( result ) {
			[self->filteredSubset removeObjectAtIndex: ix];
			[self.tableView beginUpdates];
			NSIndexPath* path = [NSIndexPath indexPathForRow: ix inSection: 0];
			[self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: path]
								  withRowAnimation: UITableViewRowAnimationTop];
			[self.tableView endUpdates];
		}
	}
	return result;
}

-(void)updateObject: (id)object atIndexPath: (NSIndexPath*)path;
{
	id old = [self objectForIndexPath: path];
	NSUInteger sourceIx = [self->sourceArray indexOfObjectIdenticalTo: old];
	[self->sourceArray replaceObjectAtIndex: sourceIx withObject: object];
	[self->filteredSubset replaceObjectAtIndex: path.row withObject: object];
	
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: path]
						  withRowAnimation: UITableViewRowAnimationFade];
	[self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: path]
						  withRowAnimation: UITableViewRowAnimationFade];
	[self.tableView endUpdates];

}

-(BOOL)updateAccessoryTypeForObject: (id)object
{
	UITableViewCell* cell = [self cellForObject: object];
	cell.accessoryType = [self subset: self 
			   accessoryTypeForObject: object];
	return cell != nil;
}

-(void)subset: (id)me 
configureCell: (UITableViewCell*)cell
	forObject: (id)object
{
	if( [self->delegate respondsToSelector: _cmd] ) {
		[self->delegate subset: me configureCell: cell forObject: object];	
	}
}

-(void)subset: (id)me didSelectObject: (id)object
{
	if( [self->delegate respondsToSelector: _cmd] ) {
		[self->delegate subset: me didSelectObject: object];
	}
	else {
		[self updateAccessoryTypeForObject: object];
	}
}

-(void)tableView: (UITableView*)tableView didSelectRowAtIndexPath: (NSIndexPath*)indexPath
{
	id target = [self->filteredSubset objectAtIndex: indexPath.row];
	[self subset: self didSelectObject: target];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self->filteredSubset.count;
}

-(UITableViewCell*)tableView: (UITableView *)tableView 
	   cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
	static NSString* REUSE = @"NTISharingTargetCell";
	
	id target = [self objectForIndexPath: indexPath];
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: REUSE];
	if( !cell ) {
		cell = [[[NTIDraggableTableViewCell alloc] 
				 initWithStyle: [self subset: self styleForObject: target]
				 reuseIdentifier: REUSE] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.contentView.backgroundColor = [UIColor clearColor];
		cell.textLabel.adjustsFontSizeToFitWidth = YES;
		cell.textLabel.minimumFontSize = 8.0;
		if( cell.detailTextLabel ) {
			cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
			cell.detailTextLabel.minimumFontSize = 8.0;
		}
	}
	cell.accessoryType = [self subset: self accessoryTypeForObject: target];
	
	[self subset: self configureCell: cell forObject: target];
	return cell;
}



-(void)dealloc
{
	NTI_RELEASE(self->searchString);
	NTI_RELEASE(self->sourceArray);
	NTI_RELEASE(self->filteredSubset);
	self.delegate = nil;
	self.predicate = nil;
	[super dealloc];
}

@end
