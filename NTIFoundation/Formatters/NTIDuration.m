//
//  NTIDuration.m
//  NTIFoundation
//
//  Created by Christopher Utz on 11/12/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import "NTIDuration.h"

@interface NTIDuration(){

}
@end

@implementation NTIDuration

-(id)initWithValues: (NSDictionary*)values
{
	self = [super init];
	if(self){
		[values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[self setValue: [obj doubleValue] forUnit: [key integerValue]];
		}];
	}
	return self;
}

-(double)valueForUnit: (NTIDurationUnit)unit
{
	switch (unit) {
		case NTIDurationUnitYears:
			return self.years;
		case NTIDurationUnitMonthes:
			return self.monthes;
		case NTIDurationUnitWeeks:
			return self.weeks;
		case NTIDurationUnitDays:
			return self.days;
		case NTIDurationUnitHours:
			return self.hours;
		case NTIDurationUnitMinutes:
			return self.minutes;
		case NTIDurationUnitSeconds:
			return self.seconds;
	}
	
	[NSException raise: @"Unsupported unit" format: @"valueForUnit: called with unsupported unit %lu", (unsigned long)unit];
}

-(void)setValue: (double)i forUnit: (NTIDurationUnit)unit
{
	switch (unit) {
		case NTIDurationUnitYears:
			self.years = i;
			break;
		case NTIDurationUnitMonthes:
			self.monthes = i;
			break;
		case NTIDurationUnitWeeks:
			self.weeks = i;
			break;
		case NTIDurationUnitDays:
			self.days = i;
			break;
		case NTIDurationUnitHours:
			self.hours = i;
			break;
		case NTIDurationUnitMinutes:
			self.minutes = i;
			break;
		case NTIDurationUnitSeconds:
			self.seconds = i;
			break;
		default:
			[NSException raise: @"Unsupported unit" format: @"setValue:forUnit: called with unsupported unit %lu", (unsigned long)unit];
	}

}

@end
