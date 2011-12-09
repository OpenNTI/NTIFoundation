//
//  SocketIOPacket.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "SocketIOPacket.h"
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


+(SocketIOPacket*)decodePacketData: (NSData*)data;
{
	NSString* dataString = [NSString stringWithData: data encoding: NSUTF8StringEncoding];
	NSArray* pieces = piecesFromString(dataString, @"([^:]+):([0-9]+)?(\\+)?:([^:]+)?:?([\\s\\S]*)?");
	if( !pieces || ![pieces count] > 0){
		//The spec allows for a simple 0 to be passed back.
		//FIXME special cased.
		if( [dataString isEqualToString: @"0"] ){
			SocketIOPacket* disconnect = [[SocketIOPacket alloc] initWithType: SocketIOPacketTypeDisconnect];
			return disconnect;
		}
		
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
		case SocketIOPacketTypeEvent: {
			NSDictionary* eventObj = nil;
			NSString* parsedAs = @"plist";
			@try {
				eventObj = [theData propertyList];
			}
			@catch( NSException* ex ) {
				//While this would be ideal our hacked together
				//json support on IOS4 does not support dictionaries.
				eventObj = [theData jsonObjectValue];
				parsedAs = @"json";
			}
			
			if(![eventObj respondsToSelector:@selector(objectForKey:)]){
				[[NSException exceptionWithName: @"InvalidData" 
										 reason: [NSString stringWithFormat: 
												  @"Event packets expect data in the format of a dictionary but parsed as %@ data was %@", parsedAs, eventObj] 
									   userInfo: nil] raise];
			}
			
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

+(SocketIOPacket*)packetForHeartbeat
{
	SocketIOPacket* packet = [[SocketIOPacket alloc] initWithType: SocketIOPacketTypeHeartbeat];
	return packet;
}

+(SocketIOPacket*)packetForMessageWithData: (NSString*)data
{
	SocketIOPacket* packet = [[SocketIOPacket alloc] initWithType: SocketIOPacketTypeMessage];
	packet.data = data;
	return packet;
}

+(SocketIOPacket*)packetForEventWithName: (NSString*)name andArgs: (NSArray*)args
{
	SocketIOPacket* packet = [[SocketIOPacket alloc] initWithType: SocketIOPacketTypeEvent];
	packet.name = name;
	packet.args = args;
	return packet;
}

-(id)initWithType: (SocketIOPacketType)theType
{
    self = [super init];
    if (self) {
        self->type = theType;
    }
    
    return self;
}
//
//-(NSString*)description
//{
//	//return [self encode];
//}

-(NSData*)encode
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
	NSString* typeString = [[NSString alloc] initWithFormat: @"%d", self.type];
	
	NSMutableArray* toEncode = [NSMutableArray arrayWithObjects: typeString, theId, theEndpoint , nil];
	
	if( theData ){
		[toEncode addObject: theData];
	}
	
	NSString* string = [toEncode componentsJoinedByString: @":"];
	
	return [string dataUsingEncoding: NSUTF8StringEncoding];
}

+(NSData*)encodePayload: (NSArray*)payload
{
	NSMutableData* data = [NSMutableData data];
	
	if([payload count] == 1){
		return [[payload firstObject] encode];
	}
	
	uint8_t first = 0xef;
	uint8_t second = 0xbf;
	uint8_t thrid = 0xbd;
	for( SocketIOPacket* part in payload){
		NSData* packetData = [part encode];
		[data appendBytes: &first length: 1];
		[data appendBytes: &second length: 1];
		[data appendBytes: &thrid length: 1];
		
		NSString* lengthString = [NSString stringWithFormat: @"%d", [packetData length]];
		NSData* lengthData = [lengthString dataUsingEncoding: NSUTF8StringEncoding];
		[data appendData: lengthData];
		
		[data appendBytes: &first length: 1];
		[data appendBytes: &second length: 1];
		[data appendBytes: &thrid length: 1];
		
		[data appendData: packetData];
	}
	
	return data;
}

+(NSArray*)decodePayload: (NSData*)payload
{
	NSArray* result = nil;

	uint8_t separtorLength = 3;
	uint8_t separator[separtorLength];
	separator[0] = 0xef;
	separator[1] = 0xbf;
	separator[2] = 0xbd;
	NSData* separatorData = [NSData dataWithBytes: separator length: separtorLength];
	
	//If our payload starts with 0xfffd then its a payload
	NSUInteger payloadLength = [payload length];
	
	NSRange firstSeperator = NSMakeRange(NSNotFound, 0);
	
	//This will throw a NSRangeException if separatorData is not within the 
	//payloads range
	@try{
		firstSeperator = [payload rangeOfData: separatorData 
									  options: NSDataSearchAnchored 
										range: NSMakeRange(0, separtorLength)];
	}
	@catch (NSException* ex) {
		//If it's not even big enough to hold a separator
		//hopefully its a single packet
	}
	
	if( firstSeperator.location == 0 ) {
		NSUInteger location=0;
		NSMutableArray* packets = [NSMutableArray arrayWithCapacity: 3];
		do {
			//Move past the two bytes that are the separator
			location = location + separtorLength;
			
			NSRange nextSepartor = [payload rangeOfData: separatorData 
												options: (int)0 
												  range: NSMakeRange(location, payloadLength - location)];
			if( nextSepartor.location == NSNotFound ){
				//Uh oh
				NSLog(@"Excpected another seperator but found none. Starting at%@ %@", 
					  payload, location);
				return nil;
			}
			//We need to consume from our location to the next separator
			NSUInteger lengthOflengthStringBytes = nextSepartor.location - location;
			uint8_t lengthBytes[lengthOflengthStringBytes];
			[payload getBytes: lengthBytes 
						range: NSMakeRange(location, lengthOflengthStringBytes)];
			
			NSUInteger bytesForPayload 
				= [[NSString stringWithData: [NSData dataWithBytes: lengthBytes 
															length: lengthOflengthStringBytes] 
								   encoding: NSUTF8StringEncoding] 
				   integerValue];
			
			location = location + lengthOflengthStringBytes;
			
			//Move over the separator
			location = location + separtorLength;
			
			uint8_t packetBytes[bytesForPayload];
			[payload getBytes:packetBytes range: NSMakeRange(location, bytesForPayload)];
			id packet = [SocketIOPacket decodePacketData: [NSData dataWithBytes: packetBytes
																		 length: bytesForPayload]];
			if( packet ) {
				[packets addObject: packet];
			}
			else {
				NSLog( @"WARN: Unable to parse packet." );
				//And stop trying. Return failure.
				packets = nil;
				break;
			}
			
			location = location + bytesForPayload;
			
			
		} while(location < payloadLength);
		
		result = packets;
	}
	else {
		id packet = [SocketIOPacket decodePacketData: payload];
		if( packet ) {
			result = [NSArray arrayWithObject: packet];
		}
	}
	
	return result;

}


@end
