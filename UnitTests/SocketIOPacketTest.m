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

#define STAssertPacketType(packet, theType)\
	STAssertTrue(packet.type == theType,\
				  @"Expected packet of type %ld but found %ld", theType, packet.type);


-(SocketIOPacket*)packetForString: (NSString*)str
{
	return [SocketIOPacket decodePacketData: [str dataUsingEncoding: NSUTF8StringEncoding]];
}

-(void)testDecodePayloadTakesPacket
{
	NSString* toDecode = @"3:1::blabla";
	
	NSArray* decoded = [SocketIOPacket decodePayload: [toDecode dataUsingEncoding: NSUTF8StringEncoding]];
	
	STAssertEquals((int)decoded.count, 1, @"Excpected one packet");
	
	SocketIOPacket* packet = [decoded firstObject];
	
	STAssertPacketType(packet, SocketIOPacketTypeMessage);
	STAssertEqualObjects(packet.packetId, @"1", @"Wrong packet id");
	STAssertEqualObjects(packet.data, @"blabla", @"Bad packet data");
}

-(void)testParseSpecialDisconnect
{
	SocketIOPacket* disconnect = [self packetForString: @"0"];
	STAssertPacketType(disconnect, SocketIOPacketTypeDisconnect);
}

-(void)testParseHeartbeat
{
	SocketIOPacket* heartbeat = [self packetForString: @"2::"];
	
	STAssertPacketType(heartbeat, SocketIOPacketTypeHeartbeat);
}

-(void)testSerializeHeartbeat
{
	
	NSData* heartbeatData = [@"2::" dataUsingEncoding: NSUTF8StringEncoding];
	
	SocketIOPacket* heartbeat = [SocketIOPacket decodePacketData: heartbeatData];
	
	STAssertEqualObjects([heartbeat encode], heartbeatData, nil);
	
	heartbeat = [SocketIOPacket packetForHeartbeat];
	
	STAssertEqualObjects([heartbeat encode], heartbeatData, nil);
	
}

-(void)testParseNoop
{
	SocketIOPacket* noop = [self packetForString: @"8::"];
	
	STAssertPacketType(noop, SocketIOPacketTypeNoop);
}

-(void)testSerializeNoop
{
	NSData* noopData = [@"8::" dataUsingEncoding: NSUTF8StringEncoding];
	
	SocketIOPacket* noop = [SocketIOPacket decodePacketData: noopData];
	
	STAssertEqualObjects([noop encode], noopData, nil);
}

-(void)testParseMessage
{	
	SocketIOPacket* message = [self packetForString: @"3:1::blabla"];
	
	STAssertPacketType(message, SocketIOPacketTypeMessage);
	
	STAssertEqualObjects(message.data, @"blabla",nil);
}

-(void)testSerializeMessage
{
	
	NSData* messageData = [@"3:::blabla" dataUsingEncoding: NSUTF8StringEncoding];
	
	SocketIOPacket* message = [SocketIOPacket decodePacketData: messageData];
	
	STAssertEqualObjects([message encode], messageData, nil);
	
	message = [SocketIOPacket packetForMessageWithData: @"blabla"];
	
	STAssertEqualObjects([message encode], messageData, nil);
	
}

-(void)testParseEvent
{	
	SocketIOPacket* event = [self packetForString: @"5:::{\"args\": [\"chris.utz@nextthought.com\"], \"name\": \"chat_enteredRoom\"}"];
	
	STAssertPacketType(event, SocketIOPacketTypeEvent);
	STAssertEqualObjects(event.name, @"chat_enteredRoom", nil);
	STAssertEqualObjects(event.args, [NSArray arrayWithObject: @"chris.utz@nextthought.com"], nil);
}

-(void)testSerializeEvent
{	
	SocketIOPacket* eventPacket = [SocketIOPacket packetForEventWithName: @"chat_enteredRoom" 
																 andArgs: [NSArray arrayWithObject: @"chris.utz@nextthought.com"]];
	
	SocketIOPacket* serializedAndDecoded = [SocketIOPacket decodePacketData: [eventPacket encode]];
	
	STAssertPacketType(serializedAndDecoded, SocketIOPacketTypeEvent);
	STAssertEqualObjects(serializedAndDecoded.name, eventPacket.name, nil);
	STAssertEqualObjects(serializedAndDecoded.args, eventPacket.args, nil);
	
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
	
	STAssertEqualObjects(encodedPackets, expectedData, nil);
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
	STAssertPacketType(p, SocketIOPacketTypeHeartbeat);
	
	p = [decodedPackets secondObject];
	STAssertPacketType(p, SocketIOPacketTypeMessage);
	STAssertEqualObjects(p.data, @"blahblahblah", nil);
	
	p = [decodedPackets lastObject];
	STAssertPacketType(p, SocketIOPacketTypeNoop);
}

@end
