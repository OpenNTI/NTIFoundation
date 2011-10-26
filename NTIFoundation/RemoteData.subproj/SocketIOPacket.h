//
//  SocketIOPacket.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>

enum {
	SocketIOPacketTypeDisconnect = 0,
	SocketIOPacketTypeConnect = 1,
	SocketIOPacketTypeHeartbeat = 2,
	SocketIOPacketTypeMessage = 3,
	SocketIOPacketTypeObjectMessage = 4,
	SocketIOPacketTypeEvent = 5,
	SocketIOPacketTypeAck = 6,
	SocketIOPacketTypeError = 7,
	SocketIOPacketTypeNoop = 8,
	SocketIOPacketTypeMax = SocketIOPacketTypeNoop,
	SocketIOPacketTypeMin = SocketIOPacketTypeDisconnect
};
typedef NSInteger SocketIOPacketType;

enum {
	SocketIOErrorReasonTransportUnsupported,
	SocketIOErrorReasonClientNotHandshaken,
	SocketIOErrorReasonUnauthorized
};
typedef NSInteger SocketIOErrorReason;

enum {
	SocketIOErrorAdviceReconnect
};
typedef NSInteger SocketIOErrorAdvice;

@interface SocketIOPacket : OFObject{
	@private
	SocketIOPacketType type;
	NSString* packetId;
	NSString* endpoint;
	NSString* ack;
	id data;
	NSString* reason;
	NSString* advice;
	NSString* ackId;
	NSString* qs;
	NSArray* args;
	NSString* name;
}
@property (nonatomic, readonly) SocketIOPacketType type;
@property (nonatomic, strong) NSString* packetId;
@property (nonatomic, strong) NSString* endpoint;
@property (nonatomic, strong) NSString* ack;
@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSString* reason;
@property (nonatomic, strong) NSString* advice;
@property (nonatomic, strong) NSString* ackId;
@property (nonatomic, copy) NSArray* args;
@property (nonatomic, strong) NSString* qs;
@property (nonatomic, strong) NSString* name;
+(SocketIOPacket*)packetForHeartbeat;
+(SocketIOPacket*)packetForMessageWithData: (NSString*)data;
+(SocketIOPacket*)packetForEventWithName: (NSString*)name andArgs: (NSArray*)args;
+(SocketIOPacket*)decodePacketData: (NSData*)data;
-(id)initWithType: (SocketIOPacketType)theType;
-(NSData*)encode;
+(NSData*)encodePayload: (NSArray*)payload;
+(NSArray*)decodePayload: (NSData*)payload;

@end
