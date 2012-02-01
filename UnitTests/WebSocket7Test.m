//
//  WebSocket7Test.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/20/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "WebSocket7Test.h"
#import "WebSockets.h"

@implementation WebSocket7Test

BOOL isSuccessfulHandshakeResponse(NSString* response, NSString* key);

-(void)testHandshakeParsing
{
	NSString* goodKey = @"w5jCl3LDpwc/Gj4EOgk7UsOXEMKa";
	NSString* handshake = @"HTTP/1.1 101 Switching Protocols\nUpgrade: WebSocket\nConnection: Upgrade\nSec-WebSocket-Accept: hrIyuqmFm4k655eTa9Ibgw8Kvss=\nAccess-Control-Allow-Origin: http://ipad.nextthought.com\nAccess-Control-Allow-Credentials: true";
	
	STAssertTrue(isSuccessfulHandshakeResponse(handshake, goodKey), nil);
	
	NSString* badKey = @"foobar";
	
	STAssertFalse(isSuccessfulHandshakeResponse(handshake, badKey), nil);
}

@end
