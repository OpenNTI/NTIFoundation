//
//  NTIBadgeCountView.m
//  NTIFoundation
//
//  Created by Christopher Utz on 2/2/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIBadgeCountView.h"

@implementation NTIBadgeCountView

-(id)initWithCount: (NSUInteger)c andFrame: (CGRect)frame;
{
    self = [super initWithFrame:frame];
    self->count = c;
	self.backgroundColor = [UIColor clearColor];
    return self;
}

// Draws the Badge with Quartz
-(void)drawRoundedRectWithContext:(CGContextRef)context withRect: (CGRect)rect
{
	CGContextSaveGState(context);
	
	CGFloat radius = CGRectGetMaxY(rect)*.5;
	CGFloat padding = CGRectGetMaxY(rect)*0.10;
	CGFloat maxX = CGRectGetMaxX(rect) - padding;
	CGFloat maxY = CGRectGetMaxY(rect) - padding;
	CGFloat minX = CGRectGetMinX(rect) + padding;
	CGFloat minY = CGRectGetMinY(rect) + padding;
	
    CGContextBeginPath(context);
	CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
	CGContextSetShadowWithColor(context, CGSizeMake(1.0,1.0), 3, [[UIColor blackColor] CGColor]);
    CGContextFillPath(context);
	
	CGContextRestoreGState(context);
	
}

-(void)drawPerimeterWithContext:(CGContextRef)context withRect: (CGRect)rect
{
	CGFloat radius = CGRectGetMaxY(rect)*.5;
	CGFloat buffer = CGRectGetMaxY(rect)*0.10;
	
	CGFloat maxX = CGRectGetMaxX(rect) - buffer;
	CGFloat maxY = CGRectGetMaxY(rect) - buffer;
	CGFloat minX = CGRectGetMinX(rect) + buffer;
	CGFloat minY = CGRectGetMinY(rect) + buffer;
	
	
    CGContextBeginPath(context);
	CGFloat lineSize = 2;
	CGContextSetLineWidth(context, lineSize);
	CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
	CGContextClosePath(context);
	CGContextStrokePath(context);

}

//Inspired by CustomBadge
- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawRoundedRectWithContext: context withRect: rect];
	
	[self drawPerimeterWithContext: context withRect: rect];
	
	NSString* countString = [NSString stringWithFormat: @"%ld" , self->count];
	
	if ([countString length]>0) {
		[[UIColor whiteColor] set];
		CGFloat sizeOfFont = 13.5;
		if ([countString length]<2) {
			sizeOfFont += sizeOfFont*0.20;
		}
		UIFont *textFont = [UIFont boldSystemFontOfSize:sizeOfFont];
		CGSize textSize = [countString sizeWithFont:textFont];
		[countString drawAtPoint: 
		 CGPointMake((rect.size.width/2-textSize.width/2), 
					 (rect.size.height/2-textSize.height/2)) 
						withFont: textFont];
	}
	
}

@end
