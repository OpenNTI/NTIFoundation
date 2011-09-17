//
//  NTIViewController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIViewController.h"
#import "NTIOSCompat.h"

@interface UIViewController(NTIParentExtensions)
-(void)setParentViewController: (UIViewController*)p;
@end

@implementation NTIViewController

-(id)initWithNibName: (NSString*)nibNameOrNil bundle: (NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
	return self;
}

-(UIViewController*)parentViewController
{
	if( self->parentVC ) {
		return self->parentVC;
	}
	return [super parentViewController];
}

-(void)removeFromParentViewController
{
	//Asymetric relationship here.
	self->parentVC = nil;
	if( [[NTIViewController superclass] instancesRespondToSelector: _cmd] ) {
		[super removeFromParentViewController];
	}
}

-(void)setParentViewController: (UIViewController*)p
{
	self->parentVC = p;
	//See NTIParentViewController
	if(		[[NTIViewController superclass] instancesRespondToSelector: _cmd] 
	   &&	[[NTIViewController superclass] instancesRespondToSelector: @selector(removeFromParentViewController)]) {
		[super setParentViewController: p];
	}
}

-(id)ancestorViewControllerWithClass: (Class)c
{
	UIViewController* result = self.parentViewController;
	while( result && ![result isKindOfClass: c] ) {
		result = result.parentViewController;
	}
	return result;
}

@end
