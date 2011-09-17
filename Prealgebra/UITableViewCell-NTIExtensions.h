//
//  UIView-NTIExtensions.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/16.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView-NTIExtensions.h"

@interface UITableViewCell (NTIExtensions)
/**
 * In order to get the square views to fit in the grouped table cells,
 * they must have masked corners--otherwise their sharp edges poke out of 
 * the rounded goodness. Unfortunately, this radius is nowhere documented
 * and we cannot seem to get the tableviewcell itself to do this (the background
 * view and/or layer which draws the radius apparently doesn't actually use a mask+radius, it just
 * draws a quarter-circle.). Hence this hack.
 * 
 * @param resize If true, then the view will be forced to fit the content
 * view's bounds.
 * @param view The view to become the one and only child of this object's
 * content view.
 */
-(void)setContentViewRoundingCornersForGroup: (UIView*)view
									  resize: (BOOL)resize;
@end
