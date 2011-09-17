//
//  NTIOSCompat.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/22.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIFoundationOSCompat.h"

#if __IPHONE_5_0 < __IPHONE_OS_VERSION_MAX_ALLOWED

#endif

id getClass_NSJSONSerialization(void)
{
	static BOOL checked = NO;
	static id jsonClass = nil;
	if( !checked ) {
		jsonClass = objc_getClass( "NSJSONSerialization");
		checked = YES;
	}
	return jsonClass;
}
