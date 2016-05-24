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
@property (nonatomic, readonly) NSURLRequest* request;
@property (nonatomic, readonly) HandshakeResponseBuffer* handshakeResponseBuffer;
@property (nonatomic, readonly) WebSocketResponseBuffer* socketResponseBuffer;
@end

@implementation WebSocket7
@synthesize status, nr_delegate;

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

-(id)initWithRequest: (NSURLRequest*)request;
{
	self = [super init];
	self->_request = [request copy];
	self->shouldForcePumpOutputStream = NO;
	self->dataToWrite = nil;
	self->dataToWriteOffset = 0;
	
	[self updateStatus: WebSocketStatusNew];
	
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
	self->socketInputStream = nil;
	self->socketOutputStream = nil;
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
	OBASSERT(!self->key);
	
	//Generate the sec-websocket-key value for checking later.
	NSMutableData* secKeyData = [NSMutableData dataWithLength: 16];
	SecRandomCopyBytes(kSecRandomDefault, secKeyData.length, secKeyData.mutableBytes);
	self->key = [secKeyData base64String];
	
	NSURL* url = self.request.URL;
	BOOL secure = ([url.scheme isEqualToString: @"https"] || [url.scheme isEqualToString: @"wss"]);
	
	CFHTTPMessageRef msgRef = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
														 (__bridge CFStringRef)self.request.HTTPMethod,
														 (__bridge CFURLRef)url,
														 kCFHTTPVersion1_1);
	
	//We have a couple of default headers we want to add.  We do these first and then allow things in the
	//request to override.
	CFHTTPMessageSetHeaderFieldValue(msgRef, CFSTR("Upgrade"), CFSTR("WebSocket"));
	CFHTTPMessageSetHeaderFieldValue(msgRef, CFSTR("Connection"), CFSTR("Upgrade"));
	CFHTTPMessageSetHeaderFieldValue(msgRef, CFSTR("User-Agent"), (__bridge CFStringRef)[self userAgentValue]);
	CFHTTPMessageSetHeaderFieldValue(msgRef, CFSTR("Sec-WebSocket-Origin"), (__bridge CFStringRef)kNTIWebSocket7Origin);
	CFHTTPMessageSetHeaderFieldValue(msgRef, CFSTR("Sec-WebSocket-Key"), (__bridge CFStringRef)self->key);
	CFHTTPMessageSetHeaderFieldValue(msgRef, CFSTR("Sec-WebSocket-Version"), CFSTR("13"));
	
	//Host has the port if it isn't default
	NSString* host = url.host;
	if(url.port){
		host = [NSString stringWithFormat: @"%@:%@", host, url.port];
	}
	CFHTTPMessageSetHeaderFieldValue(msgRef, CFSTR("Host"), (__bridge CFStringRef)host);
	
	//Force the origin to be http(s) even if we are ws(s)
	NSString *origin = [NSString stringWithFormat:@"http%@://%@", (secure) ? @"s" : @"", host];
	CFHTTPMessageSetHeaderFieldValue(msgRef, CFSTR("Origin"), (__bridge CFStringRef)origin);
	
	NSMutableDictionary* headers = [self.request.allHTTPHeaderFields mutableCopy];
	if(!headers){
		headers = [NSMutableDictionary new];
	}
	
	//Also send headers for any cookies for this host
	NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: url];
	[headers addEntriesFromDictionary: [NSHTTPCookie requestHeaderFieldsWithCookies: cookies]];

	//Now any headers specified in the incoming request and those from our cookies get added
	[headers enumerateKeysAndObjectsUsingBlock: ^(NSString* header, NSString* headerValue, BOOL *stop) {
		CFHTTPMessageSetHeaderFieldValue(msgRef, (__bridge CFStringRef)header, (__bridge CFStringRef)headerValue);
	}];
	
	NSData* requestData = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(msgRef));
	CFRelease(msgRef);
	
#ifdef DEBUG_SOCKETIO
	NSLog(@"Initiating handshake with %@", [NSString stringWithData: requestData
														   encoding: NSUTF8StringEncoding]);
#endif
	
	return requestData;
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

-(BOOL)validateResponseAcceptKey: (NSString*)acceptKey
{
	if(!acceptKey){
		return NO;
	}
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
#ifdef DEBUG_SOCKETIO
	NSString* response = [[NSString alloc] initWithData: hrBuffer.dataBuffer
											   encoding: NSUTF8StringEncoding];
	NSLog(@"Handling handshake response %@", response);
#endif
	
	//Parse the buffer as an http message
	CFHTTPMessageRef responseRef = CFHTTPMessageCreateEmpty(NULL, NO);
	CFHTTPMessageAppendBytes(responseRef, hrBuffer.dataBuffer.bytes, hrBuffer.dataBuffer.length);
	
	self->handshakeResponseBuffer = nil;
	
	//Make sure CF thinks we are complete
	if(!CFHTTPMessageIsHeaderComplete(responseRef)) {
		CFRelease(responseRef);
		[self shutdownAsResultOfError: errorWithCodeAndMessage(300, @"Encountered end of response but CF believes there is more to come")];
		return;
	}
	
	NSInteger statusCode = CFHTTPMessageGetResponseStatusCode(responseRef);
	NSDictionary* headers = [CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(responseRef)) copy];
	CFRelease(responseRef);
	
	//we expect to be upgraded
	if(statusCode == 101 && [self validateResponseAcceptKey: [headers objectForKey: @"Sec-Websocket-Accept"]]) {
		[self updateStatus: WebSocketStatusConnected];
	}
	else{
		[self shutdownAsResultOfError: errorWithCodeAndMessage(300, @"Handshake failed!")];
	}
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
		@try{
			[self consumeStreamData];
		}
		@catch (NSException* e) {
			NSLog(@"An exception occurred reading stream data %@", e);
		}
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
	//NSLog(@"recieved event %lu for stream %@ with status %lu", (unsigned long) eventCode, aStream, (unsigned long) aStream.streamStatus);
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
//	[sslSettings setObject:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
		[sslSettings setObject:(id)kCFBooleanFalse forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
#endif
	return sslSettings;
}

-(void)connect
{
	CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	
	NSURL* url = self.request.URL;
	
	BOOL useSSL = ([[url scheme] isEqual: @"https"] || [[url scheme] isEqual: @"wss"]);
	
	NSString* host = [url host];
	NSNumber* port = [url port];
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

@end
