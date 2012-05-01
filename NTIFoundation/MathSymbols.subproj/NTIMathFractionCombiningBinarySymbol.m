//
//  NTIMathFractionCombiningBinarySymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathFractionCombiningBinarySymbol.h"

@implementation NTIMathFractionCombiningBinarySymbol

-(id)init
{
	return [super initWithMathOperatorSymbol: @"/"];
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"\\frac{%@}{%@}", [self.leftMathNode latexValue], [self.rightMathNode latexValue]]; 
}

@end
