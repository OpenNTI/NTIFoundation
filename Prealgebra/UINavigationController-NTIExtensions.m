//
//  UINavigationController-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/08.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "UINavigationController-NTIExtensions.h"

@implementation UINavigationController(NTIExtensions)

-(UIViewController*) rootViewController
{
	return [[self viewControllers] objectAtIndex: 0];
}

@end
