//
//  NTIAppNavigationLayerSwitcher.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/25/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIAppNavigationLayerSwitcher.h"
#import "NTIBadgeView.h"

static NSString* keyPathForChangeCount(id layer)
{
	NSString* keyPath = nil;
	
	if( [layer respondsToSelector: @selector(backgroundChangeCountKeyPath)] ){
		keyPath = [layer backgroundChangeCountKeyPath];
	}
	
	return keyPath;
}

@interface _NTIMovableLayers : UITableViewController<UITableViewDelegate, UITableViewDataSource> {
@private
    NSArray* movableLayers;
	NTIAppNavigationLayerSwitcher* __weak nr_switcher;
}
-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
-(void)updateTabBarBadge;
@end

@implementation _NTIMovableLayers

-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
{
	self = [super initWithStyle: UITableViewStyleGrouped];
	self->nr_switcher = switcher;
	self->movableLayers = [[self->nr_switcher layersThatCanBeBroughtForwardForSwitcher: nil] reversedArray];
	
	self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem: UITabBarSystemItemRecents 
																 tag: 0];
	
	[self updateTabBarBadge];
	
	//We kvo on each provider so if the popup is over we can see updates
	for(id layer in self->movableLayers){
		NSString* kp = keyPathForChangeCount( layer );
		if( kp ){
			[layer addObserver: self
					forKeyPath: kp
					   options: NSKeyValueObservingOptionNew
					   context: NULL];
		}
	}
	
	return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{	
	NSUInteger idx = [self->movableLayers indexOfObject: object];
	if(idx != NSNotFound){
		[self.tableView reloadRowsAtIndexPaths: [NSArray arrayWithObject: 
													[NSIndexPath indexPathForRow: idx inSection: 0]] 
								withRowAnimation: UITableViewRowAnimationAutomatic];
		[self updateTabBarBadge];
	}
}


-(void)updateTabBarBadge
{
	NSUInteger count = 0;
	for(id layer in self->movableLayers){
		NSString* changeKP = keyPathForChangeCount( layer );
		if(changeKP){
			count += [[(id)layer valueForKeyPath: changeKP] integerValue];
		}
	}
	if(count > 0){
		self.tabBarItem.badgeValue = [NSString stringWithFormat: @"%lu", (unsigned long)count];
	}
	else{
		self.tabBarItem.badgeValue = nil;
	}
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Recent Layers";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self->movableLayers.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * const CellIdentifier = @"MovableLayersSwitcher";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    
	id<NTIAppNavigationLayer> layer = [self->movableLayers objectAtIndex: indexPath.row];
	//FIXME ick passing nil here
	if( [layer respondsToSelector: @selector(titleForRecentLayerList)] ){
		cell.textLabel.text = [layer titleForRecentLayerList];
	}
	else if( [layer respondsToSelector: @selector(titleForAppNavigationController:)] ){
		cell.textLabel.text = [layer titleForAppNavigationController: nil];
	}
	
	if( [layer respondsToSelector: @selector(imageForRecentLayerList)] ){
		cell.imageView.image = [layer imageForRecentLayerList];
	}
	
	NSString* changeKP = keyPathForChangeCount( layer );
	NSInteger count = 0;
	if(changeKP){
		count = [[(id)layer valueForKeyPath: changeKP] integerValue];
	}
	
	if(count > 0){
		NTIBadgeView* badgeView = [[NTIBadgeView alloc] initWithFrame: CGRectMake(0, 0, 25, 25)]; //TODO do we need to set the size?
		badgeView.badgeText = [NSString stringWithFormat: @"%lu", (unsigned long)count];
		cell.accessoryView = badgeView;
		
	}
	else{
		cell.accessoryView = nil;
	}
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	[self->nr_switcher switcher: nil bringLayerForward: [self->movableLayers objectAtIndex: indexPath.row]];
}

-(void)dealloc
{
	for(id layer in self->movableLayers){
		NSString* kp = keyPathForChangeCount( layer );
		if( kp ){
			[layer removeObserver: self forKeyPath: kp];
		}
	}
}

@end

@interface _NTIAvailableAppLayers : UITableViewController<UITableViewDelegate, UITableViewDataSource> {
@private
    NSArray* layerProviders;
	NTIAppNavigationLayerSwitcher* __weak nr_switcher;
}
-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
-(void)updateTabBarBadge;
@end


@implementation _NTIAvailableAppLayers

-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
{
	self = [super initWithStyle: UITableViewStyleGrouped];
	self->nr_switcher = switcher;
	self->layerProviders = [[self->nr_switcher layerProvidersForSwitcher: nil] copy];
	
	self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem: UITabBarSystemItemFavorites 
																 tag: 0];
	
	[self updateTabBarBadge];
	
	//We kvo on each provider so if the popup is over we can see updates
	for(id provider in self->layerProviders){
		[provider addObserver: self
				   forKeyPath: @"layerDescriptors"
					  options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
					  context: NULL];
	}
	
	return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(OFISEQUAL(keyPath, @"layerDescriptors")){
		NSKeyValueChange changeKind = [[change objectForKey: NSKeyValueChangeKindKey] intValue];
		NSUInteger sectionOfChange = [self->layerProviders indexOfObjectIdenticalTo: object];
		
		OBASSERT(sectionOfChange != NSNotFound);
		
		if( changeKind == NSKeyValueChangeInsertion ) {
			NSIndexSet* newIndexes = [change objectForKey: NSKeyValueChangeIndexesKey];
			NSMutableArray* indexPathsToInsert = [NSMutableArray arrayWithCapacity: newIndexes.count];
			[newIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
				[indexPathsToInsert addObject:[NSIndexPath indexPathForRow: index inSection: sectionOfChange]];
			}];
			[self.tableView insertRowsAtIndexPaths: indexPathsToInsert withRowAnimation: UITableViewRowAnimationAutomatic];
		}
		else if( changeKind == NSKeyValueChangeRemoval ) {
			NSIndexSet* removedIndexes = [change objectForKey: NSKeyValueChangeIndexesKey];
			NSMutableArray* indexPathsToRemove = [NSMutableArray arrayWithCapacity: removedIndexes.count];
			[removedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
				[indexPathsToRemove addObject:[NSIndexPath indexPathForRow: index inSection: sectionOfChange]];
			}];
			[self.tableView deleteRowsAtIndexPaths: indexPathsToRemove withRowAnimation: UITableViewRowAnimationAutomatic];
		}
		else if( changeKind == NSKeyValueChangeReplacement ) {
			NSIndexSet* updatedIndexes = [change objectForKey: NSKeyValueChangeIndexesKey];
			NSMutableArray* indexPathsToUpdate = [NSMutableArray arrayWithCapacity: updatedIndexes.count];
			[updatedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
				[indexPathsToUpdate addObject:[NSIndexPath indexPathForRow: index inSection: sectionOfChange]];
			}];
			[self.tableView reloadRowsAtIndexPaths: indexPathsToUpdate withRowAnimation: UITableViewRowAnimationAutomatic];	
		}
	}
	[self updateTabBarBadge];

}

-(void)updateTabBarBadge
{
	NSUInteger count = 0;
	for(id<NTIAppNavigationLayerProvider> provider in self->layerProviders){
		for(id layer in provider.layerDescriptors){
			NSString* changeKP = keyPathForChangeCount( layer );
			if(changeKP){
				count += [[(id)layer valueForKeyPath: changeKP] integerValue];
			}
		}
	}
	if(count > 0){
		self.tabBarItem.badgeValue = [NSString stringWithFormat: @"%ld", (unsigned long)count];
	}
	else{
		self.tabBarItem.badgeValue = nil;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self->layerProviders.count;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[self->layerProviders objectAtIndex: section] layerProviderName];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[[self->layerProviders objectAtIndex: section] layerDescriptors] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * const CellIdentifier = @"AppLayerSwitcher";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    
	id<NTIAppNavigationLayerDescriptor> descriptor = [[[self->layerProviders objectAtIndex: indexPath.section] layerDescriptors] objectAtIndex: indexPath.row];
	cell.textLabel.text = descriptor.title;
	cell.imageView.image = descriptor.image;
	
	NSString* changeKP = keyPathForChangeCount( descriptor );
	NSInteger count = 0;
	if(changeKP){
		count = [[(id)descriptor valueForKeyPath: changeKP] integerValue];
	}
	if(count > 0){
		NTIBadgeView* badge = [[NTIBadgeView alloc] initWithFrame: CGRectMake(0, 0, 25, 25)]; //TODO do we need to set the size?
		badge.badgeText = [NSString stringWithFormat: @"%lu", (unsigned long) count];
		cell.accessoryView  = badge;
	}
	else{
		cell.accessoryView = nil;
	}
	
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	id<NTIAppNavigationLayerDescriptor> descriptor = [[[self->layerProviders objectAtIndex: indexPath.section] layerDescriptors] objectAtIndex: indexPath.row];
	[self->nr_switcher switcher: nil showLayer: descriptor];
}

-(void)dealloc
{
	for(id provider in self->layerProviders){
		[provider removeObserver: self forKeyPath: @"layerDescriptors"];
	}
}

@end

@implementation NTIAppNavigationLayerSwitcher

-(id)initWithDelegate: (id)delegate
{
	self = [super initWithNibName: nil bundle: nil];
	self->nr_delegate = delegate;
	_NTIAvailableAppLayers* controller = [[_NTIAvailableAppLayers alloc] 
										  initWithSwitcher: self];
	_NTIMovableLayers* movableLayers = [[_NTIMovableLayers alloc] initWithSwitcher: self];
	self.viewControllers = [NSArray arrayWithObjects: controller, movableLayers, nil];
	
	return self;
}

-(NSArray*)layerProvidersForSwitcher: (NTIAppNavigationLayerSwitcher*)_
{
	return [self->nr_delegate layerProvidersForSwitcher: self];
}

-(NSArray*)layersThatCanBeBroughtForwardForSwitcher: (NTIAppNavigationLayerSwitcher*)_
{
	return [self->nr_delegate layersThatCanBeBroughtForwardForSwitcher: self];
}

-(void)switcher: (NTIAppNavigationLayerSwitcher*)_ bringLayerForward: (id<NTIAppNavigationLayer>)layer
{
	[self->nr_delegate switcher: self bringLayerForward: layer];
}

-(void)switcher: (NTIAppNavigationLayerSwitcher*)switcher showLayer: (id<NTIAppNavigationLayerDescriptor>)layerDescriptor;
{
	[self->nr_delegate switcher: self showLayer: layerDescriptor];
}

@end
