//
//  NSDate-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 3/5/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSDate-NTIExtensions.h"

@implementation NSDate(NTIExtensions)

+(NSDate*)now
{
	return [NSDate new];
}

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

+(NSString*)stringFromTimeIntervalWithLargestFittingTimeUnit: (NSUInteger)timeInterval
{
	//TODO: any string presnted to the user must be externalized.
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
	else {
		return [NSDate stringFromTimeIntervalWithLargestFittingTimeUnitWithinDays:timeInterval];
	}
	
	if(timeSince > 1){
		timeUnitString = [timeUnitString stringByAppendingString: @"s"];
	}
	
	return [NSString stringWithFormat: @"%lu %@", (unsigned long)timeSince, timeUnitString];
}

+ (NSString *)stringFromTimeIntervalWithLargestFittingTimeUnitWithinDays:(NSUInteger)timeInterval
{
    NSString *timeUnitString;
	NSUInteger timeSince = timeInterval;
    
    if (timeInterval >= kNTISecondsInADay) {
		timeSince /= kNTISecondsInADay;
		timeUnitString = @"day";
	}
	else if (timeInterval >= kNTISecondsInAnHour) {
		timeSince /= kNTISecondsInAnHour;
		timeUnitString = @"hour";
	}
	else if (timeInterval >= kNTISecondsInAMinute) {
		timeSince /= kNTISecondsInAMinute;
		timeUnitString = @"minute";
	}
	else {
		timeUnitString = @"second";
	}
	
	if (timeSince > 1) {
		timeUnitString = [timeUnitString stringByAppendingString:@"s"];
	}
	
	return [NSString stringWithFormat:@"%lu %@", (unsigned long)timeSince, timeUnitString];
}

static int const timeConstant = 60;

+(NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
	CGFloat seconds = (int)timeInterval % timeConstant;
	NSString* secondsTemplate
	= NSLocalizedStringWithDefaultValue(@"nsdate-ntiextension.seconds.template",
										@"NextThought",
										[NSBundle mainBundle],
										(seconds == 1 ? @"%@ second" : @"%@ seconds"),
										@"string representing seconds");
	NSString* secondsString = [NSString stringWithFormat: secondsTemplate, @(seconds)];
	
	int minutesTotal = (int)(timeInterval / timeConstant);
	int minutes = (int)minutesTotal % timeConstant;
	NSString* minutesTemplate
	= NSLocalizedStringWithDefaultValue(@"nsdate-ntiextension.minutes.template",
										@"NextThought",
										[NSBundle mainBundle],
										(minutes == 1 ? @"%@ minute" : @"%@ minutes"),
										@"string representing minutes");
	NSString* minutesString = [NSString stringWithFormat: minutesTemplate, @(minutes)];
	
	int hours = minutesTotal / timeConstant;
	NSString* hoursTemplate
	= NSLocalizedStringWithDefaultValue(@"nsdate-ntiextension.hours.template",
										@"NextThought",
										[NSBundle mainBundle],
										(hours == 1 ? @"%@ hour" : @"%@ hours"),
										@"string representing hours");
	NSString* hoursString = [NSString stringWithFormat: hoursTemplate, @(hours)];
	
	NSString* timeString = @"";
	if(timeInterval < timeConstant){
		timeString = [secondsString stringByAppendingString: timeString];
	}
	else{
		if(minutes > 0 || hours > 0){
			if(![NSString isEmptyString: timeString]){
				minutesString = [minutesString stringByAppendingString: @" "];
			}
			timeString = [minutesString stringByAppendingString: timeString];
		}
		if(hours > 0){
			if(![NSString isEmptyString: timeString]){
				hoursString = [hoursString stringByAppendingString: @" "];
			}
			timeString = [hoursString stringByAppendingString: timeString];
		}
	}
	
	return [timeString stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringFromTimeIntervalWithLargestFittingTimeUnitWithinDaysUsingCutoff: (NSTimeInterval)cutoff;
{
	static NSDateFormatter* dateFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle: NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle: NSDateFormatterShortStyle];
	});
	
	NSString* dateDisplayString = nil;
	NSTimeInterval cutoffPoint = [[NSDate date] timeIntervalSince1970] - cutoff;
	if( [self timeIntervalSince1970] < cutoffPoint ) {
		//if we are older than the cutoff show the full date
		dateDisplayString = [dateFormatter stringFromDate: self];
	}
	else {
		dateDisplayString = [NSDate stringFromTimeIntervalWithLargestFittingTimeUnitWithinDays:
							 [[NSDate date] timeIntervalSince1970] - [self timeIntervalSince1970]];
		//TODO: externalize
		dateDisplayString = [dateDisplayString stringByAppendingString: @" ago"];
	}
	
	return dateDisplayString;
}

-(BOOL)isOnSameDayAsDate:(NSDate*)date
{
	NSCalendar* calendar = [[NSCalendar alloc]
							initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents* selfComponents =
		[calendar components: (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: self];
	NSDateComponents* dateComponents =
		[calendar components: (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: date];
	
	BOOL sameDay = selfComponents.day == dateComponents.day;
	BOOL sameMonth = selfComponents.month == dateComponents.month;
	BOOL sameYear = selfComponents.year == dateComponents.year;
	
	return sameDay && sameMonth && sameYear;
}

-(NSComparisonResult)compareToTimeInterval: (NSTimeInterval)timeInterval
{
	NSDate* date = [NSDate dateWithTimeIntervalSince1970: timeInterval];
	return [self compare: date];
}

@end
