//
//  SocketIOSocket.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOSocket.h"

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
	NSURL* handshakeURL = [self->url URLByAppendingPathComponent: 
						   [NSString stringWithFormat: @"%@/%@/", SocketIOResource, SocketIOProtocol]];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: handshakeURL];
	[request setHTTPMethod: @"POST"];
	
	//While we use Basic auth, we can save ourselves a roundtrip to the
	//server by pre-authenticating the outgoing connection.
	NSString* auth = [[[NSString stringWithFormat: @"%@:%@", self->username, self->password] 
					   dataUsingEncoding: NSUTF8StringEncoding] base64String];
	[request setValue: [NSString stringWithFormat: @"Basic %@", auth] forHTTPHeaderField: @"Authorization"];
	
	//Use timeout?
	NSURLConnection* connection = [NSURLConnection connectionWithRequest: request delegate: self];
	[connection start];
								   
								   
}

-(void)parseHandshakeResponse: (NSData*)responseBody
{
	NSString* responseString = [NSString stringWithData: responseBody encoding: NSUTF8StringEncoding];
	NSArray* parts = [responseString componentsSeparatedByString: @":"];
	
	if( [parts count] != 4){
		[NSException raise: @"Bad handshake" reason: [NSString stringWithFormat: @"Expected 4 parts in response but got %@", parts]];
	}
	
	NSString* sessionID = [[parts firstObject] retain];
	[self->sessionId release];
	self->sessionId = sessionID;
	
	self->heartbeatTimeout = [[parts secondObject] integerValue];
	self->closeTimeout = [[parts objectAtIndex: 2] integerValue];
	
	NSArray* transports = [[[parts objectAtIndex: 3] componentsSeparatedByString: @","] retain];
	[self->serverSupportedTransports release];
	self->serverSupportedTransports = transports;
	
	//Find a transport from the list that works for us and open it
}

-(void)sendPacket: (SocketIOPacket*)packet
{
	//What to do if there is no transport
	[self->transport enqueueDataForSending: packet];
}

-(void)connect
{
	if(self->transport){
		return;
	}
	
	self->transport = [[SocketIOWSTransport alloc] initWithRootURL: self->url 
															andSessionId: @"609076794624"];
	self->transport.nr_delegate = self;
	[self->transport connect];
	
}

-(void)disconnect
{
	[self->transport disconnect];
}

-(void)dealloc
{
	NTI_RELEASE(self->transport);
	NTI_RELEASE(self->serverSupportedTransports);
	NTI_RELEASE(self->username);
	NTI_RELEASE(self->password);
	NTI_RELEASE(self->url);
	NTI_RELEASE(self->sessionId);
	[super dealloc];
}

@end
