//
//  NTIAppNavigationController.h
//  NTIFoundation
//
//  Created by Christopher Utz on 1/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NTIAppNavigationController;
@interface UIViewController(NTIAppNavigationControllerExtensions)
-(NTIAppNavigationController*)ntiAppNavigationController;
@end

@protocol NTIAppNavigationLayer <NSObject>

@optional
-(NSString*)textForAppNavigationControllerDownButton: (NTIAppNavigationController*)controller;
-(NSString*)titleForAppNavigationController: (NTIAppNavigationController*)controller;
@end

@protocol NTIAppNavigationApplicationLayer <NTIAppNavigationLayer>
@end

@protocol NTIAppNavigationTransientLayer <NTIAppNavigationLayer>
@end

@class NTIAppNavigationToolbar;
@interface NTIAppNavigationController : UIViewController{
	@private
	NSMutableArray* viewControllers;
	UINavigationController* navController;
	NTIAppNavigationToolbar* toolBar;
}

@property (nonatomic, readonly) NSArray* layers;

-(id)initWithRootLayer:(UIViewController<NTIAppNavigationApplicationLayer>*)rootViewController;
-(void)pushLayer: (UIViewController<NTIAppNavigationLayer>*)layer animated: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)popLayerAnimated: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)topLayer;
-(UIViewController<NTIAppNavigationApplicationLayer>*)topApplicationLayer;

@end
