//
//  NSDate-NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/27/15.
//  Copyright (c) 2015 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <NTIFoundation/NSDate-NTIExtensions.h>

@interface NSDate_NTIExtensionsTest : XCTestCase

@property (nonatomic, strong) NSDictionary *timeIntervalStringMapping;

@end

@implementation NSDate_NTIExtensionsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	NSTimeInterval rDown = 1.4;
	NSTimeInterval rUp = 1.5;
	self.timeIntervalStringMapping
	= @{@(1): @"1 second",
		@(rDown): @"1 second",
		@(rUp): @"2 seconds",
		@(kNTISecondsInAMinute): @"1 minute",
		@(kNTISecondsInAMinute * rDown): @"1 minute",
		@(kNTISecondsInAMinute * rUp): @"2 minutes",
		@(kNTISecondsInAnHour): @"1 hour",
		@(kNTISecondsInAnHour * rDown): @"1 hour",
		@(kNTISecondsInAnHour * rUp): @"2 hours",
		@(kNTISecondsInADay): @"1 day",
		@(kNTISecondsInADay * rDown): @"1 day",
		@(kNTISecondsInADay * rUp): @"2 days",
		@(kNTISecondsInAWeek): @"1 week",
		@(kNTISecondsInAWeek * rDown): @"1 week",
		@(kNTISecondsInAWeek * rUp): @"2 weeks",
		@(kNTISecondsInAMonth): @"1 month",
		@(kNTISecondsInAMonth * rDown): @"1 month",
		@(kNTISecondsInAMonth * rUp): @"2 months",
		@(kNTISecondsInAYear): @"1 year",
		@(kNTISecondsInAYear * rDown): @"1 year",
		@(kNTISecondsInAYear * rUp): @"2 years"};
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLargestFittingTimeUnitRounding
{
	[self.timeIntervalStringMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSTimeInterval interval = [(NSNumber *)key doubleValue];
		NSString *expected = (NSString *)obj;
		NSString *actual = [NSDate stringFromTimeIntervalWithLargestFittingTimeUnit: interval];
		XCTAssertTrue([expected isEqualToString: actual], @"Time interval %@ is not converted to largest-fitting-time-unit string form correctly; expected \"%@\" but found \"%@\"", key, expected, actual);
	}];
}

@end
