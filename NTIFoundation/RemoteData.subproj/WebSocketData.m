//
//  WebSocketData.m
//  NTIFoundation
//
//  Created by Christopher Utz on 2/7/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "WebSocketData.h"

@implementation WebSocketData
@synthesize data, dataIsText;

-(id)initWithData:(NSData *)d isText:(BOOL)t
{
	self = [super init];
	self->data = d;
	self->dataIsText = t;
	return self;
}


@end
