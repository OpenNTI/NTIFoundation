//
//  NSDate-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 3/5/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSDate-NTIExtensions.h"

typedef enum : NSUInteger {
	NTITimePeriodUnitSeconds = 0,
	NTITimePeriodUnitMinutes,
	NTITimePeriodUnitHours,
	NTITimePeriodUnitDays,
	NTITimePeriodUnitWeeks,
	NTITimePeriodUnitMonths,
	NTITimePeriodUnitYears
} NTITimePeriodUnit;

struct NTITimePeriod {
	NSUInteger count;
	NTITimePeriodUnit units;
};
typedef struct NTITimePeriod NTITimePeriod;

static NTITimePeriod NTITimePeriodMake(NSUInteger count, NTITimePeriodUnit units)
{
	NTITimePeriod timePeriod;
	timePeriod.count = count;
	timePeriod.units = units;
	return timePeriod;
}

static NSString *stringForTimePeriodUnit(NTITimePeriodUnit timeUnit)
{
	NSString *timeUnitString;
	switch (timeUnit) {
		case NTITimePeriodUnitSeconds:
		timeUnitString = @"second";
		break;
		case NTITimePeriodUnitMinutes:
		timeUnitString = @"minute";
		break;
		case NTITimePeriodUnitHours:
		timeUnitString = @"hour";
		break;
		case NTITimePeriodUnitDays:
		timeUnitString = @"day";
		break;
		case NTITimePeriodUnitWeeks:
		timeUnitString = @"week";
		break;
		case NTITimePeriodUnitMonths:
		timeUnitString = @"month";
		break;
		case NTITimePeriodUnitYears:
		timeUnitString = @"year";
		break;
		default:
		break;
	}
	return timeUnitString;
}

static NSString *pluralStringForTimePeriodUnit(NTITimePeriodUnit timeUnit)
{
	NSString *timeUnitString = stringForTimePeriodUnit(timeUnit);
	timeUnitString = [timeUnitString stringByAppendingString: @"s"];
	return timeUnitString;
}

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

+ (NTITimePeriod)timePeriodSinceInterval: (NSTimeInterval)timeInterval
		withLargestFittingTimePeriodUnit: (NTITimePeriodUnit)largestTimeUnit;
{
	NSUInteger timeSince;
	NTITimePeriodUnit timeUnit;
	
	if (NTITimePeriodUnitYears <= largestTimeUnit
		&& timeInterval >= kNTISecondsInAYear) {
		timeSince = (NSUInteger)round(timeInterval / kNTISecondsInAYear);
		timeUnit = NTITimePeriodUnitYears;
	}
	else if (NTITimePeriodUnitMonths <= largestTimeUnit
			 && timeInterval >= kNTISecondsInAMonth) {
		timeSince = (NSUInteger)round(timeInterval / kNTISecondsInAMonth);
		timeUnit = NTITimePeriodUnitMonths;
	}
	else if (NTITimePeriodUnitWeeks <= largestTimeUnit
			 && timeInterval >= kNTISecondsInAWeek) {
		timeSince = (NSUInteger)round(timeInterval / kNTISecondsInAWeek);
		timeUnit = NTITimePeriodUnitWeeks;
	}
	else if (NTITimePeriodUnitDays <= largestTimeUnit
			 && timeInterval >= kNTISecondsInADay) {
		timeSince = (NSUInteger)round(timeInterval / kNTISecondsInADay);
		timeUnit = NTITimePeriodUnitDays;
	}
	else if (NTITimePeriodUnitHours <= largestTimeUnit
			 && timeInterval >= kNTISecondsInAnHour) {
		timeSince = (NSUInteger)round(timeInterval / kNTISecondsInAnHour);
		timeUnit = NTITimePeriodUnitHours;
	}
	else if (NTITimePeriodUnitMinutes <= largestTimeUnit
			 && timeInterval >= kNTISecondsInAMinute) {
		timeSince = (NSUInteger)round(timeInterval / kNTISecondsInAMinute);
		timeUnit = NTITimePeriodUnitMinutes;
	}
	else {
		timeSince = (NSUInteger)round(timeInterval);
		timeUnit = NTITimePeriodUnitSeconds;
	}
	return NTITimePeriodMake(timeSince, timeUnit);
}

+ (NTITimePeriod)timePeriodSinceInterval: (NSTimeInterval)timeInterval
{
	return [self timePeriodSinceInterval: timeInterval
		withLargestFittingTimePeriodUnit: NTITimePeriodUnitYears];
}

+ (NSString *)stringTemplateForTimeUnit: (NTITimePeriodUnit)timeUnit
						  withUnitCount: (NSUInteger)count
{
	NSString *metaString = pluralStringForTimePeriodUnit(timeUnit);
	NSString *key = [NSString stringWithFormat: @"nsdate-ntiextension.%@.template", metaString];
	NSString *valSubstring = count == 1 ? stringForTimePeriodUnit(timeUnit) : pluralStringForTimePeriodUnit(timeUnit);
	NSString *val = [@"%@ " stringByAppendingString: valSubstring];
	NSString *timeUnitTemplate
	= NSLocalizedStringWithDefaultValue(key,
										@"NextThought",
										[NSBundle mainBundle],
										val,
										@"");
	return timeUnitTemplate;
}

+ (NSString *)stringForTimeUnit: (NTITimePeriodUnit)timeUnit
				  withUnitCount: (NSUInteger)count
{
	NSString *template = [self stringTemplateForTimeUnit: timeUnit
										   withUnitCount: count];
	NSString *string = [NSString stringWithFormat: template, @(count)];
	return string;
}

+ (NSString *)stringFromTimePeriod: (NTITimePeriod)timePeriod
{
	return [self stringForTimeUnit: timePeriod.units
					 withUnitCount: timePeriod.count];
}

+(NSString*)stringFromTimeIntervalWithLargestFittingTimeUnit: (NSTimeInterval)timeInterval
{
	NTITimePeriod timePeriod = [self timePeriodSinceInterval: timeInterval];
	return [self stringFromTimePeriod: timePeriod];
}

+ (NSString *)stringFromTimeIntervalWithLargestFittingTimeUnitWithinDays:(NSTimeInterval)timeInterval
{
	NTITimePeriod timePeriod = [self timePeriodSinceInterval: timeInterval withLargestFittingTimePeriodUnit: NTITimePeriodUnitDays];
	return [self stringFromTimePeriod: timePeriod];
}

static int const timeConstant = 60;

+(NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
	CGFloat seconds = (int)timeInterval % timeConstant;
	NSString *secondsString = [self stringForTimeUnit: NTITimePeriodUnitSeconds
										withUnitCount: (NSUInteger)seconds];
	
	int minutesTotal = (int)(timeInterval / timeConstant);
	int minutes = (int)minutesTotal % timeConstant;
	NSString *minutesString = [self stringForTimeUnit: NTITimePeriodUnitMinutes
										withUnitCount: minutes];
	
	int hours = minutesTotal / timeConstant;
	NSString *hoursString = [self stringForTimeUnit: NTITimePeriodUnitHours
									  withUnitCount: hours];
	
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
		NSString *ago = NSLocalizedStringWithDefaultValue(@"nextthought.nsdate-ntiextension.time-ago",
														  @"NextThought",
														  [NSBundle mainBundle],
														  @"ago",
														  @"Describes how long the most recent activity took place.");
		ago = [@" " stringByAppendingString: ago];
		dateDisplayString = [dateDisplayString stringByAppendingString: ago];
	}
	
	return dateDisplayString;
}

-(BOOL)isOnSameDayAsDate:(NSDate*)date
{
	NSCalendar* calendar = [[NSCalendar alloc]
							initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
	NSDateComponents* selfComponents =
		[calendar components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate: self];
	NSDateComponents* dateComponents =
		[calendar components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate: date];
	
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
