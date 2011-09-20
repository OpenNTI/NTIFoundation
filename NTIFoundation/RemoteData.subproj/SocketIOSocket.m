//
//  SocketIOSocket.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOSocket.h"


@implementation SocketIOSocket
@synthesize sessionId, heartbeatTimeout, closeTimeout;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+(SocketIOSocket*)connect
{
	return nil;
}

-(void)disconnect
{
	
}

-(void)sendPacket:(SocketIOPacket *)packet
{
	
}

-(void)dealloc
{
	NTI_RELEASE(self->sessionId);
	[super dealloc];
}

@end
