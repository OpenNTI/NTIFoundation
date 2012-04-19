//
//  NTIMathPrefixedSymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathPrefixedSymbol.h"
#import "NTIMathGroup.h"
#import "NTIMathOperatorSymbol.h"
#import "NTIMathPlaceholderSymbol.h"

@implementation NTIMathPrefixedSymbol
@synthesize prefix, contents, canAddNewSymbol;

-(id)initWithSymbolValue: (NSString *)value 
		  withMathSymbol: (NTIMathSymbol *)mathSymbol
{
	self = [super init];
	if (self) {
		self->symbolValue = value;
		self.prefix = [[NTIMathOperatorSymbol alloc] initWithValue: value];
		self.prefix.parentMathSymbol = self;
		if (mathSymbol) {
			self.contents = mathSymbol;	//This could be a valid math symbol or a placeholder symbol
			self.contents.parentMathSymbol = self;
		}
		self.canAddNewSymbol = YES;
	}
	return self;
}

#pragma mark - NTIMathExpressionSymbolProtocol Methods
-(BOOL)requiresGraphicKeyboard
{
	return [contents requiresGraphicKeyboard];
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	//Check if we're open to add new symbol or not. This is mainly driven by the navigation.
	if (!self.canAddNewSymbol) {
		return nil;
	}
	
	//Check where to add the newSymbol
	if (!self.contents) {
		self.contents = newSymbol;
		self.contents.parentMathSymbol = self;
		return newSymbol;
	}
	if ([self.contents isKindOfClass:[NTIMathPlaceholderSymbol class]]) {
		//Replace the placeholder symbol.
		self.contents = newSymbol;
		self.contents.parentMathSymbol = self;
		return self.contents;
	}
	if ( [self.contents addSymbol: newSymbol] ) {
		return newSymbol;
	}
	//We may need to switch from an atomic mathsymbol to a complex math symbol
	if (![self.contents isKindOfClass: [NTIMathGroup class]]) {
		NTIMathSymbol* tempSymbol = self.contents;
		self.contents = [[NTIMathGroup alloc] initWithMathSymbol: tempSymbol];
		
		self.contents.parentMathSymbol = self;
		[self.contents addSymbol: newSymbol];
		return newSymbol;
	}
	return nil;
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)mathSymbol
{
	if (!self->contents || [self.contents isKindOfClass: [NTIMathPlaceholderSymbol class]]) {
		return nil;
	}
	NTIMathSymbol* headSymbol = [self.contents deleteSymbol: mathSymbol];
	if (headSymbol) {
		return headSymbol;
	}
	return nil;
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"%@%@", [prefix latexValue], [contents latexValue]];
}
@end
