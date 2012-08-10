//
//  WebSocketData.m
//  NTIFoundation
//
//  Created by Christopher Utz on 2/7/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "WebSocketData.h"

@implementation WebSocketData
@synthesize data, dataIsText;

-(id)initWithData:(NSData *)d isText:(BOOL)t
{
	self = [super init];
	self->data = d;
	self->dataIsText = t;
	return self;
}

#ifdef TEST
#define PRIVATE_STATIC_TESTABLE
#else
#define PRIVATE_STATIC_TESTABLE static
#endif

PRIVATE_STATIC_TESTABLE void sizeToBytes(NSUInteger length, uint8_t* sizeInfoPointer, int* sizeLength);
PRIVATE_STATIC_TESTABLE void sizeToBytes(NSUInteger length, uint8_t* sizeInfoPointer, int* sizeLength)
{
	if( length < 126 ){
		*sizeInfoPointer = length;
		*sizeLength = 1;
	}
	else{
		//We need to send a byte array for our data
		if(length < 65536){ //2^16
			*sizeLength = 3; //126 + 2 bytes
			*sizeInfoPointer = 126;
		}
		else{
			*sizeLength = 9; //126 + 8 bytes
			*sizeInfoPointer = 127;
		}
		
		NSUInteger theLength = length;
		for(int i = *sizeLength - 1; i > 0; i--){
			sizeInfoPointer[i] = theLength & 0xFF;
			theLength = theLength >> 8;
		}
	}
	
}

#undef PRIVATE_STATIC_TESTABLE

-(NSData*)dataForTransmission
{
	//Try to allocate what we need up front
	//capacity is length of data + estimate of header length.  we will truncate appropriately
	NSMutableData* mutableData = [NSMutableData dataWithCapacity: self.data.length + 20]; 
	
	uint8_t flag_and_opcode = 0x80;
	if( [self dataIsText] ){
		//We will go as string
		flag_and_opcode = flag_and_opcode+1;
	}
	
#ifdef DEBUG_SOCKETIO_VERBOSE
	NSLog(@"Constructin data object to send %@", wsdata);
#endif
	
	uint8_t sizeInfoPointer[9] = {0};
	int sizeLength;
#ifdef DEBUG_SOCKETIO_VERBOSE	
	NSLog(@"Generating size bytes for %ld", data.length);
#endif
	sizeToBytes(self.data.length, sizeInfoPointer, &sizeLength);
	
	[mutableData appendBytes: &flag_and_opcode length: 1];
	
	//Client is always masked
	*sizeInfoPointer = *sizeInfoPointer | 0x80;
	[mutableData appendBytes: sizeInfoPointer length: sizeLength];
	
	
	//Generate a random 4 bytes to use as our mask
	uint8_t mask[4];
	for(NSInteger i = 0; i < 4; i++){
		mask[i] = arc4random() % 128;
	}
	
	[mutableData appendBytes: (const uint8_t*)mask length: 4];
	
#ifdef DEBUG_SOCKETIO
	NSLog(@"About to mask data");
#endif	
	//We must go byte by byte so we can apply the mask
	uint8_t* byteArray = (uint8_t*)self.data.bytes;
	for(NSUInteger i=0; i<[self.data length]; i++){
		*byteArray = *byteArray ^ mask[i%4];
		byteArray++;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"Data is now masked");
#endif	
	[mutableData appendBytes: self.data.bytes length: self.data.length];
	
	return mutableData;

}

@end
