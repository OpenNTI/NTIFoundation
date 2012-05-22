//
//  NTIMathBinaryExpression.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathBinaryExpression.h"
#import "NTIMathPlaceholderSymbol.h"
#import "NTIMathOperatorSymbol.h"
#import "NTIMathExponentBinaryExpression.h"
#import "NTIMathFractionBinaryExpression.h"
#import "NTIMathUnaryExpression.h"

@interface NTIMathBinaryExpression() 
//-(NSUInteger)precedenceLevelForString: (NSString *)opString;
-(NTIMathSymbol *)addAsChildMathSymbol: (NTIMathSymbol *)newMathSymbol;
@end

@implementation NTIMathBinaryExpression
@synthesize leftMathNode, rightMathNode, operatorMathNode, isOperatorImplicit;

+(NTIMathBinaryExpression *)binaryExpressionForString:(NSString *)symbolString
{
	if ([symbolString isEqualToString:@"+"]) {
		return [[NTIMathAdditionBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"-"]) {
		return [[NTIMathSubtractionBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"^"]) {
		return [[NTIMathExponentBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"*"]) {
		return [[NTIMathMultiplicationBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"/"]	) {
		return [[NTIMathFractionBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"÷"]) {
		return [[NTIMathFractionBinaryExpression alloc] init];

	}
	NSString* notReachedString = [NSString stringWithFormat: @"%@ not supported", symbolString];
	
	//Get the compiler to shutup about unused variable.
	if(notReachedString){
		OBASSERT_NOT_REACHED([notReachedString cStringUsingEncoding: NSUTF8StringEncoding] );
	}
	return nil;
}

-(id)initWithMathOperatorSymbol: (NSString *)operatorString
{
	self = [super init];
	if (self) {
		self->operatorMathNode = [[NTIMathOperatorSymbol alloc] initWithValue:operatorString];
		self->operatorMathNode.parentMathSymbol = self;
		self->leftMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		self->leftMathNode.parentMathSymbol = self;
		self->rightMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		self->rightMathNode.parentMathSymbol = self;
	}
	return self;
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
	if ([self.leftMathNode respondsToSelector:@selector(isPlaceholder)]){
		self.leftMathNode = newSymbol;
		return self.rightMathNode;
	}
	else if (![self.leftMathNode respondsToSelector:@selector(isPlaceholder)] && [self.rightMathNode respondsToSelector:@selector(isPlaceholder)] ) {
		//Left full, right is placeholder
		self.rightMathNode = newSymbol;
		return self.rightMathNode;
	}
	return nil;
}

-(NTIMathSymbol *)swapNode: (NTIMathSymbol *)childNode withNewNode: (NTIMathSymbol *)newNode
{
	//NOTE: this function should only be used to swap an existing node with another non-placeholder node.
	if (self.leftMathNode == childNode) {
		self.leftMathNode = newNode;
		return self.leftMathNode;
	}
	else if (self.rightMathNode == childNode){
		self.rightMathNode = newNode;
		return self.rightMathNode;
	}
	
	NSString* notReachedString = [NSString stringWithFormat: @"child node: %@ is not one of our children nodes", childNode];
	
	//Get the compiler to shutup about unused variable.
	if(notReachedString){
		OBASSERT_NOT_REACHED([notReachedString cStringUsingEncoding: NSUTF8StringEncoding] );
	}
	return nil;
}

-(void)replaceNode: (NTIMathSymbol *)newMathNode withPlaceholderFor: (NTIMathSymbol *)pointingTo
{
	//Replace child node with a placeholder
	if (self.leftMathNode == newMathNode) {
		self.leftMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		[(NTIMathPlaceholderSymbol *)self.leftMathNode setInPlaceOfObject: pointingTo];
		pointingTo.substituteSymbol = self.leftMathNode;
	}
	if (self.rightMathNode == newMathNode) {
		self.rightMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		[(NTIMathPlaceholderSymbol *)self.rightMathNode setInPlaceOfObject: pointingTo];
		pointingTo.substituteSymbol = self.rightMathNode;
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

-(NSString *)toStringValueForChildNode: (NTIMathSymbol *)childExpression
{
	NSString* childStringValue = [childExpression toString];
	childExpression = mathExpressionForSymbol(childExpression);
	if (childExpression.precedenceLevel < self.precedenceLevel && (childExpression.precedenceLevel > 0)) {
		childStringValue = [NSString stringWithFormat: @"(%@)", childStringValue]; 
	}
	return childStringValue;
}

-(NTIMathSymbol *)findLastLeafNodeFrom: (NTIMathSymbol *)mathSymbol
{
	if ([mathSymbol respondsToSelector:@selector(isPlaceholder)] ||
		[mathSymbol respondsToSelector:@selector(isLiteral) ]) {
		return mathSymbol;
	}
	else{
		if ([mathSymbol respondsToSelector:@selector(isBinaryOperator)]) {
			NTIMathBinaryExpression* bMathSymbol = (NTIMathBinaryExpression *)mathSymbol;
			return [self findLastLeafNodeFrom: bMathSymbol.rightMathNode];
		}
		if ([mathSymbol respondsToSelector:@selector(isUnaryOperator)]) {
			NTIMathUnaryExpression* uMathSymbol = (NTIMathUnaryExpression *)mathSymbol;
			return [self findLastLeafNodeFrom: uMathSymbol.childMathNode];
		}
		return nil;
	}
}

//Adds parenthesis, if they need to be added.
-(NSString *)latexValueForChildNode: (NTIMathSymbol *)childExpression
{
	NSString* childLatexValue = [childExpression latexValue];
	childExpression = mathExpressionForSymbol(childExpression);
	if (childExpression.precedenceLevel < self.precedenceLevel && (childExpression.precedenceLevel > 0)) {
		childLatexValue = [NSString stringWithFormat: @"(%@)", childLatexValue]; 
	}
	return childLatexValue;
}

-(NSString *)toString
{
	NSString* leftNodeString = [self toStringValueForChildNode: self.leftMathNode];
	NSString* rightNodeString = [self toStringValueForChildNode: self.rightMathNode];
	
	//If it's implicit we will ignore the operator symbol.
	if (self.isOperatorImplicit) {
		return [NSString stringWithFormat:@"%@%@", leftNodeString, rightNodeString];
	}
	NSString* string = [NSString stringWithFormat: @"%@%@%@", leftNodeString, [self.operatorMathNode toString], rightNodeString];
	return string;
}

-(NSString *)latexValue 
{
	NSString* leftNodeString = [self latexValueForChildNode: self.leftMathNode];
	NSString* rightNodeString = [self latexValueForChildNode: self.rightMathNode];
	
	//If it's implicit we will ignore the operator symbol.
	if (self.isOperatorImplicit) {
		return [NSString stringWithFormat:@"%@%@", leftNodeString, rightNodeString];
	}
	NSString* operatorString = [self.operatorMathNode latexValue];
	NSString* latexVal = [NSString stringWithFormat: @"%@%@%@", leftNodeString, operatorString, rightNodeString];
	return latexVal;
}

-(NSArray *)children
{
	return [NSArray arrayWithObjects:self.leftMathNode, self.rightMathNode, nil];
}

-(NSArray *)nonEmptyChildren
{
	NSMutableArray* neChildren = [NSMutableArray array];
	//not a placeholder, or it's a placeholder pointing to a subtree.
	if (![self.leftMathNode respondsToSelector:@selector(isPlaceholder)] || mathExpressionForSymbol(self.leftMathNode) != self.leftMathNode) {
		[neChildren addObject: self.leftMathNode];
	}
	if (![self.rightMathNode respondsToSelector:@selector(isPlaceholder)] || mathExpressionForSymbol(self.rightMathNode) != self.rightMathNode) {
		[neChildren addObject: self.rightMathNode];
	}
	return neChildren;
}

-(BOOL)isBinaryOperator
{
	return YES;
}
@end

@implementation NTIMathMultiplicationBinaryExpression
-(id)init
{
	self = [super initWithMathOperatorSymbol: @"*"];
	if (self) {
		self->precedenceLevel = 50;
	}
	return self;
}

@end

@implementation NTIMathAdditionBinaryExpression
-(id)init
{
	self = [super initWithMathOperatorSymbol: @"+"];
	if (self) {
		self->precedenceLevel = 40;
	}
	return self;
}

-(NSString *)toString
{
	if (self.isOperatorImplicit) {
		NSString* leftChildString = [self toStringValueForChildNode: self.leftMathNode];
		NSString* rightChildString = [self toStringValueForChildNode: self.rightMathNode];
		return [NSString stringWithFormat:@"%@ %@", leftChildString, rightChildString];
	}
	else {
		return [super toString];
	}
}
@end

@implementation NTIMathSubtractionBinaryExpression
-(id)init
{
	self = [super initWithMathOperatorSymbol: @"-"];
	if (self) {
		self->precedenceLevel = 40;
	}
	return self;
}
@end


