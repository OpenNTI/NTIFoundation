//
//  UIColor+NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/16/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIColor+NTIExtensions.h"

@interface UIColor_NTIExtensionsTest : XCTestCase

@end

@implementation UIColor_NTIExtensionsTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testColorFromHexString
{
	NSString *hexString = @"7b8cdf";
	CGFloat expectedR = 123.0 / 255.0;
	CGFloat expectedG = 140.0 / 255.0;
	CGFloat expectedB = 223.0 / 255.0;
	CGFloat expectedA = 1.0;
	UIColor *color = [UIColor colorFromHexString: hexString
									   withAlpha: expectedA];
	CGFloat *red, *green, *blue, *alpha;
	red = malloc(sizeof(CGFloat));
	green = malloc(sizeof(CGFloat));
	blue = malloc(sizeof(CGFloat));
	alpha = malloc(sizeof(CGFloat));
	[color getRed: red
			green: green
			 blue: blue
			alpha: alpha];
	XCTAssertEqual(*red, expectedR, @"Correct red value is parsed from hex string.");
	XCTAssertEqual(*green, expectedG, @"Correct green value is parsed from hex string.");
	XCTAssertEqual(*blue, expectedB, @"Correct blue value is parsed from hex string.");
	XCTAssertEqual(*alpha, expectedA, @"Correct alpha value is assigned to color.");
	free(red);
	red = 0;
	free(green);
	green = 0;
	free(blue);
	blue = 0;
	free(alpha);
	alpha = 0;
}

@end
