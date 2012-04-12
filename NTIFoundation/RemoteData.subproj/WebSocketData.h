//
//  WebSocketData.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/7/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"

@interface WebSocketData : OFObject {
@private
	NSData* data;
	BOOL dataIsText;
}
-(id)initWithData: (NSData*)data isText: (BOOL)t;
@property (nonatomic, strong) NSData* data;
@property (nonatomic, assign) BOOL dataIsText;

-(NSData*)dataForTransmission;

@end
