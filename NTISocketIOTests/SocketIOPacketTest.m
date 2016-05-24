//
//  SocketIOPacketTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/10/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOPacketTest.h"
#import "SocketIOPacket.h"
#import "NSArray-NTIExtensions.h"

@implementation SocketIOPacketTest

#define XCTAssertPacketType(packet, theType)\
	XCTAssertTrue(packet.type == theType,\
				  @"Expected packet of type %lu but found %lu", (unsigned long)theType, (unsigned long)packet.type);


-(SocketIOPacket*)packetForString: (NSString*)str
{
	return [SocketIOPacket decodePacketData: [str dataUsingEncoding: NSUTF8StringEncoding]];
}

-(void)testDecodePayloadTakesPacket
{
	NSString* toDecode = @"3:1::blabla";
	
	NSArray* decoded = [SocketIOPacket decodePayload: [toDecode dataUsingEncoding: NSUTF8StringEncoding]];
	
	XCTAssertEqual((int)decoded.count, 1, @"Excpected one packet");
	
	SocketIOPacket* packet = [decoded firstObject];
	
	XCTAssertPacketType(packet, SocketIOPacketTypeMessage);
	XCTAssertEqualObjects(packet.packetId, @"1", @"Wrong packet id");
	XCTAssertEqualObjects(packet.data, @"blabla", @"Bad packet data");
}

-(void)testParseSpecialDisconnect
{
	SocketIOPacket* disconnect = [self packetForString: @"0"];
	XCTAssertPacketType(disconnect, SocketIOPacketTypeDisconnect);
}

-(void)testParseHeartbeat
{
	SocketIOPacket* heartbeat = [self packetForString: @"2::"];
	
	XCTAssertPacketType(heartbeat, SocketIOPacketTypeHeartbeat);
}

-(void)testSerializeHeartbeat
{
	
	NSData* heartbeatData = [@"2::" dataUsingEncoding: NSUTF8StringEncoding];
	
	SocketIOPacket* heartbeat = [SocketIOPacket decodePacketData: heartbeatData];
	
	XCTAssertEqualObjects([heartbeat encode], heartbeatData);
	
	heartbeat = [SocketIOPacket packetForHeartbeat];
	
	XCTAssertEqualObjects([heartbeat encode], heartbeatData);
	
}

-(void)testParseNoop
{
	SocketIOPacket* noop = [self packetForString: @"8::"];
	
	XCTAssertPacketType(noop, SocketIOPacketTypeNoop);
}

-(void)testSerializeNoop
{
	NSData* noopData = [@"8::" dataUsingEncoding: NSUTF8StringEncoding];
	
	SocketIOPacket* noop = [SocketIOPacket decodePacketData: noopData];
	
	XCTAssertEqualObjects([noop encode], noopData);
}

-(void)testParseMessage
{	
	SocketIOPacket* message = [self packetForString: @"3:1::blabla"];
	
	XCTAssertPacketType(message, SocketIOPacketTypeMessage);
	
	XCTAssertEqualObjects(message.data, @"blabla");
}

-(void)testSerializeMessage
{
	
	NSData* messageData = [@"3:::blabla" dataUsingEncoding: NSUTF8StringEncoding];
	
	SocketIOPacket* message = [SocketIOPacket decodePacketData: messageData];
	
	XCTAssertEqualObjects([message encode], messageData);
	
	message = [SocketIOPacket packetForMessageWithData: @"blabla"];
	
	XCTAssertEqualObjects([message encode], messageData);
	
}

-(void)testParseEvent
{	
	SocketIOPacket* event = [self packetForString: @"5:::{\"args\": [\"chris.utz@nextthought.com\"], \"name\": \"chat_enteredRoom\"}"];
	
	XCTAssertPacketType(event, SocketIOPacketTypeEvent);
	XCTAssertEqualObjects(event.name, @"chat_enteredRoom");
	XCTAssertEqualObjects(event.args, [NSArray arrayWithObject: @"chris.utz@nextthought.com"]);
}

-(void)testSerializeEvent
{	
	SocketIOPacket* eventPacket = [SocketIOPacket packetForEventWithName: @"chat_enteredRoom" 
																 andArgs: [NSArray arrayWithObject: @"chris.utz@nextthought.com"]];
	
	SocketIOPacket* serializedAndDecoded = [SocketIOPacket decodePacketData: [eventPacket encode]];
	
	XCTAssertPacketType(serializedAndDecoded, SocketIOPacketTypeEvent);
	XCTAssertEqualObjects(serializedAndDecoded.name, eventPacket.name);
	XCTAssertEqualObjects(serializedAndDecoded.args, eventPacket.args);
	
}

-(void)testEncodePayload
{
	NSArray* packets = [NSArray arrayWithObjects: 
						[self packetForString: @"2::"],
						[self packetForString: @"3:::blahblahblah"],
						[self packetForString: @"8::"], nil];
	
	NSData* encodedPackets = [SocketIOPacket encodePayload: packets];
	
	NSMutableData* expectedData = [NSMutableData dataWithCapacity: 50];
	
	uint8_t separator[3];
	separator[0] = 0xef;
	separator[1] = 0xbf;
	separator[2] = 0xbd;
	
	for(SocketIOPacket* packet in packets){
		
		NSData* packetData = [packet encode];
		
		[expectedData appendBytes: separator length: 3];
		NSString* lengthString = [NSString stringWithFormat: @"%lu", (unsigned long)[packetData length]];
		NSData* lengthData = [lengthString dataUsingEncoding: NSUTF8StringEncoding];
		[expectedData appendData: lengthData];
		[expectedData appendBytes: separator length: 3];
		[expectedData appendData: packetData];
	}
	
	XCTAssertEqualObjects(encodedPackets, expectedData);
}

-(void)testDecodePayload
{
	NSArray* packets = [NSArray arrayWithObjects: 
						[self packetForString: @"2::"],
						[self packetForString: @"3:::blahblahblah"],
						[self packetForString: @"8::"], nil];
	
	NSData* encodedPackets = [SocketIOPacket encodePayload: packets];

	NSArray* decodedPackets = [SocketIOPacket decodePayload: encodedPackets];
	
	SocketIOPacket* p = [decodedPackets firstObject];
	XCTAssertPacketType(p, SocketIOPacketTypeHeartbeat);
	
	p = [decodedPackets secondObject];
	XCTAssertPacketType(p, SocketIOPacketTypeMessage);
	XCTAssertEqualObjects(p.data, @"blahblahblah");
	
	p = [decodedPackets lastObject];
	XCTAssertPacketType(p, SocketIOPacketTypeNoop);
}

@end
