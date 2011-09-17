//
//  UIView-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/16.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "UIView-NTIExtensions.h"

@implementation UIView (NTIExtensions)
-(void)removeAllSubviews
{
	for( id sv in self.subviews ) {
		[sv removeFromSuperview];	
	}
}
@end
