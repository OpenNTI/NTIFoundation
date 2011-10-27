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
	return [NSArray arrayWithObjects: [SocketIOWSTransport class], [SocketIOXHRPollingTransport class], nil];
}

@interface SocketIOSocket()
-(void)findAndStartTransport;
-(void)updateStatus: (SocketIOSocketStatus)s;
@end

@implementation SocketIOSocket
@synthesize nr_statusDelegate, heartbeatTimeout, 
	baseReconnectTimeout, currentReconnectTimeout, 
	reconnectAttempts, maxReconnectAttempts, 
	maxReconnectTimeout, username, password, status;

//#pragma mark SocketDelegate
////we are our own reciever delegate testing
//-(void)socket: (SocketIOSocket*)s didRecieveMessage: (NSString*)message
//{
//	NSLog(@"Recieved message \"%@\"", message);
//}
//
//-(void)chat_enteredRoom: (NSArray*)args
//{
//	NSLog(@"Recieved chat_enteredRoom event with args %@", args);
//}
//
//-(void)serverkill: (NSArray*)args
//{
//	NSLog(@"Server asked us to die with reason %@", args);
//	[self disconnect];
//}
//
//-(void)socket: (SocketIOSocket*)s didRecieveUnhandledEventNamed: (NSString *)name withArgs: (NSArray*)args
//{
//	NSLog(@"Recieved unhandled event \"%@(%@)\"", name, args);
//}

-(id)initWithURL: (NSURL *)u andName: (NSString*)name andPassword: (NSString*)pwd
{
	self = [super init];
	//URLByAppendingPathComponent likes to add a second slash if the appended path component
	//ends in a slash
	self->url = [NSURL URLWithString: [NSString stringWithFormat: @"%@/1/", u.relativeString] relativeToURL: u.baseURL];
	self->username = name;
	self->password = pwd;
	self->reconnecting = NO;
	self->buffer = [NSMutableArray arrayWithCapacity: 5];
	self->attemptedTransports = [NSMutableArray arrayWithCapacity: 3];
	self->status = SocketIOSocketStatusDisconnected;
	self.shouldBuffer = YES;	
	self->handshakeDownloader = [[NTIDelegatingDownloader alloc] 
								 initWithUsername: self->username password: self->password];
	self->eventDelegates = [NSMutableArray arrayWithCapacity: 3];
	self->baseReconnectTimeout = 3;
	self->maxReconnectAttempts = NSIntegerMax;
	self->maxReconnectTimeout = 120; //2minutes
	self->currentReconnectTimeout = self->baseReconnectTimeout;
	//[self addEventDelegate: self];
	self->handshakeDownloader.nr_delegate = self;
	return self;
}

//Add eventDelegate as an eventDelegate if it does not already exist.
//Returns false if the delegate already existed. else false
-(BOOL)addEventDelegate: (id)eventDelegate
{
	if( [self->eventDelegates containsObjectIdenticalTo: eventDelegate] ){
		return NO;
	}
	
	[self->eventDelegates addObject: eventDelegate];
	
	return YES;
}

//Remove eventDelegate from the eventsDelegate list
//returns YES if it was removed else NO
-(BOOL)removeEventDelegate: (id)eventDelegate
{
	if( [self->eventDelegates containsObjectIdenticalTo: eventDelegate] ){
		return NO;
	}
	
	[self->eventDelegates removeObjectIdenticalTo: eventDelegate];
	
	return YES;
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

-(void)clearReconnectTimer
{
	[self->reconnectTimer invalidate];
	self->reconnectTimer = nil;
}

//We try and reconnect the first 5 times fairly quickly
//Then we start backing off.
-(NSTimeInterval)nextReconnect
{
	NSTimeInterval timeout = self.currentReconnectTimeout;
	if(self->reconnectAttempts >= 5 && timeout < self.maxReconnectTimeout){
		timeout = self.currentReconnectTimeout * 1.5;
	}

	if(timeout > self->maxReconnectTimeout){
		timeout = self->maxReconnectTimeout;
	}
	return timeout;
}

-(void)startReconnectTimer
{
	if(self->reconnectTimer){
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"Scheduling reconnect timer for %f seconds", self->currentReconnectTimeout);
#endif 
	self->reconnectTimer = [NSTimer scheduledTimerWithTimeInterval: self.currentReconnectTimeout 
															   target: self 
															 selector: @selector(reconnect) 
															 userInfo: nil 
															  repeats: NO];
	self->currentReconnectTimeout = [self nextReconnect];
}

-(void)clearCloseTimer
{
	[self->closeTimeoutTimer invalidate];
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
	self->closeTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval: self->closeTimeout 
																target: self 
															  selector: @selector(closeTimeoutFired) 
															  userInfo: nil repeats: NO];
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
	
	[self sendPacket: [SocketIOPacket packetForEventWithName: @"message" 
													 andArgs: [NSArray arrayWithObjects: 
															   self->username, self->password, nil]]];
	
	self->reconnectAttempts = 0;
	self->reconnecting = NO;
	self->currentReconnectTimeout = self->baseReconnectTimeout;
	[self->attemptedTransports removeAllObjects];
}

-(void)onDisconnecting
{

}

-(void)onDisconnected
{
	//If we still have a closeTimer running make sure to cancel it
	[self clearCloseTimer];
	
	[self->buffer removeAllObjects];
	
	//If we weren't asked to disconnect this was a disconnect
	//due to a dead transport and a closeTimout.  Try to reconnect the
	//whole socket if we need to.
	//TODO a few arbitrary limits here need to be pulled out to options
	if( !self->forceDisconnect && self->reconnectAttempts < self.maxReconnectAttempts ){
		if( [self->nr_statusDelegate respondsToSelector:@selector(socketWillReconnect:) ] ){
			[self->nr_statusDelegate socketWillReconnect: self];
		}
		[self startReconnectTimer];
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
}

-(void)closeTimeoutFired
{
#ifdef DEBUG_SOCKETIO
	NSLog(@"Close timeout reached. Disconnecting.");
#endif
	[self updateStatus: SocketIOSocketStatusDisconnecting];
	[self updateStatus: SocketIOSocketStatusDisconnected];
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
			[self updateStatus: SocketIOSocketStatusDisconnected];
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
	//We will handle most errors at this layer but for information purposes we pass them on.
	NSLog(@"Recieved an error from the transport %@, %@", t, [error localizedDescription]);
	
	if([self->nr_statusDelegate respondsToSelector: @selector(socket:didEncounterError:inTransport:)]){
		[self->nr_statusDelegate socket: self didEncounterError: error inTransport: t];
	}
}

-(void)passOnEvent: (SocketIOPacket*)packet toDelegate: (id)delegate
{
	//Generator a selector
	NSString* selectorString = [NSString stringWithStrings: packet.name, @":", nil];
	
	SEL eventSel = NSSelectorFromString(selectorString);
	if( [delegate respondsToSelector: eventSel] ) {
		objc_msgSend( delegate, eventSel, packet.args );
		return;
	}
	
	if([delegate respondsToSelector: @selector(socket:didRecieveUnhandledEventNamed:withArgs:)]){
		[delegate socket: self didRecieveUnhandledEventNamed: packet.name withArgs: packet.args];
	}
}

-(void)passOnEvent: (SocketIOPacket*)packet
{
	for(id eventDelegate in self->eventDelegates){
		[self passOnEvent: packet toDelegate: eventDelegate];
	}
}

-(void)passOnMessage: (SocketIOPacket*)packet
{
	for(id eventDelegate in self->eventDelegates){
		if([eventDelegate respondsToSelector:@selector(socket:didRecieveMessage:)]){
			[eventDelegate socket: self didRecieveMessage: packet.data];
		}
	}
}

-(void)handlePacket: (SocketIOPacket*)packet
{
	switch(packet.type){
		case SocketIOPacketTypeMessage:{
			[self passOnMessage: packet];
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
	if([self->nr_statusDelegate respondsToSelector:@selector(socket:didEncounterError:inTransport:)]){
		[self->nr_statusDelegate socket: self didEncounterError: error inTransport: nil];
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
		[self updateStatus: SocketIOSocketStatusDisconnected];
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"Will use transport %@", [transportClass name]);
#endif

	[self->attemptedTransports addObject: [transportClass name]];
	self->transport = [[transportClass alloc] initWithRootURL: self->url 
												 andSessionId: self->sessionId];
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
	
	NSString* sessionID = [parts firstObject];
	self->sessionId = sessionID;
	
	self->heartbeatTimeout = [[parts secondObject] integerValue];
	self->closeTimeout = [[parts objectAtIndex: 2] integerValue];
	
	NSArray* transports = [[parts objectAtIndex: 3] componentsSeparatedByString: @","];
	self->serverSupportedTransports = transports;
	
	[self updateStatus: SocketIOSocketStatusConnected];

	//Find and start transport
	[self findAndStartTransport];
}

-(void)sendPacket: (SocketIOPacket*)packet
{
	//Do we actually want to buffer if we are connecting?
	if(self->status == SocketIOSocketStatusConnected || self->status == SocketIOSocketStatusConnecting){
		if( self->shouldBuffer ){
#ifdef DEBUG_SOCKETIO
			NSLog(@"Buffering packet");
#endif
			[self->buffer addObject: packet];
		}
		else{
			[self->transport sendPacket: packet];
		}
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
	//We can only connect if we are disconnected
	if(self->status != SocketIOSocketStatusDisconnected){
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"SocketIOSocket initiating connection to %@", self->url);
#endif
	//We need to reset our forceDisconnect state
	self->forceDisconnect = NO;
	[self initiateHandshake];
}

-(void)disconnect
{
	[self clearReconnectTimer];
	
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
		[self updateStatus: SocketIOSocketStatusDisconnected];
	}
}

-(void)forceKill
{
	[self clearReconnectTimer];
	
#ifdef DEBUG_SOCKETIO
	NSLog(@"SocketIOSocket initiating forcekill");
#endif
	
	self->forceDisconnect = YES;
	
	[self updateStatus: SocketIOSocketStatusDisconnecting];
	
	//If we have a transport disconnect it
	if(self->transport){
		[self->transport forceKill];
	}
	else{
		[self updateStatus: SocketIOSocketStatusDisconnected];
	}
}

-(void)reconnect
{
	[self clearReconnectTimer];
	
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
	[self clearReconnectTimer];
	[self clearCloseTimer];
}

@end
