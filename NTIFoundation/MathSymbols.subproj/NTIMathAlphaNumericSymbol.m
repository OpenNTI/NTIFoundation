//
//  NTIAlphaNumericSymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathAlphaNumericSymbol.h"

@implementation NTIMathAlphaNumericSymbol
@synthesize isNegative, mathSymbolValue;


-(id)initWithValue: (NSString *)value
{
	self = [super init];
	if (self) {
		self.mathSymbolValue = value;
	}
	return  self;
}

-(void)setIsNegative:(BOOL)negativeFlag
{
	//Toggle on and off.
	self->isNegative = !self->isNegative; 
}

#pragma mark - NTIMathExpressionSymbolProtocol Methods
-(BOOL)requiresGraphicKeyboard
{
	return NO;
}

-(NTIMathSymbol *)appendMathSymbol: (NTIMathSymbol *)newSymbol
{
	if (![newSymbol isKindOfClass:[NTIMathAlphaNumericSymbol class]]) {
		return nil;
	}
	
	//Append the math value of the new symbol to the old one
	self.mathSymbolValue = [NSString stringWithFormat:@"%@%@", self.mathSymbolValue, [(NTIMathAlphaNumericSymbol *)newSymbol mathSymbolValue]];
	return self;

}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	if (![newSymbol isKindOfClass:[NTIMathAlphaNumericSymbol class]]) {
		return nil;
	}
	
	//Append the math value of the new symbol to the old one
	self.mathSymbolValue = [NSString stringWithFormat:@"%@%@", self.mathSymbolValue, [(NTIMathAlphaNumericSymbol *)newSymbol mathSymbolValue]];
	return self;
}

-(NTIMathSymbol *)deleteSymbol: (NTIMathSymbol *)mathSymbol
{
	if (self != mathSymbol) {
		return nil;
	}
	if ( [self.mathSymbolValue length] == 1 ) {
		return nil;	//The whole object should be deleted
	}
	
	//Otherwise delete the last alphanumeric character.
	self.mathSymbolValue = [self.mathSymbolValue substringToIndex:[self.mathSymbolValue length] - 1];
	return self;
}

-(NTIMathSymbol *)deleteLastLiteral
{
	if ( [self.mathSymbolValue length] == 1 ) {
		return nil;	//The whole object should be deleted
	}
	//Otherwise delete the last literal character
	self.mathSymbolValue = [self.mathSymbolValue substringToIndex:[self.mathSymbolValue length] - 1];
	return self;
}

-(NSString *)latexValue
{
	NSString* latexVal = self.mathSymbolValue;
	NSRange aRange = [latexVal rangeOfString:@"π"];
	if (aRange.location != NSNotFound) {
		latexVal = [latexVal stringByReplacingOccurrencesOfString:@"π" withString:@"\\pi"];
	}
	if (self.isNegative) {
		latexVal = [NSString stringWithFormat:@"-%@", latexVal];
	}

	if (self.hasParenthesis) {
		latexVal = [NSString stringWithFormat:@"(%@)", latexVal];
	}
	return latexVal;
}

-(NSString *)toString
{
	NSString* string;
	if (self.isNegative) {
		string = [NSString stringWithFormat:@"-%@", self.mathSymbolValue];
	}
	if (self.hasParenthesis) {
		return [NSString stringWithFormat:@"(%@)", string];
	}
	return self.mathSymbolValue;
}

-(BOOL)isLiteral
{
	return YES;
}
@end
