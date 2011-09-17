//
//  OQColor-NTIExtensions.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/07/29.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "OQColor-NTIExtensions.h"

@implementation OQColor (NTIExtensions)
-(NSString*)cssString
{
	return [NSString stringWithFormat: @"rgba(%.0f,%.0f,%.0f,%.1f)",
			[self redComponent] * 255, 
			[self greenComponent] * 255,
			[self blueComponent] * 255,
			[self alphaComponent]];	
}
@end
