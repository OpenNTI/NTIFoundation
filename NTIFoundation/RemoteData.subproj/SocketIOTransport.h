//
//  SocketIOTransport.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>

typedef enum {
	SocketIOSocketStatusOpening,
	SocketIOSocketStatusOpen,
	SocketIOSocketStatusClosing,
	SocketIOSocketStatusClosed
} SocketIOSocketStatus;

@interface SocketIOTransport : OFObject

@end
