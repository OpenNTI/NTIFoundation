//
//  SendRecieveQueueTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "SendRecieveQueueTest.h"

@implementation SendRecieveQueueTest

-(void)setUp
{
    [super setUp];
	self->queue = [[SendRecieveQueue alloc] init];
}

-(void)testDequeueNothing
{
	STAssertNil([self->queue dequeueDataForSending], nil);
	STAssertNil([self->queue dequeueRecievedData], nil);
}

-(void)testEnqueueDequeueForSending
{
	NSNumber* toSend = [NSNumber numberWithInt: 0];
	NSNumber* toSend2 = [NSNumber numberWithInt: 1];
	
	[self->queue enqueueDataForSending: toSend];
	[self->queue enqueueDataForSending: toSend2];
	
	STAssertEquals( [[self->queue dequeueDataForSending] intValue], 0, nil);
	STAssertEquals( [[self->queue dequeueDataForSending] intValue], 1, nil);
	STAssertNil([self->queue dequeueDataForSending], nil);
}

-(void)testRecieveEnqueueAndDequeue
{
	NSNumber* toSend = [NSNumber numberWithInt: 0];
	NSNumber* toSend2 = [NSNumber numberWithInt: 1];
	
	[self->queue enqueueRecievedData: toSend];
	[self->queue enqueueRecievedData: toSend2];
	
	STAssertEquals( [[self->queue dequeueRecievedData] intValue], 0, nil);
	STAssertEquals( [[self->queue dequeueRecievedData] intValue], 1, nil);
	STAssertNil([self->queue dequeueRecievedData], nil);
}

@end
