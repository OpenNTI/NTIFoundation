//
//  NTIISO8601DurationFormatter.m
//  NTIFoundation
//
//  Created by Christopher Utz on 11/12/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import "NTIISO8601DurationFormatter.h"
#import "NTIDuration.h"


//Ported from the python isodata library isoduration.py
/*##############################################################################
# Copyright 2009, Gerhard Weis
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  * Neither the name of the authors nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT
##############################################################################
 */


@interface NTIISO8601DurationFormatter(){
	NSRegularExpression* durationRegex;
}
@end

#define regexParts @[@"^([+-])?", \
@"P([0-9]+(?:[,.][0-9]+)?Y)?", \
@"([0-9]+(?:[,.][0-9]+)?M)?", \
@"([0-9]+(?:[,.][0-9]+)?W)?", \
@"([0-9]+(?:[,.][0-9]+)?D)?", \
@"(?:(T)([0-9]+(?:[,.][0-9]+)?H)?", \
@"([0-9]+(?:[,.][0-9]+)?M)?", \
@"([0-9]+(?:[,.][0-9]+)?S)?)?$"]

#define _o(x) [NSNumber numberWithInt:x]
#define captureGroups @[@"sign", _o(NTIDurationUnitYears), _o(NTIDurationUnitMonthes), _o(NTIDurationUnitWeeks), _o(NTIDurationUnitDays), @"separator", _o(NTIDurationUnitHours), _o(NTIDurationUnitMinutes), _o(NTIDurationUnitSeconds)]

@implementation NTIISO8601DurationFormatter

-(id)init
{
	self = [super init];
	if(self){
		NSError* error = nil;
		self->durationRegex = [NSRegularExpression regularExpressionWithPattern: [regexParts componentsJoinedByString:@""]
																		options: 0
																		  error: &error];
		if(!self->durationRegex){
			//This is some sort of programming error.
			OBASSERT_NOT_REACHED(@"Bad durationRegex. Programming error?");
			if(error){
				NSLog(@"An error occurred parsing duration regex, %@", error);
			}
			return nil;
		}
	}
	return self;
}


-(NSString*)stringForObjectValue: (id)obj
{
	OBFinishPortingLater("String for object not yet implemented");
	return nil;
}

/**
 Parses an ISO 8601 durations into NTIDuration object
 
 The following duration formats are supported:
 -PnnW                  duration in weeks
 -PnnYnnMnnDTnnHnnMnnS  complete duration specification
 
 The '-' is optional.
 
 Limitations:  ISO standard defines some restrictions about where to use
 fractional numbers and which component and format combinations are
 allowed. This parser implementation ignores all those restrictions and
 returns something when it is able to find all necessary components.
 In detail:
 it does not check, whether only the last component has fractions.
 it allows weeks specified with all other combinations
 
 We also don't support the alternative format
*/

-(BOOL)getObjectValue:(out __autoreleasing id *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing *)error
{
	NSArray* groups = [self->durationRegex matchesInString: string options: 0 range: NSMakeRange(0, string.length)];
	
	if([NSArray isEmptyArray: groups]){
		if(*error){
			*error = (id)[NSError errorWithDomain: @"NTIISO8601DurationFormatter" code:-1 userInfo: nil];
			return NO;
		}
	}
	
	OBASSERT(groups.count == 1);
	NSTextCheckingResult* match = [groups firstObjectOrNil];
	
	if(!match){
		//This is where me could support the alternative format instead
		return NO;
	}
	
	NSArray* captures = captureGroups;
	int signAdjustment = 1;
	
	NSRange signRange = [match rangeAtIndex: [captures indexOfObject: @"sign"] + 1];
	if(signRange.location != NSNotFound){
		if([[string substringWithRange: signRange] isEqualToString: @"-"]){
			signAdjustment = -1;
		}
	}
	
	NTIDuration* duration = [[NTIDuration alloc] init];
	
	[captures enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if(![obj isKindOfClass: [NSNumber class]]){
			return;
		}
		
		NSRange range = [match rangeAtIndex: idx+1];
		if(range.location == NSNotFound){
			return;
		}
		
		NSString* component = [[string substringWithRange: range] stringByReplacingOccurrencesOfString: @"," withString:@"."];
		
		[duration setValue: signAdjustment * [component doubleValue] forUnit: [obj integerValue]];
	}];

	*obj = duration;

	return YES;
}

@end
#undef _o
#undef regexParts
