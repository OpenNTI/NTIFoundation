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

@class WebSocket7;

@protocol WebSocketDelegate <NSObject>
-(void)websocket: (WebSocket7*)socket connectionStatusDidChange: (WebSocketStatus)status;
-(void)websocket: (WebSocket7*)socket didEncounterError: (NSError*)error;
-(void)websocketDidRecieveData: (WebSocket7*)socket;
-(void)websocketIsReadyForData: (WebSocket7*)socket;
@end

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
	id nr_delegate;
}
@property (nonatomic, retain) id nr_delegate;
@property (nonatomic, readonly) WebSocketStatus status;
-(id)initWithURLString: (NSString*)url;
-(void)connect;
-(void)enqueueData: (id)data; //It really does make sense that this just be data
-(id)dequeueData;
-(void)disconnect;
@end
