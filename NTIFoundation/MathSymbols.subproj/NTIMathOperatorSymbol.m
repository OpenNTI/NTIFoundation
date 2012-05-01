//
//  NTIMathOperatorSymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathOperatorSymbol.h"

@implementation NTIMathOperatorSymbol
@synthesize mathSymbolValue;

-(id)initWithValue: (NSString *)value
{
	self = [super init];
	if (self) {
		self.mathSymbolValue = value;
	}
	return self;
}
#pragma mark - NTIMathExpressionSymbolProtocol Methods
-(BOOL)requiresGraphicKeyboard
{
	return NO;
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	return nil;
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)mathSymbol
{
	return nil;
}

-(NSString *)latexValue
{
	return mathSymbolValue;
}

-(NSString *)toString
{
	return mathSymbolValue;
}
@end
