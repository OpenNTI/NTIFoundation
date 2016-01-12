//
//  NTIHTMLReaderTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIHTMLReaderTest.h"
#import "NTIHTMLReader.h"
#import "NTIHTMLWriter.h"
#import "OAColor-NTIExtensions.h"

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

CGColorRef NTIHTMLReaderParseCreateColor(NSString* color, OAColor* defaultColor);

@implementation NTIHTMLReaderTest

-(void)testUnderlineString
{
	NSString* html = @"<html><body><p style='text-decoration: underline'>test underline</p></body></html>";
	NTIHTMLReader* reader = [[NTIHTMLReader alloc] initWithHTML: html];
	
	NSAttributedString* parsed = reader.attributedString;
	
	NSAttributedString* underlined = [[NSAttributedString alloc] initWithString: @"test underline"
																	 attributes: @{NSUnderlineStyleAttributeName:
																					   @(NSUnderlineStyleSingle)}];
	NSRange parsedRange = NSMakeRange(0, parsed.string.length);
	NSDictionary* parsedAttrs = [parsed attributesAtIndex: 0 effectiveRange: &parsedRange];
	
	NSRange underlinedRange = NSMakeRange(0, underlined.string.length);
	NSDictionary* underlinedAttrs = [underlined attributesAtIndex: 0 effectiveRange: &underlinedRange];
	
	XCTAssertTrue([parsedAttrs isEqual: underlinedAttrs], @"Expected underlined string");
}

-(void)testReaderWriterUnderlineCompliance
{
	NSAttributedString* underlined = [[NSAttributedString alloc] initWithString: @"test"
																	 attributes: @{NSUnderlineStyleAttributeName:
																					   @(NSUnderlineStyleSingle)}];
	NSData* writerHTMLData = [NTIHTMLWriter htmlDataForAttributedString: underlined];
	NSString* writerHTML = [[NSString alloc] initWithData: writerHTMLData encoding: NSUTF8StringEncoding];
	
	NTIHTMLReader* reader = [[NTIHTMLReader alloc] initWithHTML: writerHTML];
	NSAttributedString* parsed = reader.attributedString;
	
	NSRange parsedRange = NSMakeRange(0, parsed.string.length);
	NSDictionary* parsedAttrs = [parsed attributesAtIndex: 0 effectiveRange: &parsedRange];
	
	XCTAssertTrue([[parsedAttrs allKeys] containsObject: NSUnderlineStyleAttributeName], @"Expected parsed string to be underlined");
}

-(void)testCSSString
{
	OAColor* blackColor = [OAColor blackColor];
	XCTAssertEqualObjects([blackColor cssString], @"rgba(0,0,0,1.0)");
	
	OAColor* whiteColor = [OAColor whiteColor];
	XCTAssertEqualObjects([whiteColor cssString], @"rgba(255,255,255,1.0)");
	
	OAColor* color = [OAColor colorWithRed: .2 green: .5 blue: .7 alpha: .9];
	XCTAssertEqualObjects([color cssString], @"rgba(51,128,178,0.9)");
}

-(void)testColorParsing
{
	NSString* blackColor = @"black";
	
	CGColorRef parsedValue = NTIHTMLReaderParseCreateColor(blackColor, nil);
	
	XCTAssertTrue(CGColorEqualToColor(parsedValue,  [[OAColor blackColor] rgbaCGColorRef]),
						 @"Should be same color");
	
	NSString* rgbColor = @"rgb(20, 70, 200)";
	
	parsedValue = NTIHTMLReaderParseCreateColor(rgbColor, nil);
	
	XCTAssertTrue(CGColorEqualToColor(parsedValue,  [[OAColor colorWithRed: 20.0f/255.0f
																	green: 70.0f/255.0f 
																	 blue: 200.0f/255.0f
																	alpha: 1] rgbaCGColorRef]),
				 @"Should be same color");
	
	
	NSString* hexColor = @"#1446C8";
	
	parsedValue = NTIHTMLReaderParseCreateColor(hexColor, nil);
	
	XCTAssertTrue(CGColorEqualToColor(parsedValue,  [[OAColor colorWithRed: 20.0f/255.0f
																	green: 70.0f/255.0f 
																	 blue: 200.0f/255.0f
																	alpha: 1] rgbaCGColorRef]),
				 @"Should be same color");

}

-(void)testUnparsableReturnsDefault
{
	NSString* gobbledegoop = @"asdlkfadlf";
	OAColor* defaultColor = [OAColor yellowColor];
	CGColorRef parsedValue = NTIHTMLReaderParseCreateColor(gobbledegoop, defaultColor);
	
	XCTAssertTrue(CGColorEqualToColor(parsedValue, [defaultColor rgbaCGColorRef]), @"Expected default color");
	
	parsedValue = NTIHTMLReaderParseCreateColor(gobbledegoop, nil);
	
	XCTAssertTrue(CGColorEqualToColor(parsedValue, nil), @"Expected default color");
}

-(void)testDropFormattingIfWeCantParseIt
{
	NSString* badFormat = @"<html><body>blah blah blah<font color=\"FF0000\">foo foo foo</font>?</body></html>";
	
	NTIHTMLReader* reader = [[NTIHTMLReader alloc] initWithHTML: badFormat];
	
	NSAttributedString* parsed = reader.attributedString;
	
	XCTAssertEqualObjects(parsed, [[NSAttributedString alloc] initWithString: @"blah blah blahfoo foo foo?"], 
						 @"Expected formatting data to be striped", nil);
}

-(void)testBadXMLInitsToNil
{
	NSString* badFormat = @"<html><body><body>blah blah blah<font color=\"FF0000\">foo foo foo</font>?</body></html>";
	
	NTIHTMLReader* reader = [[NTIHTMLReader alloc] initWithHTML: badFormat];

	XCTAssertNil(reader, @"Bad xml should return nil from init");
}

-(void)testCapturesAudio
{
	NSString* audioHtml = @"<html><body><audio controls=\"\" src=\"data:foobar\"></audio></body></html>";
	
	AudioCapturingHtmlReader* reader = [[AudioCapturingHtmlReader alloc] initWithHTML: audioHtml];
	
	XCTAssertEqualObjects(reader.source, @"data:foobar");
}

-(void)testReadLink
{
	NSString* linkHtml = @"<html><body><a href=\"http://google.com\">http://google.com</a></body></html>";
	
	NSAttributedString* expected = [[NSAttributedString alloc] initWithString: @"http://google.com" attributeName: NSLinkAttributeName attributeValue: [NSURL URLWithString: @"http://google.com"]];
	NTIHTMLReader* reader = [[NTIHTMLReader alloc] initWithHTML: linkHtml];
	NSAttributedString* parts = reader.attributedString;
	XCTAssertEqualObjects(parts, expected);
}

@end
