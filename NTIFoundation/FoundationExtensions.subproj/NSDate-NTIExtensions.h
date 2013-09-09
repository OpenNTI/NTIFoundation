//
//  NSDate-NTIExtensions.h
//  NTIFoundation
//
//  Created by Christopher Utz on 3/5/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

@interface NSDate(NTIExtensions)

@property (nonatomic, readonly) NSString* stringWithShortDateFormatNL;
+(NSString*) stringFromTimeIntervalWithLargestFittingTimeUnit: (NSUInteger)timeInterval;

@end
