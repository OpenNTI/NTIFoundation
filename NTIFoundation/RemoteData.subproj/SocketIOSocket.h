//
//  SocketIOSocket.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "SocketIOPacket.h"

extern NSString* const SocketIOResource;
extern NSString* const SocketIOProtocol;
extern NSArray* const SocketIOTransports;

typedef enum {
	SocketIOSocketStatusConnecting,
	SocketIOSocketStatusConnected,
	SocketIOSocketStatusDisconnecting,
	SocketIOSocketStatusDisconnected
} SocketIOSocketStatus;

@class SocketIOSocket;
@protocol SocketIOSocketDelegate <NSObject>
-(void)socket: (SocketIOSocket*)socket connectionStatusDidChange: (SocketIOSocketStatus)status;
-(void)socket: (SocketIOSocket*)socket didEncounterError: (NSError*)error;
-(void)socketDidRecieveData: (SocketIOSocket*)socket;
-(void)socketIsReadyForData: (SocketIOSocket*)socket;
@end

@interface SocketIOSocket : OFObject{
@private
	NSURL* url;
	NSString* username;
	NSString* password;
	NSString* sessionId;
	NSInteger heartbeatTimeout;
	NSInteger closeTimeout;
	BOOL shouldBuffer;
	NSMutableArray* buffer;
	NSMutableDictionary* namespaces;
	SocketIOSocketStatus status;
	NSArray* serverSupportedTransports;
}
@property (nonatomic, readonly) NSString* sessionId;
@property (nonatomic, readonly) NSInteger heartbeatTimeout;
@property (nonatomic, readonly) NSInteger closeTimeout;
@property (nonatomic, assign) BOOL shouldBuffer;
-(id)initWithURLString:(NSString *)uStr andName: (NSString*)name andPassword: (NSString*)pwd;
-(void)connect;
//Sends the packet via the selected transport or buffers it for transmission
-(void)sendPacket: (SocketIOPacket*)packet;
-(void)disconnect;

@end
