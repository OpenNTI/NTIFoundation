//
//  NSObject-NTIJSONTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 2/1/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSObject-NTIJSONTest.h"
#import "NSObject-NTIJSON.h"

@implementation NSObject_NTIJSONTest

-(void)testJsonObjectUnwrap
{
	STAssertNil([[NSNull null] jsonObjectUnwrap], nil);
	STAssertNil(nil, nil);
	STAssertNotNil([NSNumber numberWithInt: 10], nil);
}

@end
