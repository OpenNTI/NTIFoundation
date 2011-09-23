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

-(id)initWithURL: (NSURL *)u andName: (NSString*)name andPassword: (NSString*)pwd
{
	self = [super init];
	self->url = [u retain];
	self->username = [name retain];
	self->password = [pwd retain];
	self->reconnecting = NO;
	self->buffer = [[NSMutableArray arrayWithCapacity: 5] retain];
	self->attemptedTransports = [[NSMutableArray arrayWithCapacity: 3] retain];
	return self;
}

-(BOOL)shouldBuffer
{
	return self->shouldBuffer;
}

-(void)setShouldBuffer:(BOOL)sb
{
	self->shouldBuffer = sb;
	
	NSLog(@"Will buffer packets? %i", self->shouldBuffer);
	
	if(!self->shouldBuffer && self->status == SocketIOSocketStatusConnected && 
	   [self->buffer count] > 0)
	{
		NSLog(@"Emptying buffer to tranport");
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
	NSLog(@"Firing close timeout timer");
	self->closeTimeoutTimer = [[NSTimer scheduledTimerWithTimeInterval: self->closeTimeout 
																target: self 
															  selector: @selector(closeTimeoutFired) 
															  userInfo: nil repeats: NO] retain];
}

-(void)onConnecting
{
	
}

-(void)onConnected
{
	self->reconnectAttempts = 0;
}

-(void)onDisconnecting
{
	[self updateStatus: SocketIOSocketStatusDisconnected];
}

-(void)onDisconnected
{
	
}


-(void)updateStatus: (SocketIOSocketStatus)s
{
	if(self->status == s){
		return;
	}
	self->status = s;
	
	NSLog(@"Socket status updated to %ld", self->status);
	
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
	
	if([self->nr_statusDelegate respondsToSelector:@selector(transport:connectionStatusDidChange:)]){
		[self->nr_statusDelegate socket: self connectionStatusDidChange: s];
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
	NSLog(@"Close timeout reached. Disconnecting.");
	[self updateStatus: SocketIOSocketStatusDisconnecting];
}

#pragma mark Transport delegate
-(void)transport:(SocketIOTransport *)t connectionStatusDidChange:(SocketIOTransportStatus)s
{
	NSLog(@"transport %@ changed connection status to  %ld", t, s);
	
	if( s == SocketIOTransportStatusOpen ){
		[self clearCloseTimer];
		[self setShouldBuffer: NO];
		[self->attemptedTransports removeAllObjects];
	}
	
	if( s == SocketIOTransportStatusClosing || s == SocketIOTransportStatusClosed){
		[self setShouldBuffer: YES];
	}
	
	if( s == SocketIOTransportStatusClosed ) {
		//If the transport closes we need to try and reconnect
		//Fire the disconnect timer and run like hell to open another transport
		[self startCloseTimer];
		[self findAndStartTransport];
	}
		 
}

-(void)transport: (SocketIOTransport*)t didEncounterError: (NSError*)error
{
	//We will handle most errors at this layer
	NSLog(@"Recieved an error from the transport %@, %@", t, [error localizedDescription]);
}

-(void)handlePacket: (SocketIOPacket*)packet
{
	switch(packet.type){
		case SocketIOPacketTypeMessage:{
			NSLog(@"Recieved message \"%@\"", packet.data);
			if([self->nr_recieverDelegate respondsToSelector:@selector(socket:didRecieveMessage:)]){
				[self->nr_recieverDelegate socket: self didRecieveMessage: packet.data];
			}
			break;
		}
		case SocketIOPacketTypeEvent:{
			NSLog(@"Recieved event \"%@(%@)\"", packet.name, packet.args);
			if([self->nr_recieverDelegate respondsToSelector:@selector(socket:didRecieveEventNamed:withArgs:)]){
				[self->nr_recieverDelegate socket: self didRecieveEventNamed: packet.name withArgs: packet.args];
			}
			break;
		}
		default:
			NSLog(@"Recieved an unhandled packet of type %ld with encoding %@", packet.type, [packet encode]);
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
	
	
	self->handshakeDownloader = [[NTIDelegatingDownloader alloc] 
								 initWithUsername: self->username password: self->password];
	self->handshakeDownloader.nr_delegate = self;
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
	
	NSLog(@"Looking for a transport");
	
	Class transportClass = [self findTransportExcluding: self->attemptedTransports];
	
	if(!transportClass){
		NSError* error = [self createErrorWithCode: 103 
										andMessage: [NSString stringWithFormat: @"Unable to find suitable transport.  Server supports %@. Our options were %@", 
													 self->serverSupportedTransports, implementedTransportClasses()]];
		//We can't find any transports.  Nothing left to do but disconnect ourselves and let the socket level retry kick
		//in.
		[self logAndRaiseError: error];
		[self updateStatus: SocketIOSocketStatusDisconnecting];
	}
	
	NSLog(@"Will use transport %@", [transportClass name]);
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
	//What to do if there is no transport
	if( self->shouldBuffer && self->status == SocketIOSocketStatusConnected){
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
	[self->handshakeDownloader release];
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
	[self->handshakeDownloader release];
}

-(void)connect
{
	[self setShouldBuffer: YES];
	self->forceDisconnect = NO;
	[self initiateHandshake];
}

-(void)disconnect
{
	self->forceDisconnect = YES;
	[self->transport disconnect];
}

-(void)reconnect
{
	if(self->reconnectAttempts < 3)
	{
		[self connect];
	}
	
	self->reconnectAttempts = self->reconnectAttempts + 1;
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
