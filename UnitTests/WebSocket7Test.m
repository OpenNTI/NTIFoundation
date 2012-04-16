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

@interface WebSocketClose : WebSocketData
@end

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
		STAssertEquals((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
											  maxLength: 1 
									  makesFullResponse: NULL], 1, nil);
		STAssertFalse([buffer containsFullResponse], nil);
		currentByte++;
	}
	STAssertEquals((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
										  maxLength: 1 
								  makesFullResponse: NULL], 1, nil);
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
		STAssertEquals((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
											  maxLength: 1 
									  makesFullResponse: NULL], 1, nil);
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
		STAssertEquals((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
											  maxLength: 1 
									  makesFullResponse: NULL], 1, nil);
		currentByte++;
	}
	WebSocketData* wsData = buffer.websocketData;
	
	NSString* dataString = [NSString stringWithData: wsData.data encoding: NSUTF8StringEncoding];
	
	NSString* correctResult = [NSString stringWithContentsOfURL: [[NSBundle bundleForClass: [self class]] 
																  URLForResource: @"LongWebSocketHexStringResult.txt" withExtension: nil]
													   encoding: NSUTF8StringEncoding error: nil];
	
	STAssertEqualObjects(dataString, correctResult, nil);
}

-(void)testWebSocketResponseBufferAllAtOnce
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a" error: nil];

	BOOL containsFullResponse = NO;
	NSUInteger consumed = [buffer appendBytesToBuffer: (uint8_t*)responseBytes.bytes 
											maxLength: responseBytes.length 
									makesFullResponse: &containsFullResponse];
	
	STAssertTrue(containsFullResponse, nil);
	STAssertEquals(consumed, responseBytes.length, nil);
	STAssertEqualObjects(buffer.dataBuffer, responseBytes, nil);
}

-(void)testWebSocketResponseBufferMultiplePackets
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a8103313a3a" error: nil];
	
	BOOL containsFullResponse = NO;
	NSUInteger consumed = [buffer appendBytesToBuffer: (uint8_t*)responseBytes.bytes 
											maxLength: responseBytes.length 
									makesFullResponse: &containsFullResponse];
	
	STAssertTrue(containsFullResponse, nil);
	STAssertEquals((int)consumed, 5, nil);
	STAssertEqualObjects(buffer.dataBuffer, [NSData dataWithHexString: @"8103313a3a" error: nil], nil);
	
	buffer = [[WebSocketResponseBuffer alloc] init];
	containsFullResponse = NO;
	consumed = [buffer appendBytesToBuffer: (uint8_t*)(responseBytes.bytes + consumed)
								 maxLength: responseBytes.length - consumed 
						 makesFullResponse: &containsFullResponse];
	
	STAssertTrue(containsFullResponse, nil);
	STAssertEquals((int)consumed, 5, nil);
	STAssertEqualObjects(buffer.dataBuffer, [NSData dataWithHexString: @"8103313a3a" error: nil], nil);

}

-(void)testWebSocketResponseBuffer
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a" error: nil];
	NSUInteger currentByte = 0;
	const void* bytes = [responseBytes bytes];
	while(currentByte < responseBytes.length - 1){
		STAssertEquals((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
											  maxLength: 1 
									  makesFullResponse: NULL], 1, nil);
		STAssertFalse([buffer containsFullResponse], nil);
		currentByte++;
	}
	STAssertEquals((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
										  maxLength: 1 
								  makesFullResponse: NULL], 1, nil);
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
		STAssertEquals((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
										maxLength: 1 
								makesFullResponse: NULL], 1, nil);
		STAssertFalse([buffer containsFullResponse], nil);
		currentByte++;
	}
	STAssertEquals((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
										  maxLength: 1 
								  makesFullResponse: NULL], 1, nil);
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

-(void)testCloseFrameGeneration
{
	WebSocketClose* close = [[WebSocketClose alloc] init];
	
	NSData* closeData = [(id)close dataForTransmission];
	
	uint8_t* firstByte = (uint8_t*)closeData.bytes;
	uint8_t* secondByte = (uint8_t*)(closeData.bytes + 1);
	STAssertEquals(*firstByte, (uint8_t)0x88, nil);
	STAssertEquals(*secondByte, (uint8_t)0x80, nil);
	
	STAssertEquals((int)closeData.length, 6, nil);
}

-(void)testCloseResponse
{
	NSMutableData* closeBytes = [NSMutableData dataWithHexString: @"0x8800" error: nil];
	STAssertNotNil(closeBytes, @"Unable to parse close bytes");
	
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	BOOL isFull = NO;
	[buffer appendBytesToBuffer: (uint8_t*)closeBytes.bytes maxLength: 4 makesFullResponse: &isFull];
	
	STAssertTrue(isFull, @"Expected full buffer");
	
	STAssertTrue([buffer isCloseResponse], @"Expected close response");
}

NSString* generateSecWebsocketKey();

-(void)testSecWebsocketKeyGenerationIsRightLength
{
	NSString* key = generateSecWebsocketKey();
	NSData* data = [NSData dataWithBase64String: key];
	STAssertEquals((int)data.length, 16, @"Expected 16 bytes of data but got");
}

void sizeToBytes(NSUInteger length, uint8_t* sizeInfoPointer, int* sizeLength);
-(void)testSizeToBytesSmall
{
	NSUInteger smallSize = 87;
	
	uint8_t bytes[8];
	int length;
	
	sizeToBytes(smallSize, bytes, &length);
	
	STAssertEquals(length, 1, @"Expected one byte", nil);
	STAssertEquals((int)bytes[0], 87, @"Excpected size of 174", nil);
}

-(void)testSizeToBytesMedium
{
	NSUInteger smallSize = 312;
	
	uint8_t bytes[8];
	int length;
	
	sizeToBytes(smallSize, bytes, &length);
	
	STAssertEquals(length, 3, @"Expected one byte", nil);
	STAssertEquals((int)bytes[0], 126, @"Excpected size control of 126", nil);
	STAssertEquals((int)bytes[1], 1, @"Excpected most significant byte of 1", nil);
	STAssertEquals((int)bytes[2], 56, @"Excpected least significant byte of 56", nil);
}

-(void)testSizeToBytesLong
{
	//9 876 543 = 0x96B43F
	NSUInteger smallSize = 9876543;
	
	uint8_t bytes[9];
	int length;
	
	sizeToBytes(smallSize, bytes, &length);
	
	STAssertEquals(length, 9, @"Expected one byte", nil);
	STAssertEquals((int)bytes[0], 127, @"Excpected size control of 127", nil);
	STAssertEquals((int)bytes[1], 0, @"Excpected byte 1 to be 0", nil);
	STAssertEquals((int)bytes[2], 0, @"Excpected byte 2 to be 0", nil);
	STAssertEquals((int)bytes[3], 0, @"Excpected byte 3 to be 0", nil);
	STAssertEquals((int)bytes[4], 0, @"Excpected byte 4 to be 0", nil);
	STAssertEquals((int)bytes[5], 0, @"Excpected byte 5 to be 0", nil);
	STAssertEquals((int)bytes[6], 150, @"Excpected byte 6 to be 0", nil);
	STAssertEquals((int)bytes[7], 180, @"Excpected byte 7 to be 0", nil);
	STAssertEquals((int)bytes[8], 63, @"Excpected byte 8 to be 0", nil);
}

@end
