//
//  NTIDuration.h
//  NTIFoundation
//
//  Created by Christopher Utz on 11/12/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NTIDurationUnit){
	NTIDurationUnitYears,
	NTIDurationUnitMonthes,
	NTIDurationUnitWeeks,
	NTIDurationUnitDays,
	NTIDurationUnitHours,
	NTIDurationUnitMinutes,
	NTIDurationUnitSeconds
};

@interface NTIDuration : NSObject

-(id)initWithValues: (NSDictionary*)values;

@property (nonatomic, assign) double years;
@property (nonatomic, assign) double monthes;
@property (nonatomic, assign) double weeks;
@property (nonatomic, assign) double days;
@property (nonatomic, assign) double hours;
@property (nonatomic, assign) double minutes;
@property (nonatomic, assign) double seconds;

-(double)valueForUnit: (NTIDurationUnit)unit;
-(void)setValue: (double)i forUnit: (NTIDurationUnit)unit;
-(NSDateComponents*)dateComponents;

@end
