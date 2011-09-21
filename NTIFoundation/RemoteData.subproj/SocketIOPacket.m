//
//  SocketIOPacket.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOPacket.h"
#import "NTIJSON.h"

@implementation SocketIOPacket
@synthesize type, packetId, endpoint, ack, data, reason, advice, ackId, args, qs, name;

static NSArray* piecesFromString(NSString* data, NSString* regexString){
	NSError* error = nil;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: regexString 
																		   options: 0 
																			 error: &error];
	
	if (error) {
		NSLog(@"%@", [error description]);
		return nil;
	}
	
	NSArray* results = [regex matchesInString: data options:0 range:NSMakeRange(0, [data length])];
	NSMutableArray* parts = [NSMutableArray arrayWithCapacity: 5];
	for (NSTextCheckingResult* result in results) {
		
		for(NSInteger i = 1 ; i<=5; i++ ){
			NSRange range = [result rangeAtIndex: i];
			if(range.location == NSNotFound){
				[parts addObject: nil];
			}else{
				[parts addObject: [data substringWithRange: range]];
			}
		}
		
		//Only take the first match
		break;
	}
	return parts;

}

static NSString* stringForErrorReason(SocketIOErrorReason reason)
{
	switch (reason) {
		case SocketIOErrorReasonUnauthorized:
			return @"Unauthorized";
		case SocketIOErrorReasonClientNotHandshaken:
			return @"Client not handshaken";
		case SocketIOErrorReasonTransportUnsupported:
			return @"Unsupported Transport";
		default:
			return @"Unknown";
	}
}

static NSString* stringForErrorAdvice(SocketIOErrorAdvice advice)
{
	switch (advice) {
		case SocketIOErrorAdviceReconnect:
			return @"reconnect";
		default:
			return @"Good luck";
	}
}


+(SocketIOPacket*)decodePacketData: (NSString*)data;
{
	NSArray* pieces = piecesFromString(data, @"([^:]+):([0-9]+)?(\\+)?:([^:]+)?:?([\\s\\S]*)?");
	if( !pieces || ![pieces count] > 0){
		//FIXME raise exception here
		return nil;
	}
	
	NSString* theId = [pieces objectAtIndex: 1] ? [pieces objectAtIndex: 1] : @"";
	NSString* theData = [pieces objectAtIndex: 4] ? [pieces objectAtIndex: 4] : @"";
	
	SocketIOPacket* packet = [[[SocketIOPacket alloc] initWithType: (NSInteger)[pieces firstObject]] autorelease];
	packet.endpoint = [pieces objectAtIndex: 3] ? [pieces objectAtIndex: 3] : @"";
	
	if(theId){
		packet.packetId = theId;
		if([pieces objectAtIndex: 2]){
			packet.ack = @"data";
		}else{
			packet.ack = @"true";
		}
	}
	
	switch(packet.type){
		case SocketIOPacketTypeError:{
			NSArray* errorParts = [theData componentsSeparatedByString: @"+"];
			//FIXME get reason and suggestion text
			NSString* reason = @"";
			NSString* advice = @"";
			
			if([errorParts count] > 0){
				reason = stringForErrorReason( (SocketIOErrorReason) [errorParts firstObject] );
			}
			
			if([errorParts count] > 1){
				reason = stringForErrorAdvice( (SocketIOErrorAdvice) [errorParts secondObject] );
			}
			
			packet.reason = reason;
			packet.advice = advice;
			break;
		}
		case SocketIOPacketTypeMessage:
			packet.data = theData ? theData : @"";
			break;
		case SocketIOPacketTypeJSONMessage:
			packet.data = [theData jsonObjectUnwrap];
		case SocketIOPacketTypeConnect:
			packet.qs = theData ? theData : @"";
			break;
		case SocketIOPacketTypeAck:{
			NSArray* ackPieces = piecesFromString(theData, @"^([0-9]+)(\\+)?(.*)");
			if(ackPieces && [ackPieces count] > 0){
				packet.ack = [ackPieces firstObject];
				packet.args = [NSArray array];
				
				if([ackPieces objectAtIndex: 2])
				{
					packet.args = [ackPieces objectAtIndex: 2] ? 
										[[ackPieces objectAtIndex: 2] jsonObjectUnwrap] : [NSArray array];
				}
			}
			break;
		}
		case SocketIOPacketTypeEvent:{
			NSDictionary* eventObj = [theData jsonObjectUnwrap];
			packet.name = [eventObj objectForKey: @"name"];
			packet.args = [eventObj objectForKey: @"args"];
			
			if(!packet.args){
				packet.args = [NSArray array];
			}
			
			break;
		}
		case SocketIOPacketTypeDisconnect:
			break;
		case SocketIOPacketTypeNoop:
			break;
		case SocketIOPacketTypeHeartbeat:
			break;
		default:
			break;
	}
	
	return packet;
	
}


+(SocketIOPacket*)packetForMessageWithData: (NSString*)data
{
	SocketIOPacket* packet = [[SocketIOPacket alloc] initWithType:SocketIOPacketTypeMessage];
	packet.data = data;
	return [packet autorelease];
}

+(SocketIOPacket*)packetForEventWithName: (NSString*)name andArgs: (NSArray*)args
{
	SocketIOPacket* packet = [[SocketIOPacket alloc] initWithType:SocketIOPacketTypeMessage];
	packet.name = name;
	packet.args = args;
	return [packet autorelease];
}

-(id)initWithType: (SocketIOPacketType)theType
{
    self = [super init];
    if (self) {
        self->type = theType;
    }
    
    return self;
}

-(NSString*)encode
{
	
	NSString* theId = self.packetId ? self.packetId : @"";
	NSString* theEndpoint = self.endpoint ? self.endpoint : @"";
	NSString* theAck = self.ack;
	NSString* theData = nil;
	
	switch(self.type){
		case SocketIOPacketTypeError:
			//TODO reason and advice
			break;
		case SocketIOPacketTypeMessage:
			//FIXME check for empty here?
			if( self.data ){ 
				theData = self.data;
			}
			break;
		case SocketIOPacketTypeJSONMessage:
			theData = [self.data stringWithJsonRepresentation];
			break;
		case SocketIOPacketTypeConnect:
			if(self.qs){
				theData = self.qs;
			}
			break;
		case SocketIOPacketTypeAck:
			theData = self.ackId;
			if(self.args && [self.args count] > 0){
				theData = [theData stringByAppendingString: 
						   [NSString stringWithFormat: @"+%@", 
							[self.args stringWithJsonRepresentation]]];
			}
			break;
		case SocketIOPacketTypeEvent:{
			NSMutableDictionary* event = [NSMutableDictionary dictionaryWithCapacity: 2];
			[event setObject: self.name forKey: @"name"];
			if( self.args && [self.args count] > 0 ){
				[event setObject: self.args forKey: @"args"];
			}
			theData = [event stringWithJsonRepresentation];
			break;
		}
		case SocketIOPacketTypeDisconnect:
			break;
		case SocketIOPacketTypeNoop:
			break;
		case SocketIOPacketTypeHeartbeat:
			break;
		default:
			break;
	}
	
	if( [theAck isEqualToString: @"data"] ){
		theId = [theId stringByAppendingString: @"+"];
	}
	
	NSMutableArray* toEncode = [NSMutableArray arrayWithObjects: [NSString stringWithFormat: @"%d", self.type], theId, theEndpoint , nil];
	
	if( theData ){
		[toEncode addObject: theData];
	}
	
	return [toEncode componentsJoinedByString: @":"];
}

+(NSString*)encodePayload: (NSArray*)payload
{
	NSMutableString* encoded = [NSMutableString stringWithCapacity: 10];
	
	if([payload count] == 1){
		return [payload firstObject];
	}
	
	for( NSString* part in payload){
		[encoded appendFormat: @"\ufffd%d\ufffd%@", [part length], part];
	}
	
	return encoded;
}

+(NSArray*)decodePayload: (NSString*)payload
{
	if( [payload characterAtIndex: 0] == '\ufffd'){
		NSMutableArray* packets = [NSMutableArray arrayWithCapacity: 5];
		NSMutableString* length = [NSMutableString string];
		for(NSUInteger i=0; i < [payload length]; i++){
			if( [payload characterAtIndex: 0] == '\ufffd' ){
				NSInteger lengthInt = [length integerValue];
				NSString* packetString = [[payload substringFromIndex: i+1] 
										  substringToIndex: lengthInt];
				[packets addObject: [SocketIOPacket decodePayload: packetString]];
				i += lengthInt + 1;
				[length setString: @""];
			}
			else{
				[length appendLongCharacter: [length characterAtIndex: i]];
			}
		}
		return packets;
		
	}else{
		return [NSArray arrayWithObject: [SocketIOPacket decodePacketData: payload]];
	}
}

-(void)dealloc
{
	NTI_RELEASE(self->endpoint);
	NTI_RELEASE(self->data);
	NTI_RELEASE(self->packetId);
	NTI_RELEASE(self->ack);
	NTI_RELEASE(self->reason);
	NTI_RELEASE(self->advice);
	NTI_RELEASE(self->ackId);
	NTI_RELEASE(self->args);
	NTI_RELEASE(self->qs);
	NTI_RELEASE(self->name);
	[super dealloc];
}

@end
