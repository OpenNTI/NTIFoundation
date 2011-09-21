//
//  SocketIOPacket.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>

typedef enum {
	SocketIOPacketTypeDisconnect = 0,
	SocketIOPacketTypeConnect = 1,
	SocketIOPacketTypeHeartbeat = 2,
	SocketIOPacketTypeMessage = 3,
	SocketIOPacketTypeJSONMessage = 4,
	SocketIOPacketTypeEvent = 5,
	SocketIOPacketTypeAck = 6,
	SocketIOPacketTypeError = 7,
	SocketIOPacketTypeNoop = 8
} SocketIOPacketType;

typedef enum {
	SocketIOErrorReasonTransportUnsupported,
	SocketIOErrorReasonClientNotHandshaken,
	SocketIOErrorReasonUnauthorized
} SocketIOErrorReason;

typedef enum {
	SocketIOErrorAdviceReconnect
} SocketIOErrorAdvice;

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
@property (readonly, assign) SocketIOPacketType type;
@property (nonatomic, retain) NSString* packetId;
@property (nonatomic, retain) NSString* endpoint;
@property (nonatomic, retain) NSString* ack;
@property (nonatomic, retain) id data;
@property (nonatomic, retain) NSString* reason;
@property (nonatomic, retain) NSString* advice;
@property (nonatomic, retain) NSString* ackId;
@property (nonatomic, copy) NSArray* args;
@property (nonatomic, retain) NSString* qs;
@property (nonatomic, retain) NSString* name;
+(SocketIOPacket*)packetForMessageWithData: (NSString*)data;
+(SocketIOPacket*)packetForEventWithName: (NSString*)name andArgs: (NSArray*)args;
+(SocketIOPacket*)decodePacketData: (NSString*)data;
-(id)initWithType: (SocketIOPacketType)theType;
-(NSString*)encode;
+(NSString*)encodePayload: (NSArray*)payload;
+(NSArray*)decodePayload: (NSString*)payload;

@end
