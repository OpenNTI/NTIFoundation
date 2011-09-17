//
//  UIView-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/16.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UITableViewCell-NTIExtensions.h"

@implementation UITableViewCell (NTIExtensions)
-(void)setContentViewRoundingCornersForGroup: (UIView*)view
									  resize: (BOOL)resize
{
	if( resize ) {
		[view sizeToFit];
		view.frame = self.contentView.bounds;
	}
	[self.contentView removeAllSubviews];
	[self.contentView addSubview: view];
	view.layer.masksToBounds = YES;
	view.layer.cornerRadius = 9.0;
}
@end
