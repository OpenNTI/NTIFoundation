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
@synthesize sessionId, heartbeatTimeout, closeTimeout, shouldBuffer;

-(id)initWithURLString:(NSString *)uStr andName: (NSString*)name andPassword: (NSString*)pwd
{
	self = [super init];
	self->url = [[NSURL URLWithString: uStr] retain];
	self->username = [name retain];
	self->password = [pwd retain];
	return self;
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

-(void)connect
{
	
	
}

-(void)disconnect
{
	
}

-(void)sendPacket:(SocketIOPacket *)packet
{
	
}

-(void)setShouldBuffer: (BOOL)willBuffer
{
	self->shouldBuffer = willBuffer;
}

-(void)dealloc
{
	NTI_RELEASE(self->serverSupportedTransports);
	NTI_RELEASE(self->username);
	NTI_RELEASE(self->password);
	NTI_RELEASE(self->url);
	NTI_RELEASE(self->namespaces);
	NTI_RELEASE(self->buffer);
	NTI_RELEASE(self->sessionId);
	[super dealloc];
}

@end
