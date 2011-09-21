//
//  SendRecieveQueue.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/21/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SendRecieveQueue.h"

@implementation SendRecieveQueue

- (id)init
{
    self = [super init];
    if (self) {
		//Fixme we probably need to bound these.
		self->sendQueue = [[NSMutableArray arrayWithCapacity: 5] retain];
		self->recieveQueue = [[NSMutableArray arrayWithCapacity: 5] retain];
    }
    
    return self;
}

-(id)dequeueDataFromQueue: (NSMutableArray*)queue
{
	if([queue count] > 0){
		id data = [queue firstObject];
		[queue removeObjectAtIndex: 0];
		NSLog(@"Dequeued %@ from %@", data, queue == self->sendQueue ? @"sendQueue" : @"revcQueue");
		return data;
	}
	NSLog(@"No data to dequeue");
	return nil;
}

-(void)enqueueData: (id)data onQueue: (NSMutableArray*)queue
{
	NSLog(@"Adding %@ to queue %@", data, queue == self->sendQueue ? @"sendQueue" : @"revcQueue");
	[queue addObject: data];
}

-(void)enqueueDataForSending: (id)data
{
	[self enqueueData: data onQueue: self->sendQueue];
}

-(id)dequeueRecievedData
{
	return [self dequeueDataFromQueue: self->recieveQueue];
}

-(void)enqueueRecievedData: (id)data
{
	[self enqueueData: data onQueue: self->recieveQueue];
}

-(id)dequeueDataForSending
{
	return [self dequeueDataFromQueue: self->sendQueue];
}

-(void)dealloc
{
	NTI_RELEASE(self->sendQueue);
	NTI_RELEASE(self->recieveQueue);
}

@end
