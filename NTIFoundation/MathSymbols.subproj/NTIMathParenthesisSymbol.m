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
	self = [super initWithMathOperatorString:@"("];
	if (self) {
		precedenceLevel = 90;	//Paranthesis have the highest precedence of all math expressions.
	}
	return self;
}

-(NSString *)latexValue
{
	//NOTE: We don't need to add parenthesis, they will be added automatically because parenthesis have the highest precedence of all the math symbols. Adding them here, results in duplicate parenthesis.
	//return [NSString stringWithFormat: @"(%@)", [self latexValueForChildNode: self.childMathNode]];
	if ([self.childMathNode respondsToSelector:@selector(isPlaceholder)] || [self.childMathNode respondsToSelector:@selector(isLiteral)]) {
		return [NSString stringWithFormat:@"(%@)", [self latexValueForChildNode: self.childMathNode]]; 
	}
	return [self latexValueForChildNode: self.childMathNode];
}

-(NSString *)toString
{
	//return [NSString stringWithFormat: @"(%@)", [self latexValueForChildNode: self.childMathNode]];
	if ([self.childMathNode respondsToSelector:@selector(isPlaceholder)] || [self.childMathNode respondsToSelector:@selector(isLiteral)]) {
		return [NSString stringWithFormat:@"(%@)", [self toStringValueForChildNode: self.childMathNode]]; 
	}
	return [self toStringValueForChildNode: self.childMathNode];
}
@end
