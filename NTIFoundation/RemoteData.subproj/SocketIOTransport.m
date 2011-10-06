//
//  SocketIOTransport.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOTransport.h"
#import "SocketIOSocket.h"

@implementation SocketIOTransport
@synthesize nr_socket, status;

-(id)initWithRootURL: (NSURL*)u andSessionId: (NSString*)sid;
{
	self = [super init];
	self->sessionId = [sid retain];
	self->rootURL = [u retain];
	self->status = SocketIOTransportStatusNew;
	return self;
}

-(void)connect
{

}

-(void)disconnect
{

}

-(void)sendPayload:(NSArray*)payload
{
	
}

-(void)sendPacket:(SocketIOPacket *)packet
{
	
}

-(void)forceKill
{
	
}

+(NSString*)name
{
	return @"unknown";
}

-(NSURL*)urlForTransport
{
	return [self->rootURL URLByAppendingPathComponent: 
			[NSString stringWithFormat: @"%@/%@", [[self class] name], self->sessionId]];
}

-(void)logAndRaiseError: (NSError*)error
{
	NSLog(@"%@", [error localizedDescription]);
	[self.nr_socket transport: self didEncounterError: error];
}

-(void)updateStatus: (SocketIOTransportStatus)s
{
	if(self->status == s){
		return;
	}
	self->status = s;
#ifdef DEBUG_SOCKETIO
	NSLog(@"Transport status updated to %ld", s);
#endif
	[self->nr_socket transport: self connectionStatusDidChange: s];
}

-(NSError*)createErrorWithCode: (NSInteger)code andMessage: (NSString*)message
{
	NSDictionary* userData = [NSDictionary dictionaryWithObject: message forKey: NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain: @"SocketIOTransport" code: code userInfo: userData];
}

-(BOOL)handlePacket: (SocketIOPacket*)p
{
#ifdef DEBUG_SOCKETIO
	NSLog(@"Handling packet %@", [p encode]);
#endif
	switch(p.type){
		case SocketIOPacketTypeConnect:
			[self updateStatus: SocketIOTransportStatusOpen];
			return YES;
		case SocketIOPacketTypeHeartbeat:
			//TODO Send a heartbeat back.
			//[self sendPacket: [SocketIOPacket packetForHeartbeat]];
			return YES;
		case SocketIOPacketTypeNoop:
			return YES;
		default:
			return NO;
	}
	return NO;
}

-(BOOL)recievedData: (NSData*)data
{
	//We have what should be a socket io serialized packet. Turn it into a packet object
	//NSLog(@"Recieved %@", data);
	NSArray* payload = nil;
	@try {
		payload = [SocketIOPacket decodePayload: data];
	}
	@catch (NSException *exception) {
		NSLog(@"Encountered issue when decoding data %@", exception);
	}
	
	//Do we do anything other than tell our delegate?  Do we even tell our delegate?
	if(!payload)
	{
		NSError* error = [self createErrorWithCode: 201 
										andMessage: 
						  [NSString stringWithFormat: 
						   @"Unable to create socket.io packet from data %@", data]];
		[self logAndRaiseError: error];
		return NO;
	}
	
	NSArray* toPassOn = [payload filteredArrayUsingPredicate: [NSPredicate predicateWithBlock: ^BOOL(id obj, NSDictionary* bindings){
		return ![self handlePacket: obj];
	}]];
	
	//Now we inform our delegate that we have data
	[self.nr_socket transport: self didRecievePayload: toPassOn];
	return YES;
}

-(void)dealloc
{
	NTI_RELEASE(self->sessionId);
	NTI_RELEASE(self->rootURL);
	[super dealloc];
}

@end

#pragma mark xhr-polling


/**
 * We currently poll for new data as soon as we get data back 
 * from the server.  This is the same implementation as the browser
 * client however it is probably not ideal for the pad.  There are a number
 * of different tradeoffs to consider on the pad, including battery life.
 * We likely want some complicated hueristic that polls repeatedly when
 * there are things going on and backs off to a timer based polling implementation.
 */
@implementation SocketIOXHRPollingTransport

+(NSString*)name
{
	return @"xhr-polling";
}

-(id)initWithRootURL:(NSURL *)u andSessionId:(NSString *)s
{
	self = [super initWithRootURL: u andSessionId: s];
	self->sendBuffer = [[NSMutableArray arrayWithCapacity: 5] retain];
	return self;
}

-(NSURLRequest*)requestWithMethod: (NSString*)method andData: (NSData*)data
{
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: [self urlForTransport]];
	[request setHTTPMethod: method];
	
	if(data){
		[request setValue: @"Content-type" forHTTPHeaderField: @"text/plain;charset=UTF-8"];
		[request setHTTPBody: data];
	}
	
	return request;
}

-(void)poll
{
	if(self->downloader || self.status != SocketIOTransportStatusOpen){
		return;
	}
#ifdef DEBUG_SOCKETIO
	NSLog(@"Sending XHR polling");
#endif
	//Dequeue data from our buffer
	//To send
	NSArray* toSend = [NSArray arrayWithArray: self->sendBuffer];
	//Remove the ones we are going to send from the buffer
	[self->sendBuffer removeIdenticalObjectsFromArray: toSend];
	
	NSString* method = @"GET";
	NSData* data = nil;
	
	if( [toSend count] > 0 ){
		method = @"POST";
		data = [SocketIOPacket encodePayload: toSend];
#ifdef DEBUG_SOCKETIO
		NSLog(@"Sending payload %@", data);
#endif
	}

	self->downloader = [[NTIDelegatingDownloader alloc] initWithUsername: nil password: nil];
	self->downloader.nr_delegate = self;
	NSURLRequest* request = [self requestWithMethod: method andData: data];
	NSURLConnection* connection = [NSURLConnection connectionWithRequest: request delegate: self->downloader];
	[connection start];
}

#pragma mark downloader delegate methods
#pragma mark handshake downloader delegate
-(void)downloader:(NTIDelegatingDownloader *)d connection: (NSURLConnection*)c didFailWithError:(NSError *)error
{
	[self->downloader release];
	self->downloader=nil;
	//Regardless of when we encountered the error. raise and disconnect.
	[self logAndRaiseError: error];
	[self disconnect];
	
}

-(void)downloader: (NTIDelegatingDownloader *)d didFinishLoading:(NSURLConnection *)c
{
	//We got a response if it was from connecting we need to start our timer.
	NSData* dataBody = [downloader data];
	[self->downloader release];
	self->downloader=nil;
	
	//We only poll if we are open.  If we are closed now just have to throw away the data
	if( self.status == SocketIOTransportStatusClosed ){
		return;
	}
	
	BOOL opening = self.status == SocketIOTransportStatusOpening;
	
	BOOL goodData = [self recievedData: dataBody];
	
	if(opening && !goodData){
		[self disconnect];
	}
	else{
		[self poll];
	}
}


-(void)connect
{
	[self updateStatus: SocketIOTransportStatusOpening];
	NSURLRequest* request = [self requestWithMethod: @"POST" andData: nil];
	self->downloader = [[NTIDelegatingDownloader alloc] initWithUsername: nil password: nil];
	self->downloader.nr_delegate = self;
	NSURLConnection* connection = [NSURLConnection connectionWithRequest: request delegate: self->downloader];
	[connection start];
}

-(void)disconnect
{
	[self updateStatus: SocketIOTransportStatusClosing];
	[self updateStatus: SocketIOTransportStatusClosed];
}

-(void)forceKill
{
	[self disconnect];
}

-(void)sendPayload:(NSArray*)payload
{
	[self->sendBuffer addObjectsFromArray: payload];
}

-(void)sendPacket:(SocketIOPacket *)packet
{
	[self->sendBuffer addObject: packet];
}

-(void)dealloc
{
	NTI_RELEASE(self->sendBuffer);
	NTI_RELEASE(self->downloader);
	[super dealloc];
}

@end

#pragma mark websocket

@implementation SocketIOWSTransport

+(NSString*)name
{
	return @"websocket";
}

-(void)connect
{
	if(self->socket)
	{
		return;
	}
	
	NSURL* websocketURL = [self urlForTransport];
	
	self->socket = [[WebSocket7 alloc] initWithURL: websocketURL];
	self->socket.nr_delegate = self;
	[self->socket connect];
}

-(void)disconnect
{
	[self updateStatus: SocketIOTransportStatusClosing];
	[self->socket disconnect];
}

-(void)forceKill
{
	[self updateStatus: SocketIOTransportStatusClosing];
	[self->socket kill];
	[self updateStatus: SocketIOTransportStatusClosed];
}
 
-(void)websocket: (WebSocket7*)socket connectionStatusDidChange: (WebSocketStatus)wss
{
#ifdef DEBUG_SOCKETIO
	NSLog(@"Websocket status updated to %ld", wss);
#endif
	if( wss == WebSocketStatusDisconnected ){
		[self updateStatus: SocketIOTransportStatusClosed];
	}
}

-(void)websocket: (WebSocket7*)socket didEncounterError: (NSError*)error
{
	[self.nr_socket transport: self didEncounterError: error];
}


-(void)websocketDidRecieveData: (WebSocket7*)socket
{
	//There is data for us it better be a string on the websocket.  We need
	//todeque it, turn it into a packet and stuff it into our rQ
	WebSocketData* wsdata = [self->socket dequeueRecievedData] ;
	
	if(!wsdata){
		NSLog(@"Attempt to dequeueData in websocketDidReceiveData resulted in nil object.");
		return;
	}
	
	//We are promised to only be called when there is a full ws object that is NSData
	
	[self recievedData: wsdata.data];
	
}

//For the websocket implementation we just queue this bad boy up for the socket
-(void)sendPayload:(NSArray*)payload
{
	//Payload isn't implement for websockets so we loop and enqueue
//	WebSocketData* data = [[[WebSocketData alloc] initWithData: 
//								 [SocketIOPacket encodePayload: payload] 
//														isText: YES] autorelease];
	for(id packet in payload){
		[self sendPacket: packet];
	}
}

-(void)sendPacket:(SocketIOPacket *)packet
{
	WebSocketData* data = [[[WebSocketData alloc] initWithData: 
							[packet encode] isText: YES] autorelease];
	[self->socket enqueueDataForSending: data];
}


-(void)dealloc
{
	NTI_RELEASE(self->socket);
	[super dealloc];
}

@end
