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
#import "NTIMathOperatorSymbol.h"

@interface NTIMathAbstractBinaryCombiningSymbol() 
-(NSUInteger)precedenceLevelForString: (NSString *)opString;
-(NTIMathSymbol *)addAsChildMathSymbol: (NTIMathSymbol *)newMathSymbol;
@end

@implementation NTIMathAbstractBinaryCombiningSymbol
@synthesize leftMathNode, rightMathNode, operatorMathNode;


-(id)initWithMathOperatorSymbol: (NSString *)operatorString
{
	self = [super init];
	if (self) {
		self->operatorMathNode = [[NTIMathOperatorSymbol alloc] initWithValue:operatorString];
		self.leftMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		self.rightMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		self->precedenceLevel = [self precedenceLevelForString: operatorString];
	}
	return self;
}

-(NSUInteger)precedenceLevelForString: (NSString *)opString
{
	if ([opString isEqualToString: @"^"]) {
		return 60;
	}
	if ([opString isEqualToString: @"*"] || 
		[opString isEqualToString: @"/"] || 
		[opString isEqualToString:@"÷"]) {
		return 50;
	}
	if ([opString isEqualToString: @"+"] || 
		[opString isEqualToString: @"-"]) {
		return 40;
	}
	return 0;
}

-(NSUInteger)precedenceLevel
{
	//Abstract binary pl
	return self->precedenceLevel; 
}

-(void)setLeftMathNode:(NTIMathSymbol *)aLeftMathNode
{
	self->leftMathNode = aLeftMathNode;
	self->leftMathNode.parentMathSymbol = self;
}

-(void)setRightMathNode:(NTIMathSymbol *)aRightMathNode
{
	self->rightMathNode = aRightMathNode;
	self->rightMathNode.parentMathSymbol = self;
}

//NOTE: NOT TO BE CONFUSED with -addSymbol, because this is only invoked in case we need to add something in between the parent node( self ) and its child( right child). We get to this case based on precedence level comparison
-(NTIMathSymbol *)addAsChildMathSymbol: (NTIMathSymbol *)newMathSymbol
{
	NTIMathSymbol* temp = self.rightMathNode;
	self.rightMathNode = newMathSymbol;
	
	//Then we take what was on the right node and move it down a level as a child of the new node.
	return [newMathSymbol addSymbol: temp];
}

#pragma mark - NTIMathExpressionSymbolProtocol Methods
-(BOOL)requiresGraphicKeyboard
{
	return [leftMathNode requiresGraphicKeyboard] && [rightMathNode requiresGraphicKeyboard];
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	//Stack it on the left
	if ([self.leftMathNode respondsToSelector:@selector(isPlaceholder)])	{
		self.leftMathNode = newSymbol;
		self.leftMathNode.parentMathSymbol = self;
		return rightMathNode;
	}
	else if (![self.leftMathNode respondsToSelector:@selector(isPlaceholder)] && [self.rightMathNode respondsToSelector:@selector(isPlaceholder)] ) {
		//Left full, right is placeholder
		self.rightMathNode = newSymbol;
		self.rightMathNode.parentMathSymbol = self;
		return rightMathNode;
	}
	
	return nil;
}

-(void)replaceNode: (NTIMathSymbol *)newMathNode withPlaceholderFor: (NTIMathSymbol *)pointingTo
{
	//Replace child node with a placeholder
	if (self.leftMathNode == newMathNode) {
		self.leftMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		[(NTIMathPlaceholderSymbol *)self.leftMathNode setInPlaceOfObject: pointingTo];
	}
	if (self.rightMathNode == newMathNode) {
		self.rightMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		[(NTIMathPlaceholderSymbol *)self.rightMathNode setInPlaceOfObject: pointingTo];
	}
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)mathSymbol
{
	//if we only have placeholders
	if ( [self.leftMathNode respondsToSelector:@selector(isPlaceholder)] && [self.rightMathNode respondsToSelector:@selector(isPlaceholder)] ) {
		return nil;
	}
	
	if ([mathSymbol respondsToSelector:@selector(isPlaceholder)]) {
		return nil;
	}
	if (self.leftMathNode == mathSymbol) {
		self.leftMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		return self.leftMathNode;
	}
	if (self.rightMathNode == mathSymbol) {
		self.rightMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		return self.rightMathNode;
	}
	return nil;
}

static NTIMathSymbol* mathExpressionForSymbol(NTIMathSymbol* mathSymbol)
{
	//helper method, for placeholder that may be pointing to expression tree.
	if ([mathSymbol respondsToSelector:@selector(isPlaceholder)]) {
		NTIMathSymbol* rep = [mathSymbol performSelector:@selector(inPlaceOfObject)];
		if (rep) {
			return rep;
		}
	}
	return mathSymbol;
}

-(NSString *)toString
{
	NSString* leftNodeString = [self.leftMathNode toString];
	NSString* rightNodeString = [self.rightMathNode toString];
	
	//case of implicit multiplication, e.g 4√3 instead of 4*√3
	if ([mathExpressionForSymbol(self.leftMathNode) respondsToSelector:@selector(isLiteral)] && [mathExpressionForSymbol(self.rightMathNode) respondsToSelector:@selector(isUnaryOperator)]) {
		return [NSString stringWithFormat:@"%@%@", leftNodeString, rightNodeString];
	}
		
	if (self.leftMathNode.precedenceLevel < self.precedenceLevel && (self.leftMathNode.precedenceLevel > 0)) {
		leftNodeString = [NSString stringWithFormat: @"(%@)", leftNodeString]; 
	}
	if (self.rightMathNode.precedenceLevel < self.precedenceLevel && (self.rightMathNode.precedenceLevel > 0)) {
		rightNodeString = [NSString stringWithFormat:@"(%@)", rightNodeString];
	}
	
	
	return [NSString stringWithFormat: @"%@%@%@", leftNodeString, [self.operatorMathNode toString], rightNodeString];
}

-(NSString *)latexValue 
{
	NSString* leftNodeString = [self.leftMathNode latexValue];
	NSString* rightNodeString = [self.rightMathNode latexValue];
	NSString* operatorString = [self.operatorMathNode latexValue];
	
	//case of implicit multiplication, e.g 4√3 instead of 4*√3
	if ([mathExpressionForSymbol(self.leftMathNode) respondsToSelector:@selector(isLiteral)] && [mathExpressionForSymbol(self.rightMathNode) respondsToSelector:@selector(isUnaryOperator)]) {
		return [NSString stringWithFormat:@"%@%@", leftNodeString, rightNodeString];
	}
	
	//we don't want paranthesis around literals and placeholders( their precedence level is 0)
	if (self.leftMathNode.precedenceLevel < self.precedenceLevel && (self.leftMathNode.precedenceLevel > 0)) {
		leftNodeString = [NSString stringWithFormat: @"(%@)", leftNodeString]; 
	}
	if (self.rightMathNode.precedenceLevel < self.precedenceLevel && (self.rightMathNode.precedenceLevel > 0)) {
		rightNodeString = [NSString stringWithFormat:@"(%@)", rightNodeString];
	}
	
	if ([operatorString isEqualToString:@"/"] || [operatorString isEqualToString:@"÷"]) {
		return [NSString stringWithFormat:@"\\frac{%@}{%@}", leftNodeString, rightNodeString];
	}
	
	return [NSString stringWithFormat: @"%@%@%@", leftNodeString, operatorString, rightNodeString];
}

-(NSArray *)children
{
	return [NSArray arrayWithObjects:self.leftMathNode, self.rightMathNode, nil];
}

-(BOOL)isBinaryOperator
{
	return YES;
}
@end
