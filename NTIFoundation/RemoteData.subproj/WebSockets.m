
//
//  WebSockets.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "WebSockets.h"
#import "WebSocketResponseBuffer.h"
#import <CommonCrypto/CommonDigest.h>
#import "OmniFoundation/NSDictionary-OFExtensions.h"
#import "OmniFoundation/NSMutableDictionary-OFExtensions.h"

@implementation WebSocket7
@synthesize status, nr_delegate;

#ifdef TEST
#define PRIVATE_STATIC_TESTABLE
#else
#define PRIVATE_STATIC_TESTABLE static
#endif

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

//Generate key.
//A "Sec-WebSocket-Key" header field with a base64-encoded (see
//Section 4 of [RFC4648]) value that, when decoded, is 16 bytes in
//length.
PRIVATE_STATIC_TESTABLE NSString* generateSecWebsocketKey(void);
PRIVATE_STATIC_TESTABLE NSString* generateSecWebsocketKey()
{
	NSMutableData* bytesToEncode = [NSMutableData data];
	
	for(NSInteger i = 0; i < 16; i++){
		uint8_t byte = arc4random() % 256;
		[bytesToEncode appendBytes: &byte length: 1];
	}
	return [bytesToEncode base64String];
}

-(id)initWithURL: (NSURL *)u
{
	self = [super init];
	self->url = u;
	self->shouldForcePumpOutputStream = NO;
	[self updateStatus: WebSocketStatusNew];

	
	self->key = generateSecWebsocketKey();
	
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
	
	uint8_t sizeInfoPointer[9] = {0};
	int sizeLength;
	
	sizeToBytes(data.length, sizeInfoPointer, &sizeLength);
	
#ifdef DEBUG_SOCKETIO
	NSLog(@"About to send data length = %ld", [data length]);
#endif
	
	[self->socketOutputStream write: &flag_and_opcode maxLength: 1];
	
	//Client is always masked
	*sizeInfoPointer = *sizeInfoPointer | 0x80;
	[self->socketOutputStream write: sizeInfoPointer maxLength: sizeLength];
	
	
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

static NSData* hashUsingSHA1(NSData* data)
{
    unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([data bytes], [data length], hashBytes);
	
    return [NSData dataWithBytes:hashBytes length:CC_SHA1_DIGEST_LENGTH];
}

PRIVATE_STATIC_TESTABLE BOOL isSuccessfulHandshakeResponse(NSString* response, NSString* key);
PRIVATE_STATIC_TESTABLE BOOL isSuccessfulHandshakeResponse(NSString* response, NSString* key)
{
	NSArray* parts = [response piecesUsingRegexString: @"Sec-WebSocket-Accept:\\s+(.+?)\\s"];
	//We expect one part the accept key
	if( [parts count] < 1  || ![parts firstObject]){
		return NO;
	}
	
	//return YES;
	NSString* acceptKey = [parts firstObject];
	//	NSLog(@"Accept key %@", acceptKey);
	//The accept key should be our key concated with the secret.  Sha-1 hashed and then base64 encoded
	NSString* concatWithSecret = [NSString stringWithFormat: @"%@%@", key, @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11", nil];
	//	NSLog(@"concat is %@", concatWithSecret);
	NSData* hash=hashUsingSHA1([concatWithSecret dataUsingEncoding: NSUTF8StringEncoding]);
	//	NSLog(@"hash %@", hash);
	NSString* encoded = [hash base64String];
	//	NSLog(@"encoded %@", encoded);
	
	return [encoded isEqualToString: acceptKey];
}

PRIVATE_STATIC_TESTABLE NSArray* validCookiesForServer(NSURL* server);
PRIVATE_STATIC_TESTABLE NSArray* validCookiesForServer(NSURL* server)
{
	NSHTTPCookieStorage* cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	NSMutableArray* cookies = [NSMutableArray array];
	NSDate* expiredAfter = [NSDate date];
	for(NSHTTPCookie* cookie in [cookieJar cookiesForURL: server])
	{
		if(    cookie.expiresDate 
		   && [cookie.expiresDate compare: expiredAfter] != NSOrderedDescending ){
			continue;
		}
		[cookies addObject: cookie];
	}
	return cookies;
}

PRIVATE_STATIC_TESTABLE NSString* cookieHeaderForServer(NSURL* server);
PRIVATE_STATIC_TESTABLE NSString* cookieHeaderForServer(NSURL* server)
{
	NSMutableArray* cookieStringParts = [NSMutableArray array];
	for(NSHTTPCookie* cookie in validCookiesForServer(server)){
		[cookieStringParts addObject: 
		 [NSString stringWithFormat: @"%@=%@", 
		  cookie.name, cookie.value]];
	}
	
	if( [NSArray isEmptyArray: cookieStringParts] ){
		return @"";
	}
	
	return [NSString stringWithFormat: @"Cookie: %@", [cookieStringParts componentsJoinedByString: @"; "]];
}

-(void)processHandshakeResponse: (HandshakeResponseBuffer*)hrBuffer
{
	NSString* response = [[NSString alloc] initWithData: hrBuffer.dataBuffer 
												encoding: NSUTF8StringEncoding];
#ifdef DEBUG_SOCKETIO
	NSLog(@"Handling handshake response %@", response);
#endif
	//FIXME actually check the accept field
	if ( response && isSuccessfulHandshakeResponse(response, self->key) ) {
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
							"Sec-WebSocket-Version: 7\r\n"
							"%@\r\n\r\n",
							self->url.path ? self->url.path : @"/",self->url.host, kNTIWebSocket7Origin,
							[NSString stringWithFormat: @"http://%@",self->url.host], self->key, cookieHeaderForServer(self->url)] ;
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

#undef PRIVATE_STATIC_TESTABLE

@end
