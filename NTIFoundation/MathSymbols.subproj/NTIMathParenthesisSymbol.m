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
	if ([self.childMathNode respondsToSelector:@selector(isPlaceholder)] 
		|| [self.childMathNode respondsToSelector:@selector(isLiteral)]) {
		//Add explicit paranthesis only if it's a placeholder(pointing nowhere) or literal. Otherwise, the paranthesis will have already been added based on the precedence level logic
		if([(NTIMathPlaceholderSymbol *)self.childMathNode inPlaceOfObject]){
			return [self latexValueForChildNode: self.childMathNode];
		}
		return [NSString stringWithFormat:@"(%@)", [self.childMathNode latexValue]]; 
	}
	return [self latexValueForChildNode: self.childMathNode];
}

-(NSString *)toString
{
	if ([self.childMathNode respondsToSelector:@selector(isPlaceholder)] || [self.childMathNode respondsToSelector:@selector(isLiteral)]) {
		if([(NTIMathPlaceholderSymbol *)self.childMathNode inPlaceOfObject]){
			return [self toStringValueForChildNode: self.childMathNode];
		}
		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
	}
	return [self toStringValueForChildNode: self.childMathNode];
}
@end
