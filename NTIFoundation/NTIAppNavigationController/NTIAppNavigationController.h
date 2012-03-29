//
//  NTIAppNavigationController.h
//  NTIFoundation
//
//  Created by Christopher Utz on 1/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniUI/OUIInspectorDelegate.h"
#import "NTIAppNavigationLayer.h"
#import "NTIAppNavigationLayerProvider.h"
#import "NTIGlobalInspector.h"
#import "NTIGlobalInspectorMainPane.h"

@class NTIAppNavigationController;
@interface UIViewController(NTIAppNavigationControllerExtensions)
-(NTIAppNavigationController*)ntiAppNavigationController;
@end

@class NTIAppNavigationController;
@protocol NTIAppNavigationControllerDelegate <NSObject>
@optional
-(NSArray*)appNavigationController: (NTIAppNavigationController*)controller 
				   globalInspector: (NTIGlobalInspector*)inspector 
makeAvailableSlicesForStackedSlicesPane: (OUIStackedSlicesInspectorPane*)pane;
-(NSSet*)appNavigationControllerInspectableObjects: (NTIAppNavigationController*)controller;
-(NSArray*)appNavigationControllerAdditionalToolbarButtons:(NTIAppNavigationController *)controller;
-(void)appNavigationController: (NTIAppNavigationController*)controller 
		  switcherDidShowLayer: (id<NTIAppNavigationLayer>)layer
				fromDescriptor: (id<NTIAppNavigationLayerDescriptor>)desc
			   layerWasCreated: (BOOL)created;
@end

@class NTIGlobalInspector;
@class NTIAppNavigationToolbar;
@interface NTIAppNavigationController : OUIViewController<OUIInspectorDelegate, UIActionSheetDelegate, UITabBarControllerDelegate>{
	@private
	UISplitViewController* splitViewController;
	
	NSMutableArray* viewControllers;
	UINavigationController* navController;
	NTIAppNavigationToolbar* toolBar;
	id __weak nr_delegate;
	UIPopoverController* popController;
	
	NTIGlobalInspector* inspector;
	
	NSMutableArray* layerProviders;
	
	//Destructive warning action sheet
	UIActionSheet* destructivePopActionSheet;
	
	//Track the tab on the switch
	NSUInteger activeLayerSwitcherTabIndex;
}
@property (nonatomic, weak) id delegate;
@property (nonatomic, readonly) NSArray* layers;
@property (nonatomic, readonly) UIViewController<NTIAppNavigationLayer>* topLayer;
@property (nonatomic, readonly) UIViewController<NTIAppNavigationApplicationLayer>* topApplicationLayer;

-(id)initWithRootLayer:(UIViewController<NTIAppNavigationApplicationLayer>*)rootViewController 
accessoryViewController: (UIViewController*)aVC;

-(void)pushLayer: (UIViewController<NTIAppNavigationLayer>*)layer animated: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)popLayerAnimated: (BOOL)animated;

-(void)presentLayerForDescriptor: (id<NTIAppNavigationLayerDescriptor>)descriptor;
-(void)presentLayerForDescriptor: (id<NTIAppNavigationLayerDescriptor>)descriptor animated: (BOOL)animated;

-(void)registerLayerProvider: (id<NTIAppNavigationLayerProvider>)layerProvider;
-(void)unregisterLayerProvider: (id<NTIAppNavigationLayerProvider>)layerProvider;

@end
