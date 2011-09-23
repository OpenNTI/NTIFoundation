//
//  SocketIOSocket.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOSocket.h"
#import "NTIAbstractDownloader.h"

NSString* const SocketIOResource = @"socket.io";
NSString* const SocketIOProtocol = @"1";

static NSArray* implementedTransportClasses()
{
	return [NSArray arrayWithObjects: [SocketIOXHRPollingTransport class], [SocketIOWSTransport class], nil];
}

@interface SocketIOSocket()
-(void)findAndStartTransport;
-(void)updateStatus: (SocketIOSocketStatus)s;
@end

@implementation SocketIOSocket
@synthesize nr_statusDelegate, nr_recieverDelegate, heartbeatTimeout;

#pragma mark SocketDelegate
//we are our own reciever delegate testing
-(void)socket: (SocketIOSocket*)s didRecieveMessage: (NSString*)message
{
	NSLog(@"Recieved message \"%@\"", message);
}

-(void)chat_enteredRoom: (NSArray*)args
{
	NSLog(@"Recieved chat_enteredRoom event with args %@", args);
}

-(void)serverkill: (NSArray*)args
{
	NSLog(@"Server asked us to die with reason %@", args);
	[self disconnect];
}

-(void)socket: (SocketIOSocket*)s didRecieveUnhandledEventNamed: (NSString *)name withArgs: (NSArray*)args
{
	NSLog(@"Recieved unhandled event \"%@(%@)\"", name, args);
}

-(id)initWithURL: (NSURL *)u andName: (NSString*)name andPassword: (NSString*)pwd
{
	self = [super init];
	self->url = [u retain];
	self->username = [name retain];
	self->password = [pwd retain];
	self->reconnecting = NO;
	self->buffer = [[NSMutableArray arrayWithCapacity: 5] retain];
	self->attemptedTransports = [[NSMutableArray arrayWithCapacity: 3] retain];
	self->status = SocketIOSocketStatusDisconnected;
	self->nr_recieverDelegate = self;
	self.shouldBuffer = YES;
	
	self->handshakeDownloader = [[NTIDelegatingDownloader alloc] 
								 initWithUsername: self->username password: self->password];
	self->handshakeDownloader.nr_delegate = self;
	return self;
}

-(BOOL)shouldBuffer
{
	return self->shouldBuffer;
}

-(void)setShouldBuffer:(BOOL)sb
{
	self->shouldBuffer = sb;
#ifdef DEBUG_SOCKETIO
	NSLog(@"Will buffer packets? %i", self->shouldBuffer);
#endif
	
	if(!self->shouldBuffer && self->status == SocketIOSocketStatusConnected && 
	   [self->buffer count] > 0)
	{
#ifdef DEBUG_SOCKETIO
		NSLog(@"Emptying buffer to tranport %ld packets", [self->buffer count]);
#endif
		[self->transport sendPayload: [NSArray arrayWithArray: self->buffer]];
		[self->buffer removeAllObjects];
	}
}

-(void)clearCloseTimer
{
	[self->closeTimeoutTimer invalidate];
	NTI_RELEASE(self->closeTimeoutTimer);
	self->closeTimeoutTimer = nil;
}

-(void)startCloseTimer
{
	if(self->closeTimeoutTimer){
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"Scheduling close timeout timer");
#endif
	self->closeTimeoutTimer = [[NSTimer scheduledTimerWithTimeInterval: self->closeTimeout 
																target: self 
															  selector: @selector(closeTimeoutFired) 
															  userInfo: nil repeats: NO] retain];
}

-(void)onConnecting
{
	if(self->reconnecting){
		if( [self->nr_statusDelegate respondsToSelector:@selector(socketIsReconnecting:) ] ){
			[self->nr_statusDelegate socketIsReconnecting: self];
		}
	}
}

-(void)onConnected
{
	if(self->reconnecting){
		if( [self->nr_statusDelegate respondsToSelector:@selector(socketDidReconnect:) ] ){
			[self->nr_statusDelegate socketDidReconnect: self];
		}
	}
	else{
		if( [self->nr_statusDelegate respondsToSelector:@selector(socketDidConnect:) ] ){
			[self->nr_statusDelegate socketDidConnect: self];
		}
	}
	
	self->reconnectAttempts = 0;
	self->reconnecting = NO;
}

-(void)onDisconnecting
{
	[self updateStatus: SocketIOSocketStatusDisconnected];
}

-(void)onDisconnected
{
	[self->buffer removeAllObjects];
	
	//If we weren't asked to disconnect this was a disconnect
	//due to a dead transport and a closeTimout.  Try to reconnect the
	//whole socket if we need to.
	//TODO a few arbitrary limits here need to be pulled out to options
	if( !self->forceDisconnect && self->reconnectAttempts < 3 ){
#ifdef DEBUG_SOCKETIO
		NSLog(@"Scheduling reconnect timer.");
#endif 
		if( [self->nr_statusDelegate respondsToSelector:@selector(socketWillReconnect:) ] ){
			[self->nr_statusDelegate socketWillReconnect: self];
		}
		//According to the docs this is retained by our run loop so we don't need to hold on to it
		NSTimer* reconnectTimer = [NSTimer scheduledTimerWithTimeInterval: 3 
																   target: self 
																 selector: @selector(reconnect) 
																 userInfo: nil 
																  repeats: NO];
		//Appease the compiler
		[[reconnectTimer retain] release];
	}
	else{
		if(self->forceDisconnect){
			if( [self->nr_statusDelegate respondsToSelector:@selector(socketDidDisconnect:) ] ){
				[self->nr_statusDelegate socketDidDisconnect: self];
			}
		}
		else{
#ifdef DEBUG_SOCKETIO
			NSLog(@"Maximum number or reconnects exceeded.");
#endif
			if( [self->nr_statusDelegate respondsToSelector:@selector(socketDidDisconnectUnexpectedly:) ] ){
				[self->nr_statusDelegate socketDidDisconnectUnexpectedly: self];
			}
		}
	}
}

-(void)updateStatus: (SocketIOSocketStatus)s
{
	if(self->status == s){
		return;
	}
	self->status = s;
#ifdef DEBUG_SOCKETIO
	NSLog(@"Socket status updated to %ld", self->status);
#endif
	
	switch(self->status){
		case SocketIOSocketStatusConnecting:
			[self onConnecting];
			break;
		case SocketIOSocketStatusConnected:
			[self onConnected];
			break;
		case SocketIOSocketStatusDisconnecting:
			[self onDisconnecting];
			break;
		case SocketIOSocketStatusDisconnected:
			[self onDisconnected];
			break;
		default:
			break;
	}
	
	//If we are now connected we go ahead and send our auth data. We wont really do this but we don't have a socketiosocket delegate
	//yet and this is a quick way to test.
	if(self->status == SocketIOSocketStatusConnected){
		[self sendPacket: [SocketIOPacket packetForEventWithName: @"message" 
														 andArgs: [NSArray arrayWithObjects: self->username, self->password, nil]]];
		[self sendPacket: [SocketIOPacket packetForEventWithName: @"message" 
														 andArgs: [NSArray arrayWithObjects: @"plist", nil]]];
		NSDictionary* args = [NSDictionary dictionaryWithObject: [NSArray arrayWithObject: @"chris.utz@nextthought.com"] forKey: @"Occupants"];
		[self sendPacket: [SocketIOPacket packetForEventWithName: @"chat_enterRoom" andArgs: [NSArray arrayWithObject: args]]];
		[self sendPacket: [SocketIOPacket packetForEventWithName: @"chat_enterRoom" andArgs: [NSArray arrayWithObject: args]]];
		[self sendPacket: [SocketIOPacket packetForEventWithName: @"chat_enterRoom" andArgs: [NSArray arrayWithObject: args]]];
	}
}

-(void)closeTimeoutFired
{
#ifdef DEBUG_SOCKETIO
	NSLog(@"Close timeout reached. Disconnecting.");
#endif
	[self updateStatus: SocketIOSocketStatusDisconnecting];
}

#pragma mark Transport delegate
-(void)transport:(SocketIOTransport *)t connectionStatusDidChange:(SocketIOTransportStatus)s
{
#ifdef DEBUG_SOCKETIO
	NSLog(@"transport %@ changed connection status to  %ld", t, s);
#endif
	if( s == SocketIOTransportStatusOpen ){
		[self clearCloseTimer];
		[self setShouldBuffer: NO];
		[self->attemptedTransports removeAllObjects];
	}
	
	if( s == SocketIOTransportStatusClosing || s == SocketIOTransportStatusClosed){
		[self setShouldBuffer: YES];
	}
	
	
	if( s == SocketIOTransportStatusClosed ) {
		//If the transport closes because we are trying to disconnect we just move our self into disconnecting
		if(self->forceDisconnect){
			//If this is a force disconnect we will happily ablige.  This means if we try to connect
			//in what would be the close timeout we will crete a new socketio session anyway
			[self updateStatus: SocketIOSocketStatusDisconnecting];
		}
		else{
			//If the transport closes but it wasn't from a force we try our hardest not to die.
			//Fire the disconnect timer and run like hell to open another transport
			[self startCloseTimer];
			[self findAndStartTransport];
		}
	}
		 
}

-(void)transport: (SocketIOTransport*)t didEncounterError: (NSError*)error
{
	//We will handle most errors at this layer
	NSLog(@"Recieved an error from the transport %@, %@", t, [error localizedDescription]);
}

-(void)passOnEvent: (SocketIOPacket*)packet
{
	//Generator a selector
	NSString* selectorString = [NSString stringWithStrings: packet.name, @":", nil];
	
	SEL eventSel = NSSelectorFromString(selectorString);
	if( [self->nr_recieverDelegate respondsToSelector: eventSel] ){
		[self->nr_recieverDelegate performSelector: eventSel withObject: packet.args];
		return;
	}
	
	if([self->nr_recieverDelegate respondsToSelector: @selector(socket:didRecieveUnhandledEventNamed:withArgs:)]){
		[self->nr_recieverDelegate socket: self didRecieveUnhandledEventNamed: packet.name withArgs: packet.args];
	}
}

-(void)handlePacket: (SocketIOPacket*)packet
{
	switch(packet.type){
		case SocketIOPacketTypeMessage:{
			if([self->nr_recieverDelegate respondsToSelector:@selector(socket:didRecieveMessage:)]){
				[self->nr_recieverDelegate socket: self didRecieveMessage: packet.data];
			}
			break;
		}
		case SocketIOPacketTypeEvent:{
			[self passOnEvent: packet];
			break;
		}
		case SocketIOPacketTypeDisconnect:{
			[self disconnect];
			break;
		}
		default:
#ifdef DEBUG_SOCKETIO
			NSLog(@"Recieved an unhandled packet of type %ld with encoding %@", packet.type, [packet encode]);
#endif
			break;
	}
}

-(void)transport: (SocketIOTransport*)socket didRecievePayload: (NSArray*)payload;
{
	//payload may be an array
	for(SocketIOPacket* packet in payload){
		[self handlePacket: packet];
	}
}

-(void)initiateHandshake
{
	[self updateStatus: SocketIOSocketStatusConnecting];
	//The handshake/negotiation begins with a POST to
	//$BASEURL/Resource/Protocol/ to retrieve timeout info
	//along with a session id and a list of supported transports
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: self->url];
	[request setHTTPMethod: @"POST"];
	
	//While we use Basic auth, we can save ourselves a roundtrip to the
	//server by pre-authenticating the outgoing connection.
	NSString* auth = [[[NSString stringWithFormat: @"%@:%@", self->username, self->password] 
					   dataUsingEncoding: NSUTF8StringEncoding] base64String];
	[request setValue: [NSString stringWithFormat: @"Basic %@", auth] forHTTPHeaderField: @"Authorization"];
	
	//Use timeout?
	NSURLConnection* connection = [NSURLConnection connectionWithRequest: request delegate: self->handshakeDownloader];
	[connection start];
								   
}

-(NSError*)createErrorWithCode: (NSInteger)code andMessage: (NSString*)message
{
	NSDictionary* userData = [NSDictionary dictionaryWithObject: message forKey: NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain: @"Socket.IO" code: code userInfo: userData];
}

-(void)logAndRaiseError: (NSError*)error
{
	NSLog(@"%@", [error localizedDescription]);
	if([self->nr_statusDelegate respondsToSelector:@selector(socket:didEncounterError:)]){
		[self->nr_statusDelegate socket: self didEncounterError: error];
	}
}

-(BOOL)transportSupported: (NSString*)transportName
{
	for(NSString* serverTrans in self->serverSupportedTransports){
		if( [serverTrans isEqualToString: transportName] ){
			return YES;
		}
	}
	return NO;
}

-(Class)findTransportExcluding: (NSArray*)toExcludeName
{
	if(!toExcludeName){
		toExcludeName = [NSArray array];
	}
	//Right now our hueristics is simple.  We assume our list of
	//implemented classes is in priority order.  we find the first one that is
	//implemented by the server but not in our toExcludeName list
	for(Class transportClass in implementedTransportClasses()){
		NSString* tName = [transportClass name];
		if( [self->serverSupportedTransports containsObject: tName] && ![toExcludeName containsObject: tName] ){
			return transportClass;
		}
	}
	return nil;
}

-(void)findAndStartTransport
{
	//We can only open a transform in the connected state.
	if(self->status != SocketIOSocketStatusConnected){
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"Looking for a transport");
#endif
	
	Class transportClass = [self findTransportExcluding: self->attemptedTransports];
	
	if(!transportClass){
		NSError* error = [self createErrorWithCode: 103 
										andMessage: [NSString stringWithFormat: @"Unable to find suitable transport.  Server supports %@. Our options were %@", 
													 self->serverSupportedTransports, implementedTransportClasses()]];
		//We can't find any transports.  Nothing left to do but disconnect ourselves and let the socket level retry kick
		//in.
		[self logAndRaiseError: error];
		[self updateStatus: SocketIOSocketStatusDisconnecting];
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"Will use transport %@", [transportClass name]);
#endif
	[self->attemptedTransports addObject: [transportClass name]];
	[self->transport release];
	self->transport = [[transportClass alloc] initWithRootURL: self->url andSessionId: self->sessionId];
	self->transport.nr_socket= self;
	[self->transport connect];
}

-(void)parseHandshakeResponse: (NSString*)responseBody
{
	NSArray* parts = [responseBody componentsSeparatedByString: @":"];
	
	if( [parts count] != 4){
		NSError* error = [self createErrorWithCode: 100 
										andMessage: [NSString stringWithFormat: @"Expected 4 parts but got %@", parts]];
		[self logAndRaiseError: error];
		[self updateStatus: SocketIOSocketStatusDisconnected];
		return;
	}
	
	NSString* sessionID = [[parts firstObject] retain];
	[self->sessionId release];
	self->sessionId = sessionID;
	
	self->heartbeatTimeout = [[parts secondObject] integerValue];
	self->closeTimeout = [[parts objectAtIndex: 2] integerValue];
	
	NSArray* transports = [[[parts objectAtIndex: 3] componentsSeparatedByString: @","] retain];
	[self->serverSupportedTransports release];
	self->serverSupportedTransports = transports;
	
	[self updateStatus: SocketIOSocketStatusConnected];

	//Find and start transport
	[self findAndStartTransport];
}

-(void)sendPacket: (SocketIOPacket*)packet
{
	//Do we actually want to buffer if we are connecting?
	if( self->shouldBuffer && 
	   (self->status == SocketIOSocketStatusConnected || self->status == SocketIOSocketStatusConnecting)){
#ifdef DEBUG_SOCKETIO
		NSLog(@"Buffering packet");
#endif
		[self->buffer addObject: packet];
	}
	else{
		[self->transport sendPacket: packet];
	}
}

#pragma mark handshake downloader delegate
-(void)downloader:(NTIDelegatingDownloader *)d connection: (NSURLConnection*)c didFailWithError:(NSError *)error
{
	[self logAndRaiseError: error];
	[self updateStatus: SocketIOSocketStatusDisconnected];
}

-(void)downloader: (NTIDelegatingDownloader *)d didFinishLoading:(NSURLConnection *)c
{
	NSString* dataString = [self->handshakeDownloader stringFromData];
	
	if(!dataString){
		NSError* error = [self createErrorWithCode: 101 
										andMessage: @"No response data from handshake"];
		[self logAndRaiseError: error];
		[self updateStatus: SocketIOSocketStatusDisconnected];
	}
	[self parseHandshakeResponse: dataString];
}

-(void)connect
{
#ifdef DEBUG_SOCKETIO
	NSLog(@"SocketIOSocket initiating connect");
#endif
	//We can only connect if we are disconnected
	if(self->status != SocketIOSocketStatusDisconnected){
		return;
	}
	//We need to reset our forceDisconnect state
	self->forceDisconnect = NO;
	[self initiateHandshake];
}

-(void)disconnect
{
	if(self->status != SocketIOSocketStatusConnected){
		return;
	}
	
#ifdef DEBUG_SOCKETIO
	NSLog(@"SocketIOSocket initiating disconnect");
#endif
	self->forceDisconnect = YES;
	
	//If we have a transport disconnect it
	if(self->transport){
		[self->transport disconnect];
	}
	else{
		[self updateStatus: SocketIOSocketStatusDisconnecting];
	}
}

-(void)reconnect
{
	if(self->status != SocketIOSocketStatusDisconnected){
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"SocketIOSocket initiating reconnect");
#endif
	self->reconnecting = YES;
	self->reconnectAttempts = self->reconnectAttempts + 1;
	[self connect];	
	
}

-(void)dealloc
{
	[self clearCloseTimer];
	NTI_RELEASE(self->attemptedTransports);
	NTI_RELEASE(self->buffer);
	NTI_RELEASE(self->handshakeDownloader);
	NTI_RELEASE(self->transport);
	NTI_RELEASE(self->serverSupportedTransports);
	NTI_RELEASE(self->username);
	NTI_RELEASE(self->password);
	NTI_RELEASE(self->url);
	NTI_RELEASE(self->sessionId);
	[super dealloc];
}

@end
