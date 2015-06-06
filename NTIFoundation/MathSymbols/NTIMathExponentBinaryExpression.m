//
//  NTIMathExponentBinaryExpression.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathExponentBinaryExpression.h"

@implementation NTIMathExponentBinaryExpression

+(NSUInteger)precedenceLevel
{
	return 60;
}

-(id)init
{
	self = [super initWithMathOperatorSymbol: @"^"];
	if (self) {
	}
	return self;
}
@end
