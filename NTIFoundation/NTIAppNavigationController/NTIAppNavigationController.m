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
#import "NTIAppNavigationLayerSwitcher.h"
#import <OmniUI/OUIAppController.h>
#import "NTIGlobalInspector.h"

@interface NTIAppNavigationToolbar : UIToolbar{
	@private
	id target;
	UIBarButtonItem* downButton;
	UIBarButtonItem* layerSelectorButton;
	UIBarButtonItem* titleButton; //Custom view that is a label
	UIBarButtonItem* inspectorButton;
	UIBarButtonItem* searchButton;
	UIBarButtonItem* globeButton;
	
}
-(id)initWithTarget: (id)target andFrame: (CGRect)frame;
-(void)setDownButtonTitle: (NSString*)title;
-(void)setDownButtonHidden: (BOOL)enabled;
-(void)setTitle: (NSString*)title;
@end

@implementation NTIAppNavigationToolbar

static UILabel* titleLabelForToolbar()
{
	UILabel* titleLabel = [[UILabel alloc] init];
	titleLabel.text = @"Title";
	CGRect titleFrame = titleLabel.frame;
	titleFrame.size = CGSizeMake(150, 44);
	titleLabel.frame = titleFrame;
	titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.textColor = [UIColor colorWithRed:157.0/255.0 green:157.0/255.0 blue:157.0/255.0 alpha:1.0];
	titleLabel.textAlignment = UITextAlignmentCenter;
	//titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	return titleLabel;
}

-(id)initWithTarget: (id)target andFrame: (CGRect)frame
{
	self = [super initWithFrame: frame];
	
	self->downButton = [[UIBarButtonItem alloc] initWithTitle: @"Down"
														style: UIBarButtonItemStyleBordered 
													   target: self->target
													   action: @selector(down:)];
	
	self->layerSelectorButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAction target: self->target action: @selector(layer:)];
	
	UILabel* titleLabel = titleLabelForToolbar();
	self->titleButton = [[UIBarButtonItem alloc] initWithCustomView: titleLabel];
	
	self->inspectorButton =  [[UIBarButtonItem alloc]
							  initWithImage: [[UIButton buttonWithType: UIButtonTypeInfoLight]
											  imageForState: UIControlStateNormal]
							  style: UIBarButtonItemStylePlain
							  target: self->target action: @selector(inspector:)];
	
	self->searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSearch 
																	   target: self->target
																	   action: @selector(search:)];
	
	self->globeButton = [[UIBarButtonItem alloc] initWithTitle: @"Globe"
														  style: UIBarButtonItemStyleBordered 
														 target: self->target
														 action: @selector(globe:)];
	
	UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] 
									  initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace		
									  target: nil action: nil];
	
	self.items = [NSArray arrayWithObjects: self->downButton, self->layerSelectorButton, 
				  flexibleSpace, self->titleButton, flexibleSpace, self->inspectorButton,
				  self->searchButton, self->globeButton, nil];
	
	return self;
}

-(void)setDownButtonHidden: (BOOL)hidden
{
	if(hidden){
		self.items = [self.items arrayByRemovingObjectIdenticalTo: self->downButton];
	}
	else if(![self.items containsObjectIdenticalTo: self->downButton]){
		NSMutableArray* newItems = [NSMutableArray arrayWithObject: self->downButton];
		[newItems addObjectsFromArray: self.items];
		self.items = newItems;
	}
}

-(void)setDownButtonTitle: (NSString*)title
{
	self->downButton.title = title;
}

-(void)setTitle: (NSString*)title
{
	[(UILabel*)self->titleButton.customView setText: title];
}

@end

@implementation UIViewController(NTIAppNavigationControllerExtensions)
-(NTIAppNavigationController*)ntiAppNavigationController
{
	id rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
	if( [rootViewController respondsToSelector: @selector(appNavController)] ){
		return objc_msgSend(rootViewController, @selector(appNavController));
	}
	return nil;
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

static BOOL isAppLayer(id possibleLayer)
{
	return [possibleLayer conformsToProtocol: @protocol(NTIAppNavigationApplicationLayer)];
}

@implementation NTIAppNavigationController
@synthesize delegate = nr_delegate;
@synthesize inspectorDelegate;

-(id)initWithRootLayer:(UIViewController<NTIAppNavigationApplicationLayer>*)rootViewController
{
	self = [super initWithNibName: nil bundle: nil];
	
	self->layerProviders = [NSMutableArray arrayWithCapacity: 3];
	self->viewControllers = [NSMutableArray arrayWithCapacity: 5];
	self->navController = [[UINavigationController alloc] initWithNibName: nil bundle: nil];
	self->navController.navigationBarHidden = YES;
	
	[self addChildViewController: self->navController];
	
	[self pushLayer: rootViewController animated: NO];
	
	return self;
}

-(void)loadView
{
	[super loadView]; //Default implemenation sets up a base UIView
	self->toolBar = [[NTIAppNavigationToolbar alloc] initWithTarget: self andFrame: CGRectMake(0, 0, self.view.frame.size.width, 44)];
	self->toolBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview: self->toolBar];
	
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	self->navController.view.frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 44);
	[self.view addSubview: self->navController.view];
}

-(NSString*)titleForLayer: (id)layer
{
	NSString* title = nil; //TODO: default to what is in the NavItem?
	if( [layer respondsToSelector: @selector(titleForAppNavigationController:)] ){
		title = [layer titleForAppNavigationController: self];
	}
	return title;
}

-(NSString*)downTextForLayer: (id)layer
{
	NSString* downText = nil;
	
	if( [layer respondsToSelector: @selector(textForAppNavigationControllerDownButton:)] ){
		downText = [layer textForAppNavigationControllerDownButton: self];
	}
	
	if(!downText){
		NSUInteger idxOfLayer = [self->viewControllers indexOfObjectIdenticalTo: layer];
		if(idxOfLayer != NSNotFound && idxOfLayer > 0){
			id layerBeneath = [self->viewControllers objectAtIndex: idxOfLayer - 1];
			downText = [self titleForLayer: layerBeneath];
		}
	}
	
	if(!downText){
		downText = @"Down";
	}
	
	return downText;
}

-(void)updateToolbarForTopLayer
{
	UIViewController<NTIAppNavigationLayer>* topLayer = [self->viewControllers lastObjectOrNil];
	[self->toolBar setTitle: [self titleForLayer: topLayer]];
	
	if (self->viewControllers.count > 1) {
		[self->toolBar setDownButtonTitle: [self downTextForLayer: topLayer]];
		
	}
	[self->toolBar setDownButtonHidden: self->viewControllers.count <= 1];
}

-(void)pushLayer: (UIViewController<NTIAppNavigationLayer>*)layer animated: (BOOL)animated
{	
	[[OUIAppController controller] dismissPopoverAnimated: YES];
	if( isAppLayer(layer) ){
		[self pushApplicationLayer: (id)layer animated: animated];
	}
	else{
		[self pushTransientLayer: (id)layer animated: animated];
	}
	[self updateToolbarForTopLayer];
}

-(UIViewController<NTIAppNavigationLayer>*)popLayerAnimated: (BOOL)animated
{
	//Cant pop the final layer
	if([self->viewControllers count] == 1){
		return nil;
	}

	[[OUIAppController controller] dismissPopoverAnimated: YES];
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
	[self updateToolbarForTopLayer];
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
	[self addChildViewController: appLayer];	
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
	transLayer.view.layer.cornerRadius = 5;
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
		vc.view.layer.shadowOpacity = .5;
		vc.view.layer.shadowOffset = CGSizeMake(-5, 0);
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
		
		UIViewController* leaving = [self->navController popViewControllerAnimated: NO];
		UIView* toAnimateOut = leaving.view;
		[toAnimateOut removeFromSuperview];
		toAnimateOut.layer.shadowOpacity = .5;
		toAnimateOut.layer.shadowOffset = CGSizeMake(-5, 0);
		[self addChildViewController: leaving];
		[self.view addSubview: toAnimateOut];
		
		toAnimateOut.frame = startingRect;
				
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

-(NSArray*)layers
{
	return [self->viewControllers copy];
}

-(UIViewController<NTIAppNavigationLayer>*)topLayer
{
	return [self->viewControllers lastObjectOrNil];
}

-(UIViewController<NTIAppNavigationApplicationLayer>*)topApplicationLayer
{
	for(NSInteger i = [self->viewControllers count] - 1 ; i >= 0; i-- ){
		id layer = [self->viewControllers objectAtIndex: i];
		if( isAppLayer(layer) ){
			return layer;
		}
	}
	return nil;
}

-(void)moveAppLayerToTop: (id<NTIAppNavigationApplicationLayer>)appLayer
{
	//If we are asked to move the top applayer do nothing, it is already on top
	if( self->navController.topViewController == (id)appLayer){
		return;
	}
	
	//Because this is an app layer moving the actual view is easy.  Just 
	//remove the layer to move from the nav controller, grab all the view controllers
	//in our list up to the next app controller and move them to the end and then animate
	//in the appLayer
	
	NSMutableArray* appControllersToMoveToTop = [NSMutableArray array];
	NSUInteger idx = [self->viewControllers indexOfObjectIdenticalTo: appLayer];
	OBASSERT(idx != NSNotFound);
	
	id layerToMove = [self->viewControllers objectAtIndex: idx];
	do{
		[appControllersToMoveToTop addObject: layerToMove];
		layerToMove = [self->viewControllers objectAtIndex: ++idx];
	}
	while(idx < self->viewControllers.count && !isAppLayer( layerToMove ));
	
	//We have the layers that need to move.  Remove them from the view controller list and add them to the end
	for(id layerToMove in appControllersToMoveToTop){
		[self->viewControllers removeObjectIdenticalTo: layerToMove];
		[self->viewControllers addObject: layerToMove];
	}
	
	//change the actual nav heirarchy
	
	//Remove it from somewhere in the middle of the stack
	NSArray* navVCs = self->navController.viewControllers;
	self->navController.viewControllers = [navVCs arrayByRemovingObjectIdenticalTo: appLayer];
	
	//Now we need to push the app layer
	[self pushNavController: (id)appLayer animated: YES];
}

-(void)moveTransientLayerToTop: (id<NTIAppNavigationApplicationLayer>)layer
{
	NSLog(@"Moving transient layer not yet implemented.");
}

-(void)bringLayerForward: (id<NTIAppNavigationLayer>)layer
{
	if(isAppLayer(layer)){
		[self moveAppLayerToTop: (id)layer];
	}
	else{
		[self moveTransientLayerToTop: (id)layer];
	}
	[self updateToolbarForTopLayer];
}

#pragma mark switcher delegate
-(NSArray*)layerProvidersForSwitcher: (NTIAppNavigationLayerSwitcher*)switcher
{
	return self->layerProviders;
}

-(NSArray*)layersThatCanBeBroughtForwardForSwitcher: (NTIAppNavigationLayerSwitcher*)switcher
{
	//If it responds to canBringToFront we go based off the result of that, if it does not
	//respond to that message it can be brought to front if it is an app layer
	return [self->viewControllers filteredArrayUsingPredicate: 
			[NSPredicate predicateWithBlock: 
			 ^BOOL(id obj, NSDictionary* bindings){
				 if( [obj respondsToSelector: @selector(canBringToFront)] ){
					 return [obj canBringToFront];
				 }
				 
				 return isAppLayer(obj);
			 }]];
}

-(void)switcher: (NTIAppNavigationLayerSwitcher*)switcher bringLayerForward: (id<NTIAppNavigationLayer>)layer
{
	[[OUIAppController controller] dismissPopoverAnimated: YES];
	[self bringLayerForward: layer];
}

-(void)switcher: (NTIAppNavigationLayerSwitcher*)switcher showLayer: (id<NTIAppNavigationLayerDescriptor>)layerDescriptor;
{
	UIViewController<NTIAppNavigationLayer>* toPush = [layerDescriptor.provider createLayerForDescriptor: layerDescriptor]; 
	[self pushLayer: toPush animated: YES];
}

-(void)registerLayerProvider: (id<NTIAppNavigationLayerProvider>)layerProvider
{
	[self->layerProviders addObject: layerProvider];
}

-(void)unregisterLayerProvider: (id<NTIAppNavigationLayerProvider>)layerProvider
{
	[self->layerProviders removeObjectIdenticalTo: layerProvider];
}

#pragma mark actions from toolbar

-(void)down: (id)_
{
	[self popLayerAnimated: YES];
}

-(void)layer: (id)_
{
	if(self->popController.isPopoverVisible){
		[[OUIAppController controller] dismissPopoverAnimated: YES];
	}
	//TODO probably want to stash this around or save some state so we can show the tab that was last shown.
	NTIAppNavigationLayerSwitcher* switcher = [[NTIAppNavigationLayerSwitcher alloc] initWithDelegate: (id)self];
	switcher.contentSizeForViewInPopover = CGSizeMake(320, 480);
	self->popController = [[UIPopoverController alloc] initWithContentViewController: switcher];
	[[OUIAppController controller] presentPopover: popController 
								fromBarButtonItem: _ 
						 permittedArrowDirections: UIPopoverArrowDirectionUp 
										 animated: YES];
}

-(void)inspector: (id)_
{
	if(!inspector){
		self->inspector = [[NTIGlobalInspector alloc] init];
		inspector.delegate = self->inspectorDelegate;
	}
	[self->inspector inspectObjectsFromBarButtonItem: _];
}


-(void)search: (id)_
{
}

-(void)globe: (id)_
{
}


#pragma mark actions

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

#pragma mark layer switcher delegate

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end
