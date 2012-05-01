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
@synthesize openingParanthesis;

-(id)initWithMathSymbolString: (NSString *)string
{
	self = [super init];
	if (self) {
		if ([string isEqualToString: @"("]) {
			self->openingParanthesis = YES;
		}
		else{
			self->openingParanthesis = NO;
		}
	}
	return self;
}

-(NTIMathSymbol *)addSymbol:(id)mathSym
{
	//Doesn't handle adding.
	return nil;
}

-(NSString *)latexValue
{
	//This won't be necessary now because the paranthesis won't be an actual math symbol, rather a way of displaying a grouping.
	//return [NSString stringWithFormat:@"{%@}", [super latexValue]];
//	if (self.openingParanthesis) {
//		return @"(";
//	}
//	return @")";
	return nil;
}

-(NSString *)toString
{
	return nil;
}
@end
