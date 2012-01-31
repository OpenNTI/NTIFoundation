//
//  NSString-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSString-NTIExtensionsTest.h"

@implementation NSString_NTIExtensionsTest

-(void)testJavascriptBoolValue
{
	STAssertFalse([@"false" javascriptBoolValue], nil);
	STAssertTrue([@"true" javascriptBoolValue], nil);
	STAssertFalse([@"None" javascriptBoolValue], nil);
}

-(void)testLongValue
{
	STAssertEquals([@"123456" longValue], (long)123456, nil);
}

@end
