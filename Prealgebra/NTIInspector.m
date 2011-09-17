//
//  NTIInspector.m
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/12/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIInspector.h"

@implementation NTINavigableInspector

@synthesize navigationController;

-(id)initWithMainPane: (OUIInspectorPane*)mainPane
			   height: (CGFloat)height
  navgationController: (UINavigationController*)nav
{
	//Must set this before calling super, it panics if the embedded 
	//state changes later.
	self->navigationController = [nav retain];
	self = [super initWithMainPane: mainPane height: height];
	return self;
}

-(id)initWithNavigationController: (UINavigationController*)nav
{
	return [self initWithMainPane: nil
						   height: 400 //copied from super
			  navgationController: nav];
}

-(id)init
{
	return [self initWithNavigationController: nil];
}

-(BOOL)isEmbededInOtherNavigationController;
{
    return self.navigationController != nil;
}

-(UINavigationController*)embeddingNavigationController;
{
    return navigationController;
}

-(BOOL)isVisible
{
	//TODO: The superclass does bad things if it gets
	//called when embedded. How to fix?
	if( self.navigationController ) {
		return self.navigationController.isViewLoaded && self.navigationController.view.window != nil;
	}
	return [super isVisible];
}

-(void)dealloc
{
	NTI_RELEASE( self->navigationController );
	[super dealloc];
}

@end

