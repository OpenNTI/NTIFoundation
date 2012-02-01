//
//  NTIAppNavigationLayerSwitcher.h
//  NTIFoundation
//
//  Created by Christopher Utz on 1/25/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTIAppNavigationController.h"
#import "NTIAppNavigationLayerDescriptor.h"

@protocol NTIAppNavigationLayer;
@class NTIAppNavigationLayerSwitcher;
@protocol NTIAppNavigationLayerSwitcherDelegate <NSObject>
-(NSArray*)layerProvidersForSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
-(NSArray*)layersThatCanBeBroughtForwardForSwitcher: (NTIAppNavigationLayerSwitcher*)switcher;
-(void)switcher: (NTIAppNavigationLayerSwitcher*)switcher bringLayerForward: (id<NTIAppNavigationLayer>)layer;
-(void)switcher: (NTIAppNavigationLayerSwitcher*)switcher showLayer: (id<NTIAppNavigationLayerDescriptor>)layerDescriptor;
@end

//A tab bar controller that is shown when the layer switch is tapped.
//We show two tabs.  The first is a way to select app layers regardless of whether
//or not they exist in the vc stack anywhere. The second is a way to bring views that are
//already in the stack to the front.
@interface NTIAppNavigationLayerSwitcher : UITabBarController<NTIAppNavigationLayerSwitcherDelegate>
{
	id<NTIAppNavigationLayerSwitcherDelegate> __weak nr_delegate;
}
-(id)initWithDelegate: (id<NTIAppNavigationLayerSwitcherDelegate>)delegate;
@end
