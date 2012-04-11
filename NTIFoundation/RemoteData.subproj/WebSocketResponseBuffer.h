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

//Appends bytes from the byte array to the buffer.  As many bytes will be appended
//to the buffer as available or until a full response is created.  The BOOL outparameter
//will be populated with whether or not the response is not full and the return value
//will indicate the number of bytes from the bytes array that were actually buffered.
-(NSInteger)appendBytesToBuffer: (uint8_t*)bytes 
					  maxLength: (NSUInteger)length 
			  makesFullResponse: (BOOL*)fullResponse;
//For subclasses
-(BOOL)containsFullResponse;

@end

@interface HandshakeResponseBuffer : ResponseBuffer {
@private
    uint8_t state;
	NSNumber* isValidHTTPResponse;
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
