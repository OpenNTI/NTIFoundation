//
//  UIColor+NTIExtensions.m
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/15/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//

#import "UIColor+NTIExtensions.h"


@implementation UIColor (NTIExtensions)

static NSRegularExpression *hexRegex;

static BOOL isHexStringValid(NSString *hexString)
{
	if ( !hexRegex ) {
		hexRegex = [[NSRegularExpression alloc]
					initWithPattern: @"#?[a-fA-F0-9]{6}"
					options: 0
					error: nil];
	}
	NSRange range = NSMakeRange(0, hexString.length);
	NSRange matchRange = [hexRegex rangeOfFirstMatchInString: hexString
													 options: 0
													   range: range];
	return NSEqualRanges(range, matchRange);
}

+ (UIColor *)colorFromHexString: (NSString *)hexString
					  withAlpha: (CGFloat)alpha
{
	NSUInteger hexInt = [[self class] unsignedIntegerFromHexString: hexString];
	
	if (hexInt == NSNotFound) {
		NSLog(@"Invalid hexString. Returning nil.");
		return nil;
	}
	
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
	unsigned int hexInt = 0;
	
	if ( !isHexStringValid( hexString ) ) {
		return NSNotFound;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString: hexString];
	
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString: @"#"]];
	
	[scanner scanHexInt: &hexInt];
	
	return ( hexInt == UINT_MAX ? NSNotFound : (NSUInteger)hexInt );
}

@end
