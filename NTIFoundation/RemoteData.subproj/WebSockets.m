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
#import "UIDevice-NTIExtensions.h"

@interface WebSocketClose : WebSocketData
@end

@implementation WebSocketClose

-(id)init
{
	return [super initWithData: nil isText: NO];
}

-(NSData*)dataForTransmission
{
	uint8_t closeBytes[6];
	closeBytes[0] = 0x88;
	closeBytes[1] = 0x80;
	//Generate a random 4 bytes to use as our mask
	for(NSInteger i = 2; i < 6; i++){
		closeBytes[i] = arc4random() % 128;
	}
	return [NSData dataWithBytes: closeBytes length: 6];
}

@end

//TODO we are version 13 now.
@interface WebSocket7()
@property (nonatomic, readonly) HandshakeResponseBuffer* handshakeResponseBuffer;
@property (nonatomic, readonly) WebSocketResponseBuffer* socketResponseBuffer;
@end

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
	self->dataToWrite = nil;
	self->dataToWriteOffset = 0;
	
	[self updateStatus: WebSocketStatusNew];
	self->key = generateSecWebsocketKey();
	
	return self;
}

-(HandshakeResponseBuffer*)handshakeResponseBuffer
{
	if(!self->handshakeResponseBuffer){
		self->handshakeResponseBuffer = [[HandshakeResponseBuffer alloc] init];
	}
	return self->handshakeResponseBuffer;
}

-(WebSocketResponseBuffer*)socketResponseBuffer
{
	if(!self->socketRespsonseBuffer){
		self->socketRespsonseBuffer= [[WebSocketResponseBuffer alloc] init];
	}
	return self->socketRespsonseBuffer;
}

-(void)shutdownStreams
{
	if(!self->socketInputStream && !self->socketOutputStream){
		return;
	}
	
	[self->socketOutputStream close];
	[self->socketInputStream close];
	[self->socketInputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self->socketOutputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	self->socketInputStream.delegate = nil;
	self->socketOutputStream.delegate = nil;
	self->socketInputStream = nil;
	self->socketOutputStream = nil;
	dispatch_async(dispatch_get_main_queue(), ^(){
		[self updateStatus: WebSocketStatusDisconnected];
	});
	
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
		
		//Fixme this isn't quite right.
		//If we aren't already disconnecting send the disconnect packet
		if( self->status != WebSocketStatusDisconnecting ){
			[self updateStatus: WebSocketStatusDisconnecting];
			[self enqueueDataForSending: [[WebSocketClose alloc] init]];
		}
		[self shutdownStreams];
	}
	else{
		WebSocketData* wsdata = [responseBuffer websocketData];
#ifdef DEBUG_SOCKETIO
		NSLog(@"Recieved data for length %ld", (unsigned long)wsdata.data.length);
#endif
		[self enqueueRecievedData: wsdata];
		if( [self->nr_delegate respondsToSelector: @selector(websocketDidRecieveData:)] ){
			[self->nr_delegate websocketDidRecieveData: self];
		}
	}
	self->socketRespsonseBuffer = nil;
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

-(NSString*)userAgentValue
{
	//If we have app info in our defaults lets append that.
	NSString* appInfo = [[NSUserDefaults standardUserDefaults] objectForKey: @"NTIUserAgentInfo"];
	
	//If not lets default to the bundle name and version
	if([NSString isEmptyString: appInfo]){
		NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
		appInfo = [NSString stringWithFormat:@"%@/%@",
				   [infoDictionary objectForKey:@"CFBundleName"],
				   [infoDictionary objectForKey:@"CFBundleVersion"]];
	}
	
	return [NSString stringWithFormat: @"NTIFoundation WebSocket %@", appInfo];
}

//See http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-17#page-7
-(NSData*)createHandshakeData
{
	//The spec indicates the origin header "may" be sent by non browser clients
	//We go ahead and send it so we look as much like a browser client as possible (for firewall sake)
	//and for an added layer of security should the server decide to use it.
	
	NSString* getRequest = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
							"Upgrade: WebSocket\r\n"
							"Connection: Upgrade\r\n"
							"User-Agent: %@\r\n"
							"Host: %@\r\n"
							"Origin: %@\r\n"
							"sec-websocket-origin: %@\r\n"
							"Sec-WebSocket-Key: %@\r\n"
							"Sec-WebSocket-Version: 13\r\n"
							"%@\r\n\r\n",
							self->url.path ? self->url.path : @"/", [self userAgentValue],
							self->url.host, kNTIWebSocket7Origin,
							[NSString stringWithFormat: @"http://%@",self->url.host], self->key, cookieHeaderForServer(self->url)] ;
#ifdef DEBUG_SOCKETIO
	NSLog(@"Initiating handshake with %@", getRequest);
#endif
	
	return [getRequest dataUsingEncoding: NSUTF8StringEncoding];
}

//Sends as much data is possible from the dataToWrite buffer.
//Returns the number of bytes actually written
-(NSUInteger)sendDataFromBuffer
{
	NSUInteger numBytesToTryAndSend = self->dataToWrite.length - self->dataToWriteOffset;
#ifdef DEBUG_SOCKETIO
	NSLog(@"About to send data length = %ld", (unsigned long)numBytesToTryAndSend);
#endif
	NSInteger bytesSent = [self->socketOutputStream write: self->dataToWrite.bytes + self->dataToWriteOffset 
												maxLength: numBytesToTryAndSend];
#ifdef DEBUG_SOCKETIO
	NSLog(@"Data send complete.  Sent %ld bytes", (unsigned long)bytesSent);
#endif
	self->shouldForcePumpOutputStream = NO;
	self->dataToWriteOffset += bytesSent;
	
	if(self->dataToWriteOffset >= self->dataToWrite.length){
#ifdef DEBUG_SOCKETIO
		NSLog(@"Entire send buffer depleted.");
#endif		
		self->dataToWrite = nil;
		self->dataToWriteOffset = 0;
	}
	
	return bytesSent;
}

//Consumes the bytes from the stream by appending them to the various buffers (which will intern
//cause complete packets to be handled)
-(void)pumpBytesOntoStream
{
	//If we currently have a buffer of bytes to put on the stream just keep sending those
	if(self->dataToWrite){
		[self sendDataFromBuffer];
	}
	else{
		OBASSERT(self->dataToWriteOffset == 0);
		
		if(self->status == WebSocketStatusNew){
			self->dataToWrite = [self createHandshakeData];
			[self updateStatus: WebSocketStatusConnecting];
		}
		else if(   self->status == WebSocketStatusConnected
				|| self->status == WebSocketStatusDisconnecting){
			
			self->dataToWrite = [[self dequeueDataForSending] dataForTransmission];
			
		}
		else{
#ifdef DEBUG_SOCKETIO
			NSLog(@"Unhandled stream event NSStreamEventHasSpaceAvailable for stream %@.  Will force pump output stream", self->socketOutputStream);
#endif
		}
		
		if(self->status == WebSocketStatusConnected){
			//TODO it's not clear doing this here is correct any longer.  Nothing actually
			//implements this.  I'm not sure its even needed anymore...
			//if we just wrote data we have room for more, otherwise we were empty and we 
			//have room for more.
			if( [self->nr_delegate respondsToSelector: @selector(websocketIsReadyForData:)] ){
				[self->nr_delegate websocketIsReadyForData: self];
			}

		}

		if(self->dataToWrite){
			[self sendDataFromBuffer];
		}
		else{
			self->shouldForcePumpOutputStream = YES;
		}
		
	}
}

-(void)enqueueDataForSending:(id)data
{
	if(   self->status == WebSocketStatusDisconnecting
	   || self->status == WebSocketStatusDisconnected ){
		return;
	}
	[super enqueueDataForSending: data];
	if(self->shouldForcePumpOutputStream){
		[self pumpBytesOntoStream];
	}
}

static NSData* hashUsingSHA1(NSData* data)
{
    unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([data bytes], (uint32_t)[data length], hashBytes);
	
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

//Appends as many bytes as necessary to the handshake response dealing with a complete handshake if necessary
//returns the number of bytes consumed.
-(NSUInteger)handleHandshakeResponseBytes: (uint8_t*)bytes length: (NSUInteger)maxLength
{
	BOOL completeResponse = NO;
	NSUInteger consumed = [self.handshakeResponseBuffer appendBytesToBuffer: bytes 
																  maxLength: maxLength
														  makesFullResponse: &completeResponse];
	
	if(completeResponse){
		[self processHandshakeResponse: self.handshakeResponseBuffer];
	}
	
	return consumed;
}

//Appends bytes to the socket response buffer handling the packet when its complete.
-(NSUInteger)handleSocketResponseBytes: (uint8_t*)bytes length: (NSUInteger)maxLength
{
	BOOL completeResponse = NO;
	NSUInteger consumed = [self.socketResponseBuffer appendBytesToBuffer: bytes 
															   maxLength: maxLength
													   makesFullResponse: &completeResponse];
	
	if(completeResponse){
		[self processSocketResponse: self.socketResponseBuffer];
	}
	
	return consumed;
}

//Consumes the bytes from the stream by appending them to the various buffers (which will intern
//cause complete packets to be handled)
-(void)consumeBytesFromStream: (uint8_t*)bytes length: (NSUInteger)maxLength
{
	NSUInteger consumed = 0;
	uint8_t* byteArray = bytes;
	while(consumed < maxLength){
		
		if(self->status == WebSocketStatusConnecting){
			consumed += [self handleHandshakeResponseBytes: byteArray + consumed length: maxLength - consumed];
		}
		else if(   self->status == WebSocketStatusConnected
				|| self->status == WebSocketStatusDisconnecting){
			consumed += [self handleSocketResponseBytes: byteArray + consumed length: maxLength - consumed];
		}
		else{
#ifdef DEBUG_SOCKETIO
			NSLog(@"Unhandled stream event NSStreamEventHasBytesAvailable for stream %@ status is %ld. Dropping %ld bytes", 
				  self->socketInputStream, (unsigned long)self->status,(unsigned long) maxLength - consumed);
#endif
			
			break;
		}
	}
}

-(void)consumeStreamData
{
	while( [self->socketInputStream hasBytesAvailable] ){
		//Fill our buffer with data
		NSInteger countFromSocketRead = [self->socketInputStream read: self->readBuffer maxLength: kNTIWebSocketReadBufferSize];
		
		//If we didn't read byte its because we reached the end
		//of the stream or the operation failed.  Either case is bad
		if(countFromSocketRead < 0){
			[self shutdownAsResultOfError: 
			 errorWithCodeAndMessage(300, 
									 [NSString stringWithFormat: 
									  @"Unable to consume data from stream.  Error code %ld", (long)countFromSocketRead])];
		}
		else if(countFromSocketRead == 0){
			if(self->status == WebSocketStatusDisconnecting){
				//We found the end of the stream after sending a disconnect.
				//Should the server have sent us a disconnect?
				[self shutdownStreams];
			}
			else{
				[self shutdownAsResultOfError: 
				 errorWithCodeAndMessage(310, 
										 [NSString stringWithFormat: 
										  @"Encountered unexpexted end of stream, websocket status is %ld", (long)self->status])];
			}
		}
		else{
			//ok we have a bunch of bytes from the server.  Consume them
			[self consumeBytesFromStream: self->readBuffer length: countFromSocketRead];
		}
		
	}

}

-(void)handleInputStreamEvent: (NSStreamEvent)eventCode
{
	//Stream wants us to read something
	if( eventCode == NSStreamEventHasBytesAvailable)
	{
		[self consumeStreamData];
	}
	else if( eventCode == NSStreamEventEndEncountered ){
		if(self->status != WebSocketStatusDisconnected){
			NSLog(@"End of input stream encoutered");
			[self shutdownStreams];
		}
	}
}

-(void)handleOutputStreamEvent: (NSStreamEvent)eventCode
{
	//The stream wants us to write something
	if(eventCode == NSStreamEventHasSpaceAvailable) {
		[self pumpBytesOntoStream];
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
	NSLog(@"recieved event %lu for stream %@ with status %lu", (unsigned long) eventCode, aStream, (unsigned long) aStream.streamStatus);
	if( eventCode == NSStreamEventErrorOccurred){
		NSError *theError = [aStream streamError];
		NSLog(@"%@ Error: %@ code=%ld domain=%@", aStream, [theError localizedDescription], (long)theError.code, theError.domain);
		[self shutdownAsResultOfError: theError];
	}

	if (aStream == self->socketInputStream){
		OBASSERT(aStream.streamStatus != NSStreamStatusClosed);
		[self handleInputStreamEvent: eventCode];
		return;
	}
	
	if(aStream == self->socketOutputStream){
		OBASSERT(aStream.streamStatus != NSStreamStatusClosed);
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
	
	self->socketInputStream = (__bridge_transfer NSInputStream *)readStream;
	self->socketOutputStream = (__bridge_transfer NSOutputStream *)writeStream;
	
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
	[self enqueueDataForSending: [[WebSocketClose alloc] init]];
	[self updateStatus: WebSocketStatusDisconnecting];
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
