//
//  NTIMathFractionBinaryExpression.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathFractionBinaryExpression.h"

@implementation NTIMathFractionBinaryExpression

-(id)init
{
	return [super initWithMathOperatorSymbol: @"/"];
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"\\frac{%@}{%@}", [self.leftMathNode latexValue], [self.rightMathNode latexValue]]; 
}

@end
