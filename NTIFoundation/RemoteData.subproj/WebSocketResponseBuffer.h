//
//  WebSocketResponseBuffer.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/7/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"
#import "WebSocketData.h"

@interface ResponseBuffer : OFObject{
@protected
	NSMutableData* buffer;
}
@property (strong, nonatomic, readonly) NSData* dataBuffer;
//Appends the byte to the buffer and returns whether the buffer
//contains a full response.  May through an exception if
//the byte makes the buffer an invalid response.
-(BOOL)appendByteToBuffer: (uint8_t*)byte;
//For subclasses
-(BOOL)containsFullResponse;

@end

@interface HandshakeResponseBuffer : ResponseBuffer {
@private
    uint8_t state;
}
@end

@interface WebSocketResponseBuffer : ResponseBuffer
{
@private
	NSUInteger dataBytesSoFar;
	NSUInteger dataLength;
	uint8_t readingPart;
	uint8_t responseSize;
	uint8_t responseType;
	uint8_t mask[4];
	uint8_t sizeBytes[8];
	NSInteger dataPosition;
	uint8_t sizeBytesRead;
	uint8_t maskBytesRead;
	BOOL masked;
}
-(WebSocketData*)websocketData;
-(BOOL)isCloseResponse;
@end
