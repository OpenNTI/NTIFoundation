//
//  WebSocketResponseBuffer.m
//  NTIFoundation
//
//  Created by Christopher Utz on 2/7/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "WebSocketResponseBuffer.h"
#import "OmniFoundation/OmniFoundation.h"
#import "WebSocketData.h"

@implementation ResponseBuffer

-(id)init
{
	self = [super init];
	self->buffer = [[NSMutableData alloc] init];
	return self;
}

-(BOOL)containsFullResponse
{
	return NO;
}

//The stupid implementation just appends all the bytes
-(NSInteger)appendBytesToBuffer: (uint8_t*)bytes 
					  maxLength: (NSUInteger)length 
			  makesFullResponse: (BOOL*)fullResponse;
{
	[self->buffer appendBytes: bytes length: length];
	if(fullResponse != NULL){
		*fullResponse = [self containsFullResponse];
	}
	return length;
}

-(NSData*)dataBuffer
{
	return [NSData dataWithData: self->buffer];
}

@end

@implementation HandshakeResponseBuffer

-(id)init
{
	self = [super init];
	self->state = 0;  //1 is \r, 2 is \r\n, 3=\r\n\r, 4=\r\n\r\n
	return self;
}

-(NSInteger)appendBytesToBuffer: (uint8_t*)bytes 
					  maxLength: (NSUInteger)length 
			  makesFullResponse: (BOOL*)fullResponse;
{	
	//Look ahead in bytes to see if we encounter the end state
	//Capture the whole array or the ammount required to make a full response
	uint8_t currentState = self->state;
	uint8_t* byteArray = bytes;
	NSUInteger endOffset = 0;
	for(endOffset=0; endOffset<length; endOffset++){
		if( *byteArray == 0x0d && (currentState == 0 || currentState == 2)){
			currentState = currentState + 1;
		}
		else if( *byteArray == 0x0a && (currentState == 1 || currentState == 3)){
			currentState = currentState + 1;
		}
		else{
			currentState = 0;
		}
		
		byteArray++;
		
		if(currentState == 4){
			endOffset++;
			break;
		}
	}
	
	[self->buffer appendBytes: bytes length: endOffset];
	self->state = currentState;
	
	if(  self->isValidHTTPResponse == nil
	   && self->buffer.length >4){
		uint8_t buf[4];
		[self->buffer getBytes: buf range: NSMakeRange(0, 4)];
		NSData* firstFourData = [NSData dataWithBytes: buf length: 4];
		NSString* firstFourBytesString = [NSString stringWithData: firstFourData encoding: NSUTF8StringEncoding];
		if(![firstFourBytesString isEqualToString: @"HTTP"]){
			self->isValidHTTPResponse = [NSNumber numberWithBool: NO];
			[[NSException exceptionWithName: @"UnexpectedResponse" 
									 reason: @"Expected an http response to handshake" 
								   userInfo: nil] raise];
		}
		else{
			self->isValidHTTPResponse = [NSNumber numberWithBool: YES];
		}
	}
	
	if(fullResponse){
		*fullResponse = [self containsFullResponse];
	}
	return length;
}

-(BOOL)containsFullResponse
{
	return self->state == 4;
}

@end

//Define some states to use
#define WebSocketResponseTypeUnknown 0
#define WebSocketResponseTypeClose 1
#define WebSocketResponseTypeText 2
#define WebSocketResponseTypeBinary 3

#define WebSocketResponseSizeUnknown 0
#define WebSocketResponseSize16bit 1
#define WebSocketResponseSize32bit 2
#define WebSocketResponseSize64bit 3

#define WebSocketResponseReadingUnknown 0
#define WebSocketResponseReadingMask 1
#define WebSocketResponseReadingData 2
#define WebSocketResponseReadingSizeAndMask 3
#define WebSocketResponseReadingSizeBytes 4

@implementation WebSocketResponseBuffer

-(id)init
{
	self = [super init];
	
	self->readingPart = WebSocketResponseReadingUnknown;
	self->dataBytesSoFar = 0;
	self->dataLength = -1;
	self->responseSize = WebSocketResponseSizeUnknown;
	self->responseType = WebSocketResponseTypeUnknown;
	self->dataPosition = -1;
	self->sizeBytesRead = 0;
	self->maskBytesRead = 0;
	
	for(NSUInteger i = 0; i < 4 ; i++){
		self->mask[i] = 0x00;
	}
	
	for(NSUInteger i=0; i < 8 ; i++){
		self->sizeBytes[i] = 0x00;
	}
	
	return self;
}

-(BOOL)isCloseResponse
{
	return self->responseType == WebSocketResponseTypeClose;
}

-(void)readFirstByte: (uint8_t*)byte
{
	if( *byte == 0x81 ){ //This is text
		self->responseType = WebSocketResponseTypeText;
	}
	else if( *byte == 0x82 ){ //This is binary
		self->responseType = WebSocketResponseTypeBinary;
	}
	else if( *byte == 0x88){ //This is a close
		self->responseType = WebSocketResponseTypeClose;
	}
	else{ //1000 0001
		[[NSException exceptionWithName: @"UnexpectedResponse" 
								 reason: [NSString stringWithFormat: 
										  @"Unknown opcode recieved. First byte of frame=%d", *byte]
							   userInfo: nil] raise];
	}
	
	[self->buffer appendBytes: byte length: 1];
	//Up next is the size and mask
	self->readingPart = WebSocketResponseReadingSizeAndMask; 
	
}

#ifdef TEST
#define PRIVATE_STATIC_TESTABLE
#else
#define PRIVATE_STATIC_TESTABLE static
#endif

PRIVATE_STATIC_TESTABLE NSUInteger bytesToLength(uint8_t* bytes, uint8_t num);
PRIVATE_STATIC_TESTABLE NSUInteger bytesToLength(uint8_t* bytes, uint8_t num)
{
	NSUInteger theLength = 0;
	for(int i=0; i<num; i++){
		theLength = theLength << 8;
		theLength = theLength | bytes[i];
	}
	return theLength;
}

#undef PRIVATE_STATIC_TESTABLE

//Reads as much data from the byte array as it can for the mask and length bits.
//Returns the number of bytes actually consumed.
-(NSUInteger)readSizeAndMasked: (uint8_t*)bytes maxLength: (NSUInteger)length
{	
	OBASSERT(length > 0);
	
	//if we don't know our size yet this is the first attempt at reading size and masked
	if(self->responseSize == WebSocketResponseSizeUnknown){		
		//Save if we are masked
		self->masked = (*bytes & 0x80);
		
		//The first size byte will determine what response size we are
		int client_len = *bytes & 0x7F;
		
		//If we are less than 126 we are 16bit, 126 is 32 bit and we expect two more databytes, > 126 we don't support
		if( client_len < 126){
			self->responseSize = WebSocketResponseSize16bit;
			self->dataLength = client_len;
			//Next is the mask or the data
			self->readingPart = self->masked ? WebSocketResponseReadingMask : WebSocketResponseReadingData;
		}
		else if( client_len == 126 ){
			self->responseSize = WebSocketResponseSize32bit;
		}
		else if( client_len == 127){
			self->responseSize = WebSocketResponseSize64bit;
		}
		else{
			self->responseSize = WebSocketResponseSizeUnknown;
			[[NSException exceptionWithName: @"UnexpectedResponse" 
									 reason: [NSString stringWithFormat: 
											  @"Encounted bad size info. expected value <= 127 but found %ld", client_len]
								   userInfo: nil] raise];
		}
		
		//Append the byte we read to the buffer
		[self->buffer appendBytes: bytes length: 1];
		return 1;
	}
	else{
		if(self->responseSize == WebSocketResponseSizeUnknown){
			[[NSException exceptionWithName: @"UnexpectedResponse" 
									 reason: [NSString stringWithFormat: 
											  @"Expected known size but had size state of %ld", self->responseSize]
								   userInfo: nil] raise];
		}
		
		int sizeBytesRequired = 0;
		if(self->responseSize == WebSocketResponseSize32bit){
			sizeBytesRequired = 2;
		}
		else if(self->responseSize == WebSocketResponseSize64bit){
			sizeBytesRequired = 8;
		}
		
		//Read as many sizeBytes as we can
		NSUInteger sizeBytesRemaining = sizeBytesRequired - self->sizeBytesRead;
		NSUInteger toRead = MIN(sizeBytesRemaining, length);
		
		for(int i = 0; i < (int)toRead; i++){
			self->sizeBytes[self->sizeBytesRead++] = bytes[i];
		}
		
		//We read what we can into size bytes.  add it to the main buffer and 
		//update state
		[self->buffer appendBytes: bytes length: toRead];
		
		//If we have read two size bytes we have all we need to construct the lenght
		if( self->sizeBytesRead == sizeBytesRequired){
			self->dataLength = bytesToLength(self->sizeBytes, sizeBytesRequired);
			//Next is the mask or the data
			self->readingPart = self->masked ? WebSocketResponseReadingMask : WebSocketResponseReadingData;
		}
		
		return toRead;
	}
}

#define kWebSocketExpectedMaskBytes 4

//Reads as much data from bytes as possible and needed to build up the mask.
//Returns the number of bytes consumed
-(NSUInteger)readMask: (uint8_t*)bytes maxLength: (NSUInteger)length
{
	//We want to read as many mask bytes as we can
	NSUInteger maskBytesRemaining = kWebSocketExpectedMaskBytes - self->maskBytesRead;
	
	NSUInteger toRead = MIN(maskBytesRemaining, length);
	
	for(int i = 0; i < (int)toRead; i++){
		self->mask[self->maskBytesRead++] = bytes[i];
	}
	
	//If we have read four mask bytes it's time to move onto data
	if(self->maskBytesRead == 4){
		self->readingPart = WebSocketResponseReadingData;
	}
	
	//Add them to the full buffer
	[self->buffer appendBytes: bytes length: toRead];
	
	return toRead;
}

//Reads as much data as we can from the bytes array until we run out
//or reach a full response.  Returns how much we actually read
-(NSUInteger)readData: (uint8_t*)bytes maxLength: (NSUInteger)length
{
	OBASSERT(length > 0);
	
	//If this is the first data we have read we need to set the data position so it can
	//be extracted later
	if( self->dataPosition < 0 ){
		self->dataPosition = [self->buffer length];
	}
	
	NSUInteger toRead = MIN(length, self->dataLength - self->dataBytesSoFar);
	[self->buffer appendBytes: bytes length: toRead];
	self->dataBytesSoFar += toRead;
	return toRead;
}

-(NSInteger)appendBytesToBuffer: (uint8_t*)bytes 
					  maxLength: (NSUInteger)length 
			  makesFullResponse: (BOOL*)fullResponse
{
	if(length < 1){
		if(fullResponse != NULL){
			*fullResponse = [self containsFullResponse];
		}
		return 0;
	}
	
	NSUInteger bytesConsumed = 0;
	
	if(self->responseType == WebSocketResponseTypeUnknown){
		//Read the first byte it should be the packet type.
		[self readFirstByte: bytes];
		bytesConsumed++;
	}
	else if(    self->readingPart == WebSocketResponseReadingSizeAndMask 
			 || self->readingPart == WebSocketResponseReadingSizeBytes ){
		bytesConsumed += [self readSizeAndMasked: bytes maxLength: length];
	}
	else if( self->readingPart == WebSocketResponseReadingMask){
		bytesConsumed += [self readMask: bytes maxLength: length];
	}
	else if( self->readingPart == WebSocketResponseReadingData){
		bytesConsumed += [self readData: bytes maxLength: length];
	}
	else{
		[[NSException exceptionWithName: @"UnexpectedResponse" 
								 reason: [NSString stringWithFormat: 
										  @"Unknown buffer state readingpart = %ld", 
										  self->readingPart]
							   userInfo: nil] raise];
	}
	
	BOOL isFullResponse = [self containsFullResponse];
	
	//Ok so we want to read some more bytes if we have them available. and we haven't finished
	//gathering this packet yet. otherwise we just return appropriately
	if(   bytesConsumed < length  
	   && !isFullResponse ){
		//There is more we can read
		BOOL fullResponseEncountered = NO;
		bytesConsumed += [self appendBytesToBuffer: bytes+bytesConsumed 
										 maxLength: length-bytesConsumed 
								 makesFullResponse: &fullResponseEncountered];
		
		//We read as much as we could
		if(fullResponse != NULL){
			*fullResponse = fullResponseEncountered;
		}
		return bytesConsumed;
	}
	
	//We have read all we can or we encountered a full response.
	if(fullResponse != NULL){
		*fullResponse = isFullResponse;
	}
	return bytesConsumed;
}

-(WebSocketData*)websocketData
{
	if(	  ![self containsFullResponse] 
	   || self->responseType == WebSocketResponseTypeClose 
	   || self->responseType == WebSocketResponseSizeUnknown ){
		return nil;
	}
	
	if(self->masked){
		uint8_t offsetForMask = self->dataPosition % 4;
		
		//TODO we unmask in place now, which means buffer is now corrupt.  should we nil it out?  Nothing
		//should be using us after getting the websocketData from us...
		
		uint8_t* byteArray = (uint8_t*)self->buffer.bytes;
		byteArray += self->dataPosition;
		for(NSUInteger location = 0; location + self->dataPosition < self->dataLength; location++){
			*byteArray = *byteArray ^ mask[(offsetForMask + location) % 4];
			byteArray++;
		}
	}
	
		
	return [[WebSocketData alloc] initWithData: 
										[NSData dataWithBytes: (uint8_t*)self->buffer.bytes + self->dataPosition 
													   length: self->dataLength]
										isText: self->responseType == WebSocketResponseTypeText];
}

-(BOOL)containsFullResponse
{
	return dataBytesSoFar == dataLength;
}

@end

