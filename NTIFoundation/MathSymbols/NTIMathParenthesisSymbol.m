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

+(NSUInteger)precedenceLevel
{
	return 90; //Paranthesis have the highest precedence of all math expressions.
}


-(id)init
{
	self = [super initWithMathOperatorString:@"("];
	if (self) {
	}
	return self;
}

-(NSString *)latexValue
{
//	if ([self.childMathNode respondsToSelector:@selector(isLiteral)]) {
//		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
//	}
//	if([self.childMathNode respondsToSelector:@selector(isPlaceholder)]
//	   && ![(NTIMathPlaceholderSymbol *)self.childMathNode inPlaceOfObject]){
//		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
//	}
//	return [self latexValueForChildNode: self.childMathNode];
	
	return [NSString stringWithFormat:@"(%@)", [self.childMathNode latexValue]]; 
}

-(NSString *)toString
{	
//	if ([self.childMathNode respondsToSelector:@selector(isLiteral)]) {
//		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
//	}
//	if([self.childMathNode respondsToSelector:@selector(isPlaceholder)]
//	   && ![(NTIMathPlaceholderSymbol *)self.childMathNode inPlaceOfObject]){
//		return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
//	}
//	return [self toStringValueForChildNode: self.childMathNode];
	
	return [NSString stringWithFormat:@"(%@)", [self.childMathNode toString]]; 
}
@end
