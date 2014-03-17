//
//  NSAttributedString-HTMLReadingExtensions.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NSAttributedString-HTMLReadingExtensionsTest.h"
#import "NSAttributedString-HTMLReadingExtensions.h"

@implementation NSAttributedString_HTMLReadingExtensions

-(void)testStyleAndDirect
{
	NSAttributedString* style =
	[NSAttributedString stringFromHTML: @"<html><body><p><span style='font-style: italic'>The text</span></p></body></html>"];	
	NSAttributedString* direct =
	[NSAttributedString stringFromHTML: @"<html><body><p><i>The text</i></p></body></html>"];
	
	XCTAssertEqualObjects(
		direct,
		style,
		@"Italics" );
	
	style =
	[NSAttributedString stringFromHTML: @"<html><body><p><span style='font-weight: bold'>The text</span></p></body></html>"];	direct =
	[NSAttributedString stringFromHTML: @"<html><body><p><strong>The text</strong></p></body></html>"];
	
	XCTAssertEqualObjects(
		direct,
		style,
		@"Bold" );	

}

@end
