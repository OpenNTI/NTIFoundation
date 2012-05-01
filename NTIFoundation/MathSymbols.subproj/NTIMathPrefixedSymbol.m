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

@interface NTIMathPrefixedSymbol()
-(NSUInteger)precedenceLevelForString: (NSString *)opString;
@end

@implementation NTIMathPrefixedSymbol
@synthesize prefix, precedenceLevel, childMathNode;

-(id)initWithMathOperatorString: (NSString *)operatorString
{
	self = [super init];
	if (self) {
		self->prefix = [[NTIMathOperatorSymbol alloc] initWithValue: operatorString];
		self->prefix.parentMathSymbol = self;
		self->childMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		self->precedenceLevel = [self precedenceLevelForString: operatorString];
	}
	return self;
}

-(NSUInteger)precedenceLevelForString: (NSString *)opString
{
	/*if ([opString isEqualToString: @"!"] || [opString isEqualToString: @"√"]) {
		return 60;
	} */
	return 60;
}

//NOTE: NOT TO BE CONFUSED with -addSymbol, because this is only invoked in case we need to add something in between the parent node( self ) and its child. We get to this case based on precedence level comparison.
-(NTIMathSymbol *)addAsChildMathSymbol: (NTIMathSymbol *)newMathSymbol
{
	NTIMathSymbol* temp = self.childMathNode;
	self.childMathNode = newMathSymbol;
	
	//Then we take what was on the right node and move it down a level as a child of the new node.
	return [newMathSymbol addSymbol: temp];
}

#pragma mark - NTIMathExpressionSymbolProtocol Methods
-(BOOL)requiresGraphicKeyboard
{
	return [self.childMathNode requiresGraphicKeyboard];
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	//Stack it on the left
	if ([self.childMathNode isKindOfClass: [NTIMathPlaceholderSymbol class]])	{
		self.childMathNode = newSymbol;
		self.childMathNode.parentMathSymbol = self;
		return self.childMathNode;
	}
	return nil;
}

-(void)removeMathNode: (NTIMathSymbol *)newMathNode
{
	//Replace child node with a placeholder
	if (self.childMathNode == newMathNode) {
		self.childMathNode = [[NTIMathPlaceholderSymbol alloc] init];
	}
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)mathSymbol
{
	//FIXME: we haven't yet decided what the right behavior should be.
	
	/*
	if (!self->contents || [self.contents isKindOfClass: [NTIMathPlaceholderSymbol class]]) {
		return nil;
	}
	NTIMathSymbol* headSymbol = [self.contents deleteSymbol: mathSymbol];
	if (headSymbol) {
		return headSymbol;
	}
	*/
	return nil;
}

-(NSString *)latexValue
{
	if ([[self.prefix latexValue] isEqualToString:@"√"]) {
		NSString* childlaTex = [childMathNode latexValue];
		if (self.precedenceLevel > self.childMathNode.precedenceLevel && self.childMathNode.precedenceLevel > 0) {
			childlaTex = [NSString stringWithFormat:@"(%@)", [childMathNode latexValue]];
		}
		return [NSString stringWithFormat: @"\\sqrt{%@}", childlaTex];
	}
	return [NSString stringWithFormat: @"%@%@", [prefix latexValue], [childMathNode latexValue]];
}

-(NSString *)toString
{
	if (self.precedenceLevel > self.childMathNode.precedenceLevel && self.childMathNode.precedenceLevel > 0) {
		return [NSString stringWithFormat: @"%@(%@)", [prefix toString], [childMathNode toString]];
	}
	return [NSString stringWithFormat: @"%@%@", [prefix toString], [childMathNode toString]];
}
@end
