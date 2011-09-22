//
//  SocketIOPacket.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOPacket.h"
#import "NTIJSON.h"
#import "NSString-NTIJSON.h"

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
	NSMutableArray* parts = [NSMutableArray arrayWithCapacity: regex.numberOfCaptureGroups];
	for (NSTextCheckingResult* result in results) {
		
		for(NSUInteger i = 1 ; i<=regex.numberOfCaptureGroups; i++ ){
			NSRange range = [result rangeAtIndex: i];
			if(range.location == NSNotFound){
				[parts addObject: @""];
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
	
	NSString* theId = [pieces objectAtIndex: 1];
	NSString* theData = [pieces objectAtIndex: 4];
	
	SocketIOPacket* packet = [[SocketIOPacket alloc] initWithType: [[pieces firstObject] intValue]];
	packet.endpoint = [pieces objectAtIndex: 3];
	
	if(theId){
		packet.packetId = theId;
		if(![[pieces objectAtIndex: 2] isEqualToString: @""]){
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
		case SocketIOPacketTypeObjectMessage:
			packet.data = [theData propertyList];
		case SocketIOPacketTypeConnect:
			packet.qs = theData ? theData : @"";
			break;
		case SocketIOPacketTypeAck:{
			NSArray* ackPieces = piecesFromString(theData, @"^([0-9]+)(\\+)?(.*)");
			if(ackPieces && [ackPieces count] > 0){
				packet.ack = [ackPieces firstObject];
				packet.args = [NSArray array];
				
				if(![[ackPieces objectAtIndex: 2] isEqualToString: @""])
				{
					packet.args = [[ackPieces objectAtIndex: 2] propertyList];
				}
			}
			break;
		}
		case SocketIOPacketTypeEvent:{
			NSDictionary* eventObj = [theData propertyList];
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
	
	return [packet autorelease];
	
}


+(SocketIOPacket*)packetForMessageWithData: (NSString*)data
{
	SocketIOPacket* packet = [[SocketIOPacket alloc] initWithType: SocketIOPacketTypeMessage];
	packet.data = data;
	return [packet autorelease];
}

+(SocketIOPacket*)packetForEventWithName: (NSString*)name andArgs: (NSArray*)args
{
	SocketIOPacket* packet = [[SocketIOPacket alloc] initWithType: SocketIOPacketTypeEvent];
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

-(NSString*)description
{
	return [self encode];
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
		case SocketIOPacketTypeObjectMessage:{
			NSData* plist = [NSPropertyListSerialization dataWithPropertyList: self.data
																  format: NSPropertyListXMLFormat_v1_0
																 options: 0
																   error: NULL];

			theData = [NSString stringWithData: plist encoding: NSUTF8StringEncoding];
			break;
		}
		case SocketIOPacketTypeConnect:
			if(self.qs){
				theData = self.qs;
			}
			break;
		case SocketIOPacketTypeAck:
			theData = self.ackId;
			if(self.args && [self.args count] > 0){
				
				NSData* plist = [NSPropertyListSerialization dataWithPropertyList: self.args
																		   format: NSPropertyListXMLFormat_v1_0
																		  options: 0
																			error: NULL];
				
				theData = [theData stringByAppendingString: 
						   [NSString stringWithFormat: @"+%@", 
							[NSString stringWithData: plist encoding: NSUTF8StringEncoding]]];
			}
			break;
		case SocketIOPacketTypeEvent:{
			NSMutableDictionary* event = [NSMutableDictionary dictionaryWithCapacity: 2];
			[event setObject: self.name forKey: @"name"];
			if( self.args && [self.args count] > 0 ){
				[event setObject: self.args forKey: @"args"];
			}
			NSData* plist = [NSPropertyListSerialization dataWithPropertyList: event
																	   format: NSPropertyListXMLFormat_v1_0
																	  options: 0
																		error: NULL];
			theData = [NSString stringWithData: plist encoding: NSUTF8StringEncoding];
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
	NSString* typeString = [[[NSString alloc] initWithFormat: @"%d", self.type] autorelease];
	
	NSMutableArray* toEncode = [NSMutableArray arrayWithObjects: typeString, theId, theEndpoint , nil];
	
	if( theData ){
		[toEncode addObject: theData];
	}
	
	return [toEncode componentsJoinedByString: @":"];
}

+(NSString*)encodePayload: (NSArray*)payload
{
	NSMutableString* encoded = [NSMutableString stringWithCapacity: 10];
	
	if([payload count] == 1){
		return [[payload firstObject] encode];
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
