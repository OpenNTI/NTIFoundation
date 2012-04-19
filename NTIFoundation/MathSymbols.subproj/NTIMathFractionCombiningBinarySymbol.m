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
	return [super initWithLeftMathSymbol: nil rightMathSymbol: nil];
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"\\frac{%@}{%@}", [self.leftMathSymbol latexValue], [self.rightMathSymbol latexValue]]; 
}


@end
