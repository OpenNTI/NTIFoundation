//
//  NTIAppNavigationLayerSwitcher.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/25/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIAppNavigationLayerSwitcher.h"

@interface _NTIMovableLayers : UITableViewController<UITableViewDelegate, UITableViewDataSource> {
@private
    NSArray* movableLayers;
	NTIAppNavigationLayerSwitcher* __weak nr_switcher;
}
-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
@end

@implementation _NTIMovableLayers

-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
{
	self = [super initWithStyle: UITableViewStylePlain];
	self->nr_switcher = switcher;
	self->movableLayers = [[self->nr_switcher layersThatCanBeBroughtForwardForSwitcher: nil] reversedArray];
	
	self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem: UITabBarSystemItemRecents 
																 tag: 0];
	
	return self;
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
	cell.textLabel.text = [layer titleForAppNavigationController: nil];
	
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	[self->nr_switcher switcher: nil bringLayerForward: [self->movableLayers objectAtIndex: indexPath.row]];
}

@end

@interface _NTIAvailableAppLayers : UITableViewController<UITableViewDelegate, UITableViewDataSource> {
@private
    NSArray* layerProviders;
	NTIAppNavigationLayerSwitcher* __weak nr_switcher;
}
-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
@end

@implementation _NTIAvailableAppLayers

-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
{
	self = [super initWithStyle: UITableViewStyleGrouped];
	self->nr_switcher = switcher;
	self->layerProviders = [[self->nr_switcher layerProvidersForSwitcher: nil] copy];
	
	self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem: UITabBarSystemItemFavorites 
																 tag: 0];
	
	return self;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
	//We kvo on each provider so if the popup is over we can see updates
	for(id provider in self->layerProviders){
		[provider addObserver: self
				   forKeyPath: @"layerDescriptors"
					  options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
					  context: NULL];
	}
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear: animated];
	for(id provider in self->layerProviders){
		[provider removeObserver: self forKeyPath: @"layerDescriptors"];
	}
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
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
	
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	id<NTIAppNavigationLayerDescriptor> descriptor = [[[self->layerProviders objectAtIndex: indexPath.section] layerDescriptors] objectAtIndex: indexPath.row];
	[self->nr_switcher switcher: nil showLayer: descriptor];
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
