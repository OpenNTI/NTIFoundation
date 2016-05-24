//
//  OAColor-NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 5/18/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "OAColor-NTIExtensionsTest.h"
#import "OAColor-NTIExtensions.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@implementation OAColor_NTIExtensionsTest

// All code under test must be linked into the Unit Test bundle
-(void)testCssString
{
    OAColor* red = [OAColor redColor];
	assertThat([red cssString], equalTo(@"rgba(255,0,0,1.0)"));
}

-(void)testCGColorRef
{
	OAColor* color = [OAColor colorWithRed: .52 green: .32 blue: .87 alpha: .6];
	
	CGColorRef colorRef = [color rgbaCGColorRef];
	
	const CGFloat* components = CGColorGetComponents(colorRef);
	
	assertThat(@(components[0]), is(equalTo(@(.52))));
	assertThat(@(components[1]), is(equalTo(@(.32))));
	assertThat(@(components[2]), is(equalTo(@(.87))));
	assertThat(@(components[3]), is(equalTo(@(.6))));
}

@end
