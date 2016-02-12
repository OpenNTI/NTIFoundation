//
//  NTIBadgeView.m
//  NTIFoundation
//
//  Created by Christopher Utz on 2/2/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIBadgeView.h"

@interface NTIBadgeView()
@property (nonatomic, readonly) CAShapeLayer* layer;
@property (nonatomic, readonly) UILabel* label;
@end

@implementation NTIBadgeView
@dynamic layer;
@dynamic font, textColor;

+(Class)layerClass
{
	return [CAShapeLayer class];
}

-(id)initWithFrame: (CGRect)frame;
{
    self = [super initWithFrame:frame];
	if(self){
		self.layer.lineWidth = 3;
		
		self->_label = [[UILabel alloc] initWithFrame: self.bounds];
		self.label.translatesAutoresizingMaskIntoConstraints = NO;
		self.label.textAlignment = NSTextAlignmentCenter;
		[self addSubview: self.label];
		
		[self.label addConstraint: [NSLayoutConstraint constraintWithItem: self.label
														  attribute: NSLayoutAttributeWidth
														  relatedBy: NSLayoutRelationGreaterThanOrEqual
																   toItem: self.label
														  attribute: NSLayoutAttributeHeight
															   multiplier: 1
														   constant: 0]];
		
		[self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-(6)-[l]-(6)-|"
																	  options: 0
																	  metrics: nil
																		views: @{@"l": self.label}]];
		[self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(3)-[l]-(3)-|"
																	  options: 0
																	  metrics: nil
																		views: @{@"l": self.label}]];
		
		self.backgroundColor = [UIColor clearColor];
		self.font = [UIFont boldSystemFontOfSize: 14];
		self.textColor = [UIColor blackColor];
		self.badgeColor = [UIColor redColor];
		self.borderColor = [UIColor blackColor];
	}
    return self;
}

-(UIColor *)textColor
{
	return self.label.textColor;
}

-(void)setTextColor:(UIColor *)textColor
{
	self.label.textColor = textColor;
}

-(UIFont *)font
{
	return self.label.font;
}

-(void)setFont:(UIFont *)font
{
	self.label.font = font;
}

-(void)layoutSublayersOfLayer:(CALayer *)layer
{
	self.layer.path = [UIBezierPath bezierPathWithRoundedRect: self.bounds
												 cornerRadius: self.bounds.size.height / 2.0].CGPath;
	[super layoutSublayersOfLayer: layer];

}

-(void)setBadgeText:(NSString *)badgeText
{
	self->_badgeText = badgeText;
	self.label.text = self.badgeText;
}

-(void)setBadgeColor:(UIColor *)badgeColor
{
	self->_badgeColor = badgeColor;
	self.layer.fillColor = [self.badgeColor CGColor];
}

-(void)setBorderColor:(UIColor *)borderColor
{
	self->_borderColor = borderColor;
	self.layer.strokeColor = self.borderColor.CGColor;
}

@end
