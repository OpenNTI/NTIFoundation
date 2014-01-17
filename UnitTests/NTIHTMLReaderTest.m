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

@interface AudioCapturingHtmlReader : NTIHTMLReader{
	NSString* source;
}
@property (nonatomic, readonly) NSString* source;
@end

@implementation AudioCapturingHtmlReader

-(NSString*)source
{
	return self->source;
}

-(void)handleAudioTag:(NSMutableAttributedString *)attrBuffer currentAudio:(NSString *)currentAudio
{
	self->source = currentAudio;
}

@end

CGColorRef NTIHTMLReaderParseCreateColor(NSString* color, OQColor* defaultColor);

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
	
	CGColorRef parsedValue = NTIHTMLReaderParseCreateColor(blackColor, nil);
	
	STAssertTrue(CGColorEqualToColor(parsedValue,  [[OQColor blackColor] rgbaCGColorRef]),
						 @"Should be same color");
	
	NSString* rgbColor = @"rgb(20, 70, 200)";
	
	parsedValue = NTIHTMLReaderParseCreateColor(rgbColor, nil);
	
	STAssertTrue(CGColorEqualToColor(parsedValue,  [[OQColor colorWithRed: 20.0f/255.0f 
																	green: 70.0f/255.0f 
																	 blue: 200.0f/255.0f
																	alpha: 1] rgbaCGColorRef]),
				 @"Should be same color");
	
	
	NSString* hexColor = @"#1446C8";
	
	parsedValue = NTIHTMLReaderParseCreateColor(hexColor, nil);
	
	STAssertTrue(CGColorEqualToColor(parsedValue,  [[OQColor colorWithRed: 20.0f/255.0f 
																	green: 70.0f/255.0f 
																	 blue: 200.0f/255.0f
																	alpha: 1] rgbaCGColorRef]),
				 @"Should be same color");

}

-(void)testUnparsableReturnsDefault
{
	NSString* gobbledegoop = @"asdlkfadlf";
	OQColor* defaultColor = [OQColor yellowColor];
	CGColorRef parsedValue = NTIHTMLReaderParseCreateColor(gobbledegoop, defaultColor);
	
	STAssertTrue(CGColorEqualToColor(parsedValue, [defaultColor rgbaCGColorRef]), @"Expected default color");
	
	parsedValue = NTIHTMLReaderParseCreateColor(gobbledegoop, nil);
	
	STAssertTrue(CGColorEqualToColor(parsedValue, nil), @"Expected default color");
}

-(void)testDropFormattingIfWeCantParseIt
{
	NSString* badFormat = @"<html><body>blah blah blah<font color=\"FF0000\">foo foo foo</font>?</body></html>";
	
	NTIHTMLReader* reader = [[NTIHTMLReader alloc] initWithHTML: badFormat];
	
	NSAttributedString* parsed = reader.attributedString;
	
	STAssertEqualObjects(parsed, [[NSAttributedString alloc] initWithString: @"blah blah blahfoo foo foo?"], 
						 @"Expected formatting data to be striped", nil);
}

-(void)testBadXMLInitsToNil
{
	NSString* badFormat = @"<html><body><body>blah blah blah<font color=\"FF0000\">foo foo foo</font>?</body></html>";
	
	NTIHTMLReader* reader = [[NTIHTMLReader alloc] initWithHTML: badFormat];

	STAssertNil(reader, @"Bad xml should return nil from init");
}

-(void)testCapturesAudio
{
	NSString* audioHtml = @"<html><body><audio controls=\"\" src=\"data:foobar\"></audio></body></html>";
	
	AudioCapturingHtmlReader* reader = [[AudioCapturingHtmlReader alloc] initWithHTML: audioHtml];
	
	STAssertEqualObjects(reader.source, @"data:foobar", nil);
}

-(void)testReadLink
{
	NSString* linkHtml = @"<html><body><a href=\"http://google.com\">http://google.com</a></body></html>";
	
	NSAttributedString* expected = [[NSAttributedString alloc] initWithString: @"http://google.com" attributeName: NSLinkAttributeName attributeValue: [NSURL URLWithString: @"http://google.com"]];
	NTIHTMLReader* reader = [[NTIHTMLReader alloc] initWithHTML: linkHtml];
	NSAttributedString* parts = reader.attributedString;
	STAssertEqualObjects(parts, expected, nil);
}

@end
