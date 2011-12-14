//
//  NTIHTMLReaderTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIHTMLReaderTest.h"
#import "NTIHTMLReader.h"
#import "OQColor-NTIExtensions.h"

CGColorRef NTIHTMLReaderParseCreateColor(NSString* color);

@implementation NTIHTMLReaderTest

-(void)testCSSString
{
	OQColor* blackColor = [OQColor blackColor];
	STAssertEqualObjects([blackColor cssString], @"rgba(0,0,0,1.0)", nil);
	
	OQColor* whiteColor = [OQColor whiteColor];
	STAssertEqualObjects([whiteColor cssString], @"rgba(255,255,255,1.0)", nil);
	
	OQColor* color = [OQColor colorWithRed: .2 green: .5 blue: .7 alpha: .9];
	STAssertEqualObjects([color cssString], @"rgba(51,128,178,0.9)", nil);
}

-(void)testColorParsing
{
	NSString* blackColor = @"black";
	
	CGColorRef parsedValue = NTIHTMLReaderParseCreateColor(blackColor);
	
	STAssertTrue(CGColorEqualToColor(parsedValue,  [[OQColor blackColor] rgbaCGColorRef]),
						 @"Should be same color");
	
	NSString* rgbColor = @"rgb(20, 70, 200)";
	
	parsedValue = NTIHTMLReaderParseCreateColor(rgbColor);
	
	STAssertTrue(CGColorEqualToColor(parsedValue,  [[OQColor colorWithRed: 20.0f/255.0f 
																	green: 70.0f/255.0f 
																	 blue: 200.0f/255.0f
																	alpha: 1] rgbaCGColorRef]),
				 @"Should be same color");
	
	
	NSString* hexColor = @"#1446C8";
	
	parsedValue = NTIHTMLReaderParseCreateColor(hexColor);
	
	STAssertTrue(CGColorEqualToColor(parsedValue,  [[OQColor colorWithRed: 20.0f/255.0f 
																	green: 70.0f/255.0f 
																	 blue: 200.0f/255.0f
																	alpha: 1] rgbaCGColorRef]),
				 @"Should be same color");

}
@end
