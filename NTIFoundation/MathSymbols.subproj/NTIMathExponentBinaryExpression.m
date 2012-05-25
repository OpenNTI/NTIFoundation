//
//  NTIMathExponentBinaryExpression.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathExponentBinaryExpression.h"

@implementation NTIMathExponentBinaryExpression

-(id)init
{
	self = [super initWithMathOperatorSymbol: @"^"];
	if (self) {
		self->precedenceLevel = 60;
	}
	return self;
}
@end
