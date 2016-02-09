//
//  NTIISO8601DurationFormatterTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 11/12/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NTIISO8601DurationFormatter.h"
#import "NTIDuration.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@interface NTIISO8601DurationFormatterTest : XCTestCase{
	@private
	NTIISO8601DurationFormatter* formatter;
}
@property (nonatomic, strong) NSString* durationString;
@property (nonatomic, strong) NSArray* cmps;

@end

@interface NTIDuration(PRIVATE_TESTING)
@property (nonatomic, readonly) NSArray* components;
@end

@implementation NTIDuration(PRIVATE_TESTING)
@dynamic components;

//For testing
-(NSArray*)components
{
#define _o(x) [NSNumber numberWithDouble:x]
	return @[_o(self.years), _o(self.monthes), _o(self.weeks),
			 _o(self.days), _o(self.hours),
			 _o(self.minutes), _o(self.seconds)];

}


@end

@implementation NTIISO8601DurationFormatterTest

#define _dv(values) [[NTIDuration alloc] initWithValues: values].components

+(NSDictionary*)formatterIO
{
	return @{@"P18Y9M4DT11H9M8S": @[@18, @9, @0, @4, @11, @9, @8],
			 @"P2W": @[@0, @0, @2, @0, @0, @0, @0],
			 @"P3Y6M4DT12H30M5S": @[@3, @6, @0, @4, @12, @30, @5],
			 @"P4Y": _dv(@{_o(NTIDurationUnitYears): @4}),
			 @"P1M": _dv(@{_o(NTIDurationUnitMonthes): @1}),
			 @"PT1M": _dv(@{_o(NTIDurationUnitMinutes): @1}),
			 @"PT2.3H": _dv(@{_o(NTIDurationUnitHours): @2.3}),
			 @"P0.5Y": @[@0.5, @0, @0, @0, @0, @0, @0],
			 @"P23DT23H": @[@0, @0, @0, @23, @23, @0, @0],
			 @"PT36H": _dv(@{_o(NTIDurationUnitHours): @36}),
			 @"P1DT12H": @[@0, @0, @0, @1, @12, @0, @0],
			 @"+P11D": _dv(@{_o(NTIDurationUnitDays): @11}),
			 @"-P2W": _dv(@{_o(NTIDurationUnitWeeks): @-2}),
			 @"-P2.2W": _dv(@{_o(NTIDurationUnitWeeks): @-2.2}),
			 @"P1DT2H3M4S": @[@0, @0, @0, @1, @2, @3, @4],
			 @"P1DT2H3M": @[@0, @0, @0, @1, @2, @3, @0],
			 @"P1DT2H": @[@0, @0, @0, @1, @2, @0, @0],
			 @"PT2H": @[@0, @0, @0, @0, @2, @0, @0],
			 @"PT2H": @[@0, @0, @0, @0, @2.3, @0, @0],
			 @"PT2H3M4S": @[@0, @0, @0, @0, @2, @3, @4],
			 @"PT3M4S": @[@0, @0, @0, @0, @0, @3, @4],
			 @"PT22S": @[@0, @0, @0, @0, @0, @0, @22],
			 //@"PT22.22S": @[@0, @0, @0, @0, @0, @0, closeTo(22.22, .01)],
			 @"-P2Y": @[@-2, @0, @0, @0, @0, @0, @0],
			 @"-P3Y6M4DT12H30M5S": @[@-3, @-6, @0, @-4, @-12, @-30, @-5],
			 @"-P1DT2H3M4S": @[@0, @0, @0, @-1, @-2, @-3, @-4],
			 //@"P0018-09-04T11:09:08": @[@18, @9, @0, @4, @11, @9, @8],
			 //@"PT000022.22": @[@0, @0, @0, @0, @0, @0, @22.22]
			 };
}

#undef  _dv
#undef _o

+(id)defaultTestSuite
{
	XCTestSuite* suite = [XCTestSuite testSuiteWithName: NSStringFromClass(self)];
	
	[[self formatterIO] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		SEL sel = @selector(checkDuration);
		NSInvocation* inv = [NSInvocation invocationWithMethodSignature: [self instanceMethodSignatureForSelector: sel]];
		[inv setSelector: sel];

		NTIISO8601DurationFormatterTest* test = [self testCaseWithInvocation: inv];
		test.durationString = key;
		test.cmps = obj;
		[suite addTest: test];
		
	}];
	
	NSLog(@"Generated test suite with %lu tests", (unsigned long) suite.tests.count);
	[suite.tests enumerateObjectsUsingBlock:^(__kindof XCTest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSLog(@"%@", obj);
	}];
	
	[suite addTest: [self testCaseWithSelector: @selector(testCreation)]];
	
	return suite;
}

- (void)setUp
{
    [super setUp];
	self->formatter = [[NTIISO8601DurationFormatter alloc] init];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
	self->formatter = nil;
}

- (NSString *)name {
	NSInvocation *invocation = [self invocation];
	
	NSString *methodName = NSStringFromSelector(invocation.selector);
	if ([methodName hasPrefix:@"checkDuration"]) {
		return [NSString stringWithFormat: @"%@_%@", methodName, self.durationString];
	}
	else {
		return [super name];
	}
}

-(void)checkDuration
{
	assertThat(self.durationString, notNilValue());
	assertThat(self.cmps, notNilValue());
	
	NTIDuration* duration = nil;
	BOOL result = [self->formatter getObjectValue: &duration forString: self.durationString
								 errorDescription: nil];
	assertThat(@(result), isTrue());
	
	NSArray* components = self.cmps;
	
	assertThat(duration.components, describedAs(@"expected duration %0 to parse to %1", equalTo(components), self.durationString, components, nil));
}

-(void)testCreation
{
	assertThat([[NTIISO8601DurationFormatter alloc] init], notNilValue());
}


@end

#undef HC_SHORTHAND
