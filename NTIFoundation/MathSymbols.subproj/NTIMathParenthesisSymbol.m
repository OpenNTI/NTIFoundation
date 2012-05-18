//
//  NTIMathParenthesisSymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathParenthesisSymbol.h"
#import "NTIMathPlaceholderSymbol.h"
@implementation NTIMathParenthesisSymbol
-(id)init
{
	self = [super initWithMathOperatorString:@"()"];
	if (self) {
		precedenceLevel = 90;	//Paranthesis have the highest precedence of all math expressions.
	}
	return self;
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"(%@)", [self latexValueForChildNode: self.childMathNode]];
}

-(NSString *)toString
{
	return [NSString stringWithFormat: @"(%@)", [self latexValueForChildNode: self.childMathNode]];
}
@end
