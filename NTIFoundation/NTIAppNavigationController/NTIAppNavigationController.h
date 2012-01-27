//
//  NTIAppNavigationController.h
//  NTIFoundation
//
//  Created by Christopher Utz on 1/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniUI/OUIInspectorDelegate.h"

@class NTIAppNavigationController;
@interface UIViewController(NTIAppNavigationControllerExtensions)
-(NTIAppNavigationController*)ntiAppNavigationController;
@end

@protocol NTIAppNavigationLayer <NSObject>
@optional
//Messages for configuration of the title bar
-(NSString*)textForAppNavigationControllerDownButton: (NTIAppNavigationController*)controller;
-(NSString*)titleForAppNavigationController: (NTIAppNavigationController*)controller;
//Can this layer be moved to the front from somewhere down in the stack.
-(BOOL)canBringToFront;
@end

@protocol NTIAppNavigationApplicationLayer <NTIAppNavigationLayer>
@end

@protocol NTIAppNavigationTransientLayer <NTIAppNavigationLayer>
@end

@class NTIAppNavigationController;
@protocol NTIAppNavigationControllerDelegate <NSObject>
@optional
//Returns a list of layer factories that can be used to create app layers for the global layer switcher button
-(NSArray*)applicationLayerFactoriesForAppNavigationController: (NTIAppNavigationController*)appNavController;
@end
@class NTIGlobalInspector;
@class NTIAppNavigationToolbar;
@interface NTIAppNavigationController : UIViewController{
	@private
	NSMutableArray* viewControllers;
	UINavigationController* navController;
	NTIAppNavigationToolbar* toolBar;
	id __weak nr_delegate;
	UIPopoverController* popController;
	
	NTIGlobalInspector* inspector;
	id<OUIInspectorDelegate> inspectorDelegate;
}
@property (nonatomic, strong) id<OUIInspectorDelegate> inspectorDelegate;
@property (nonatomic, weak) id delegate;
@property (nonatomic, readonly) NSArray* layers;

-(id)initWithRootLayer:(UIViewController<NTIAppNavigationApplicationLayer>*)rootViewController;
-(void)pushLayer: (UIViewController<NTIAppNavigationLayer>*)layer animated: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)popLayerAnimated: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)topLayer;
-(UIViewController<NTIAppNavigationApplicationLayer>*)topApplicationLayer;

@end
