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
	if ( !self.mathSymbolValue || [self.mathSymbolValue isEqualToString:@""] || [self.mathSymbolValue length] == 1 ) {
		return nil;	//The whole object should be deleted
	}
	
	//Otherwise delete the last alphanumeric character.
	self.mathSymbolValue = [self.mathSymbolValue substringToIndex:[self.mathSymbolValue length] - 1];
	return self;
}

-(NTIMathSymbol *)deleteLastLiteral
{
	if ( !self.mathSymbolValue || [self.mathSymbolValue isEqualToString:@""] || [self.mathSymbolValue length] == 1 ) {
		return nil;	//The whole object should be deleted
	}
	//Otherwise delete the last literal character
	self.mathSymbolValue = [self.mathSymbolValue substringToIndex:[self.mathSymbolValue length] - 1];
	return self;
}

static NSString* latexify(NSString* lText)
{

	//More special symbols
	lText = [lText stringByReplacingOccurrencesOfString:@"∫" withString:@"\\int"];
	lText = [lText stringByReplacingOccurrencesOfString:@"±" withString:@"\\pm"];
	lText = [lText stringByReplacingOccurrencesOfString:@"√" withString:@"\\surd"];
	
	//Greek symbols
	lText = [lText stringByReplacingOccurrencesOfString:@"ε" withString:@"\\epsilon"];
	lText = [lText stringByReplacingOccurrencesOfString:@"θ" withString:@"\\theta"];
	lText = [lText stringByReplacingOccurrencesOfString:@"λ" withString:@"\\lambda"];
	lText = [lText stringByReplacingOccurrencesOfString:@"Φ" withString:@"\\Phi"];
	lText = [lText stringByReplacingOccurrencesOfString:@"α" withString:@"\\alpha"];
	lText = [lText stringByReplacingOccurrencesOfString:@"β" withString:@"\\beta"];
	lText = [lText stringByReplacingOccurrencesOfString:@"γ" withString:@"\\gamma"];
	lText = [lText stringByReplacingOccurrencesOfString:@"δ" withString:@"\\sigma"];
	lText = [lText stringByReplacingOccurrencesOfString:@"∆" withString:@"\\Delta"];
	lText = [lText stringByReplacingOccurrencesOfString:@"Ω" withString:@"\\Omega"];
	lText = [lText stringByReplacingOccurrencesOfString:@"∏" withString:@"\\Pi"];
	lText = [lText stringByReplacingOccurrencesOfString:@"Ψ" withString:@"\\psi"];
	lText = [lText stringByReplacingOccurrencesOfString:@"∑" withString:@"\\Sigma"];
	lText = [lText stringByReplacingOccurrencesOfString:@"π" withString:@"\\pi"];
	//Comparisons
	lText = [lText stringByReplacingOccurrencesOfString:@"≈" withString:@"\\approx"];
	lText = [lText stringByReplacingOccurrencesOfString:@"≥" withString:@"\\geq"];
	lText = [lText stringByReplacingOccurrencesOfString:@"≤" withString:@"\\leq"];
	
	return lText;
}

-(NSString*)latexValue
{
	NSString* latexVal = latexify(self.mathSymbolValue);
	
	if (self.isNegative) {
		latexVal = [NSString stringWithFormat:@"-%@", latexVal];
	}
	return latexVal;
}

-(NSString *)toString
{
	NSString* string = self.mathSymbolValue;
	if (self.isNegative) {
		string = [NSString stringWithFormat:@"-%@", self.mathSymbolValue];
	}
	return string;
}

-(BOOL)isLiteral
{
	return YES;
}
@end
