//
//  SocketIOTransport.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "WebSockets.h"
#import "SocketIOPacket.h"

enum {
	SocketIOTransportStatusNew,
	SocketIOTransportStatusConnecting,
	SocketIOTransportStatusConnected,
	SocketIOTransportStatusDisconnecting,
	SocketIOTransportStatusDisconnected
}; 
typedef NSInteger SocketIOTransportStatus;

@class SocketIOTransport;

@protocol SocketIOTransportDelegate <NSObject>
-(void)transport: (SocketIOTransport*)socket connectionStatusDidChange: (SocketIOTransportStatus)status;
-(void)transport: (SocketIOTransport*)socket didEncounterError: (NSError*)error;
-(void)transportDidRecieveData: (SocketIOTransport*)transport;
-(void)transportIsReadyForData: (SocketIOTransport*)transport;
@end

@interface SocketIOTransport : SendRecieveQueue {
	@private
	NSString* sessionId;
	NSURL* rootURL;
	SocketIOTransportStatus status;
	id nr_delegate;
}
@property (nonatomic, assign) id nr_delegate;
+(NSString*)name;
-(id)initWithRootURL: (NSURL*)url andSessionId: (NSString*)sessionId;
-(void)connect;
-(void)disconnect;
-(NSURL*)urlForTransport;

@end

@interface SocketIOWSTransport : SocketIOTransport<WebSocketDelegate>{
	@private
	BOOL shouldForcePumpOutputStream;
	WebSocket7* socket;
}
@end
