//
//  NSDate-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 3/5/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSDate-NTIExtensions.h"

@implementation NSDate(NTIExtensions)

static NSString* shortDateStringNL( NSDate* date )
{
	static NSDateFormatter* dateFormatter;
	if( !dateFormatter  ) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat: @"yyyy-MM-dd"];
	}
	return [dateFormatter stringFromDate: date];
}

-(NSString*)stringWithShortDateFormatNL
{
	return shortDateStringNL( self );
}

@end
