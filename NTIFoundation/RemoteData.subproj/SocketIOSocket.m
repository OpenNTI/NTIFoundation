//
//  SocketIOSocket.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOSocket.h"
#import "NTIAbstractDownloader.h"

@implementation SocketIOHandshakeDownloader
@synthesize nr_delegate;

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[super connection: connection didFailWithError: error];
	if( [self->nr_delegate respondsToSelector: @selector(connection:didFailWithError:)] ){
		[self->nr_delegate connection: connection didFailWithError: error];
	}
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[super connectionDidFinishLoading: connection];
	if( [self->nr_delegate respondsToSelector: @selector(connectionDidFinishLoading:)] ){
		[self->nr_delegate connectionDidFinishLoading: connection];
	}
}

@end

NSString* const SocketIOResource = @"socket.io";
NSString* const SocketIOProtocol = @"1";

@implementation SocketIOSocket
@synthesize nr_delegate;

-(id)initWithURL: (NSURL *)u andName: (NSString*)name andPassword: (NSString*)pwd
{
	self = [super init];
	self->url = [u retain];
	self->username = [name retain];
	self->password = [pwd retain];
	return self;
}

-(void)updateStatus: (SocketIOSocketStatus)s
{
	if(self->status == s){
		return;
	}
	self->status = s;
	
	if([self->nr_delegate respondsToSelector:@selector(transport:connectionStatusDidChange:)]){
		[self->nr_delegate socket: self connectionStatusDidChange: s];
	}
	
	//If we are now connected we go ahead and send our auth data
	if(self->status == SocketIOSocketStatusConnected){
		[self sendPacket: [SocketIOPacket packetForEventWithName: @"message" 
														 andArgs: [NSArray arrayWithObjects: self->username, self->password, nil]]];
		[self sendPacket: [SocketIOPacket packetForEventWithName: @"message" 
														 andArgs: [NSArray arrayWithObjects: @"plist", nil]]];
		NSDictionary* args = [NSDictionary dictionaryWithObject: [NSArray arrayWithObject: @"chris.utz@nextthought.com"] forKey: @"Occupants"];
		[self sendPacket: [SocketIOPacket packetForEventWithName: @"chat_enterRoom" andArgs: [NSArray arrayWithObject: args]]];
	}
}

-(void)updateStatusFromTransportStatus: (SocketIOTransportStatus)wss
{
	[self updateStatus: (int)wss];
}

#pragma mark Transport delegate
-(void)transport:(SocketIOTransport *)t connectionStatusDidChange:(SocketIOTransportStatus)s
{
	[self updateStatusFromTransportStatus: s];
}

-(void)transport: (SocketIOTransport*)t didEncounterError: (NSError*)error
{
	//We will handle most errors at this layer
	NSLog(@"Recieved an error from the transport %@, %@", t, [error localizedDescription]);
}

-(void)transportDidRecieveData: (SocketIOTransport*)transport
{
	//When the transport has received data we grab the packet and inspect it.
	//Some things like handshakes, connects, disconnects we will handle.  Others
	//we shoot on to the delegate
	SocketIOPacket* packet = [self->transport dequeueRecievedData];
	if(!packet){
		NSLog(@"Attempt to dequeueData in transportDidRecieveData resulted in nil object.");
		return;
	}
	
	switch(packet.type){
		case SocketIOPacketTypeMessage:{
			NSLog(@"Recieved message \"%@\"", packet.data);
			if([self->nr_delegate respondsToSelector:@selector(socket:didRecieveMessage:)]){
				[self->nr_delegate socket: self didRecieveMessage: packet.data];
			}
			break;
		}
		case SocketIOPacketTypeEvent:{
			NSLog(@"Recieved event \"%@(%@)\"", packet.name, packet.args);
			if([self->nr_delegate respondsToSelector:@selector(socket:didRecieveEventNamed:withArgs:)]){
				[self->nr_delegate socket: self didRecieveEventNamed: packet.name withArgs: packet.args];
			}
			break;
		}
		default:
			NSLog(@"Recieved an unhandled packet of type %ld with encoding %@", packet.type, [packet encode]);
			break;
	}
}

-(void)transportIsReadyForData: (SocketIOTransport*)transport
{
	//We don't do anything here because we just stuff all the send packets down to
	//the transport automatically
}

-(void)initiateHandshake
{
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
	
	
	self->handshakeDownloader = [[SocketIOHandshakeDownloader alloc] 
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
	if([self->nr_delegate respondsToSelector:@selector(socket:didEncounterError:)]){
		[self->nr_delegate socket: self didEncounterError: error];
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

-(void)findAndStartTransport
{
	//Need a registry for this
	NSDictionary* ourTransports = [NSDictionary dictionaryWithObject: [SocketIOWSTransport class] forKey: @"websocket"];
	
	//We know what transport is best for us.
	for(NSString* key in [ourTransports allKeys])
	{
		if( [self transportSupported: key] ){
			NSLog(@"Will use transport %@", key);
			[self->transport release];
			self->transport = [[[ourTransports objectForKey: key] alloc] initWithRootURL: self->url andSessionId: self->sessionId];
			self->transport.nr_delegate = self;
			[self->transport connect];
			return;
		}
	}
	
	NSError* error = [self createErrorWithCode: 103 
									andMessage: [NSString stringWithFormat: @"Unable to find suitable transport.  Server supports %@. We support %@", self->serverSupportedTransports, [ourTransports allKeys]]];
	[self logAndRaiseError: error];
}

-(void)parseHandshakeResponse: (NSString*)responseBody
{
	NSArray* parts = [responseBody componentsSeparatedByString: @":"];
	
	if( [parts count] != 4){
		NSError* error = [self createErrorWithCode: 100 
										andMessage: [NSString stringWithFormat: @"Expected 4 parts but got %@", parts]];
		[self logAndRaiseError: error];
		[self updateStatus: SocketIOSocketStatusDisconnected];
	}
	
	NSString* sessionID = [[parts firstObject] retain];
	[self->sessionId release];
	self->sessionId = sessionID;
	
	self->heartbeatTimeout = [[parts secondObject] integerValue];
	self->closeTimeout = [[parts objectAtIndex: 2] integerValue];
	
	NSArray* transports = [[[parts objectAtIndex: 3] componentsSeparatedByString: @","] retain];
	[self->serverSupportedTransports release];
	self->serverSupportedTransports = transports;
	
	//Find and start transport
	[self findAndStartTransport];
}

-(void)sendPacket: (SocketIOPacket*)packet
{
	//What to do if there is no transport
	[self->transport enqueueDataForSending: packet];
}

#pragma mark handshake downloader delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if( [self->nr_delegate respondsToSelector: @selector(socket:didEncounterError:)] ){
		[self->nr_delegate socket: self didEncounterError: error];
	}
	[self updateStatus: SocketIOSocketStatusDisconnected];
	[self->handshakeDownloader release];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
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
	if(self->transport){
		return;
	}
	
	[self initiateHandshake];
}

-(void)disconnect
{
	[self->transport disconnect];
}

-(void)dealloc
{
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
