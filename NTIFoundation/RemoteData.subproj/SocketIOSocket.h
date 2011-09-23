//
//  SocketIOSocket.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "SocketIOPacket.h"
#import "SocketIOTransport.h"
#import "NTIAbstractDownloader.h"

extern NSString* const SocketIOResource;
extern NSString* const SocketIOProtocol;

enum {
	SocketIOSocketStatusNew = 0,
	SocketIOSocketStatusConnecting = 1,
	SocketIOSocketStatusConnected = 2,
	SocketIOSocketStatusDisconnecting = 3,
	SocketIOSocketStatusDisconnected = 4,
	SocketIOSocketStatusMax = SocketIOSocketStatusDisconnected,
	SocketIOSocketStatusMin = SocketIOSocketStatusNew
};
typedef NSInteger SocketIOSocketStatus;

@class SocketIOSocket;
@protocol SocketIOSocketStatusDelegate <NSObject>
-(void)socket: (SocketIOSocket*)socket connectionStatusDidChange: (SocketIOSocketStatus)status;
-(void)socket: (SocketIOSocket*)socket didEncounterError: (NSError*)error;
@end

@protocol SocketIOSocketRecieverDelegate <NSObject>
-(void)socket: (SocketIOSocket*)socket didRecieveMessage: (NSString*)message;
-(void)socket:(SocketIOSocket *)socket didRecieveEventNamed: (NSString *)name withArgs: (NSArray*)args;
@end

@interface SocketIOSocket : OFObject{
@private
	NSURL* url;
	NSString* username;
	NSString* password;
	NSString* sessionId;
	NSInteger heartbeatTimeout;
	NSArray* serverSupportedTransports;
	NSInteger closeTimeout;
	SocketIOSocketStatus status;
	SocketIOWSTransport* transport;
	id nr_statusDelegate;
	id nr_recieverDelegate;
	NTIDelegatingDownloader* handshakeDownloader;
	BOOL shouldBuffer;
	NSMutableArray* buffer;
	BOOL reconnecting;
	NSTimer* closeTimeoutTimer;
	NSUInteger reconnectAttempts;
	NSMutableArray* attemptedTransports;
	BOOL forceDisconnect;
}
@property (nonatomic, readonly) NSInteger heartbeatTimeout;
@property (nonatomic, assign) BOOL shouldBuffer;
@property (nonatomic, assign) id nr_statusDelegate;
@property (nonatomic, assign) id nr_recieverDelegate;
-(id)initWithURL: (NSURL *)url andName: (NSString*)name andPassword: (NSString*)pwd;
-(void)connect;
//Sends the packet via the selected transport or buffers it for transmission
-(void)sendPacket: (SocketIOPacket*)packet;
-(void)disconnect;
//Bascially delegat emethods but the socket is the only delegate the transport will need.
-(void)transport: (SocketIOTransport*)t connectionStatusDidChange: (SocketIOTransportStatus)status;
-(void)transport: (SocketIOTransport*)t didEncounterError: (NSError*)error;
-(void)transport: (SocketIOTransport*)t didRecievePayload: (NSArray*)payload;
@end
