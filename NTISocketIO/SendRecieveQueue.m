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
		self->sendQueue = [NSMutableArray arrayWithCapacity: 5];
		self->recieveQueue = [NSMutableArray arrayWithCapacity: 5];
    }
    
    return self;
}

-(id)dequeueDataFromQueue: (NSMutableArray*)queue
{
	NSUInteger count = [queue count];
	//NSString* queueName = self->sendQueue ? @"sendQueue" : @"revcQueue";
	if(count > 0){
		id data = [queue firstObject];
		[queue removeObjectAtIndex: 0];
		//NSLog(@"%@ dequeued %@ from %@", self, data, queueName);
		return data;
	}
	//NSLog(@"No data to dequeue");
	return nil;
}

-(void)enqueueData: (id)data onQueue: (NSMutableArray*)queue
{
	[queue addObject: data];
	//NSString* queueName = self->sendQueue ? @"sendQueue" : @"revcQueue";
	//NSLog(@"%@ Enqueued %@ on %@", self, data, queueName);
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


@end
