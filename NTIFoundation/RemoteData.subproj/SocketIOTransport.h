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

typedef enum {
	SocketIOTransportStatusNew,
	SocketIOTransportStatusConnecting,
	SocketIOTransportStatusConnected,
	SocketIOTransportStatusDisconnecting,
	SocketIOTransportStatusDisconnected
} SocketIOTransportStatus;

@class SocketIOTransport;

@protocol SocketIOTransportDelegate <NSObject>
-(void)transport: (SocketIOTransport*)socket connectionStatusDidChange: (SocketIOTransportStatus)status;
-(void)transport: (SocketIOTransport*)socket didEncounterError: (NSError*)error;
-(void)transportDidRecieveData: (SocketIOTransport*)transport;
-(void)transportIsReadyForData: (SocketIOTransport*)transport;
@end

@interface SocketIOTransport : SendRecieveQueue {
}
@end

@interface SocketIOWSTransport : SocketIOTransport<WebSocketDelegate>{
	@private
	SocketIOTransportStatus status;
	WebSocket7* socket;
	id nr_delegate;
	BOOL shouldForcePumpOutputStream;
}
@property (nonatomic, assign) id nr_delegate;
@property (nonatomic, readonly) NSString* name;

@end
