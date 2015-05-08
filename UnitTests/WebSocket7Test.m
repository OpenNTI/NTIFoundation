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
		XCTAssertEqual((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
											  maxLength: 1 
									  makesFullResponse: NULL], 1);
		XCTAssertFalse([buffer containsFullResponse]);
		currentByte++;
	}
	XCTAssertEqual((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
										  maxLength: 1 
								  makesFullResponse: NULL], 1);
	XCTAssertTrue([buffer containsFullResponse]);
	
	XCTAssertEqualObjects(buffer.dataBuffer, responseBytes);
}

-(void)testLongWebSocketResponseToData
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a" error: nil];
	NSUInteger currentByte = 0;
	const void* bytes = [responseBytes bytes];
	while(currentByte < responseBytes.length){
		XCTAssertEqual((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
											  maxLength: 1 
									  makesFullResponse: NULL], 1);
		currentByte++;
	}
	WebSocketData* wsData = buffer.websocketData;
	
	NSString* dataString = [NSString stringWithData: wsData.data encoding: NSUTF8StringEncoding];
	
	XCTAssertEqualObjects(dataString, @"1::");
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
		XCTAssertEqual((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
											  maxLength: 1 
									  makesFullResponse: NULL], 1);
		currentByte++;
	}
	WebSocketData* wsData = buffer.websocketData;
	
	NSString* dataString = [NSString stringWithData: wsData.data encoding: NSUTF8StringEncoding];
	
	NSString* correctResult = [NSString stringWithContentsOfURL: [[NSBundle bundleForClass: [self class]] 
																  URLForResource: @"LongWebSocketHexStringResult.txt" withExtension: nil]
													   encoding: NSUTF8StringEncoding error: nil];
	
	XCTAssertEqualObjects(dataString, correctResult);
}

-(void)testWebSocketResponseBufferAllAtOnce
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a" error: nil];

	BOOL containsFullResponse = NO;
	NSUInteger consumed = [buffer appendBytesToBuffer: (uint8_t*)responseBytes.bytes 
											maxLength: responseBytes.length 
									makesFullResponse: &containsFullResponse];
	
	XCTAssertTrue(containsFullResponse);
	XCTAssertEqual(consumed, responseBytes.length);
	XCTAssertEqualObjects(buffer.dataBuffer, responseBytes);
}

-(void)testWebSocketResponseBufferMultiplePackets
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a8103313a3a" error: nil];
	
	BOOL containsFullResponse = NO;
	NSUInteger consumed = [buffer appendBytesToBuffer: (uint8_t*)responseBytes.bytes 
											maxLength: responseBytes.length 
									makesFullResponse: &containsFullResponse];
	
	XCTAssertTrue(containsFullResponse);
	XCTAssertEqual((int)consumed, 5);
	XCTAssertEqualObjects(buffer.dataBuffer, [NSData dataWithHexString: @"8103313a3a" error: nil]);
	
	buffer = [[WebSocketResponseBuffer alloc] init];
	containsFullResponse = NO;
	consumed = [buffer appendBytesToBuffer: (uint8_t*)(responseBytes.bytes + consumed)
								 maxLength: responseBytes.length - consumed 
						 makesFullResponse: &containsFullResponse];
	
	XCTAssertTrue(containsFullResponse);
	XCTAssertEqual((int)consumed, 5);
	XCTAssertEqualObjects(buffer.dataBuffer, [NSData dataWithHexString: @"8103313a3a" error: nil]);

}

-(void)testWebSocketResponseBuffer
{
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	NSData* responseBytes = [NSData dataWithHexString: @"8103313a3a" error: nil];
	NSUInteger currentByte = 0;
	const void* bytes = [responseBytes bytes];
	while(currentByte < responseBytes.length - 1){
		XCTAssertEqual((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
											  maxLength: 1 
									  makesFullResponse: NULL], 1);
		XCTAssertFalse([buffer containsFullResponse]);
		currentByte++;
	}
	XCTAssertEqual((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
										  maxLength: 1 
								  makesFullResponse: NULL], 1);
	XCTAssertTrue([buffer containsFullResponse]);
	
	XCTAssertEqualObjects(buffer.dataBuffer, responseBytes);
}


-(void)testHandshakeResponseBuffer
{
	HandshakeResponseBuffer* buffer = [[HandshakeResponseBuffer alloc] init];
	
	NSString* handshake = @"HTTP/1.1 101 Switching Protocols\nUpgrade: WebSocket\nConnection: Upgrade\nSec-WebSocket-Accept: hrIyuqmFm4k655eTa9Ibgw8Kvss=\nAccess-Control-Allow-Origin: http://ipad.nextthought.com\nAccess-Control-Allow-Credentials: true\r\n\r\n";
	
	NSData* handshakeBytes = [handshake dataUsingEncoding: NSUTF8StringEncoding];
	
	NSUInteger currentByte = 0;
	const void* bytes = [handshakeBytes bytes];
	while(currentByte < handshakeBytes.length - 1){
		XCTAssertEqual((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
										maxLength: 1 
								makesFullResponse: NULL], 1);
		XCTAssertFalse([buffer containsFullResponse]);
		currentByte++;
	}
	XCTAssertEqual((int)[buffer appendBytesToBuffer: (uint8_t*)bytes+currentByte 
										  maxLength: 1 
								  makesFullResponse: NULL], 1);
	XCTAssertTrue([buffer containsFullResponse]);
	
	XCTAssertEqualObjects(buffer.dataBuffer, handshakeBytes);
					
}

-(void)testHandshakeResponseBufferReturnsCorrectConsumptionLength
{
	NSString* fullHandshake = @"HTTP/1.1 101 Switching Protocols\nUpgrade: websocket\n"
								"Connection: Upgrade\nSec-WebSocket-Accept: lLqFF6P67X8D9hOfRq1A5BR073Y=\r\n\r\n";
	

	NSData* fullHandshakeData = [fullHandshake dataUsingEncoding: NSUTF8StringEncoding];
	
	NSUInteger fullLength = fullHandshakeData.length;
	
	HandshakeResponseBuffer* buffer = [[HandshakeResponseBuffer alloc] init];
	NSUInteger consumed = [buffer appendBytesToBuffer: (uint8_t*)fullHandshakeData.bytes
											maxLength: fullLength 
									makesFullResponse: NULL];
	
	XCTAssertEqual(fullLength, consumed, 
				   @"Expected all bytes (%ld) to be consumed but only consumed %ld", 
				   (unsigned long)fullLength, (unsigned long)consumed);
	
	NSMutableData* handshakeWithMore = [NSMutableData dataWithData: fullHandshakeData];
	[handshakeWithMore appendData: [@"foobarfalksdfaldf" dataUsingEncoding: NSUTF8StringEncoding]];
	
	consumed = [buffer appendBytesToBuffer: (uint8_t*)handshakeWithMore.bytes
								 maxLength: handshakeWithMore.length 
						 makesFullResponse: NULL];
	XCTAssertTrue( handshakeWithMore.length > fullLength);
	XCTAssertEqual(fullLength, consumed, 
				   @"Expected %ld bytes to be consumed but only consumed %ld", 
				   (unsigned long)fullLength, (unsigned long)consumed);
}

-(void)testCloseFrameGeneration
{
	WebSocketClose* close = [[WebSocketClose alloc] init];
	
	NSData* closeData = [(id)close dataForTransmission];
	
	uint8_t* firstByte = (uint8_t*)closeData.bytes;
	uint8_t* secondByte = (uint8_t*)(closeData.bytes + 1);
	XCTAssertEqual(*firstByte, (uint8_t)0x88);
	XCTAssertEqual(*secondByte, (uint8_t)0x80);
	
	XCTAssertEqual((int)closeData.length, 6);
}

-(void)testCloseResponse
{
	NSMutableData* closeBytes = [NSMutableData dataWithHexString: @"0x8800" error: nil];
	XCTAssertNotNil(closeBytes, @"Unable to parse close bytes");
	
	WebSocketResponseBuffer* buffer = [[WebSocketResponseBuffer alloc] init];
	BOOL isFull = NO;
	[buffer appendBytesToBuffer: (uint8_t*)closeBytes.bytes maxLength: 4 makesFullResponse: &isFull];
	
	XCTAssertTrue(isFull, @"Expected full buffer");
	
	XCTAssertTrue([buffer isCloseResponse], @"Expected close response");
}

//NSString* generateSecWebsocketKey();
//
//-(void)testSecWebsocketKeyGenerationIsRightLength
//{
//	NSString* key = generateSecWebsocketKey();
//	NSData* data = [NSData dataWithBase64String: key];
//	XCTAssertEqual((int)data.length, 16, @"Expected 16 bytes of data but got");
//}
//
//void sizeToBytes(NSUInteger length, uint8_t* sizeInfoPointer, int* sizeLength);
//-(void)testSizeToBytesSmall
//{
//	NSUInteger smallSize = 87;
//	
//	uint8_t bytes[8];
//	int length;
//	
//	sizeToBytes(smallSize, bytes, &length);
//	
//	XCTAssertEqual(length, 1, @"Expected one byte", nil);
//	XCTAssertEqual((int)bytes[0], 87, @"Excpected size of 174", nil);
//}
//
//-(void)testSizeToBytesMedium
//{
//	NSUInteger smallSize = 312;
//	
//	uint8_t bytes[8];
//	int length;
//	
//	sizeToBytes(smallSize, bytes, &length);
//	
//	XCTAssertEqual(length, 3, @"Expected one byte", nil);
//	XCTAssertEqual((int)bytes[0], 126, @"Excpected size control of 126", nil);
//	XCTAssertEqual((int)bytes[1], 1, @"Excpected most significant byte of 1", nil);
//	XCTAssertEqual((int)bytes[2], 56, @"Excpected least significant byte of 56", nil);
//}
//
//-(void)testSizeToBytesLong
//{
//	//9 876 543 = 0x96B43F
//	NSUInteger smallSize = 9876543;
//	
//	uint8_t bytes[9];
//	int length;
//	
//	sizeToBytes(smallSize, bytes, &length);
//	
//	XCTAssertEqual(length, 9, @"Expected one byte", nil);
//	XCTAssertEqual((int)bytes[0], 127, @"Excpected size control of 127", nil);
//	XCTAssertEqual((int)bytes[1], 0, @"Excpected byte 1 to be 0", nil);
//	XCTAssertEqual((int)bytes[2], 0, @"Excpected byte 2 to be 0", nil);
//	XCTAssertEqual((int)bytes[3], 0, @"Excpected byte 3 to be 0", nil);
//	XCTAssertEqual((int)bytes[4], 0, @"Excpected byte 4 to be 0", nil);
//	XCTAssertEqual((int)bytes[5], 0, @"Excpected byte 5 to be 0", nil);
//	XCTAssertEqual((int)bytes[6], 150, @"Excpected byte 6 to be 0", nil);
//	XCTAssertEqual((int)bytes[7], 180, @"Excpected byte 7 to be 0", nil);
//	XCTAssertEqual((int)bytes[8], 63, @"Excpected byte 8 to be 0", nil);
//}

@end
