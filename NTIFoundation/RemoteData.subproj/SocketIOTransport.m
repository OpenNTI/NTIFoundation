//
//  SocketIOTransport.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOTransport.h"
#import "SocketIOSocket.h"
#import "WebSocketData.h"

@implementation SocketIOTransport
@synthesize nr_socket, status;

-(id)initWithRootURL: (NSURL*)u andSessionId: (NSString*)sid;
{
	self = [super init];
	self->sessionId = sid;
	self->rootURL = u;
	self->status = SocketIOTransportStatusNew;
	return self;
}

-(void)connect
{
	OBRequestConcreteImplementation(self, _cmd);
}

-(void)disconnect
{
	OBRequestConcreteImplementation(self, _cmd);
}

-(void)sendPayload:(NSArray*)payload
{
	OBRequestConcreteImplementation(self, _cmd);
}

-(void)sendPacket:(SocketIOPacket *)packet
{
	OBRequestConcreteImplementation(self, _cmd);
}

-(void)forceKill
{
	OBRequestConcreteImplementation(self, _cmd);
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
	NSLog(@"Transport status updated to %ld", (unsigned long)s);
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
#ifdef DEBUG_SOCKETIO_VERBOSE
	//These can be
	NSLog(@"Handling packet %@", [p encode]);
#endif
	switch(p.type){
		case SocketIOPacketTypeConnect:
			[self updateStatus: SocketIOTransportStatusOpen];
			return YES;
		case SocketIOPacketTypeHeartbeat:
			[self sendPacket: [SocketIOPacket packetForHeartbeat]];
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
	@catch( NSException *exception ) {
		NSLog(@"Encountered issue when decoding data %@", exception);
	}
	
	//Do we do anything other than tell our delegate?  Do we even tell our delegate?
	if( !payload ) {
		NSError* error = [self createErrorWithCode: 201 
										andMessage: 
						  [NSString stringWithFormat: 
						   @"Unable to create socket.io packet from data %@", data]];
		[self logAndRaiseError: error];
		return NO;
	}
	

	//We need to make sure we handle things FIFO
	for(SocketIOPacket* packet in payload){
		if( ![self handlePacket: packet] ){
			[self.nr_socket transport: self didRecievePacket: packet];
		}
	}

	return YES;
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
@interface SocketIOXHRPollingTransport()
@property (nonatomic, strong) NSURLSessionDataTask* currentTask;
@end

@implementation SocketIOXHRPollingTransport

+(NSString*)name
{
	return @"xhr-polling";
}

-(id)initWithRootURL:(NSURL *)u andSessionId:(NSString *)s
{
	self = [super initWithRootURL: u andSessionId: s];
	self->sendBuffer = [NSMutableArray arrayWithCapacity: 5];
	return self;
}

-(NSURLRequest*)requestWithMethod: (NSString*)method andData: (NSData*)data
{
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: [self urlForTransport]];
	[request setHTTPMethod: method];
	
	if( data ) {
		[request setValue: @"text/plain;charset=UTF-8" forHTTPHeaderField: @"Content-Type"];
		[request setHTTPBody: data];
	}
	
	return request;
}

-(void)poll
{
	if(self.currentTask || self.status != SocketIOTransportStatusOpen){
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
#ifdef DEBUG_SOCKETIO_VERBOSE
		NSLog(@"Sending payload %@", data);
#endif
	}

	NSURLRequest* request = [self requestWithMethod: method andData: data];
	
	[self performTaskForRequest: request];
}

-(void)performTaskForRequest: (NSURLRequest*)request
{
	SocketIOXHRPollingTransport* weakSelf = self;
	
	//TODO use our own session for this.
	NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest: request
																 completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
																	 weakSelf.currentTask = nil;
																	 if(!data && error){
																		 [weakSelf handleError: error];
																	 }
																	 else{
																		 [weakSelf handleResponse: (id)response withData: data];
																	 }
																 }];
	self.currentTask = task;
	[self.currentTask resume];
}

-(void)handleError: (NSError*)error
{
	[self logAndRaiseError: error];
	[self disconnect];
}

-(void)handleResponse: (NSHTTPURLResponse*)response withData: (NSData*)dataBody
{
	if( [[NSIndexSet indexSetWithIndexesInRange: NSMakeRange(200, 100)] containsIndex: response.statusCode] ){
		//We got a response if it was from connecting we need to start our timer.

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
	else{
		NSError* error = [self createErrorWithCode: response.statusCode
										andMessage: @"The transport recieved an unsuccesful http response"];
		[self handleError: error];
	}

}

-(void)connect
{
	[self updateStatus: SocketIOTransportStatusOpening];
	NSURLRequest* request = [self requestWithMethod: @"POST" andData: nil];
	[self performTaskForRequest: request];
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
	[self updateStatus: SocketIOTransportStatusOpening];
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
	NSLog(@"Websocket status updated to %ld", (unsigned long)wss);
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
	WebSocketData* data = [[WebSocketData alloc] initWithData: 
							[packet encode] isText: YES];
	[self->socket enqueueDataForSending: data];
}



@end
