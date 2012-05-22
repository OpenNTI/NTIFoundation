//
//  NTIMathUnaryExpression.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathUnaryExpression.h"
#import "NTIMathOperatorSymbol.h"
#import "NTIMathPlaceholderSymbol.h"
#import "NTIMathParenthesisSymbol.h"

@implementation NTIMathUnaryExpression
@synthesize prefix, childMathNode;

+(NTIMathUnaryExpression *)unaryExpressionForString: (NSString *)stringValue
{
	if ([stringValue isEqualToString: @"("] || [stringValue isEqualToString:@"( )"]) {
		return [[NTIMathParenthesisSymbol alloc] init];
	}
	if ([stringValue isEqualToString:@"√"]) {
		return [[NTIMathSquareRootUnaryExpression alloc] init];
	}
	if ([stringValue isEqualToString:@"≈"]) {
		return [[NTIMathAprroxUnaryExpression alloc] init];
	}
	return nil;
}

-(id)initWithMathOperatorString: (NSString *)operatorString
{
	self = [super init];
	if (self) {
		self->prefix = [[NTIMathOperatorSymbol alloc] initWithValue: operatorString];
		self->prefix.parentMathSymbol = self;
		self->childMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		self->childMathNode.parentMathSymbol = self;
	}
	return self;
}

-(void)setChildMathNode:(NTIMathSymbol *)newChildMathNode
{
	self->childMathNode = newChildMathNode;
	self->childMathNode.parentMathSymbol = self;
}

-(NSUInteger)precedenceLevel
{
	return self->precedenceLevel;
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
	if ([self.childMathNode respondsToSelector:@selector(isPlaceholder)])	{
		self.childMathNode = newSymbol;
		self.childMathNode.parentMathSymbol = self;
		return self.childMathNode;
	}
	return nil;
}

-(NTIMathSymbol *)swapNode: (NTIMathSymbol *)childNode withNewNode: (NTIMathSymbol *)newNode
{
	//NOTE: this function should only be used to swap an existing node with another non-placeholder node.
	if (self.childMathNode == childNode){
		self.childMathNode = newNode;
		return self.childMathNode;
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
	if (self.childMathNode == newMathNode) {
		self.childMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		[(NTIMathPlaceholderSymbol *)self.childMathNode setInPlaceOfObject: pointingTo];
		pointingTo.substituteSymbol = self.childMathNode;
	}
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)mathSymbol
{
	if ([self.childMathNode respondsToSelector:@selector(isPlaceholder)]) {
		return nil;
	}
	if (self.childMathNode == mathSymbol) {
		self.childMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		return self.childMathNode;
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

-(NSString *)latexValue
{
	return [NSString stringWithFormat: @"%@%@", [prefix latexValue], [self latexValueForChildNode: self.childMathNode]];
}

-(NSString *)toString
{
	return [NSString stringWithFormat: @"%@%@", [prefix toString], [self toStringValueForChildNode:self.childMathNode]];
}

-(NSArray *)children
{
	return [NSArray arrayWithObject: self.childMathNode];
}

-(NSArray *)nonEmptyChildren
{
	NSMutableArray* neChildren = [NSMutableArray array];
	//not a placeholder, or it's a placeholder pointing to a subtree.
	if (![self.childMathNode respondsToSelector:@selector(isPlaceholder)] || mathExpressionForSymbol(self.childMathNode) != self.childMathNode) {
		[neChildren addObject: self.childMathNode];
	}
	return neChildren;
}

-(BOOL)isUnaryOperator
{
	return YES;
}
@end



@implementation NTIMathAprroxUnaryExpression
-(id)init
{
	self = [super initWithMathOperatorString: @"≈"];
	if (self) {
		self->precedenceLevel = 0;
	}
	return self;
}
@end

@implementation NTIMathSquareRootUnaryExpression

-(id)init
{
	self = [super initWithMathOperatorString: @"√"];
	if (self) {
		self->precedenceLevel = 60;
	}
	return self;
}

-(NSString *)latexValue
{
	//Now we are sending \\surd{ instead of \\sqrt{} for latex.
	NSString* lString = [NSString stringWithFormat: @"\\surd%@", [self latexValueForChildNode: self.childMathNode]];
	return lString; 
}
@end


