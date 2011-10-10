//
//  WebSockets.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "SendRecieveQueue.h"

#define kNTIWebSocket7Origin @"http://ipad.nextthought.com"

enum {
	WebSocketStatusNew = 0,
	WebSocketStatusConnecting = 1,
	WebSocketStatusConnected = 2,
	WebSocketStatusDisconnecting = 3,
	WebSocketStatusDisconnected = 4,
	WebSocketStatusMax = WebSocketStatusDisconnected,
	WebSocketStatusMin = WebSocketStatusNew
};
typedef NSInteger WebSocketStatus;

@interface WebSocketData : OFObject {
@private
	NSData* data;
	BOOL dataIsText;
}
-(id)initWithData: (NSData*)data isText: (BOOL)t;
@property (nonatomic, retain) NSData* data;
@property (nonatomic, assign) BOOL dataIsText;
@end

@class WebSocket7;

@protocol WebSocketDelegate <NSObject>
-(void)websocket: (WebSocket7*)socket connectionStatusDidChange: (WebSocketStatus)status;
-(void)websocket: (WebSocket7*)socket didEncounterError: (NSError*)error;
-(void)websocketDidRecieveData: (WebSocket7*)socket;
-(void)websocketIsReadyForData: (WebSocket7*)socket;
@end

@class HandshakeResponseBuffer;
@class WebSocketResponseBuffer;

//Our implementation of the websocket spec v7
//http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-17
@interface WebSocket7 : SendRecieveQueue<NSStreamDelegate>{
@private
	NSString* key;
	NSInputStream* socketInputStream;
	NSOutputStream* socketOutputStream;
	BOOL shouldForcePumpOutputStream;
	WebSocketStatus status;
	NSURL* url;
	id nr_delegate;
	
	HandshakeResponseBuffer* handshakeResponseBuffer;
	WebSocketResponseBuffer* socketRespsonseBuffer;
}
@property (nonatomic, assign) id nr_delegate;
@property (nonatomic, readonly) WebSocketStatus status;
-(id)initWithURL: (NSURL*)url;
-(void)connect;
-(void)disconnect;
-(void)kill;
@end
