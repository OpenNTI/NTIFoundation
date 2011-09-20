//
//  WebSockets.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>

typedef enum {
	WebSocketStatusNew,
	WebSocketStatusConnecting,
	WebSocketStatusConnected,
	WebSocketStatusDisconnecting,
	WebSocketStatusDisconnected,
	WebSocketStatusError
} WebSocketStatus;

@interface WebSocket7 : OFObject<NSStreamDelegate>{
@private
	NSString* key;
	NSInputStream* socketInputStream;
	NSOutputStream* socketOutputStream;
	NSMutableArray* sendQueue;
	NSMutableArray* recieveQueue;
	BOOL shouldForcePumpOutputStream;
	WebSocketStatus status;
	NSURL* url;
}
@property (nonatomic, readonly) WebSocketStatus status;
-(id)initWithURLString: (NSString*)url;
-(void)connect;
-(void)disconnect;
@end
