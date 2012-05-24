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
	if ([self.childMathNode respondsToSelector:@selector(isLiteral)]) {
		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
	}
	if([self.childMathNode respondsToSelector:@selector(isPlaceholder)]
	   && ![(NTIMathPlaceholderSymbol *)self.childMathNode inPlaceOfObject]){
		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
	}
	return [self latexValueForChildNode: self.childMathNode];
}

-(NSString *)toString
{	
	if ([self.childMathNode respondsToSelector:@selector(isLiteral)]) {
		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
	}
	if([self.childMathNode respondsToSelector:@selector(isPlaceholder)]
	   && ![(NTIMathPlaceholderSymbol *)self.childMathNode inPlaceOfObject]){
		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
	}
	return [self toStringValueForChildNode: self.childMathNode];
}
@end
