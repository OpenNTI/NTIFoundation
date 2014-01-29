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
	STAssertFalse([@"false" javascriptBoolValue], nil);
	STAssertTrue([@"true" javascriptBoolValue], nil);
	STAssertFalse([@"None" javascriptBoolValue], nil);
}

-(void)testLongValue
{
	STAssertEquals([@"123456" longValue], 123456, nil);
}

-(void)testPiecesUsingRegex
{
	NSString* handshake = @"HTTP/1.1 101 Switching Protocols\nUpgrade: WebSocket\nConnection: Upgrade\nSec-WebSocket-Accept: hrIyuqmFm4k655eTa9Ibgw8Kvss=\nAccess-Control-Allow-Origin: http://ipad.nextthought.com\nAccess-Control-Allow-Credentials: true";
	
	NSArray* parts = [handshake piecesUsingRegexString: @"Sec-WebSocket-Accept:\\s+(.+?)\\s"];
	
	STAssertEquals((int)parts.count, 1, nil);
	
	STAssertEqualObjects([parts firstObject], @"hrIyuqmFm4k655eTa9Ibgw8Kvss=", nil);

	
	NSString* packet = @"3:1::blabla";
	NSArray* pieces = [packet piecesUsingRegexString: @"([^:]+):([0-9]+)?(\\+)?:([^:]+)?:?([\\s\\S]*)?"];
	
	NSArray* shouldEqual = [NSArray arrayWithObjects: @"3", @"1", @"", @"", @"blabla", nil];
	
	STAssertEqualObjects(pieces, shouldEqual, nil);
	
	
}

@end
