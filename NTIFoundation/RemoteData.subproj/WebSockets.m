//
//  WebSockets.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "WebSockets.h"

@implementation WebSocket7
@synthesize status;
-(id)initWithURLString:(NSString *)urlString
{
	self = [super init];
	self->url = [[NSURL URLWithString: urlString] retain];
	self->shouldForcePumpOutputStream = NO;
	self->status = WebSocketStatusNew;
	//Fixme we probably need to bound these.
	self->sendQueue = [[NSMutableArray arrayWithCapacity: 10] retain];
	self->recieveQueue = [[NSMutableArray arrayWithCapacity: 10] retain];
	return self;
}


-(void)shutdownStreams
{
	[self->socketOutputStream close];
	[self->socketInputStream close];
	[self->socketInputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self->socketOutputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	NTI_RELEASE(self->socketInputStream);
	NTI_RELEASE(self->socketOutputStream);
}


-(void)shutdownAsResultOfError
{
	self->status = WebSocketStatusError;
	[self shutdownStreams];
}

-(void)readAndEnqueue
{
	//Second nibble of first byte is opcode.  We require text?
	uint8_t firstByte = 0x00;
	[self->socketInputStream read: &firstByte maxLength: 1];
	if( !(firstByte & 0x81) ){
		[self shutdownAsResultOfError];
	}
	
	//Next byte is our flag and opcode
	uint8_t mask_and_len = 0x00;
	[self->socketInputStream read: &mask_and_len maxLength: 1];
	
	uint8_t client_len = mask_and_len & 0x7F;
	
	uint8_t b1;
	uint8_t b2;
	if( client_len == 126 ){
		[self->socketInputStream read: &b1 maxLength: 1];
		b1 = b1 << 8;
		[self->socketInputStream read: &b2 maxLength: 1];
		client_len = b1 | b2;
	}
	else if(client_len == 127){
		[NSException raise: @"Not Implemented" reason: @"Implement 64 bit lengths"];
	}
	
	//The server doesn't have to send a masking key
	BOOL masked = (mask_and_len & 0x80);
	
	uint8_t mask[4];
	for(NSInteger i = 0; i<4; i++){
		if(masked){
			[self->socketInputStream read: &mask[i] maxLength: 1];
		}
		else{
			mask[i]=0x00;
		}
	}
	
	//We must go byte by byte so we can apply the mask if necessary
	NSMutableData* data = [NSMutableData dataWithLength: client_len];
	for(NSUInteger i=0; i<client_len; i++){
		uint8_t byte;
		[self->socketInputStream read: &byte maxLength: 1];
		byte = byte ^ mask[i%4];
		[data appendBytes: &byte length: 1];
	}
	
	[self->recieveQueue addObject: [NSString stringWithData: data encoding: NSUTF8StringEncoding]];
}

-(BOOL)dequeueAndSend
{
	if( [self->sendQueue count] < 1){
		return NO;
	}
	
	NSString* message = [self->sendQueue firstObject];
	[self->sendQueue removeObjectAtIndex: 0];
	
	if( !message ){
		return NO;
	}
	
	NSData* data = [message dataUsingEncoding: NSUTF8StringEncoding];
	
	uint8_t flag_and_opcode = 0x81;
	
	BOOL isLong=NO;
	uint8_t first = 0x00;
	uint8_t second = 0x00;
	uint8_t third = 0x00;
		
	if( [message length] < 126 ){
		first = [message length];
	}
	else if([message length] < 0xFFFF){
		first = 126;
		second = [message length] & 0xFF00 >> 8;
		third = [message length] & 0xFF;
		isLong = YES;
	}
	else{
		[NSException raise: @"Not Implemented" reason: @"Implement 64 bit lengths"];
	}
	
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
		[self->socketOutputStream write: (const uint8_t*)mask[i] maxLength: 1];
	}

	//We must go byte by byte so we can apply the mask
	for(NSUInteger i=0; i<[data length]; i++){
		uint8_t byte;
		[data getBytes: &byte range: NSMakeRange(i, 1)];
		byte = byte ^ mask[i%4];
		[self->socketOutputStream write: &byte maxLength: 1];
	}
	
	return YES;
}


-(void)handleInputStreamEvent: (NSStreamEvent)eventCode
{
	if( self->status == WebSocketStatusConnecting && eventCode == NSStreamEventHasBytesAvailable){
		//FIXME how much to actually read here?
		uint8_t buffer[1024];
		[self->socketInputStream read: buffer maxLength: 1024];
		NSData* response = [NSData dataWithBytes: buffer length: 1024];
		NSString* stringResponse = [NSString stringWithData: response encoding: NSUTF8StringEncoding];
		
		if ([stringResponse hasPrefix:@"HTTP/1.1 101 Web Socket Protocol Handshake\r\nUpgrade: WebSocket\r\nConnection: Upgrade\r\n"]) {
			//FIXME we completely ignore the accept key here
            self->status = WebSocketStatusConnected;
        } else {
            [self shutdownAsResultOfError];
        }
		return;
	}
	
	if( self->status == WebSocketStatusConnected && eventCode == NSStreamEventHasBytesAvailable ){
		[self readAndEnqueue];
	}
}

-(void)handleOutputStreamEvent: (NSStreamEvent)eventCode
{
	if( self->status == WebSocketStatusNew && eventCode == NSStreamEventHasSpaceAvailable){
		//Initiate the handshake
		NSString* getRequest = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
								"Upgrade: WebSocket\r\n"
								"Connection: Upgrade\r\n"
								"Host: %@\r\n"
								"Origin: %@\r\n"
								"\r\n",
								self->url.path,url.host,
								[NSString stringWithFormat: @"http://%@",url.host]];
		
		NSData* data = [getRequest dataUsingEncoding: NSUTF8StringEncoding];
		[self->socketOutputStream write: [data bytes] maxLength: [data length]];
		self->status = WebSocketStatusConnecting;
		self->shouldForcePumpOutputStream = NO;
		return;
	}
	
	if( self->status == WebSocketStatusConnecting && eventCode == NSStreamEventHasSpaceAvailable){
		self->shouldForcePumpOutputStream = YES;
		return;
	}
	
	if( self->status == WebSocketStatusConnected && eventCode == NSStreamEventHasSpaceAvailable){
		BOOL didSendData = [self dequeueAndSend];
		self->shouldForcePumpOutputStream = !didSendData;
		return;
	}
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
	if( eventCode == NSStreamEventErrorOccurred){
		NSError *theError = [aStream streamError];
		NSLog(@"%@ Error: %@", aStream, [theError localizedDescription]);
		[self shutdownAsResultOfError];
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

-(void)connect
{
	CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)[url host], (uint32_t)[url port], &readStream, &writeStream);
	
	self->socketInputStream = (NSInputStream *)readStream;
	self->socketOutputStream = (NSOutputStream *)writeStream;
	[self->socketInputStream setDelegate:self];
	[self->socketOutputStream setDelegate:self];
	[self->socketInputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self->socketOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self->socketInputStream open];
	[self->socketOutputStream open];
}



-(void)disconnect
{
	//FIXME Send remaining data and Tear down handshake?
	self->status = WebSocketStatusDisconnecting;
	[self shutdownStreams];
	self->status = WebSocketStatusDisconnected;
}



-(void)dealloc
{
	NTI_RELEASE(self->sendQueue);
	NTI_RELEASE(self->recieveQueue);
	NTI_RELEASE(self->url);
}

@end
//
//-(BOOL)dequeueAndSend
//{
//	if( [self->sendQueue count] < 1){
//		return NO;
//	}
//	
//	NSString* message = [self->sendQueue firstObject];
//	[self->sendQueue removeObjectAtIndex: 0];
//	
//	if( !message ){
//		return NO;
//	}
//	
//	NSData* data = [message dataUsingEncoding: NSUTF8StringEncoding];
//	
//	uint8_t flag_and_opcode = 0x81;
//	
//	BOOL isLong=NO;
//	uint8_t first;
//	uint8_t second;
//	uint8_t third;
//		
//	if( [message length] < 126 ){
//		first = [message length];
//	}
//	else if([message length] < 0xFFFF){
//		first = 126;
//		second = [message length] & 0xFF00 >> 8;
//		third = [message length] & 0xFF;
//		isLong = YES;
//	}
//	else{
//		[NSException raise: @"Not Implemented" reason: @"Implement 64 bit lengths"];
//	}
//	
//	[self->socketOutputStream write: &flag_and_opcode maxLength: 1];
//
//	[self->socketOutputStream write: &first maxLength: 1];
//	if(isLong){
//		[self->socketOutputStream write: &second maxLength: 1];
//		[self->socketOutputStream write: &third maxLength: 1];
//	}
//	
//	//Send a random 4 bytes that is the masking key
//	for(NSInteger i = 0; i < 4; i++){
//		uint8_t toSend = arc4random() % 128;
//		[self->socketOutputStream write: &toSend maxLength: 1];
//	}
//
//	
//	uint8_t *readBytes = (uint8_t *)[data bytes];
//	[self->socketOutputStream write:(const uint8_t *)readBytes maxLength: [data length]];
//	
//
//	
//	return YES;
//}
//
//-(void)readAndEnqueue
//{
//	//Ignore the first byte of the frame
//	uint8_t firstByte = 0x00;
//	[self->socketInputStream read: &firstByte maxLength: 1];
//	
//	//Next byte is our flag and opcode
//	uint8_t mask_and_len = 0x00;
//	[self->socketInputStream read: &mask_and_len maxLength: 1];
//	
//	if( (mask_and_len & 0x80) != 0x80 ){
//		[NSException raise: @"Read error" reason: @"Client sent unmasked data"];
//	}
//	
//	uint8_t client_len = mask_and_len & 0x7F;
//	
//	uint8_t b1;
//	uint8_t b2;
//	if( client_len == 126 ){
//		[self->socketInputStream read: &b1 maxLength: 1];
//		b1 = b1 << 8;
//		[self->socketInputStream read: &b2 maxLength: 1];
//		client_len = b1 | b2;
//	}
//	else if(client_len == 127){
//		[NSException raise: @"Not Implemented" reason: @"Implement 64 bit lengths"];
//	}
//	
//	uint8_t mask[4];
//	for(NSInteger i = 0; i<4; i++){
//		[self->socketInputStream read: (uint8_t*)mask[i] maxLength: 1];
//	}
//	
//	NSMutableData* data = [NSMutableData dataWithLength: client_len];
//	uint8_t* readBytes[client_len];
//	[self->socketInputStream read: (uint8_t*)readBytes maxLength: client_len];
//	[data appendBytes: readBytes length: client_len];
//	
//	[self->recieveQueue addObject: [NSString stringWithData: data encoding: NSUTF8StringEncoding]];
//	
//	
//}
//
//-(void)handleInputStreamEvent: (NSStreamEvent)eventCode
//{
//	//If we are connected and we have data read it
//	if(self->connected && eventCode == NSStreamEventHasBytesAvailable){
//		[self readAndEnqueue];
//	}
//	else if(!self->connected && self->connecting){
//		//We got a handshake response
//	}
//}
//
//-(void)handleOutputStreamEvent: (NSStreamEvent)eventCode
//{
//	switch( eventCode ){
//		case NSStreamEventHasSpaceAvailable:{
//			BOOL didSend = [self dequeueAndSend];
//			self->shouldForcePumpOutputStream = !didSend;
//		}
//		break;
//	}
//}
//
//-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
//{
//	if( eventCode == NSStreamEventErrorOccurred){
//		NSError *theError = [aStream streamError];
//		NSLog(@"Error: %@",[theError localizedDescription]);
//		return;
//	}
//
//
//	if (aStream == self->socketInputStream){
//		[self handleInputStreamEvent: eventCode];
//		return;
//	}
//	
//	if(aStream == self->socketOutputStream){
//		[self handleOutputStreamEvent: eventCode];
//		return;
//	}
//	
//}
//
//-(BOOL)forcePumpOutputStream
//{
//	if (!self->shouldForcePumpOutputStream){
//		return NO;
//	}
//	BOOL didSend = [self dequeueAndSend];
//	self->shouldForcePumpOutputStream = !didSend;
//	return didSend;
//}
//
//-(void)enqueueForTransmission: (NSString*)data
//{
//	[self->sendQueue addObject: data];
//	if(self->shouldForcePumpOutputStream){
//		[self forcePumpOutputStream];
//	}
//}
//
//-(void)dealloc
//{
//	NTI_RELEASE(self->socketInputStream);
//	NTI_RELEASE(self->socketOutputStream);
//	NTI_RELEASE(self->sendQueue);
//	NTI_RELEASE(self->recieveQueue);
//	[super dealloc];
//}
//
//@end
