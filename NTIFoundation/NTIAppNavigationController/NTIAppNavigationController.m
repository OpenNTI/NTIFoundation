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

@interface _TransientLayerMask : UIView
@end
	
@implementation _TransientLayerMask

-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame: frame];
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.alpha = .3;
	self.backgroundColor = [UIColor blackColor];
	return self;
}

@end

#define kTransientLayerAnimationSpeed .25
#define kTransientLayerSize 320

@interface NTIAppNavigationController()
-(void)pushNavController:(UIViewController*)vc animated: (BOOL)animated;
-(void)popNavControllerAnimated: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)popApplicationLayer: (BOOL)animated;
-(UIViewController<NTIAppNavigationLayer>*)popTransientLayer: (BOOL)animated;
-(void)pushApplicationLayer: (UIViewController<NTIAppNavigationApplicationLayer>*)appLayer animated: (BOOL)animated;
-(void)pushTransientLayer: (UIViewController<NTIAppNavigationTransientLayer>*)transLayer animated: (BOOL)animated;
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
	[super loadView]; //Default implemenation sets up a base UIView
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview: self->navController.view];
}

-(void)pushLayer: (UIViewController<NTIAppNavigationLayer>*)layer animated: (BOOL)animated
{	
	if( [layer conformsToProtocol: @protocol(NTIAppNavigationApplicationLayer)] ){
		[self pushApplicationLayer: (id)layer animated: animated];
	}
	else{
		[self pushTransientLayer: (id)layer animated: animated];
	}
	self->navController.topViewController.navigationItem.leftBarButtonItem.enabled = [self->viewControllers count] > 1;
}

-(UIViewController<NTIAppNavigationLayer>*)popLayerAnimated: (BOOL)animated
{
	//Cant pop the final layer
	if([self->viewControllers count] == 1){
		return nil;
	}
	
	id popped = nil;
	//Are we popping an app layer.  Only app layers are on the nav stack
	//if the controller to pop is the same as the top nav controller it is an 
	//application
	if( [self->viewControllers lastObject] == self->navController.topViewController){
		popped = [self popApplicationLayer: animated];
	}
	else{
		popped = [self popTransientLayer: animated];
	}
	
	//If we have more than one vc left enable the down button
	self->navController.topViewController.navigationItem.leftBarButtonItem.enabled = [self->viewControllers count] > 1;
	return popped;
}

-(UIViewController<NTIAppNavigationLayer>*)popApplicationLayer: (BOOL)animated
{
	id popped = [self->viewControllers pop];
	[self popNavControllerAnimated: animated];
	return popped;
}

-(UIViewController<NTIAppNavigationLayer>*)popTransientLayer: (BOOL)animated
{
	UIViewController* popped = [self->viewControllers pop];
	
	void (^completion)(BOOL) = ^(BOOL success){
		[popped.view removeFromSuperview];
		[popped removeFromParentViewController];
		
//		//If there are no more transLayers remove the mask
//		if( [self->viewControllers lastObject] == self->navController.topViewController ){
//			//Need to clear the mask
//			for(UIView* subView in self->navController.topViewController.view.subviews){
//				if([subView isKindOfClass: [_TransientLayerMask class]]){
//					[subView removeFromSuperview];
//					break;
//				}
//			}
//		}
	} ;
	
	//Do this at the beggining
	if([self->viewControllers lastObject] != self->navController.topViewController){
		//Need to show the trans
		[[self->viewControllers lastObject] view].hidden = NO;
	}
	else{
		//We may decide to do this when the animation completes.
		//Need to clear the mask
		for(UIView* subView in self->navController.topViewController.view.subviews){
			if([subView isKindOfClass: [_TransientLayerMask class]]){
				[subView removeFromSuperview];
				break;
			}
		}
	}
	
	if(!animated){
		completion(YES);
	}
	else{
		[UIView animateWithDuration: kTransientLayerAnimationSpeed 
						 animations: ^{
							 CGRect endFrame = popped.view.frame;
							 endFrame.origin.x = endFrame.origin.x + kTransientLayerSize;
							 popped.view.frame = endFrame;
						 }
						 completion: completion];
	}
	return (id)popped;

}

-(void)pushApplicationLayer: (UIViewController<NTIAppNavigationApplicationLayer>*)appLayer 
				   animated: (BOOL)animated
{
	[self->viewControllers addObject: appLayer];
	//Anything that wants to get pushed on our nav controller has to take our down button
	appLayer.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
													 initWithTitle: @"Down"
												 style: UIBarButtonItemStyleBordered
												 target: self action: @selector(down:)];
	appLayer.navigationItem.leftBarButtonItem.enabled = [self->viewControllers count] > 1;
	
	[self pushNavController: appLayer animated: animated];
}

-(void)pushTransientLayer: (UIViewController<NTIAppNavigationTransientLayer>*)transLayer 
				 animated: (BOOL)animated
{
	//If this is the first transient we have pushed for this appLayer we need
	//to mask it out.  It is the first transient if the viewController on top of our
	//stack is the same as the nav controllers top vc.  If its not we are going to want to
	//hide the other transient view
	UIViewController* transToHide=nil;
	if( [self->viewControllers lastObject] == self->navController.topViewController ){
		//Ok we need to push the mask.  The mask is a subview of the applicationLayers view
		_TransientLayerMask* mask = [[_TransientLayerMask alloc] 
									 initWithFrame: self->navController.topViewController.view.bounds];
		[self->navController.topViewController.view addSubview: mask];
		[mask addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(maskTapped:)]];
		//[mask addGestureRecognizer: [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(swipedToRemoveTransient:)]];
	}
	else{
		//Ok we have another transient view that we want to hide. but we don;t
		//actually want to hide it until we have presented the new one.
		transToHide = [self->viewControllers lastObject];
	}
	
	
	//We are a transient viewController
	//OUr parent becomes the view controller that is on top of the nav controller (the top most application layer)
	[self->navController.topViewController addChildViewController: transLayer];
	[self->viewControllers addObject: transLayer];
	//Add the layers view as a subview of the topViewControllersView.  Adjust the frame first
	transLayer.view.backgroundColor = [UIColor whiteColor];
	transLayer.view.alpha = 1;
	transLayer.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
	
	//Setup the shadow
	transLayer.view.layer.masksToBounds = NO;
	transLayer.view.layer.cornerRadius = 3;
	transLayer.view.layer.shadowRadius = 5;
	transLayer.view.layer.shadowOpacity = 0.5;
	
	CGRect parentViewsFrame = self->navController.topViewController.view.frame;
	//We want to start off the right had side of the screen
	CGRect transientFrameStart = CGRectMake(parentViewsFrame.origin.x + parentViewsFrame.size.width, 
											0, 
											kTransientLayerSize, 
											parentViewsFrame.size.height);
	transLayer.view.frame = transientFrameStart;

	//[transLayer.view addGestureRecognizer: [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(swipedToRemoveTransient:)]];
	
	[self->navController.topViewController.view addSubview: transLayer.view];
	
	//Now animate it in
	[UIView animateWithDuration: kTransientLayerAnimationSpeed 
					 animations: ^{
						 CGRect endFrame = transientFrameStart;
						 endFrame.origin.x = endFrame.origin.x - kTransientLayerSize;
						 transLayer.view.frame = endFrame;
					 }
					 completion: ^(BOOL success){
						 transToHide.view.hidden = YES;
					 }];

}

-(void)pushNavController:(UIViewController*)vc animated: (BOOL)animated
{
	if(!animated){
		[self->navController pushViewController: vc animated: NO];
	}
	else{
		//When pushing a nav controller we want it to appear to slide over and sit on 
		//top of the current view. 
		
		//The current view being shown
		UIView* viewToCover = self->navController.topViewController.view;
		
		//The ending rect we need to cover in window coordinate space
		CGRect endInView = [viewToCover convertRect: viewToCover.frame toView: self.view];
		
		//Start position is the end position shifted right by the width
		CGRect startInView = endInView;
		startInView.origin.x = startInView.origin.x + startInView.size.width;
		
		//Set the frame of our view to push to the start positoin, add it to the window
		
		vc.view.frame = startInView;
		[self.view addSubview: vc.view];
		
		//Animate the position change and on complete push it
		[UIView animateWithDuration: kTransientLayerAnimationSpeed
						 animations: ^(){
							 vc.view.frame = endInView;
						 } 
						 completion: ^(BOOL success){
							 //Remove it from the window and push it on the view controller
							 [vc.view removeFromSuperview];
							 [self->navController pushViewController: vc animated: NO];
						 }];
		
	}
}

-(void)popNavControllerAnimated: (BOOL)animated
{
	if(!animated){
		[self->navController popViewControllerAnimated: NO];
	}
	else{
		
		//We want to take it out of the nav control un animated and put it in our view
		UIView* viewToCover = self->navController.topViewController.view;
		
		//We start over the new view
		CGRect startingRect = [viewToCover convertRect: viewToCover.frame toView: self.view];
		
		//end position is the start position shifted right by the width
		CGRect endingRect = startingRect;
		endingRect.origin.x = endingRect.origin.x + startingRect.size.width;
		
		UIView* toAnimateOut = [self->navController popViewControllerAnimated: NO].view;
		toAnimateOut.frame = startingRect;
		[self.view addSubview: toAnimateOut];
		
		//Animate the position change and on complete push it
		[UIView animateWithDuration: kTransientLayerAnimationSpeed
						 animations: ^(){
							 toAnimateOut.frame = endingRect;
						 } 
						 completion: ^(BOOL success){
							 //Remove it from the window and push it on the view controller
							 [toAnimateOut removeFromSuperview];
						 }];

	}
}

#pragma mark actions

-(void)down: (id)_
{
	[self popLayerAnimated: YES];
}

-(void)maskTapped: (UIGestureRecognizer*)rec
{
	if(rec.state == UIGestureRecognizerStateEnded){
		[self down: rec];
	}
}

-(void)swipedToRemoveTransient: (UIGestureRecognizer*)rec
{
	[self down: rec];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end
