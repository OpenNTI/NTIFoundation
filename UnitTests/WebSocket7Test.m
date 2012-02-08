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

-(void)testWebSocketResponseToData
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

@end
