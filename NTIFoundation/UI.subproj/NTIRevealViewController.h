//
//  NTIRevealViewController.h
//  NTIFoundation
//
//  Created by Christopher Utz on 8/1/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <OmniUI/OUIViewController.h>



/*
 *	A container controller the slide to reveal paradigm common
 *  in many applications.  A good example of what we are going for is
 *  the facebook application.  This class is a container controller for two
 *  user specified view controllers.  The topViewController is the view controller
 *  for the view that must be slid right to reveal the view controlled by 
 *  bottomViewController.
 */
@interface NTIRevealViewController : OUIViewController{
	@private
	//Hold a reference to our vcs
	OUIViewController* topViewController;
	OUIViewController* bottomViewController;
	
	//Container views for each vc's view
	UIView* topView;
	UIView* bottomView;
}

//Designated initializer
-(id)initWithTopViewController: (OUIViewController*)tvc
		  bottomViewController: (OUIViewController*)bvc;

//Properties for the currently contained view controllers
@property (nonatomic, readonly) OUIViewController* topViewController;
@property (nonatomic, readonly) OUIViewController* bottomViewController;

//Some configuration properties
@property (nonatomic, assign) NSTimeInterval defaultRevealAnimationDuration;
@property (nonatomic, assign) NSTimeInterval defaultHideAnimationDuration;
@property (nonatomic, assign) CGFloat revealWidth;

//Methods to reveal the bottom view
-(void)revealBottomViewController;
-(void)revealBottomViewControllerWithDuration: (NSTimeInterval)duration;

//Methods to hide the bottom view
-(void)hideBottomViewController;
-(void)hideBottomViewControllerWithDuration: (NSTimeInterval)duration;

@end
