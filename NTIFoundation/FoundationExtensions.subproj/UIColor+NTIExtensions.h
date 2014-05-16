//
//  UIColor+NTIExtensions.h
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/15/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (NTIExtensions)

+ (UIColor *)colorFromHexString: (NSString *)hexString
					  withAlpha: (CGFloat)alpha;

+ (NSUInteger)unsignedIntegerFromHexString: (NSString *)hexString;

@end
