//
//  NTIAppNavigationLayerSwitcher.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/25/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIAppNavigationLayerSwitcher.h"

@interface _NTIAvailableAppLayers : UITableViewController<UITableViewDelegate, UITableViewDataSource> {
@private
    NSArray* layerFactories;
	NTIAppNavigationLayerSwitcher* __weak nr_switcher;
}
-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
@end

@implementation _NTIAvailableAppLayers

-(id)initWithSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
{
	self = [super initWithStyle: UITableViewStylePlain];
	self->nr_switcher = switcher;
	self->layerFactories = [self->nr_switcher layerFactoriesForSwitcher: nil];
	
	self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem: UITabBarSystemItemFavorites 
																 tag: 0];
	
	return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self->layerFactories.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * const CellIdentifier = @"AppLayerSwitcher";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    
	NTIAppNavigationAppLayerFactory* layerFactory = [self->layerFactories objectAtIndex: indexPath.row];
	cell.textLabel.text = layerFactory.title;
	
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	[self->nr_switcher switcher: nil showAppLayer: [self->layerFactories objectAtIndex: indexPath.row]];
}

@end

@implementation NTIAppNavigationLayerSwitcher

-(id)initWithDelegate: (id)delegate
{
	self = [super initWithNibName: nil bundle: nil];
	self->nr_delegate = delegate;
	_NTIAvailableAppLayers* controller = [[_NTIAvailableAppLayers alloc] 
										  initWithSwitcher: self];
	self.viewControllers = [NSArray arrayWithObjects: controller, nil];
	
	return self;
}

-(NSArray*)layerFactoriesForSwitcher: (NTIAppNavigationLayerSwitcher*)_
{
	return [self->nr_delegate layerFactoriesForSwitcher: self];
}

-(NSArray*)layersThatCanBeBroughtForwardForSwitcher: (NTIAppNavigationLayerSwitcher*)_
{
	return [self->nr_delegate layersThatCanBeBroughtForwardForSwitcher: self];
}

-(void)switcher: (NTIAppNavigationLayerSwitcher*)_ bringLayerForward: (id<NTIAppNavigationLayer>)layer
{
	[self->nr_delegate switcher: self bringLayerForward: layer];
}

-(void)switcher: (NTIAppNavigationLayerSwitcher*)_ showAppLayer: (NTIAppNavigationAppLayerFactory*)appLayer
{
	[self->nr_delegate switcher: self showAppLayer: appLayer];
}

@end
