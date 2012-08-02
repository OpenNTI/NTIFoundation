//
//  NTIRevealViewController.m
//  NTIFoundation
//
//  Created by Christopher Utz on 8/1/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIRevealViewController.h"
#import "QuartzCore/QuartzCore.h"

@interface NTIRevealViewController ()
@end

@implementation NTIRevealViewController
@synthesize topViewController, bottomViewController;
@synthesize defaultHideAnimationDuration, defaultRevealAnimationDuration;

-(id)initWithTopViewController: (OUIViewController*)tvc
		  bottomViewController: (OUIViewController*)bvc
{
	self = [super initWithNibName: nil bundle: nil];
	if(self){
		self->topViewController = tvc;
		self->bottomViewController = bvc;
		self.defaultHideAnimationDuration = .4;
		self.defaultRevealAnimationDuration = .4;
		self.revealWidth = 150;
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	//Setup our container views
	self->topView = [[UIView alloc] initWithFrame: self.view.bounds];
	self->topView = [[UIView alloc] initWithFrame: self.view.bounds];
	
	self->topView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self->bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	//Add them to our view.  Note the order is important here
	[self.view addSubview: self->bottomView];
	[self.view addSubview: self->topView];
	
	//Add a shadow to the top view.  
	self->topView.layer.masksToBounds = NO;
	self->topView.layer.shadowColor = [[UIColor blackColor] CGColor];
	self->topView.layer.shadowOpacity = 1;
	self->topView.layer.shadowRadius = 2;
	self->topView.layer.shadowOffset = CGSizeZero;
	//Note the use of the path some reading suggested this helps to reduce
	//lag during rotation.  TODO maybe we should only do this when we are ready to reveal the bottom view?
	UIBezierPath* path = [UIBezierPath bezierPathWithRect: self->topView.bounds];
	self->topView.layer.shadowPath = path.CGPath;
	
	//Now we need to add the vcs and their views into the proper heirarchies
	[self addChildViewController: self->bottomViewController];
	[self->bottomView addSubview: self->bottomViewController.view];
	[self->bottomViewController didMoveToParentViewController: self];
	
	[self addChildViewController: self->topViewController];
	[self->topView addSubview: self->topViewController.view];
	[self->topViewController didMoveToParentViewController: self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
	self->topView = nil;
	self->bottomView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//Methods to reveal the bottom view
-(void)revealBottomViewController
{
	[self revealBottomViewControllerWithDuration: self.defaultRevealAnimationDuration];
}

//TODO when the back view has been revealed the facebook app disables interaction with the
//top view.  We could do this by disabling user interaction, or if we thought it might save
//resources we can take a snapshot of the top view and replace it with an image.  Whatever
//we do, we must do the inverse when we hide the bottom again.

//NOTE while there are some advantages to doing something as described above.  Our current design,
//unlink other apps I can think of with this slide out, has the button to reveal/hide the bottom
//view in the top view.  If we do something like above users could use the button to reveal the bottom
//view, but not to hide it again.
-(void)revealBottomViewControllerWithDuration: (NSTimeInterval)duration
{
	//TODO make sure we can't do this if we are already revealing
	
	//self->topView.userInteractionEnabled = NO;
	//To reveal we wan't to animate over the top view at the given speed
	//to the reveal width
	[UIView animateWithDuration: duration
					 animations: ^(){
						 CGRect endFrame = CGRectApplyAffineTransform(self->topView.frame,
											CGAffineTransformMakeTranslation(self.revealWidth, 0));
						 self->topView.frame = endFrame;
					 }];
	
}

//Methods to hide the bottom view
-(void)hideBottomViewController
{
	[self hideBottomViewControllerWithDuration: self.defaultHideAnimationDuration];
}

-(void)hideBottomViewControllerWithDuration: (NSTimeInterval)duration
{
	//TODO agan make sure we don't do this if we are already hiding
	
	//Move the topview back to its original location
	[UIView animateWithDuration: duration
					 animations: ^(){
						 self->topView.frame = CGRectMake(0, 0,
														  self->topView.frame.size.width,
														  self->topView.frame.size.height);
					 }
					 completion: ^(BOOL finished){
						// self->topView.userInteractionEnabled = YES;
					 }];
}

@end
