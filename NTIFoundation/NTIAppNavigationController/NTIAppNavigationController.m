//
//  NTIAppNavigationController.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIAppNavigationController.h"
#import "NSMutableArray-NTIExtensions.h"
#import "QuartzCore/QuartzCore.h"

@implementation UIViewController(NTIAppNavigationControllerExtensions)
-(NTIAppNavigationController*)ntiAppNavigationController
{
	return (id)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
}
@end

#define kTransientLayerAnimationSpeed .4
#define kTransientLayerSize 320

@interface NTIAppNavigationController()
-(void)popNavControllerAnimated: (BOOL)animated;
@end

@implementation NTIAppNavigationController

-(id)initWithRootLayer:(UIViewController<NTIAppNavigationApplicationLayer>*)rootViewController
{
	self = [super initWithNibName: nil bundle: nil];
	
	self->viewControllers = [NSMutableArray arrayWithCapacity: 5];
	self->navController = [[UINavigationController alloc] initWithNibName: nil bundle: nil];
	
	[self addChildViewController: self->navController];
	
	[self pushLayer: rootViewController animated: NO];
	
	return self;
}

-(void)loadView
{
	[super loadView];
	[self.view addSubview: self->navController.view];
}

-(void)pushLayer: (UIViewController<NTIAppNavigationLayer>*)layer animated: (BOOL)animated
{
	[self->viewControllers addObject: layer];
	if( [layer conformsToProtocol: @protocol(NTIAppNavigationApplicationLayer)] ){
		[self->navController pushViewController: layer animated: animated];
	}
	else{
		//We are a transient viewController
		//OUr parent becomes the view controller that is on top of the nav controller (the top most application layer)
		[self->navController.topViewController addChildViewController: layer];
		//Add the layers view as a subview of the topViewControllersView.  Adjust the frame first
		
		layer.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
		
		//Setup the shadow
		layer.view.layer.masksToBounds = NO;
		layer.view.layer.cornerRadius = 3;
		layer.view.layer.shadowRadius = 5;
		layer.view.layer.shadowOpacity = 0.5;
		layer.view.layer.shadowPath = [UIBezierPath bezierPathWithRect: layer.view.bounds].CGPath;
		
		CGRect parentViewsFrame = self->navController.topViewController.view.frame;
		
		//We want to start off the right had side of the screen
		CGRect transientFrameStart = CGRectMake(parentViewsFrame.origin.x + parentViewsFrame.size.width, 
												0, 
												kTransientLayerSize, 
												parentViewsFrame.size.height);
		layer.view.frame = transientFrameStart;
		
		//Add it as a subview
		[self->navController.topViewController.view addSubview: layer.view];
		
		//Now animate it in
		[UIView animateWithDuration: kTransientLayerAnimationSpeed 
						 animations: ^{
							 CGRect endFrame = transientFrameStart;
							 endFrame.origin.x = endFrame.origin.x - kTransientLayerSize;
							 layer.view.frame = endFrame;
						 }
						 completion: nil];
	}
	
}

-(UIViewController<NTIAppNavigationLayer>*)popLayerAnimated: (BOOL)animated
{
	//Cant pop the final layer
	if([self->viewControllers count] == 1){
		return nil;
	}
	UIViewController<NTIAppNavigationLayer>* toPop = [self->viewControllers pop];
	if( toPop == self->navController.topViewController ){
		[self popNavControllerAnimated: animated];
	}
	else{
		//Ok so this better be a transient view
		//Animate it out and then remove it from the parent view
		[UIView animateWithDuration: kTransientLayerAnimationSpeed 
						 animations: ^{
							 CGRect endFrame = toPop.view.frame;
							 endFrame.origin.x = endFrame.origin.x + kTransientLayerSize;
							 toPop.view.frame = endFrame;
						 }
						 completion: ^(BOOL completion){
							 [toPop.view removeFromSuperview];
							 [toPop removeFromParentViewController];
						 }];
	}
	return toPop;
}

-(void)popNavControllerAnimated: (BOOL)animated
{
	if(!animated){
		[self->navController popViewControllerAnimated: NO];
	}
	else{
		[self->navController popViewControllerAnimated: YES];
		
//		UIViewController* toPopVC = self->navController.topViewController;
//		UIView* animatedOut = toPopVC.view;
//		[UIView animateWithDuration: kTransientLayerAnimationSpeed 
//						 animations: ^{
//							 CGRect endFrame = animatedOut.frame;
//							 endFrame.origin.x = endFrame.origin.x + animatedOut.frame.size.width;
//							 animatedOut.frame = endFrame;
//						 }
//						 completion: ^(BOOL completion){
//							 [self->navController popViewControllerAnimated:NO];
//						 }];
//		
//		
		

	}
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end
