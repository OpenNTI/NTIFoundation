//
//  UIColor+NTIExtensions.m
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/15/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//

#import "UIColor+NTIExtensions.h"

@implementation UIColor (NTIExtensions)

+ (UIColor *)colorFromHexString: (NSString *)hexString
					  withAlpha: (CGFloat)alpha
{
	NSUInteger hexInt = [[self class] unsignedIntegerFromHexString: hexString];
	
	CGFloat r = ( (CGFloat) ((hexInt & 0xFF0000) >> 16)) / 255.0;
	CGFloat g = ((CGFloat) ((hexInt & 0xFF00) >> 8)) / 255.0;
	CGFloat b = ((CGFloat) (hexInt & 0xFF)) / 255.0;
	UIColor *color = [UIColor colorWithRed: r
									 green: g
									  blue: b
									 alpha: alpha];
	return color;
}

+ (NSUInteger)unsignedIntegerFromHexString: (NSString *)hexString
{
	NSUInteger hexInt = 0;
	
	NSScanner *scanner = [NSScanner scannerWithString: hexString];
	
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString: @"#"]];
	
	[scanner scanHexInt: &hexInt];
	
	return hexInt;
}

@end
