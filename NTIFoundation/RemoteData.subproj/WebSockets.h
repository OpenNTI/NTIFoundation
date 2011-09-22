//
//  WebSockets.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "SendRecieveQueue.h"

enum {
	WebSocketStatusNew,
	WebSocketStatusConnecting,
	WebSocketStatusConnected,
	WebSocketStatusDisconnecting,
	WebSocketStatusDisconnected
};
typedef NSInteger WebSocketStatus;

@class WebSocket7;

@protocol WebSocketDelegate <NSObject>
-(void)websocket: (WebSocket7*)socket connectionStatusDidChange: (WebSocketStatus)status;
-(void)websocket: (WebSocket7*)socket didEncounterError: (NSError*)error;
-(void)websocketDidRecieveData: (WebSocket7*)socket;
-(void)websocketIsReadyForData: (WebSocket7*)socket;
@end

@interface WebSocket7 : SendRecieveQueue<NSStreamDelegate>{
@private
	NSString* key;
	NSInputStream* socketInputStream;
	NSOutputStream* socketOutputStream;
	BOOL shouldForcePumpOutputStream;
	WebSocketStatus status;
	NSURL* url;
	id nr_delegate;
}
@property (nonatomic, assign) id nr_delegate;
@property (nonatomic, readonly) WebSocketStatus status;
-(id)initWithURL: (NSURL*)url;
-(void)connect;
-(void)disconnect;
@end
