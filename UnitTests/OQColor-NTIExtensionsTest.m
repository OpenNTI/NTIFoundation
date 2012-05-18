//
//  OQColor-NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 5/18/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "OQColor-NTIExtensionsTest.h"
#import "NTIFoundation/NTIFoundation.h"

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@implementation OQColor_NTIExtensionsTest

// All code under test must be linked into the Unit Test bundle
-(void)testCssString
{
    OQColor* red = [OQColor redColor];
	assertThat([red cssString], equalTo(@"rgba(255,0,0,1.0)"));
}

-(void)testCGColorRef
{
	OQColor* color = [OQColor colorWithRed: .52 green: .32 blue: .87 alpha: .6];
	
	CGColorRef colorRef = [color rgbaCGColorRef];
	
	const CGFloat* components = CGColorGetComponents(colorRef);
	
	assertThatFloat(components[0], is(equalToFloat(.52)));
	assertThatFloat(components[1], is(equalToFloat(.32)));
	assertThatFloat(components[2], is(equalToFloat(.87)));
	assertThatFloat(components[3], is(equalToFloat(.6)));
}

@end
