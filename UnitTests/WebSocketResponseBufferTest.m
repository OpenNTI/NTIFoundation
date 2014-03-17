//
//  WebSocketResponseBufferTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 4/9/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "WebSocketResponseBufferTest.h"

@implementation WebSocketResponseBufferTest

NSUInteger bytesToLength(uint8_t* bytes, uint8_t num);

-(void)testBytesToLengthSmall
{
	uint8_t bytes = 87;
	
	NSUInteger smallSize = bytesToLength(&bytes, 1);
	
	XCTAssertEqual((int)smallSize, 87, @"Excpeted a length of 87");
}

-(void)testBytesToLengthMedium
{
	uint8_t bytes[2] = {1, 56};
	
	NSUInteger mediumSize = bytesToLength(bytes, 2);

	XCTAssertEqual((int)mediumSize, 312, @"Excpeted a length of 312");
}

-(void)testBytesToLengthLong
{
	uint8_t bytes[8] = {0, 0, 0, 0, 0, 150, 180, 63};
	
	NSUInteger longSize = bytesToLength(bytes, 8);
	
	XCTAssertEqual((int)longSize, 9876543, @"Excpeted a length of 9876543");
}


@end
