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

+(NSDate*)now;

/**
 * Returns a string of the form "<n> <timeunit>(s)", where:<br>
 *  - <timeunit> is the largest unit of time which fits inside |timeInterval|<br>
 *  - <n> is the number of <timeunit>s which fit inside |timeInterval|<br>, rounded to the nearest unit
 * E.g., "1 second", "8 seconds", "10 minutes", "3 hours", "5 days", "2 weeks", "3 months", "5 years", etc.
 */
+ (NSString *)stringFromTimeIntervalWithLargestFittingTimeUnit: (NSTimeInterval)timeInterval;

/**
 * Returns a string of the form "<n> <timeunit>(s)", where:<br>
 *  - <timeunit> is the largest unit of time, up to days, which fits inside |timeInterval|<br>
 *  - <n> is the number of <timeunit>s which fit inside |timeInterval|<br>, rounded to the nearest unit
 * E.g., "1 second", "8 seconds", "10 minutes", "3 hours", "5 days", "17 days", "64 days", "562 days", etc.
 */
+ (NSString *)stringFromTimeIntervalWithLargestFittingTimeUnitWithinDays:(NSTimeInterval)timeInterval;

+ (NSString*)stringFromTimeInterval: (NSTimeInterval)timeInterval;

/**
 * Same as stringFromTimeIntervalWithLargestFittingTimeUnitWithinDays but if it is more than cutoff seconds
 * just displays the full date.
 */
- (NSString *)stringFromTimeIntervalWithLargestFittingTimeUnitWithinDaysUsingCutoff: (NSTimeInterval)cutoff;

/**
 *  Returns a boolean value that details if the given date is on the same day as the reciever
 *
 *  @param date the date that will be compared to the reciever
 *
 *  @return YES if date is on the same day as the reciever
 */
- (BOOL)isOnSameDayAsDate:(NSDate*)date;

/**
 *  compares the reciever instance to the given time interval
 *
 *  @param timeInterval time interval to be compared to
 *
 *  @return The receiver and anotherDate are exactly equal to each other, NSOrderedSame
			The receiver is later in time than anotherDate, NSOrderedDescending
			The receiver is earlier in time than anotherDate, NSOrderedAscending.
 */
- (NSComparisonResult)compareToTimeInterval: (NSTimeInterval)timeInterval;

@end
