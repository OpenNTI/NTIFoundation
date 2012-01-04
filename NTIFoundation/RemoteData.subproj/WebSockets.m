
//
//  WebSockets.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "WebSockets.h"
#import <CommonCrypto/CommonDigest.h>
#import "OmniFoundation/NSDictionary-OFExtensions.h"
#import "OmniFoundation/NSMutableDictionary-OFExtensions.h"

@implementation WebSocketData
@synthesize data, dataIsText;

-(id)initWithData:(NSData *)d isText:(BOOL)t
{
	self = [super init];
	self->data = d;
	self->dataIsText = t;
	return self;
}


@end

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

@interface HandshakeResponseBuffer : ResponseBuffer {
@private
    uint8_t state;
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

@interface WebSocketResponseBuffer : ResponseBuffer
{
	@private
	NSUInteger dataBytesSoFar;
	NSUInteger dataLength;
	uint8_t readingPart;
	uint8_t responseSize;
	uint8_t responseType;
	uint8_t mask[4];
	uint8_t sizeBytes[2];
	NSInteger dataPosition;
	uint8_t sizeBytesRead;
	uint8_t maskBytesRead;
	BOOL masked;
}
-(WebSocketData*)websocketData;
-(BOOL)isCloseResponse;
@end

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
	
	for(NSUInteger i=0; i < 2 ; i++){
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
		else{
			self->responseSize = WebSocketResponseSize64bit;
			[[NSException exceptionWithName: @"UnexpectedResponse" 
									 reason: [NSString stringWithFormat: 
											  @"Expected 32 bit size but had size state of %ld", self->responseSize]
								   userInfo: nil] raise];
		}
	}
	else{
		//If we ever get to here we better be 32 bit response
		if(self->responseSize != WebSocketResponseSize32bit){
			[[NSException exceptionWithName: @"UnexpectedResponse" 
									 reason: [NSString stringWithFormat: 
											  @"Expected 32 bit size but had size state of %ld", self->responseSize]
								   userInfo: nil] raise];
		}
		//We have size bytes to read
		self->sizeBytes[self->sizeBytesRead++] = *byte;
		
		//If we have read two size bytes we have all we need to construct the lenght
		if( self->sizeBytesRead == 2){
			self->dataLength = (self->sizeBytes[0] << 8) | (self->sizeBytes[1]);
			
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

@implementation WebSocket7
@synthesize status, nr_delegate;

static NSString* b64EncodeString(NSString* string)
{
	return [[string dataUsingEncoding: NSUTF8StringEncoding] base64String];
}

static NSError* errorWithCodeAndMessage(NSInteger code, NSString* message)
{
	NSDictionary* userData = [NSDictionary dictionaryWithObject: message forKey: NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain: @"WebSocketError" code: code userInfo: userData];
}

-(void)updateStatus: (WebSocketStatus)s
{
	if(self->status == s){
		return;
	}
	self->status = s;
	if([self->nr_delegate respondsToSelector:@selector(websocket:connectionStatusDidChange:)]){
		[self->nr_delegate websocket: self connectionStatusDidChange: s];
	}
	
	if(self->status == WebSocketStatusConnected && self->shouldForcePumpOutputStream){
		if( [self->nr_delegate respondsToSelector: @selector(websocketIsReadyForData:)] ){
			[self->nr_delegate websocketIsReadyForData: self];
		}
	}
	
}

-(id)initWithURL: (NSURL *)u
{
	self = [super init];
	self->url = u;
	self->shouldForcePumpOutputStream = NO;
	[self updateStatus: WebSocketStatusNew];

	//Generate key.
	//A "Sec-WebSocket-Key" header field with a base64-encoded (see
	//Section 4 of [RFC4648]) value that, when decoded, is 16 bytes in
	//length.
	
	NSMutableData* bytesToEncode = [NSMutableData data];
	
	for(NSInteger i = 0; i < 16; i++){
		uint8_t byte = arc4random() % 256;
		[bytesToEncode appendBytes: &byte length: 1];
	}
	NSString* k = [NSString stringWithData: bytesToEncode encoding: NSASCIIStringEncoding] ;
	self->key = b64EncodeString(k);
	
	return self;
}


-(void)shutdownStreams
{
	[self->socketOutputStream close];
	[self->socketInputStream close];
	[self->socketInputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self->socketOutputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self updateStatus: WebSocketStatusDisconnected];
}


-(void)shutdownAsResultOfError: (NSError*)error
{
	NSLog(@"Shutting down as a result of an error! %@", error ? [error localizedDescription] : @"");
	[self updateStatus: WebSocketStatusDisconnecting];
	
	if( [self->nr_delegate respondsToSelector: @selector(websocket:didEncounterError:)] ){
		[self->nr_delegate websocket: self didEncounterError: error];
	}
	
	[self shutdownStreams];
}

-(void)processSocketResponse: (WebSocketResponseBuffer*)responseBuffer
{
	//If we are a close we just need to shut things down
	if( [responseBuffer isCloseResponse] ){
		
		//If we aren't already disconnecting send the disconnect packet
		if( self->status != WebSocketStatusDisconnecting ){
			uint8_t shutdownByte = 0x88;
			[self updateStatus: WebSocketStatusDisconnecting];
			//Does this need to be queued up for writing?  Is it possible this blocks?
			[self->socketOutputStream write: &shutdownByte maxLength: 1];
		}
		[self shutdownStreams];
		
		
	}
	else{
		WebSocketData* wsdata = [responseBuffer websocketData];
		[self enqueueRecievedData: wsdata];
		if( [self->nr_delegate respondsToSelector: @selector(websocketDidRecieveData:)] ){
			[self->nr_delegate websocketDidRecieveData: self];
		}
	}
}

//FIXME This code is extremely similar to how we readResponseData for the handshake
//generalize and abstract it away
-(void)readSocketResponse
{
	//When we are told to read we will read as much as we
	//possibly can.
	uint8_t currentByte = 0x00;
	while( [self->socketInputStream hasBytesAvailable] ){
		
		//If we haven't yet started the response start it now.
		if(!self->socketRespsonseBuffer){
			self->socketRespsonseBuffer = [[WebSocketResponseBuffer alloc] init];
		}
		
		//Read a byte off the input stream.  Be careful to inspect
		//the return value
		NSInteger readResult = -5;
		readResult = [self->socketInputStream read: &currentByte maxLength: 1];
		
		//If we didn't read one byte its because we reached the end
		//of the stream or the operation failed.  Either case is bad
		if(readResult != 1){
			[self shutdownAsResultOfError: 
			 errorWithCodeAndMessage(300, 
									 [NSString stringWithFormat: 
									  @"Unable to read socket response.  Error code %ld", readResult])];
			break;
		}
		
		//Ok we have a byte from the stream.  Put it in our buffer.  Remember this may throw an exception
		BOOL completeResult = NO;
		@try{
			completeResult = [self->socketRespsonseBuffer appendByteToBuffer: &currentByte];
		}
		@catch (NSException* e) {
			[self shutdownAsResultOfError: 
			 errorWithCodeAndMessage(301, [NSString stringWithFormat: @"%@: %@", e.name, e.reason])];
			break;
		}
		
		//Ok we added the byte.  If we have a complete result we need to handle it.
		if(completeResult){
			[self processSocketResponse: self->socketRespsonseBuffer];
			//Unlike with the handshake we may have more data that start new packets. 
			//We clear our the socketResponseBuffer and keep reading if we can
			self->socketRespsonseBuffer = nil;
			
		}
	}
	
}

-(void)dequeueAndSend
{
	WebSocketData* wsdata = [self dequeueDataForSending];
	
	if( !wsdata ){
		self->shouldForcePumpOutputStream = YES;
		return;
	}
	
		
	uint8_t flag_and_opcode = 0x80;
	if( [wsdata dataIsText] ){
		//We will go as string
		flag_and_opcode = flag_and_opcode+1;
	}
	
	NSData* data = wsdata.data;
#ifdef DEBUG_SOCKETIO
	NSLog(@"About to send data %@", wsdata);
#endif
	
	BOOL isLong=NO;
	uint8_t first = 0x00;
	uint8_t second = 0x00;
	uint8_t third = 0x00;
		
	if( [data length] < 126 ){
		first = [data length];
	}
	else if([data length] < 0xFFFF){
		first = 126;
		second = ([data length] & 0xFF00) >> 8;
		third = [data length] & 0xFF;
		isLong = YES;
	}
	else{
		[self shutdownAsResultOfError: errorWithCodeAndMessage(301, @"64 bit length frame not allowed")];
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"About to send data length = %ld", [data length]);
#endif
	//Client is always masked
	first = first | 0x80;
	
	[self->socketOutputStream write: &flag_and_opcode maxLength: 1];
	[self->socketOutputStream write: &first maxLength: 1];
	if(isLong){
		[self->socketOutputStream write: &second maxLength: 1];
		[self->socketOutputStream write: &third maxLength: 1];
	}
	
	//Generate a random 4 bytes to use as our mask
	uint8_t mask[4];
	for(NSInteger i = 0; i < 4; i++){
		mask[i] = arc4random() % 128;
	}
	
	[self->socketOutputStream write: (const uint8_t*)mask maxLength: 4];

	//We must go byte by byte so we can apply the mask
	for(NSUInteger i=0; i<[data length]; i++){
		uint8_t byte;
		[data getBytes: &byte range: NSMakeRange(i, 1)];
		byte = byte ^ mask[i%4];
		[self->socketOutputStream write: &byte maxLength: 1];
	}
	
	self->shouldForcePumpOutputStream = NO;
}

-(void)enqueueDataForSending:(id)data
{
	[super enqueueDataForSending: data];
	if(self->shouldForcePumpOutputStream){
		[self dequeueAndSend];
	}
}

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
		
		for(NSUInteger i = 1 ; i<=regex.numberOfCaptureGroups; i++ ){
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

static NSData* hashUsingSHA1(NSData* data)
{
    unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([data bytes], [data length], hashBytes);
	
    return [NSData dataWithBytes:hashBytes length:CC_SHA1_DIGEST_LENGTH];
}

-(BOOL)isSuccessfulHandshakeResponse: (NSString*)response
{
	NSArray* parts = piecesFromString( response, @"Sec-WebSocket-Accept:\\s+(.+?)\\s");
	//We expect one part the accept key
	if( [parts count] < 1  || ![parts firstObject]){
		return NO;
	}
	
	//return YES;
	NSString* acceptKey = [parts firstObject];
//	NSLog(@"Accept key %@", acceptKey);
	//The accept key should be our key concated with the secret.  Sha-1 hashed and then base64 encoded
	NSString* concatWithSecret = [NSString stringWithFormat: @"%@%@", self->key, @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11", nil];
//	NSLog(@"concat is %@", concatWithSecret);
	NSData* hash=hashUsingSHA1([concatWithSecret dataUsingEncoding: NSUTF8StringEncoding]);
//	NSLog(@"hash %@", hash);
	NSString* encoded = [hash base64String];
//	NSLog(@"encoded %@", encoded);
	
	return [encoded isEqualToString: acceptKey];
}

-(void)processHandshakeResponse: (HandshakeResponseBuffer*)hrBuffer
{
	NSString* response = [[NSString alloc] initWithData: hrBuffer.dataBuffer 
												encoding: NSUTF8StringEncoding];
#ifdef DEBUG_SOCKETIO
	NSLog(@"Handling handshake response %@", response);
#endif
	//FIXME actually check the accept field
	if ( response && [self isSuccessfulHandshakeResponse: response] ) {
		[self updateStatus: WebSocketStatusConnected];
	} else {
		[self shutdownAsResultOfError: errorWithCodeAndMessage(300, 
															   [NSString stringWithFormat: 
																@"Unexpected response for handshake. %@", response])];
	}
	//We don't need to hold onto this object anymore.
	self->handshakeResponseBuffer = nil;

}

-(void)readHandshakeResponse
{
	//If we haven't yet started the response start it now.
	if(!self->handshakeResponseBuffer){
		self->handshakeResponseBuffer = [[HandshakeResponseBuffer alloc] init];
	}
	
	//When we are told to read we will read as much as we
	//possibly can.
	uint8_t currentByte = 0x00;
	while( [self->socketInputStream hasBytesAvailable] ){
		
		//Read a byte off the input stream.  Be careful to inspect
		//the return value
		NSInteger readResult = -5;
		readResult = [self->socketInputStream read: &currentByte maxLength: 1];
		
		//If we didn't read one byte its because we reached the end
		//of the stream or the operation failed.  Either case is bad
		if(readResult != 1){
			[self shutdownAsResultOfError: 
			 errorWithCodeAndMessage(300, 
									 [NSString stringWithFormat: 
											@"Unable to read handshake response.  Error code %ld", readResult])];
			break;
		}
		
		//Ok we have a byte from the stream.  Put it in our buffer.  Remember this may through an exception
		BOOL completeResult = NO;
		@try{
			completeResult = [self->handshakeResponseBuffer appendByteToBuffer: &currentByte];
		}
		@catch (NSException* e) {
			[self shutdownAsResultOfError: 
			 errorWithCodeAndMessage(301, [NSString stringWithFormat: @"%@: %@", e.name, e.reason])];
			break;
		}
		
		//Ok we added the byte.  If we have a complete result we need to handle it.
		if(completeResult){
			[self processHandshakeResponse: self->handshakeResponseBuffer];
			//When we are reading the response we know we wont have data after it.
			//we haven't sent any socket data until we move to connected.  safe assumption?
			break;
		}
	}
	
}

-(void)handleInputStreamEvent: (NSStreamEvent)eventCode
{
	//Stream wants us to read something
	if( eventCode == NSStreamEventHasBytesAvailable)
	{
		switch (self->status) {
			case WebSocketStatusConnecting:
				[self readHandshakeResponse];
				break;
			case WebSocketStatusConnected:{ //Todo handle opcodes here
				[self readSocketResponse];
				break;
			}
			case WebSocketStatusDisconnecting:{
				[self readSocketResponse];
				break;
			}
			default:
#ifdef DEBUG_SOCKETIO
				NSLog(@"Unhandled stream event %ld for stream %@ status is %ld", 
					  eventCode, self->socketInputStream, self->status);
#endif
				break;
		}
	}
	else if( eventCode == NSStreamEventEndEncountered ){
		if(self->status != WebSocketStatusDisconnected){
			NSLog(@"End of input stream encoutered");
			[self shutdownStreams];
		}
	}
}

//See http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-17#page-7
-(void)initiateHandshake
{
	//The spec indicates the origin header "may" be sent by non browser clients
	//We go ahead and send it so we look as much like a browser client as possible (for firewall sake)
	//and for an added layer of security should the server decide to use it.
	
	NSString* getRequest = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
							"Upgrade: WebSocket\r\n"
							"Connection: Upgrade\r\n"
							"Host: %@\r\n"
							"Origin: %@\r\n"
							"sec-websocket-origin: %@\r\n"
							"Sec-WebSocket-Key: %@\r\n"
							"Sec-WebSocket-Version: 7\r\n\r\n",
							self->url.path ? self->url.path : @"/",self->url.host, kNTIWebSocket7Origin,
							[NSString stringWithFormat: @"http://%@",self->url.host], self->key] ;
#ifdef DEBUG_SOCKETIO
	NSLog(@"Initiating handshake with %@", getRequest);
#endif
	NSData* data = [getRequest dataUsingEncoding: NSUTF8StringEncoding];
	[self->socketOutputStream write: [data bytes] maxLength: [data length]];
	[self updateStatus: WebSocketStatusConnecting];
	self->shouldForcePumpOutputStream = NO;
}

-(void)handleOutputStreamEvent: (NSStreamEvent)eventCode
{
	//The stream wants us to write something
	if(eventCode == NSStreamEventHasSpaceAvailable) {
		switch (self->status){
			case WebSocketStatusNew:
				[self initiateHandshake];
				break;
			case WebSocketStatusConnecting:
				self->shouldForcePumpOutputStream = YES;
				break;
			case WebSocketStatusConnected:{
				[self dequeueAndSend];
				
				//if we just wrote data we have room for more, otherwise we were empty and we 
				//have room for more.
				if( [self->nr_delegate respondsToSelector: @selector(websocketIsReadyForData:)] ){
					[self->nr_delegate websocketIsReadyForData: self];
				}
				
				break;
			}
			default:
#ifdef DEBUG_SOCKETIO
				NSLog(@"Unhandled stream event %ld for stream %@", eventCode, self->socketOutputStream);
#endif
				break;
		}
	}
	else if( eventCode == NSStreamEventEndEncountered ){
		if(self->status != WebSocketStatusDisconnected){
#ifdef DEBUG_SOCKETIO
			NSLog(@"End of output stream encoutered");
#endif
			[self shutdownStreams];
		}
	}
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
	if( eventCode == NSStreamEventErrorOccurred){
		NSError *theError = [aStream streamError];
		NSLog(@"%@ Error: %@ code=%ld domain=%@", aStream, [theError localizedDescription], theError.code, theError.domain);
		[self shutdownAsResultOfError: theError];
	}

	if (aStream == self->socketInputStream){
		[self handleInputStreamEvent: eventCode];
		return;
	}
	
	if(aStream == self->socketOutputStream){
		[self handleOutputStreamEvent: eventCode];
		return;
	}
	
}


//Make sure we have ssl turned on.  Similar to NTIAbstractDownloader we allow self signed certs in DEBUG.
static NSDictionary* sslProperties()
{
	NSMutableDictionary *sslSettings = [[NSMutableDictionary alloc] init];
	[sslSettings setObject:NSStreamSocketSecurityLevelNegotiatedSSL forKey:(NSString *)kCFStreamSSLLevel];
#ifdef DEBUG
	//There is some confusion as to whether or not kCGStreamSSLAllowsAnyRoot is depricated or not.
	//If it is, it appears we have to fall back to the more "global" kCFStreamSSLValidatesCertificateChain.
	//It def. appears depricated in mac osx 10.6 but it doesn't appear depricated in IOS
	[sslSettings setObject:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	//	[sslSettings setObject:(id)kCFBooleanFalse forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
#endif
	return sslSettings;
}

-(void)connect
{
	CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	
	BOOL useSSL = [[self->url scheme] isEqual: @"https"];
	
	NSString* host = [self->url host];
	NSNumber* port = [self->url port];
	if(!port){
		if(useSSL){
			port = [NSNumber numberWithInt: 443];
		}
		else{
			port = [NSNumber numberWithInt: 80];
		}
	}
	
	CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, [port intValue], &readStream, &writeStream);
	
	self->socketInputStream = (__bridge NSInputStream *)readStream;
	self->socketOutputStream = (__bridge NSOutputStream *)writeStream;
	
	//Setup ssl if necessary
	if(useSSL){
		NSDictionary* sslProps = sslProperties();
		[self->socketInputStream setProperty: sslProps forKey: (__bridge NSString*)kCFStreamPropertySSLSettings];
		[self->socketOutputStream setProperty: sslProps forKey: (__bridge NSString*)kCFStreamPropertySSLSettings];
	}

	[self->socketInputStream setDelegate:self];
	[self->socketOutputStream setDelegate:self];
	[self->socketInputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self->socketOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self->socketInputStream open];
	[self->socketOutputStream open];
}

-(void)disconnect
{
	if(self->status == WebSocketStatusDisconnecting || self->status == WebSocketStatusDisconnected)
	{
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"Client initiated disconnect");
#endif
	//FIXME Send disconnect handshake.
	[self updateStatus: WebSocketStatusDisconnecting];
	uint8_t closeByte = 0x88;
	[self->socketOutputStream write: &closeByte maxLength: 1];
}

-(void)kill
{
	[self updateStatus: WebSocketStatusDisconnecting];
	[self shutdownStreams];
}


-(void)dealloc
{
	[self shutdownStreams];
}

@end
