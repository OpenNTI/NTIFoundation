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
#import "NTIInspectableController.h"

@class NTIAppNavigationToolbar;
@protocol NTIAppNavigationToolbarDelegate
@optional
-(NSArray*)appNavigationToolbarExtraButtons: (NTIAppNavigationToolbar*)toolbar;
@end

@interface NTIAppNavigationToolbar : UIToolbar{
	@private
	id target;
	UIBarButtonItem* downButton;
	UIBarButtonItem* layerSelectorButton;
	UIBarButtonItem* titleButton; //Custom view that is a label
	UIBarButtonItem* inspectorButton;
	
}
@property (nonatomic, weak) id delegate;
@property (nonatomic, readonly) UIBarButtonItem* downButton;
-(id)initWithTarget: (id)target andFrame: (CGRect)frame andDelegate: (id)delegate;
-(void)setDownButtonTitle: (NSString*)title;
-(void)setDownButtonHidden: (BOOL)enabled;
-(void)setTitle: (NSString*)title;
-(void)setLayerButtonActive: (BOOL)active;
@end

@implementation NTIAppNavigationToolbar
@synthesize delegate;
@synthesize downButton;
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

-(UIView*)customViewForLayerSwitcher: (BOOL)active
{
	UIImage* image = [UIImage imageNamed: active ? @"switch_active.png" : @"switch_inactive.png"];
	UIButton* button = [[UIButton alloc] init];
	[button addTarget: self action: @selector(interceptLayer:) forControlEvents: UIControlEventTouchUpInside];
	[button setImage: image forState: UIControlStateNormal];
	button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	return button;
}

-(void)interceptLayer: (id)_
{
	[self->target performSelector: @selector(layer:) withObject: self->layerSelectorButton];
}

-(id)initWithTarget: (id)t andFrame: (CGRect)frame andDelegate:(id)d
{
	self = [super initWithFrame: frame];
	self.delegate = d;
	self->target = t;
	self->downButton = [[UIBarButtonItem alloc] initWithTitle: @"Down"
														style: UIBarButtonItemStyleBordered 
													   target: self->target
													   action: @selector(down:)];
	
	UIView* customView = [self customViewForLayerSwitcher: NO];
	self->layerSelectorButton = [[UIBarButtonItem alloc] initWithCustomView: customView];
//	self->layerSelectorButton.action = @selector(layer:);
//	self->layerSelectorButton.target = self->target;
	
	UILabel* titleLabel = titleLabelForToolbar();
	self->titleButton = [[UIBarButtonItem alloc] initWithCustomView: titleLabel];
	
	self->inspectorButton =  [[UIBarButtonItem alloc]
							  initWithImage: [[UIButton buttonWithType: UIButtonTypeInfoLight]
											  imageForState: UIControlStateNormal]
							  style: UIBarButtonItemStylePlain
							  target: self->target action: @selector(inspector:)];
	
	UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] 
									  initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace		
									  target: nil action: nil];
	
	NSArray* buttons = [NSArray arrayWithObjects: self->downButton, self->layerSelectorButton, 
						flexibleSpace, self->titleButton, flexibleSpace, self->inspectorButton, nil];
	
	if( [self.delegate respondsToSelector: @selector(appNavigationToolbarExtraButtons:)] ){
		buttons = [buttons arrayByAddingObjectsFromArray: [self.delegate appNavigationToolbarExtraButtons: self]];
	}
	
	self.items = buttons;
	
	return self;
}

-(void)setLayerButtonActive: (BOOL)active
{
	UIButton* buttonView = (id)self->layerSelectorButton.customView;
	UIImage* image = [UIImage imageNamed: active ? @"switch_active.png" : @"switch_inactive.png"];
	[buttonView setImage: image forState: UIControlStateNormal];
	CGRect frame = buttonView.frame;
	frame.size = image.size;
	buttonView.frame = frame;
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

#define kTransientLayerAnimationSpeed .4
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

-(id)initWithRootLayer:(UIViewController<NTIAppNavigationApplicationLayer>*)rootViewController
{
	self = [super initWithNibName: nil bundle: nil];
	self->activeLayerSwitcherTabIndex = 0;
	self->layerProviders = [NSMutableArray arrayWithCapacity: 3];
	self->viewControllers = [NSMutableArray arrayWithCapacity: 5];
	self->navController = [[UINavigationController alloc] initWithNibName: nil bundle: nil];
	self->navController.navigationBarHidden = YES;
	
	[self addChildViewController: self->navController];
	
	[self pushLayer: rootViewController animated: NO];
	
	return self;
}

-(BOOL)anyChangeCounts
{
	for(id<NTIAppNavigationLayerProvider> provider in self->layerProviders){
		for(id descriptor in provider.layerDescriptors)
		if( [descriptor respondsToSelector: @selector(backgroundChangeCountKeyPath)] ){
			NSString* keyPath = [descriptor backgroundChangeCountKeyPath]; 
			if( [[descriptor valueForKeyPath: keyPath] integerValue] > 0 ){
				return YES;
			}
		}
	}
	
	for(id layer in [(id)self layersThatCanBeBroughtForwardForSwitcher: nil]){
		if( [layer respondsToSelector: @selector(backgroundChangeCountKeyPath)] ){
			NSString* keyPath = [layer backgroundChangeCountKeyPath]; 
			if( [[layer valueForKeyPath: keyPath] integerValue] > 0 ){
				return YES;
			}
		}
	}
	
	return NO;
}

-(void)updateLayerIcon
{
	
	[self->toolBar setLayerButtonActive: [self anyChangeCounts]];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if( OFISEQUAL( keyPath, @"layerDescriptors") ){
		[self updateLayerIcon];
	}
	else{
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	}
}

-(void)loadView
{
	[super loadView]; //Default implemenation sets up a base UIView
	self->toolBar = [[NTIAppNavigationToolbar alloc] initWithTarget: self andFrame: CGRectMake(0, 0, self.view.frame.size.width, 44) andDelegate: self];
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
	id layerGoingAway = self.topLayer;
	
	if( [layer respondsToSelector: @selector(willAppearInAppNavigationControllerAsResultOfPush:)] ){
		[layer willAppearInAppNavigationControllerAsResultOfPush: YES];
	}
	
	if( [layerGoingAway respondsToSelector: @selector(willDisappearInAppNavigationControllerAsResultOfPush:)] ){
		[layerGoingAway willDisappearInAppNavigationControllerAsResultOfPush: YES];
	}
	
//	[self possibleStartTrackingLayer: self.topLayer];
	[[OUIAppController controller] dismissPopoverAnimated: YES];
	if( isAppLayer(layer) ){
		[self pushApplicationLayer: (id)layer animated: animated];
	}
	else{
		[self pushTransientLayer: (id)layer animated: animated];
	}
//	[self possibleStopTrackingLayer: layer];
//	[self resetCountsForLayer: layer];
	[self updateLayerIcon];
	[self updateToolbarForTopLayer];
	
	if( [layerGoingAway respondsToSelector: @selector(didDisappearInAppNavigationControllerAsResultOfPush:)] ){
		[layerGoingAway didDisappearInAppNavigationControllerAsResultOfPush: YES];
	}
	
	if( [layer respondsToSelector: @selector(didAppearInAppNavigationControllerAsResultOfPush:)] ){
		[layer didAppearInAppNavigationControllerAsResultOfPush: YES];
	}
	
	[self updateLayerIcon];
}

-(UIViewController<NTIAppNavigationLayer>*)unconditionallyPopLayerAnimated: (BOOL)animated
{
	//Cant pop the final layer
	if(!([self->viewControllers count] > 1)){
		return nil;
	}
	
	id willShow = [self.layers objectAtIndex: self.layers.count - 2 ];
	id willDisappear = [self.layers lastObject];
	
	if( [willShow respondsToSelector: @selector(willAppearInAppNavigationControllerAsResultOfPush:)] ){
		[willShow willAppearInAppNavigationControllerAsResultOfPush: NO];
	}
	
	if( [willDisappear respondsToSelector: @selector(willDisappearInAppNavigationControllerAsResultOfPush:)] ){
		[willDisappear willDisappearInAppNavigationControllerAsResultOfPush: NO];
	}
	
	//[self possibleStartTrackingLayer: self.topLayer];
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
	//[self possibleStopTrackingLayer: self.topLayer];
	//[self resetCountsForLayer: self.topLayer];
	[self updateLayerIcon];
	//If we have more than one vc left enable the down button
	[self updateToolbarForTopLayer];
	
	if( [willDisappear respondsToSelector: @selector(didDisappearInAppNavigationControllerAsResultOfPush:)] ){
		[willDisappear didDisappearInAppNavigationControllerAsResultOfPush: NO];
	}
	
	if( [willShow respondsToSelector: @selector(didAppearInAppNavigationControllerAsResultOfPush:)] ){
		[willShow didAppearInAppNavigationControllerAsResultOfPush: NO];
	}
	
	[self updateLayerIcon];
	
	return popped;
}


-(UIViewController<NTIAppNavigationLayer>*)popLayerAnimated: (BOOL)animated
{
	if(destructivePopActionSheet){
		//They are in the middle of a destructive pop, don't let them pop again
		return nil;
	}
	
	id layer = self.topLayer;
	if(   [layer respondsToSelector: @selector(poppingLayerWouldBeDestructive)] ){
		NSString* message = [layer poppingLayerWouldBeDestructive];
		if( message ){
			destructivePopActionSheet = [[UIActionSheet alloc] initWithTitle: message 
																	   delegate: self 
															  cancelButtonTitle: @"Cancel" 
														 destructiveButtonTitle: @"Continue" 
															  otherButtonTitles: nil];
			[destructivePopActionSheet showFromBarButtonItem: self->toolBar.downButton animated: YES];
			return nil;
		}
	}
	return [self unconditionallyPopLayerAnimated: animated];

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if( [[actionSheet buttonTitleAtIndex: buttonIndex] isEqualToString: @"Continue"] ){
		[self unconditionallyPopLayerAnimated: YES];
	}
	self->destructivePopActionSheet = nil;
}

-(void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	self->destructivePopActionSheet = nil;
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
							 endFrame.origin.x = endFrame.origin.x + popped.view.frame.size.width;
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
	
	CGFloat tranisientLayerWidth = kTransientLayerSize;
	if(   [transLayer respondsToSelector: @selector(wantsFullScreenLayout)] 
	   && [transLayer wantsFullScreenLayout]){
		transLayer.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		tranisientLayerWidth = parentViewsFrame.size.width;
	}
	
	//We want to start off the right had side of the screen
	CGRect transientFrameStart = CGRectMake(parentViewsFrame.origin.x + parentViewsFrame.size.width, 
											0, 
											tranisientLayerWidth, 
											parentViewsFrame.size.height);
	transLayer.view.frame = transientFrameStart;

	//[transLayer.view addGestureRecognizer: [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(swipedToRemoveTransient:)]];
	
	[self->navController.topViewController.view addSubview: transLayer.view];
	
	//Now animate it in
	[UIView animateWithDuration: kTransientLayerAnimationSpeed 
					 animations: ^{
						 CGRect endFrame = transientFrameStart;
						 endFrame.origin.x = endFrame.origin.x - tranisientLayerWidth;
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
		[leaving removeFromParentViewController];
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
							 [toAnimateOut removeFromSuperview];
							 [leaving removeFromParentViewController];
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

-(void)moveTransientLayerToTop: (UIViewController<NTIAppNavigationTransientLayer>*)layer
{
	//If we are asekd to move the top transient layer do nothing
	if(self.topLayer == (id)layer){
		return;
	}

	NSUInteger indexOfTransientLayer = [self->viewControllers indexOfObjectIdenticalTo: layer];
	
	OBASSERT(indexOfTransientLayer != NSNotFound);
	OBASSERT(indexOfTransientLayer < self->viewControllers.count - 1);
	
	//Are we the top transient layer of our app layer.  If so the next vc in the view controller list will
	//be an app layer
	BOOL isTopTransientLayer = isAppLayer([self->viewControllers objectAtIndex: indexOfTransientLayer + 1]);
	
	//We also need to know if we are the very bottom transient layer
	BOOL isBottomTransientLayer = isAppLayer([self->viewControllers objectAtIndex: indexOfTransientLayer - 1]);
	
	//We need to know the applayer this transient layer currently belongs to so we can do
	//things like removing the mask if necessary
	UIViewController* appLayerThatOwnsUs = nil;
	NSInteger idx = indexOfTransientLayer - 1;
	do{
		id potentialAppLayer = [self->viewControllers objectAtIndex: idx];
		if(isAppLayer(potentialAppLayer)){
			appLayerThatOwnsUs = potentialAppLayer;
			break;
		}
		idx--;
		
	}while(idx >= 0);
	
	OBASSERT_NOTNULL(appLayerThatOwnsUs);
	
	//Now if we are the top transient but not the bottom we need to unhide what is beneath us
	if( isTopTransientLayer && !isBottomTransientLayer){
		UIViewController* transientRightBeneathUs = [self->viewControllers objectAtIndex: indexOfTransientLayer - 1];
		transientRightBeneathUs.view.hidden = NO;
	}
	
	//If we are the only transient layer we need to remove the mask
	if( isTopTransientLayer && isBottomTransientLayer ){
		for(UIView* subview in appLayerThatOwnsUs.view.subviews){
			if( [subview isKindOfClass: [_TransientLayerMask class]] ){
				[subview removeFromSuperview];
			}
		}
	}
	
	//Now we need to remove overselves and push us
	[layer.view removeFromSuperview];
	[layer removeFromParentViewController];
	
	[self->viewControllers removeObjectIdenticalTo: layer];
	
	[self pushLayer: layer animated: YES];
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


//Current hueristic is as follows
//Search through our view controllers from top to bottom looking for a layer represented by the layerDescriptor. If the layer
//is found and it responds to and answers yes for canBringToFront as well as shouldAlwaysBringToFront, move it to the front
//else create a new one and push it.
-(id<NTIAppNavigationLayer>)layerToMoveForwardForDescriptor: (id<NTIAppNavigationLayerDescriptor>)descriptor
{
	//Go from top to bottom
	id<NTIAppNavigationLayer> layer = nil;
	for(NSInteger idx = self->viewControllers.count - 1; idx >= 0; idx--)
	{
		layer = [self->viewControllers objectAtIndex: idx];
		if(   [descriptor wouldCreatedLayerBeTheSameAs: (id)layer]
		   && [layer respondsToSelector: @selector(canBringToFront)]
		   && [layer canBringToFront]
		   && [layer respondsToSelector: @selector(shouldAlwaysBringToFront)]
		   && [layer shouldAlwaysBringToFront]){
			return layer;
		}
		
	}
	return nil;
}

-(void)switcher: (NTIAppNavigationLayerSwitcher*)switcher showLayer: (id<NTIAppNavigationLayerDescriptor>)layerDescriptor;
{
	//If this returns nil we will create a new one
	id<NTIAppNavigationLayer> layerToMove = [self layerToMoveForwardForDescriptor: layerDescriptor];
	
	if(layerToMove){
		[self bringLayerForward: layerToMove];
	}
	else{
		UIViewController<NTIAppNavigationLayer>* toPush = [layerDescriptor createLayer]; 
		[self pushLayer: toPush animated: YES];
	}
	[[OUIAppController controller] dismissPopoverAnimated: YES];
}

-(void)registerLayerProvider: (NSObject<NTIAppNavigationLayerProvider>*)lp
{
	[lp addObserver: self
			   forKeyPath: @"layerDescriptors"
				  options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context: NULL];
	[self->layerProviders addObject: lp];
}

-(void)unregisterLayerProvider: (NSObject<NTIAppNavigationLayerProvider>*)lp
{
	[lp removeObserver: self
			forKeyPath: @"layerDescriptors"];
	[self->layerProviders removeObjectIdenticalTo: lp];
}

#pragma mark actions from toolbar

-(void)down: (id)sender
{
	if(sender == self->toolBar.downButton){
		[self unconditionallyPopLayerAnimated: YES];
	}
	else{
		[self popLayerAnimated: YES];
	}
}

-(void)layer: (id)_
{
	if(self->popController.isPopoverVisible){
		[[OUIAppController controller] dismissPopoverAnimated: YES];
	}
	//TODO probably want to stash this around or save some state so we can show the tab that was last shown.
	NTIAppNavigationLayerSwitcher* switcher = [[NTIAppNavigationLayerSwitcher alloc] initWithDelegate: (id)self];
	switcher.delegate = self;
	switcher.contentSizeForViewInPopover = CGSizeMake(320, 480);
	
	if(   self->activeLayerSwitcherTabIndex < switcher.viewControllers.count
	   && self->activeLayerSwitcherTabIndex != NSNotFound){
		switcher.selectedIndex = self->activeLayerSwitcherTabIndex;
	}
	
	self->popController = [[UIPopoverController alloc] initWithContentViewController: switcher];
	[[OUIAppController controller] presentPopover: popController 
								fromBarButtonItem: _ 
						 permittedArrowDirections: UIPopoverArrowDirectionUp 
										 animated: YES];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
	self->activeLayerSwitcherTabIndex = tabBarController.selectedIndex;
}

#pragma mark global inspector
//TODO where if anywhere should this be split out

static UIResponder* findFirstResponderBeneathView(UIView* startAt)
{
	if(startAt.isFirstResponder){
		return startAt;
	}
	
	UIResponder* firstResponder = nil;
	for(UIView* child in startAt.subviews){
		firstResponder = findFirstResponderBeneathView( child );
		if(firstResponder){
			break;
		}
	}
	return firstResponder;
}

static UIResponder* findFirstResponder()
{
	return findFirstResponderBeneathView([[OUIAppController controller] window]);
}

static void searchUpResponderChain(UIResponder* responder, NSMutableArray* objects)
{
	if(!responder){
		return;
	}
	
	if( [responder respondsToSelector: @selector(inspectableObjects)] ){
		[objects addObjectsFromArray: [(id)responder inspectableObjects]];
	}
	
	searchUpResponderChain(responder.nextResponder, objects);
}

static void searchUpVCHiererarchy(UIViewController* controller, NSMutableArray* objects)
{
	if(!controller){
		return;
	}
	
	if( [controller respondsToSelector: @selector(inspectableObjects)] ){
		[objects addObjectsFromArray: [(id)controller inspectableObjects]];
	}
	
	searchUpVCHiererarchy(controller.parentViewController, objects);
}

//Create an inspector if one doesn't exist, find all the objects that are inspectable, 
//and inspect them.  If there is a first responder it will be resigned and restored when the inspector closes.
//Our current hueristic for locating inspectable objects is as follows.  We search the view/vc heirarchy in one of two
//ways.  If we can find a firstResponder start there and search up the responder chain for things responding to NTIInspectableController.
//If we can't find a first responder we ask the top layer if it is an NTIInspectableController.  In both cases we also ask our delegate
//for objects to inspect
-(void)inspector: (id)inspectorButton
{
	if(!inspector){
		// NOTE: Using our custom panes
		NTIGlobalInspectorMainPane* pane = [[NTIGlobalInspectorMainPane alloc] init];
		self->inspector = [[NTIGlobalInspector alloc] initWithMainPane: pane height: 400];
		inspector.delegate = self;
	}
	
	//NSMutableSet* inspectableObjects = [NSMutableSet set];
	NSMutableArray* inspectableObjects = [NSMutableArray array];
	UIResponder* firstResponder = findFirstResponder();
	self->inspector.shownFromFirstResponder = firstResponder;
	
	if(firstResponder){
		searchUpResponderChain(firstResponder, inspectableObjects);
	}
	else{
		//TODO Top layer or application layer here?
		searchUpVCHiererarchy(self.topLayer, inspectableObjects);
	}
	
	//Now ask our delegate
	if( [self.delegate respondsToSelector: @selector(appNavigationControllerInspectableObjects:)] ){
		[inspectableObjects addObjectsFromArray: [[self.delegate appNavigationControllerInspectableObjects: self] allObjects]];
		//Avoid duplicates
		//NSSet *uniqueObjects = [NSSet setWithArray: inspectableObjects];
		//[inspectableObjects removeAllObjects];
		//[inspectableObjects addObjectsFromArray: [uniqueObjects allObjects]];
	}
	
	[self->inspector.shownFromFirstResponder resignFirstResponder];
	
	//TODO what do we do if no objects are selected?
	[self->inspector inspectObjects: inspectableObjects 
				  fromBarButtonItem: inspectorButton];
}

#pragma mark inspector delegate
// If this is not implemented or returns nil, and the inspector pane doesn't already have a title, an assertion will fire it will be given a title of "Inspector".
// Thus, you either need to implement this or the manually give titles to the panes.
-(NSString*)inspector: (NTIGlobalInspector*)insp
		 titleForPane: (OUIInspectorPane*)pane
{
	if(pane == insp.mainPane){
		return @"Inspector";
	}
	//Nil will cause the inspector to ask the pane for the title
	return nil;
}

// If this is not implemented or returns nil, and the stacked inspector pane doesn't already have slices, an assertion will fire and the inspector dismissed.
// Thus, you either need to implement this or the manually give slices to the stacked slice panes. If you make slices this way, you must return all the possible slices and have the slices themselves decide whether they are appropriate for the inspected object set.
-(NSArray*)inspector: (NTIGlobalInspector*)insp
makeAvailableSlicesForStackedSlicesPane: (OUIStackedSlicesInspectorPane *)pane
{
	if( [self.delegate respondsToSelector: @selector(appNavigationController:globalInspector:makeAvailableSlicesForStackedSlicesPane:)] ){
		return [self.delegate appNavigationController: self globalInspector: insp makeAvailableSlicesForStackedSlicesPane: pane];
	}
	return nil;
}

-(void)inspectorDidDismiss:(NTIGlobalInspector *)insp
{
	[insp.shownFromFirstResponder becomeFirstResponder];
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

-(id)appNavController
{
	return self;
}

#pragma mark toolbar delegate
-(NSArray*)appNavigationToolbarExtraButtons: (NTIAppNavigationToolbar*)toolbar
{
	if( [self->nr_delegate respondsToSelector:@selector(appNavigationControllerAdditionalToolbarButtons:)] ){
		return [self->nr_delegate appNavigationControllerAdditionalToolbarButtons: self];
	}
	return [NSArray array];
}

-(void)dealloc
{
	for(id lp in self->layerProviders){
		[lp removeObserver: self
				forKeyPath: @"layerDescriptors"];
	}
}

@end
