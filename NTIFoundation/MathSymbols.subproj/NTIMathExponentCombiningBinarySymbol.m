//
//  NTIExponentCombiningBinarySymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathExponentCombiningBinarySymbol.h"

@implementation NTIMathExponentCombiningBinarySymbol

-(id)init
{
	return [super initWithLeftMathSymbol: nil rightMathSymbol: nil];
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"%@^%@", [self.leftMathSymbol latexValue], [self.rightMathSymbol latexValue]];
}
@end
