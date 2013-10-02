//
//  NSDate-NTIExtensions.h
//  NTIFoundation
//
//  Created by Christopher Utz on 3/5/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

@interface NSDate(NTIExtensions)

#define kNTISecondsInAYear		31540000
#define kNTISecondsInAMonth		2628000
#define kNTISecondsInAWeek		604800
#define kNTISecondsInADay		86400
#define kNTISecondsInAnHour		3600
#define kNTISecondsInAMinute	60

@property (nonatomic, readonly) NSString* stringWithShortDateFormatNL;

+(NSString*) stringFromTimeIntervalWithLargestFittingTimeUnit: (NSUInteger)timeInterval;

/**
 * Returns a string of the form "<n> <timeunit>(s)", where:<br>
 *  - <timeunit> is the largest unit of time, up to days, which fits inside |timeInterval|<br>
 *  - <n> is the number of <timeunit>s which fit inside |timeInterval|<br>
 * E.g., "1 second", "8 seconds", "3 hours", "5 days", "17 days", "64 days", "562 days", etc.
 */
+ (NSString *)stringFromTimeIntervalWithLargestFittingTimeUnitWithinDays:(NSUInteger)timeInterval;

@end
