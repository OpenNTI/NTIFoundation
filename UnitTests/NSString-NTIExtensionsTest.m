//
//  NSString-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSString-NTIExtensionsTest.h"

#import "NSString-NTIExtensions.h"

@implementation NSString_NTIExtensionsTest

-(void)testJavascriptBoolValue
{
	XCTAssertFalse([@"false" javascriptBoolValue]);
	XCTAssertTrue([@"true" javascriptBoolValue]);
	XCTAssertFalse([@"None" javascriptBoolValue]);
}

-(void)testLongValue
{
	XCTAssertEqual([@"123456" longValue], (NSInteger)123456);
}

-(void)testPiecesUsingRegex
{
	NSString* handshake = @"HTTP/1.1 101 Switching Protocols\nUpgrade: WebSocket\nConnection: Upgrade\nSec-WebSocket-Accept: hrIyuqmFm4k655eTa9Ibgw8Kvss=\nAccess-Control-Allow-Origin: http://ipad.nextthought.com\nAccess-Control-Allow-Credentials: true";
	
	NSArray* parts = [handshake piecesUsingRegexString: @"Sec-WebSocket-Accept:\\s+(.+?)\\s"];
	
	XCTAssertEqual((int)parts.count, 1);
	
	XCTAssertEqualObjects([parts firstObject], @"hrIyuqmFm4k655eTa9Ibgw8Kvss=");

	
	NSString* packet = @"3:1::blabla";
	NSArray* pieces = [packet piecesUsingRegexString: @"([^:]+):([0-9]+)?(\\+)?:([^:]+)?:?([\\s\\S]*)?"];
	
	NSArray* shouldEqual = [NSArray arrayWithObjects: @"3", @"1", @"", @"", @"blabla", nil];
	
	XCTAssertEqualObjects(pieces, shouldEqual);
	
	
}

- (void)testStringByRemovingHTML
{
	NSString *string = @"<html><b class='test'>functional group</b></html>";
	string = [string stringByRemovingHTML];
	// HTML is properly removed from string
	XCTAssert([string isEqualToString: @"functional group"],
			  @"HTML is not properly removed from string.");
	string = [string stringByRemovingHTML];
	// String with no HTML is not modified erroneously
	XCTAssert([string isEqualToString: @"functional group"],
			  @"String with no HTML is modified erroneously.");
}

@end
