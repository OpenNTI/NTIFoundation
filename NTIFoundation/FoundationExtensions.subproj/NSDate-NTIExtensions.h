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

@end
