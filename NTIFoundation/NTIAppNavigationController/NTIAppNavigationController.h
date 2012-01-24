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
@end

@protocol NTIAppNavigationApplicationLayer <NTIAppNavigationLayer>
@end

@protocol NTIAppNavigationTransientLayer <NTIAppNavigationLayer>
@end

@interface NTIAppNavigationController : UIViewController{
	@private
	NSMutableArray* viewControllers;
	UINavigationController* navController;
}

@property (nonatomic, readonly) NSArray* layers;

-(id)initWithRootLayer:(UIViewController<NTIAppNavigationApplicationLayer>*)rootViewController;
-(void)pushLayer: (UIViewController<NTIAppNavigationLayer>*)layer animated: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)popLayerAnimated: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)topLayer;
-(UIViewController<NTIAppNavigationApplicationLayer>*)topApplicationLayer;

@end
