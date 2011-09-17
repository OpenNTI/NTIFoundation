//
//  NSString-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/21.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSString-NTIExtensions.h"

@implementation NSString (NTIConversions)

-(BOOL)javascriptBoolValue
{
	return [@"true" isEqualToString: self];	
}

-(NSInteger)longValue 
{
	return [self integerValue]; 
}
@end

static NSDateFormatter* rfc3339DateFormatter()
{
	static NSDateFormatter* rfc3339DateFormatter = nil;
	if( !rfc3339DateFormatter ) {
		rfc3339DateFormatter = [[NSDateFormatter alloc] init];
		NSLocale* enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
	
		[rfc3339DateFormatter setLocale: enUSPOSIXLocale];
		[rfc3339DateFormatter setDateFormat: @"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
		[rfc3339DateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
	}
	return rfc3339DateFormatter;
}

@implementation NSString (NTIHTTPHeaderConversions)

-(NSDate*)httpHeaderDateValue
{
    NSDate* date = [rfc3339DateFormatter() dateFromString: self];
	return date;
}

@end

@implementation NSDate(NTIHTTPHeaderConversions)
-(NSString*)httpHeaderStringValue
{
	return [rfc3339DateFormatter() stringFromDate: self];	
}
@end


