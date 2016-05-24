//
//  SendRecieveQueue.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/21/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>

@interface SendRecieveQueue : OFObject{
@private
	NSMutableArray* sendQueue;
	NSMutableArray* recieveQueue;
}
-(void)enqueueDataForSending: (id)data;
-(id)dequeueRecievedData;

//For subclasses
-(void)enqueueRecievedData: (id)data;
-(id)dequeueDataForSending;
@end
