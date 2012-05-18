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
	self = [super initWithMathOperatorSymbol: @"/"];
	if (self) {
		precedenceLevel = 50;
	}
	return self;
}

-(NSString *)latexValue
{
	NSString* leftString = [self latexValueForChildNode: self.leftMathNode];
	NSString* rightString = [self latexValueForChildNode: self.rightMathNode];
	return [NSString stringWithFormat: @"\\frac{%@}{%@}", leftString, rightString]; 
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	//Stack it on the left
	if ([self.leftMathNode respondsToSelector:@selector(isPlaceholder)]){
		self.leftMathNode = newSymbol;
		self.leftMathNode.parentMathSymbol = self;
		return [self findLastLeafNodeFrom: self.leftMathNode];
	}
	else if (![self.leftMathNode respondsToSelector:@selector(isPlaceholder)] && [self.rightMathNode respondsToSelector:@selector(isPlaceholder)] ) {
		//Left full, right is placeholder
		self.rightMathNode = newSymbol;
		self.rightMathNode.parentMathSymbol = self;
		return self.rightMathNode;
	}
	return nil;
}

@end
