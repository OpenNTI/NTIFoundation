//
//  NSDate-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 3/5/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSDate-NTIExtensions.h"

#define kNTISecondsInAYear		31540000
#define kNTISecondsInAMonth		2628000
#define kNTISecondsInAWeek		604800
#define kNTISecondsInADay		86400
#define kNTISecondsInAnHour		3600
#define kNTISecondsInAMinute	60

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

+(NSString*)stringFromTimeIntervalWithLargestFittingTimeUnit:(NSUInteger)timeInterval
{
	NSString* timeUnitString;
	NSUInteger timeSince = timeInterval;
	if(timeInterval >= kNTISecondsInAYear){
		timeSince /= kNTISecondsInAYear;
		timeUnitString = @"year";
	}
	else if(timeInterval >= kNTISecondsInAMonth){
		timeSince /= kNTISecondsInAMonth;
		timeUnitString = @"month";
	}
	else if(timeInterval >= kNTISecondsInAWeek){
		timeSince /= kNTISecondsInAWeek;
		timeUnitString = @"week";
	}
	else if(timeInterval >= kNTISecondsInADay){
		timeSince /= kNTISecondsInADay;
		timeUnitString = @"day";
	}
	else if(timeInterval >= kNTISecondsInAnHour){
		timeSince /= kNTISecondsInAnHour;
		timeUnitString = @"hour";
	}
	else if(timeInterval >= kNTISecondsInAMinute){
		timeSince /= kNTISecondsInAMinute;
		timeUnitString = @"minute";
	}
	else{
		timeUnitString = @"second";
	}
	
	if(timeSince > 1){
		timeUnitString = [timeUnitString stringByAppendingString: @"s"];
	}
	
	return [NSString stringWithFormat: @"%lu %@", timeSince, timeUnitString];
}

@end
