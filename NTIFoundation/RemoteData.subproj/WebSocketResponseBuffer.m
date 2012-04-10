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
	self->buffer = [[NSMutableData alloc] initWithCapacity: 1024];
	return self;
}

-(BOOL)containsFullResponse
{
	return NO;
}

-(BOOL)appendByteToBuffer:(uint8_t *)byte
{
	[self->buffer appendBytes: byte length: 1];
	return [self containsFullResponse];
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

-(BOOL)appendByteToBuffer:(uint8_t *)currentByte
{	
	//1 is \r, 2 is \r\n, 3=\r\n\r, 4=\r\n\r\n
	if( *currentByte == 0x0d && (state == 0 || state == 2)){
		state = state + 1;
	}
	else if( *currentByte == 0x0a && (state == 1 || state == 3)){
		state = state + 1;
	}
	else{
		state = 0;
	}
	
	BOOL result = [super appendByteToBuffer: currentByte];
	
	//We expect an http response
	if( [self->buffer length] == 4 ){
		uint8_t buf[4];
		[self->buffer getBytes: buf range: NSMakeRange(0, 4)];
		NSData* firstFourData = [NSData dataWithBytes: buf length: 4];
		NSString* firstFourBytesString = [NSString stringWithData: firstFourData encoding: NSUTF8StringEncoding];
		if(![firstFourBytesString isEqualToString: @"HTTP"]){
			[[NSException exceptionWithName: @"UnexpectedResponse" 
									 reason: @"Expected an http response to handshake" 
								   userInfo: nil] raise];
		}
	}
	
	return result;
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

-(BOOL)readFirstByte: (uint8_t*)byte
{
	if( *byte & 0x81 ){ //This is text
		self->responseType = WebSocketResponseTypeText;
	}
	else if( *byte & 0x82 ){ //This is binary
		self->responseType = WebSocketResponseTypeBinary;
	}
	else if( *byte & 0x88){ //This is a close
		self->responseType = WebSocketResponseTypeClose;
	}
	else{ //1000 0001
		[[NSException exceptionWithName: @"UnexpectedResponse" 
								 reason: [NSString stringWithFormat: 
										  @"Unknown opcode recieved. First byte of frame=%d", *byte]
							   userInfo: nil] raise];
	}
	
	//Up next is the size and mask
	self->readingPart = WebSocketResponseReadingSizeAndMask; 
	
	//Actually append the byte
	return [super appendByteToBuffer: byte];
	
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

-(BOOL)readSizeAndMasked: (uint8_t*)byte
{	
	
	//if we don't know our size yet this is the first attempt at reading size and masked
	if(self->responseSize == WebSocketResponseSizeUnknown){		
		//Save if we are masked
		self->masked = (*byte & 0x80);
		
		//The first size byte will determine what response size we are
		int client_len = *byte & 0x7F;
		
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
	}
	else{
		//If we ever get to here we better be 32 bit response
		if(self->responseSize == WebSocketResponseSizeUnknown){
			[[NSException exceptionWithName: @"UnexpectedResponse" 
									 reason: [NSString stringWithFormat: 
											  @"Expected known size but had size state of %ld", self->responseSize]
								   userInfo: nil] raise];
		}
		
		//We have size bytes to read
		self->sizeBytes[self->sizeBytesRead++] = *byte;
		
		int sizeBytesRequired = 0;
		if(self->responseSize == WebSocketResponseSize32bit){
			sizeBytesRequired = 2;
		}
		else if(self->responseSize == WebSocketResponseSize64bit){
			sizeBytesRequired = 8;
		}
		
		//If we have read two size bytes we have all we need to construct the lenght
		if( self->sizeBytesRead == sizeBytesRequired){
			self->dataLength = bytesToLength(self->sizeBytes, sizeBytesRequired);
			//Next is the mask or the data
			self->readingPart = self->masked ? WebSocketResponseReadingMask : WebSocketResponseReadingData;
		}
	}
	
	return [super appendByteToBuffer: byte];
}

-(BOOL)readMask: (uint8_t*)byte
{
	//Reading the mask is easy.  save off the mask so we have it for later
	//append the byte and increment the maskCounter
	self->mask[self->maskBytesRead++] = *byte;
	
	//If we have read four mask bytes it's time to move onto data
	if(self->maskBytesRead == 4){
		self->readingPart = WebSocketResponseReadingData;
	}
	
	return [super appendByteToBuffer: byte];
}

-(BOOL)readData: (uint8_t*)byte
{
	//If this is the first data we have read we need to set the data position so it can
	//be extracted later
	if( self->dataPosition < 0 ){
		self->dataPosition = [self->buffer length];
	}
	
	//Reading data is easy we just increment the number of bytes read 
	//and append the bytes
	self->dataBytesSoFar++;
	return [super appendByteToBuffer: byte];
}

-(BOOL)appendByteToBuffer:(uint8_t *)byte
{
	switch(self->readingPart){
		case WebSocketResponseReadingUnknown:
			return [self readFirstByte: byte];
			break;
		case WebSocketResponseReadingSizeAndMask:
			return [self readSizeAndMasked: byte];
			break;
		case WebSocketResponseReadingSizeBytes:
			return [self readSizeAndMasked: byte];
			break;
		case WebSocketResponseReadingMask:
			return [self readMask: byte];
			break;
		case WebSocketResponseReadingData:
			return [self readData: byte];
		default:
			[[NSException exceptionWithName: @"UnexpectedResponse" 
									 reason: [NSString stringWithFormat: 
											  @"Unknown buffer state readingpart = %ld", 
											  self->readingPart]
								   userInfo: nil] raise];
			
			//To shut the compiler up
			return NO;
	}
}

-(WebSocketData*)websocketData
{
	if(	  ![self containsFullResponse] 
	   || self->responseType == WebSocketResponseTypeClose 
	   || self->responseType == WebSocketResponseSizeUnknown ){
		return nil;
	}
	NSMutableData* theData = [NSMutableData dataWithCapacity: self->dataLength];
	
	uint8_t currentByte = 0x00;
	uint8_t offsetForMask = self->dataPosition % 4;
	for(NSUInteger location = self->dataPosition; location < self->dataPosition + self->dataLength; location++){
		[self->buffer getBytes: &currentByte range: NSMakeRange(location, 1)];
		currentByte = currentByte ^ mask[(location - offsetForMask) % 4];
		[theData appendBytes: &currentByte length: 1];
	}
	
	return [[WebSocketData alloc] initWithData: theData 
										isText: self->responseType == WebSocketResponseTypeText];
}

-(BOOL)containsFullResponse
{
	return self->responseType == WebSocketResponseTypeClose || dataBytesSoFar == dataLength;
}

@end

