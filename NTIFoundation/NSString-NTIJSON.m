//
//  NSString-NTIJSON.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/07/25.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSString-NTIJSON.h"
#import "NTIFoundationOSCompat.h"
#import <objc/objc.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import "NSData-NTIJSON.h"


@implementation NSString(NTIJSON)

-(id)jsonObjectValue
{
	return [[self dataUsingEncoding: NSUTF8StringEncoding] jsonObjectValue];
}

@end


