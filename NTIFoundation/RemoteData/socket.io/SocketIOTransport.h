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
#import "NTIAbstractDownloader.h"


enum {
	SocketIOTransportStatusNew = 0,
	SocketIOTransportStatusOpening = 1,
	SocketIOTransportStatusOpen = 2,
	SocketIOTransportStatusClosing = 3,
	SocketIOTransportStatusClosed = 4,
	SocketIOTransportStatusMax = SocketIOTransportStatusClosed,
	SocketIOTransportStatusMin = SocketIOTransportStatusNew
}; 
typedef NSInteger SocketIOTransportStatus;

@class SocketIOSocket;

@interface SocketIOTransport : OFObject {
	@private
	NSString* sessionId;
	NSURL* rootURL;
	SocketIOTransportStatus status;
	SocketIOSocket* __weak nr_socket;
}
@property (nonatomic, weak) SocketIOSocket* nr_socket;
@property (nonatomic, assign) SocketIOTransportStatus status;
+(NSString*)name;
-(id)initWithRootURL: (NSURL*)url andSessionId: (NSString*)sessionId;
-(void)sendPayload: (NSArray*)payload;
-(void)sendPacket: (SocketIOPacket*)packet;
-(void)connect;
-(void)disconnect;
-(void)forceKill;
-(NSURL*)urlForTransport;

@end

@interface SocketIOWSTransport : SocketIOTransport{
	@private
	WebSocket7* socket;
}
@end

@interface SocketIOXHRPollingTransport : SocketIOTransport{
@private
	NSMutableArray* sendBuffer;
}
@end
