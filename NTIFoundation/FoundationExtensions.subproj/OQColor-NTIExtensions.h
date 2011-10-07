//
//  OQColor-NTIExtensions.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/07/29.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "OmniQuartz/OQColor.h"

@interface OQColor (NTIExtensions)
@property (readonly,nonatomic) NSString* cssString;
@property (nonatomic, readonly) CGColorRef rgbaCGColorRef;
@end
