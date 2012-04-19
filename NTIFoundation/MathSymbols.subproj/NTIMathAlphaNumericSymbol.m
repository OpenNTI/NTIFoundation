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
		self.isNegative = NO;
		self.mathSymbolValue = value;
	}
	return  self;
}

#pragma mark - NTIMathExpressionSymbolProtocol Methods
-(BOOL)requiresGraphicKeyboard
{
	return NO;
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

-(NSString *)latexValue
{
	return self.mathSymbolValue;
}

@end
