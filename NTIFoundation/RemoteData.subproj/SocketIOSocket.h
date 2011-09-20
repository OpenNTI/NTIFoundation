//
//  SocketIOSocket.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "SocketIOPacket.h"

typedef enum {
	SocketIOSocketStatusConnecting,
	SocketIOSocketStatusConnected,
	SocketIOSocketStatusDisconnecting,
	SocketIOSocketStatusDisconnected
} SocketIOSocketStatus;

@interface SocketIOSocket : OFObject{
@private
	NSString* sessionId;
	NSInteger heartbeatTimeout;
	NSInteger closeTimeout;
}
@property (nonatomic, readonly) NSString* sessionId;
@property (nonatomic, readonly) NSInteger heartbeatTimeout;
@property (nonatomic, readonly) NSInteger closeTimeout;

+(SocketIOSocket*)connect;
-(void)sendPacket: (SocketIOPacket*)packet;
-(void)disconnect;

@end
