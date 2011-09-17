//
//  NTIParentViewController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIParentViewController.h"
#import "NTIOSCompat.h"
#import "NSMutableArray-NTIExtensions.h"
#import <OmniFoundation/OmniFoundation.h>

@implementation NTIParentViewController

-(id)initWithNibName: (NSString*)nibNameOrNil bundle: (NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    if( self ) {
        self->children = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc
{
	[children release];
	[super dealloc];
}

-(void)addChildViewController: (UIViewController*)c
{
	[self addChildViewController: c animated: NO];	
}

-(id)addChildViewController: (UIViewController*)child animated: (BOOL)animated
{
	//In 4.3, views respond to "add" but not remove -> leak. Thus, only
	//add if they also can remove.
	if(		[[NTIParentViewController superclass] instancesRespondToSelector: @selector(addChildViewController:)]
	   &&	[[UIViewController class] instancesRespondToSelector: @selector(removeFromParentViewController)]) {
		//iOS 5
		[super addChildViewController: child];
	}
	else if( [child respondsToSelector: @selector(setParentViewController:)] ) {
		[(id)child setParentViewController: self];
	}

	[children addObject: child];
	return child;
}

-(id)removeChildViewController: (UIViewController*)child animated: (BOOL)animated
{
	if( [self->children indexOfObjectIdenticalTo: child] != NSNotFound ) {
		if( [child respondsToSelector: @selector(removeFromParentViewController)] ) {
			//iOS 5
			[child removeFromParentViewController];
		}
		else if( [child respondsToSelector: @selector(setParentViewController:)] ) {
			[(id)child setParentViewController: nil];
		}
	}
	[self->children removeObject: child];
	return child;
}
//iOS5 has a method with the name removeChildViewController
//which can lead to infinite recursion. So we use a diff name.
-(id)ntiRemoveChildViewController: (UIViewController*)child
{
	return [self removeChildViewController: child 
								  animated: NO];
}


-(NSArray*)childViewControllersWithClass: (Class)clazz
{
	return [self->children objectsSatisfyingCondition: @selector(isKindOfClass:) 
										   withObject: clazz];
}

-(BOOL)removeChildViewControllersWithClass: (Class)clazz
{
	
	
	NSArray* controllers = [self childViewControllersWithClass: clazz]; 
	
	BOOL removed = ![NSArray isEmptyArray: controllers];
	
	[self performSelector:@selector(ntiRemoveChildViewController:)
		withEachObjectInArray:controllers];
	
	return removed;
}

#pragma mark UIViewController subclass


-(void)didRotateFromInterfaceOrientation: (UIInterfaceOrientation)old
{
	if( self->askingChildren ) {
		return;
	}
	@try {
		self->askingChildren = YES;
		for( id child in self->children ) {
			[child didRotateFromInterfaceOrientation: old];
		}
	}
	@finally {
		self->askingChildren = NO;
	}
}

-(BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
{
	if( self->askingChildren ) {
		return YES;
	}
	@try {
		self->askingChildren = YES;
		for( id child in self->children ) {
			if( ![child shouldAutorotateToInterfaceOrientation: toInterfaceOrientation] ) {
				return NO;
			}
		}
		return YES;
	}
	@finally {
		self->askingChildren = NO;
	}
}

-(void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation 
							   duration: (NSTimeInterval)duration
{
	if( self->askingChildren ) {
		return;
	}
	@try {
		self->askingChildren = YES;
		for( UIViewController* child in self->children ) {
			[child willRotateToInterfaceOrientation: toInterfaceOrientation duration: duration];
		}
	}
	@finally {
		self->askingChildren = NO;
	}
	[super willRotateToInterfaceOrientation: toInterfaceOrientation duration: duration];
}

-(void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation 
										duration: (NSTimeInterval)duration
{
	if( self->askingChildren ) {
		return;
	}
	@try {
		self->askingChildren = YES;
		for( UIViewController* child in self->children ) {
			[child willAnimateRotationToInterfaceOrientation: toInterfaceOrientation duration: duration];
		}
	}
	@finally {
		self->askingChildren = NO;
	}
	[super willAnimateRotationToInterfaceOrientation: toInterfaceOrientation duration: duration];
}

//TODO: The superclass looks for subclass implementations to determine
//whether to do one or two step rotation. We're forcing one step by
//having the above method implemented. If we add these other methods,
//then we're forcing two-step.

/*
-(void)willAnimateFirstHalfOfRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation 
										duration: (NSTimeInterval)duration
{
	for( UIViewController* child in self->children ) {
		[child willAnimateFirstHalfOfRotationToInterfaceOrientation: toInterfaceOrientation duration: duration];
	}
}

-(void)didAnimateFirstHalfOfRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
{
	for( UIViewController* child in self->children ) {
		[child didAnimateFirstHalfOfRotationToInterfaceOrientation: toInterfaceOrientation];
	}
}

-(void)willAnimateSecondHalfOfRotationFromInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation 
										duration: (NSTimeInterval)duration
{
	for( UIViewController* child in self->children ) {
		[child willAnimateSecondHalfOfRotationFromInterfaceOrientation: toInterfaceOrientation duration: duration];
	}
}
*/


-(void)didReceiveMemoryWarning
{
	if( self->askingChildren ) {
		return;
	}
	@try {
		self->askingChildren = YES;
		for( id child in self->children ) {
			[child didReceiveMemoryWarning];
		}
	}
	@finally {
		self->askingChildren = NO;
	}
}

-(void)viewWillAppear: (BOOL)animated
{
	if( self->askingChildren ) {
		return;
	}
	@try {
		self->askingChildren = YES;
		for( UIViewController* child in self->children ) {
			[child viewWillAppear: animated];
		}
	}
	@finally {
		self->askingChildren = NO;
	}
	[super viewWillAppear: animated];
}

@end
