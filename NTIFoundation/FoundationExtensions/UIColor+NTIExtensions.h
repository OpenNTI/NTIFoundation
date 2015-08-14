//
//  UIColor+NTIExtensions.h
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/15/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (NTIExtensions)

/**
 * Creates a UIColor object by parsing a string which textually represents red, green, and blue hexadecimal color-values, with alpha specified separately.
 * @param hexString A string-encoding of red, green, and blue hexadecimal color-values. E.g., "7b8cdf". May be prefixed by "#".
 * @param alpha Floating-point alpha (transparency) value specified in the range of 0 to 1 (1 being completely opaque, 0 being completely transparent).
 * @return A UIColor object with red, green, and blue values as represented by |hexString| and alpha value specified by |alpha|. Returns nil if |hexString| is invalid.
 */
+ (UIColor *)colorFromHexString: (NSString *)hexString
					  withAlpha: (CGFloat)alpha;

@end
