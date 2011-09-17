//
//  NSNumber-NTIJSON.m
//  NextThoughtApp
//
//  Created by Christopher Utz on 9/12/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSNumber-NTIJSON.h"
#import "NTIJSON.h"
#import "NTIOSCompat.h"

@implementation NSNumber (NTIJSON)
-(NSString*)stringWithJsonRepresentation
{
	//use ios5 if possible.
	NTI_RETURN_SELF_TO_JSON();
	
	return [self stringValue];
}
@end
