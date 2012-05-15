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
	return [super initWithMathOperatorSymbol: @"^"];
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"%@^%@", [self.leftMathNode latexValue], [self.rightMathNode latexValue]];
}
@end
