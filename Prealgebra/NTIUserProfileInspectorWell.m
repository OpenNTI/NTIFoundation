//
//  NTIUserProfileInspectorWell.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/04.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIUserProfileInspectorWell.h"

//Damn it, they don't publish this
//#import "OmniUI/OUIParameters.h"
#define kOUIInspectorWellHeight (37)
#import <OmniQuartz/OQDrawing.h>

@implementation NTIUserProfileInspectorWell

-(CGFloat)buttonHeight
{
	return 120;
}

-(void)layoutSubviews
{
	[super layoutSubviews];
	//The superclass lays out the right view in a rectangel based oun 
	//centering within /height/ width, which makes no sense here, 
	//since we're so tall. We force the same height constant they would
	//expect.
	if( self.rightView ) {
		CGRect contentsRect = OUIInspectorWellInnerRect(self.bounds);
		
		CGRect rightRect;
		CGRectDivide(	contentsRect,
					 &rightRect,
					 &contentsRect,
					 kOUIInspectorWellHeight,
					 CGRectMaxXEdge);
		
		self.rightView.frame = OQCenteredIntegralRectInRect(rightRect, self.rightView.bounds.size);
	}
	
}

@end
