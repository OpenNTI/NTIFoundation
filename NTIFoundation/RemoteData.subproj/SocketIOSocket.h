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
	SocketIOSocketStatusNew,
	SocketIOSocketStatusConnecting,
	SocketIOSocketStatusConnected,
	SocketIOSocketStatusDisconnecting,
	SocketIOSocketStatusDisconnected
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


@interface SocketIOHandshakeDownloader : NTIBufferedDownloader {
@private
    id nr_delegate;
}
@property (nonatomic, assign) id nr_delegate;
@end

@interface SocketIOSocket : OFObject<SocketIOTransportDelegate>{
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
	SocketIOHandshakeDownloader* handshakeDownloader;
}
@property (nonatomic, assign) id nr_statusDelegate;
@property (nonatomic, assign) id nr_recieverDelegate;
-(id)initWithURL: (NSURL *)url andName: (NSString*)name andPassword: (NSString*)pwd;
-(void)connect;
//Sends the packet via the selected transport or buffers it for transmission
-(void)sendPacket: (SocketIOPacket*)packet;
-(void)disconnect;

@end
