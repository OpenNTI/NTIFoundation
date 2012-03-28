//
//  WebSocket7Test.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/20/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "WebSocket7Test.h"
#import "WebSockets.h"
#import "WebSocketResponseBuffer.h"

@implementation WebSocket7Test

-(void)testLongWebSocketResponseBuffer
{
	NSString* hexString = [NSString stringWithContentsOfURL: [[NSBundle bundleForClass: [self class]] 
															  URLForResource: @"LongWebSocketHexString.txt" withExtension: nil]
						   encoding: NSUTF8StringEncoding error: nil];
	hexString = [hexString stringByReplacingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet] withString: @""];
	
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: hexString error: nil];
	NSUInteger currentByte = 0;
	const void* bytes = [responseBytes bytes];
	while(currentByte < responseBytes.length - 1){
		STAssertFalse([buffer appendByteToBuffer: (u_int8_t*)(bytes + currentByte)], nil);
		STAssertFalse([buffer containsFullResponse], nil);
		currentByte++;
	}
	STAssertTrue([buffer appendByteToBuffer: (u_int8_t*)(bytes + currentByte)], nil);
	STAssertTrue([buffer containsFullResponse], nil);
	
	STAssertEqualObjects(buffer.dataBuffer, responseBytes, nil);
}

-(void)testLongWebSocketResponseToData
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a" error: nil];
	NSUInteger currentByte = 0;
	const void* bytes = [responseBytes bytes];
	while(currentByte < responseBytes.length){
		[buffer appendByteToBuffer: (u_int8_t*)(bytes + currentByte)];
		currentByte++;
	}
	WebSocketData* wsData = buffer.websocketData;
	
	NSString* dataString = [NSString stringWithData: wsData.data encoding: NSUTF8StringEncoding];
	
	STAssertEqualObjects(dataString, @"1::", nil);
}


-(void)testWebSocketResponseToData
{
	NSString* hexString = [NSString stringWithContentsOfURL: [[NSBundle bundleForClass: [self class]] 
															  URLForResource: @"LongWebSocketHexString.txt" withExtension: nil]
												   encoding: NSUTF8StringEncoding error: nil];
	hexString = [hexString stringByReplacingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet] withString: @""];
	
	NSData* responseBytes = [NSData dataWithHexString: hexString error: nil];
	
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	
	NSUInteger currentByte = 0;
	const void* bytes = [responseBytes bytes];
	while(currentByte < responseBytes.length){
		[buffer appendByteToBuffer: (u_int8_t*)(bytes + currentByte)];
		currentByte++;
	}
	WebSocketData* wsData = buffer.websocketData;
	
	NSString* dataString = [NSString stringWithData: wsData.data encoding: NSUTF8StringEncoding];
	
	NSString* correctResult = [NSString stringWithContentsOfURL: [[NSBundle bundleForClass: [self class]] 
																  URLForResource: @"LongWebSocketHexStringResult.txt" withExtension: nil]
													   encoding: NSUTF8StringEncoding error: nil];
	
	STAssertEqualObjects(dataString, correctResult, nil);
}

-(void)testWebSocketResponseBuffer
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a" error: nil];
	NSUInteger currentByte = 0;
	const void* bytes = [responseBytes bytes];
	while(currentByte < responseBytes.length - 1){
		STAssertFalse([buffer appendByteToBuffer: (u_int8_t*)(bytes + currentByte)], nil);
		STAssertFalse([buffer containsFullResponse], nil);
		currentByte++;
	}
	STAssertTrue([buffer appendByteToBuffer: (u_int8_t*)(bytes + currentByte)], nil);
	STAssertTrue([buffer containsFullResponse], nil);
	
	STAssertEqualObjects(buffer.dataBuffer, responseBytes, nil);
	
}


-(void)testHandshakeResponseBuffer
{
	HandshakeResponseBuffer* buffer = [[HandshakeResponseBuffer alloc] init];
	
	NSString* handshake = @"HTTP/1.1 101 Switching Protocols\nUpgrade: WebSocket\nConnection: Upgrade\nSec-WebSocket-Accept: hrIyuqmFm4k655eTa9Ibgw8Kvss=\nAccess-Control-Allow-Origin: http://ipad.nextthought.com\nAccess-Control-Allow-Credentials: true\r\n\r\n";
	
	NSData* handshakeBytes = [handshake dataUsingEncoding: NSUTF8StringEncoding];
	
	NSUInteger currentByte = 0;
	const void* bytes = [handshakeBytes bytes];
	while(currentByte < handshakeBytes.length - 1){
		STAssertFalse([buffer appendByteToBuffer: (u_int8_t*)(bytes + currentByte)], nil);
		STAssertFalse([buffer containsFullResponse], nil);
		currentByte++;
	}
	STAssertTrue([buffer appendByteToBuffer: (u_int8_t*)(bytes + currentByte)], nil);
	STAssertTrue([buffer containsFullResponse], nil);
	
	STAssertEqualObjects(buffer.dataBuffer, handshakeBytes, nil);
					
}

BOOL isSuccessfulHandshakeResponse(NSString* response, NSString* key);

-(void)testHandshakeParsing
{
	NSString* goodKey = @"w5jCl3LDpwc/Gj4EOgk7UsOXEMKa";
	NSString* handshake = @"HTTP/1.1 101 Switching Protocols\nUpgrade: WebSocket\nConnection: Upgrade\nSec-WebSocket-Accept: hrIyuqmFm4k655eTa9Ibgw8Kvss=\nAccess-Control-Allow-Origin: http://ipad.nextthought.com\nAccess-Control-Allow-Credentials: true\r\n\r\n";
	
	STAssertTrue(isSuccessfulHandshakeResponse(handshake, goodKey), nil);
	
	NSString* badKey = @"foobar";
	
	STAssertFalse(isSuccessfulHandshakeResponse(handshake, badKey), nil);
}

static NSHTTPCookie* cookieWithNameValue(NSString* domain, NSString* name, NSString* value)
{
	NSMutableDictionary* cookieProps = [NSMutableDictionary dictionary];
	[cookieProps setObject: name forKey: NSHTTPCookieName];
	[cookieProps setObject: value 
					forKey: NSHTTPCookieValue];
	[cookieProps setObject: domain forKey: NSHTTPCookieDomain];
	[cookieProps setObject: @"/" forKey: NSHTTPCookiePath];
	[cookieProps setObject: @"60" forKey: NSHTTPCookieMaximumAge];
	
	return [NSHTTPCookie cookieWithProperties: cookieProps];
}

NSString* cookieHeaderForServer(NSURL* server);

-(void)testCookieHeader
{
	NSURL* noCookieHost = [NSURL URLWithString: @"http://foobar.com/"];
	NSURL* cookieHost = [NSURL URLWithString: @"http://cookiehost.com/"];
	
	NSHTTPCookieStorage* cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	//Start with a clean slate
	for(NSHTTPCookie* cookie in [cookieJar cookiesForURL: noCookieHost]){
		[cookieJar deleteCookie: cookie];
	}
	for(NSHTTPCookie* cookie in [cookieJar cookiesForURL: cookieHost]){
		[cookieJar deleteCookie: cookie];
	}
	
	STAssertEqualObjects(cookieHeaderForServer(noCookieHost), @"", @"Excpected empty cookie header", nil);
	
	NSHTTPCookie* c1 = cookieWithNameValue(@"cookiehost.com", @"foo", @"bar");
	[cookieJar setCookie: c1];
	
	STAssertEqualObjects(cookieHeaderForServer(cookieHost), @"Cookie: foo=bar", nil);
	
	NSHTTPCookie* c2 = cookieWithNameValue(@"cookiehost.com", @"red", @"fish");
	[cookieJar setCookie: c2];
	
	STAssertEqualObjects(cookieHeaderForServer(cookieHost), @"Cookie: foo=bar; red=fish", nil);
	
}

@end
