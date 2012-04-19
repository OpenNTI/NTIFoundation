//
//  NTIMathSymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbol.h"

@implementation NTIMathSymbol
@synthesize latexValue, parentMathSymbol;

-(BOOL)requiresGraphicKeyboard
{
	[NSException raise:NSInvalidArgumentException
				format:@"Subclasses need to implement implement requiresGraphicKeyboard"];
	return NO;
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)mathSym 
{
	[NSException raise:NSInvalidArgumentException
				format:@"Subclasses need to implement addSymbol:"];
	return nil;
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)mathSymbol
{
	[NSException raise:NSInvalidArgumentException
				format:@"Subclasses need to implement deleteCurrentSymbol:"];

	return nil;
}
@end
