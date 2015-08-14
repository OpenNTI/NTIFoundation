//
//  NSNotification-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/18/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import "NSNotification-NTIExtensions.h"

@implementation NSNotification(NTIExtensions)

+(void)ntiPostNetworkActivityBegan: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"NTINotificationNetworkActivityBeganName"
														object: sender];
}

+(void)ntiPostNetworkActivityEnded: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"NTINotificationNetworkActivityEndedName"
														object: sender];
}

@end
