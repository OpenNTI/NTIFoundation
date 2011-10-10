//
//  SocketIOPacketTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/10/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOPacketTest.h"
#import "SocketIOPacket.h"

@implementation SocketIOPacketTest

#define STAssertPacketType(packet, theType)\
	STAssertTrue(packet.type == theType,\
				  @"Expected packet of type %ld but found %ld", theType, packet.type);


-(SocketIOPacket*)packetForString: (NSString*)str
{
	return [SocketIOPacket decodePacketData: [str dataUsingEncoding: NSUTF8StringEncoding]];
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
	SocketIOPacket* event = [self packetForString: @"5:::<?xml version=\"1.0\" encoding=\"UTF-8\"?>\
							 <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\
							 <plist version=\"1.0\">\
							 <dict>\
							 <key>args</key>\
							 <array>\
							 <string>chris.utz@nextthought.com</string>\
							 </array>\
							 <key>name</key>\
							 <string>chat_enteredRoom</string>\
							 </dict>\
							 </plist>"];
	
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

@end
