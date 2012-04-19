//
//  NTIMathPlaceholderSymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathPlaceholderSymbol.h"

@implementation NTIMathPlaceholderSymbol


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
	return nil;
}
@end
