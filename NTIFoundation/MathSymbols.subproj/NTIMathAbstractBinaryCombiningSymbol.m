//
//  NTIMathAbstractBinaryCombiningSymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathAbstractBinaryCombiningSymbol.h"
#import "NTIMathGroup.h"
#import "NTIMathPlaceholderSymbol.h"
@implementation NTIMathAbstractBinaryCombiningSymbol
@synthesize leftMathSymbol, rightMathSymbol, leftSymbolOpen, rightSymbolOpen;

-(id)initWithLeftMathSymbol: (NTIMathSymbol *)leftSymbol rightMathSymbol: (NTIMathSymbol *)rightSymbol
{
	self = [super init];
	if (self) {
		if (leftSymbol) {
			self.leftMathSymbol = leftSymbol;
			self.leftMathSymbol.parentMathSymbol = self;
		}
		if (rightSymbol) {
			self.rightMathSymbol = rightSymbol;
			self.rightMathSymbol.parentMathSymbol = self;
		}
		self.leftSymbolOpen = YES;
		self.rightSymbolOpen = YES;
	}
	return self;
}

#pragma mark - NTIMathExpressionSymbolProtocol Methods
-(BOOL)requiresGraphicKeyboard
{
	return [leftMathSymbol requiresGraphicKeyboard] && [rightMathSymbol requiresGraphicKeyboard];
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	if (self.leftSymbolOpen) {
		//Add to the left symbol
		if (!self.leftMathSymbol || [self.leftMathSymbol isKindOfClass:[NTIMathPlaceholderSymbol class]] ) {
			self.leftMathSymbol = newSymbol;
			self.leftMathSymbol.parentMathSymbol = self;
			return newSymbol;
		}
		if ( [self.leftMathSymbol addSymbol: newSymbol] ) {
			return newSymbol;
		}
		//We may need to switch from an atomic mathsymbol to a complex math symbol
		if (![self.leftMathSymbol isKindOfClass: [NTIMathGroup class]]) {
			self.leftMathSymbol = [[NTIMathGroup alloc] initWithMathSymbol: self.leftMathSymbol];
			
			self.leftMathSymbol.parentMathSymbol = self;
			[self.leftMathSymbol addSymbol: newSymbol];
			return newSymbol;
		}
	}
	if (self.rightSymbolOpen) {
		
		//Add to the right symbol,, and replace the placeholder if we have one.
		if (!self.rightMathSymbol || [self.rightMathSymbol isKindOfClass:[NTIMathPlaceholderSymbol class]]) {
			self.rightMathSymbol = newSymbol;
			self.rightMathSymbol.parentMathSymbol = self;
			return newSymbol;
		}
		if ( [self.rightMathSymbol addSymbol: newSymbol] ) {
			return newSymbol;
		}
		//We may need to switch from an atomic mathsymbol to a complex math symbol
		if (![self.rightMathSymbol isKindOfClass: [NTIMathGroup class]]) {
			self.rightMathSymbol = [[NTIMathGroup alloc] initWithMathSymbol: self.rightMathSymbol];
			
			self.rightMathSymbol.parentMathSymbol = self;
			[self.rightMathSymbol addSymbol: newSymbol];
			return newSymbol;
		}
	}
	return nil;
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)mathSymbol
{
	//if we only have placeholder
	if ( [self.leftMathSymbol isKindOfClass: [NTIMathPlaceholderSymbol class]] && [self.rightMathSymbol isKindOfClass: [NTIMathPlaceholderSymbol class]] ) {
		return nil;
	}
	
	//Delete something on the left math symbol
	NTIMathSymbol* tempSmyol = [self.leftMathSymbol deleteSymbol: mathSymbol];
	if (tempSmyol) {
		return tempSmyol;
	}
	
	tempSmyol = [self.rightMathSymbol deleteSymbol: mathSymbol];
	if (tempSmyol) {
		return tempSmyol;
	}
	//Unhandled issue: should we immediately add placeholders for empty left or right symbol?
	
	return nil;
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"%@%@", [self.leftMathSymbol latexValue], [self.rightMathSymbol latexValue]];
}

@end
