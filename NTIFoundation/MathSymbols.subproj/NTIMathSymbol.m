//
//  NTIMathSymbol.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbol.h"
#import "NTIMathPlaceholderSymbol.h"

@implementation NTIMathSymbol
@synthesize parentMathSymbol, precedenceLevel,substituteSymbol;

//TODO the getters for leftMathNode and rightMathNode should return after passing
//through this function.
static NTIMathSymbol* mathExpressionForSymbol(NTIMathSymbol* mathSymbol)
{
	//helper method, for placeholder that may be pointing to expression tree.
	if ([mathSymbol respondsToSelector: @selector(isPlaceholder)]) {
		NTIMathSymbol* rep = [mathSymbol performSelector: @selector(inPlaceOfObject)];
		if (rep) {
			return rep;
		}
	}
	return mathSymbol;
}

+(NTIMathSymbol*)followIfPlaceholder: (NTIMathSymbol*) symbol
{
	return mathExpressionForSymbol(symbol);
}

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

-(NSArray*)children
{
	return nil;
}

-(NSArray*)childrenFollowingLinks
{
	return [self.children arrayByPerformingBlock: ^id(id obj){
		return mathExpressionForSymbol(obj);
	}];
}

-(NTIMathSymbol*)parentMathSymbolFollowingLinks
{
	if(self.parentMathSymbol){
		return self.parentMathSymbol;
	}
	
	if(self.substituteSymbol){
		if( [self.substituteSymbol respondsToSelector: @selector(isPlaceholder)] ){
			return self.substituteSymbol.parentMathSymbolFollowingLinks;
		}
	}
	
	return nil;
}


-(NTIMathSymbol*)nextSibling
{
	NTIMathSymbol* next = nil;
	
	NSArray* siblings = self.parentMathSymbolFollowingLinks.childrenFollowingLinks;
	if( [NSArray isNotEmptyArray: siblings] ){
		NSInteger indexOfSelf = [siblings indexOfObjectIdenticalTo: self];
		if(indexOfSelf != NSNotFound && indexOfSelf + 1 < (NSInteger)siblings.count){
			next = [siblings objectAtIndex: indexOfSelf + 1];
		}
	}
	
	return next;
}

-(NTIMathSymbol*)previousSibling
{
	NTIMathSymbol* previous = nil;
	
	NSArray* siblings = self.parentMathSymbolFollowingLinks.childrenFollowingLinks;
	if( [NSArray isNotEmptyArray: siblings] ){
		NSInteger indexOfSelf = [siblings indexOfObjectIdenticalTo: self];
		if(indexOfSelf != NSNotFound && indexOfSelf - 1 >= 0){
			previous = [siblings objectAtIndex: indexOfSelf - 1];
		}
	}
	
	return previous;
}

-(NTIMathSymbol*)firstChild
{
	NSArray* children = self.childrenFollowingLinks;
	if( [NSArray isNotEmptyArray: children] ){
		return [children firstObject];
	}
	return nil;
}

-(NSUInteger)precedenceLevel
{
	return 0;
}

-(NSString *)toString
{
	return nil;
}

-(NSString *)latexValue
{
	return nil;
}
@end
