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
@synthesize openQueueSymbol;
-(id)initWithMathSymbol:(NTIMathSymbol *)aSymbol
{
	self = [super initWithMathSymbol: aSymbol];
	self.openQueueSymbol = YES;
	return self;
}

-(NTIMathSymbol *)addSymbol:(id)mathSym
{
	if (!self.openQueueSymbol) {
		return nil;
	}
	//Make sure to delete the placeholder before add new symbol.
	if ( [[self.components objectAtIndex: 0] isKindOfClass:[NTIMathPlaceholderSymbol class]] && [self.components count] == 1 && mathSym ) {
		[_components removeObjectAtIndex: 0];
	}
	return [super addSymbol: mathSym];
}

-(NSString *)latexValue
{
	return [NSString stringWithFormat:@"{%@}", [super latexValue]];
}
@end
