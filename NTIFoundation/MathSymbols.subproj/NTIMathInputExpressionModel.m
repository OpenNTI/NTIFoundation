//
//  NTIMathInputExpressionModel.m
//  NTIFoundation
//
//  Created by  on 4/26/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathInputExpressionModel.h"
#import "NTIMathSymbol.h"
#import "NTIMathAbstractBinaryCombiningSymbol.h"
#import "NTIMathPrefixedSymbol.h"
#import "NTIMathPlaceholderSymbol.h"
#import "NTIMathAlphaNumericSymbol.h"
#import "NTIMathOperatorSymbol.h"
#import "NTIMathExponentCombiningBinarySymbol.h"
#import "NTIMathParenthesisSymbol.h"
#import "NTIMathFractionCombiningBinarySymbol.h"

@interface NSString(mathSymbolExtension)
-(BOOL)isOperatorSymbol;
-(BOOL)isAlphaNumeric;
-(BOOL)isMathPrefixedSymbol;
-(BOOL)isMathBinaryCombiningSymbol;
@end

@implementation NSString(mathSymbolExtension)

-(BOOL)isOperatorSymbol
{
	NSArray* array = [[NSArray alloc] initWithObjects: @"=", nil];
	return [array containsObject: self];
}

-(BOOL)isAlphaNumeric
{
	NSString* regex = @"^[a-zA-Z0-9]*$|^\\.$";	//count alphanumeric plus a dot(.)
	NSPredicate* regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	return [regexTest evaluateWithObject: self];
}

-(BOOL)isMathPrefixedSymbol
{
	//The list will grow as we support more symbols
	NSArray* array = [[NSArray alloc] initWithObjects: @"∫", @"√", nil];
	return [array containsObject: self];
}

-(BOOL)isParanthesisSymbol
{
	NSArray* array = [[NSArray alloc] initWithObjects: @"(", @")", nil];
	return [array containsObject: self];
}

-(BOOL)isMathBinaryCombiningSymbol
{
	//The list will grow as we support more symbols
	NSArray* array = [[NSArray alloc] initWithObjects:@"^",@"/", @"+", @"-", @"*", @"÷", nil];
	return [array containsObject: self];
}

@end

@interface NTIMathInputExpressionModel()
-(NTIMathSymbol *)addMathNode: (NTIMathSymbol *)newNode on: (NTIMathSymbol *)currentNode;
-(NTIMathSymbol *)createMathSymbolForString: (NSString *)stringValue;
-(void)logCurrentAndRootSymbol;
@end

@implementation NTIMathInputExpressionModel
//@synthesize mathInputModel;

-(id)initWithMathSymbol:(NTIMathSymbol *)mathExpression
{
	self = [super init];
	if (self) {
		if (!mathExpression) {
			mathExpression = [[NTIMathPlaceholderSymbol alloc] init];
		}
		//self.mathInputModel = mathExpression;
		self->rootMathSymbol = mathExpression;
		self->currentMathSymbol = mathExpression;
		self->stackEquationTrees = [NSMutableArray array];
	}
	return self;
}

-(void)addMathSymbolForString: (NSString *)stringValue
{
	NTIMathSymbol* newSymbol = [self createMathSymbolForString:stringValue];
	if (!newSymbol) {
		return;
	}
	[self logCurrentAndRootSymbol];
	self->currentMathSymbol = [self addMathNode: newSymbol on: self->currentMathSymbol];
	[self logCurrentAndRootSymbol];
}

#pragma mark -- Handling and building the equation model
//Creating a new tree
-(NTIMathSymbol *)newMathSymbolTreeWithRoot: (NTIMathSymbol *)newRootSymbol 
								 firstChild: (NTIMathSymbol *)childSymbol
{
	if (!newRootSymbol) {
		NTIMathSymbol* placeHolder = [[NTIMathPlaceholderSymbol alloc] init];
		[self->stackEquationTrees addObject: self->rootMathSymbol];
		self->rootMathSymbol = placeHolder;
		return self->rootMathSymbol; //it's the current symbol as well.
	}
	else {
		if (childSymbol.parentMathSymbol) {
			NTIMathSymbol* parent = childSymbol.parentMathSymbol;
			if ([parent respondsToSelector: @selector(removeMathNode:)]) {
				//We remove it from its parent
				[parent performSelector: @selector(removeMathNode:) withObject: childSymbol];
				
				//Add current root to stack
				[self->stackEquationTrees addObject: self->rootMathSymbol];
				
				//Set new root 
				self->rootMathSymbol = newRootSymbol;
				
				//Add the childsymbol to new root
				return [self->rootMathSymbol addSymbol: childSymbol];
			}
		}
		else {
			//No parent
			//Set new root to be the root symbol
			self->rootMathSymbol = newRootSymbol;
			if ([newRootSymbol isKindOfClass: [NTIMathAlphaNumericSymbol class]]) {
				return self->rootMathSymbol;
			}
			
			//Add as first child the childsymbol
			return [self->rootMathSymbol addSymbol: childSymbol];
		}
	}
	return nil;
}

//We return the currentSymbol
-(NTIMathSymbol *)closeAndAppendTree
{
	//we make the parent the current symbol
//	if (self->currentMathSymbol.parentMathSymbol) {
//		NTIMathSymbol* newCurrentSymbol = self->currentMathSymbol.parentMathSymbol;
//		return newCurrentSymbol;
//	}
//	return nil;
	
	//Pop the top most item off the tree stack
	NTIMathSymbol* oldRootSymbol = [self->stackEquationTrees lastObject];
	if (oldRootSymbol) {
		//remove the last object 
		[self->stackEquationTrees removeLastObject];
		NTIMathSymbol* tempCurrentSymbol = self->rootMathSymbol;	//Because we are done adding things to this tree
		//We add the new rootMathSymbol to the tree.
		if (![oldRootSymbol addSymbol: self->rootMathSymbol]) {
			//if we can't add it, that means we could be a placeholder, in which case we would simple replace it
			if ([oldRootSymbol isKindOfClass: [NTIMathPlaceholderSymbol class]]) {
				oldRootSymbol = self->rootMathSymbol;
			}
		}
		self->rootMathSymbol = oldRootSymbol;
		//the current symbol should becomes the root symbol.
		return tempCurrentSymbol;
	}
	return  nil;
}

//We return the composed math symbol
-(NTIMathSymbol *)appendParentTreeTo: (NTIMathSymbol *)aRootSymbol
{
	NTIMathSymbol* oldRootSymbol = [self->stackEquationTrees lastObject];
	if (oldRootSymbol) {
		//We add the new rootMathSymbol to the tree.
		NTIMathSymbol* tempCurrent = [oldRootSymbol addSymbol: aRootSymbol];
		if (!tempCurrent) {
			//if we can't add it, that means we could be a placeholder, in which case we would simply be replaced.
			if ([oldRootSymbol isKindOfClass: [NTIMathPlaceholderSymbol class]]) {
				oldRootSymbol = aRootSymbol;
			}
		}
		//Remove the element from the stack tree
		[self->stackEquationTrees removeObject: oldRootSymbol];
		return oldRootSymbol;
	}
	return aRootSymbol;
}

-(NTIMathSymbol *)replacePlaceHolder: (NTIMathSymbol *)pholder withLiteral: (NTIMathSymbol *)literal
{
	if (![pholder isKindOfClass: [NTIMathPlaceholderSymbol class]] ||
		![literal isKindOfClass: [NTIMathAlphaNumericSymbol class]]) {
		return nil;
	}
	
	if (pholder.parentMathSymbol) {
		// Add literal to replace pholder
		return [pholder.parentMathSymbol addSymbol: literal];
	}
	else {
		//a pholder is the root element
		self->rootMathSymbol = literal;
		return literal;
	}
	return nil;
}

-(NTIMathSymbol *)addMathNode: (NTIMathSymbol *)newNode on: (NTIMathSymbol *)currentNode
{
	// Paranthesis
	if ([newNode respondsToSelector:@selector(openingParanthesis)]) {
		if( [newNode performSelector:@selector(openingParanthesis)] ) {
			//Make a new tree
			return [self newMathSymbolTreeWithRoot: nil firstChild: nil];
		}
		else {
			//close and append tree --> closing paranthesis
			return [self closeAndAppendTree];
		}
	}
	
	//See if we can append it
	if ([currentNode respondsToSelector: @selector(appendMathSymbol:)] && 
		[newNode isKindOfClass: [NTIMathAlphaNumericSymbol class]]) {
		return [currentNode performSelector:@selector(appendMathSymbol:) withObject: newNode];
	}
	
	//Replace pholder with literal.
	NTIMathSymbol* num = [self replacePlaceHolder: currentNode withLiteral: newNode];
	if (num) {
		return num;
	}
	
	//
	while ( currentNode.parentMathSymbol ) {
		// look ahead
		// Rule 1: if our parent's precedence is lower, we make a new tree at current.
		if ( [currentNode.parentMathSymbol precedenceLevel] < [newNode precedenceLevel] ) {		
			//Make new tree with currentNode as a childNode to newNode. Basically swapping them.
			return [self newMathSymbolTreeWithRoot: newNode firstChild: currentNode];		
		}
		// Rule 2: if our parent's precedence is higher or equal to the new node's precedence:
		//			move up ( repeat process )
		currentNode = currentNode.parentMathSymbol;
	}
	
	if (currentNode.parentMathSymbol == nil) {
		//Make a new tree with root as newNode
		return [self newMathSymbolTreeWithRoot: newNode firstChild: currentNode];
	}
	return nil;
}

-(NSString *)generateEquationString
{
	NSString* eqString;
	//We will start by appending things on the stack tree,
	for (NTIMathSymbol* m in self->stackEquationTrees) {
		eqString = [NSString stringWithFormat:@"%@%@", eqString, [m toString]];
	}
	//The current root last,
	if (!eqString) {
		eqString = [self->rootMathSymbol toString];
	}
	else {
		eqString =  [NSString stringWithFormat:@"%@%@", eqString, [self->rootMathSymbol toString]];
	}
	return eqString;
}

-(NTIMathSymbol *)fullEquation
{
	//Should we return the original or a copy?
	NTIMathSymbol* rootCopy = self->rootMathSymbol;
	if (!stackEquationTrees || stackEquationTrees.count == 0) {
		return self->rootMathSymbol;
	}
	
	NTIMathSymbol* composedRoot = rootCopy;
	for (NSUInteger i = 0;  i<=stackEquationTrees.count; i++) {
		composedRoot = [self appendParentTreeTo: composedRoot];
	}
	
	//set new root
	self->rootMathSymbol = composedRoot;
	return composedRoot;
}

-(void)setCurrentSymbolTo: (NTIMathSymbol *)mathSymbol
{
	//Needs to be implemented better. go through the math expression tree to find our node
	self->currentMathSymbol = [self newMathSymbolTreeWithRoot:nil firstChild: mathSymbol]; 
	//self->currentMathSymbol = mathSymbol;
}

-(void)clearEquation
{
	NTIMathSymbol* pholder = [[NTIMathPlaceholderSymbol alloc] init];
	self->rootMathSymbol= pholder;
	self->currentMathSymbol = pholder;
	[self->stackEquationTrees removeAllObjects];
}

//Override property
-(NTIMathSymbol *)mathInputModel
{
	return [self fullEquation];
}

#pragma mark - Building on a mathSymbol
-(NTIMathSymbol *)createMathSymbolForString: (NSString *)stringValue
{	
	if ( [stringValue isAlphaNumeric] ) {
		return [[NTIMathAlphaNumericSymbol alloc] initWithValue: stringValue];
	}
	if ( [stringValue isOperatorSymbol] ) {
		return [[NTIMathOperatorSymbol alloc] initWithValue: stringValue];
	}
	if ( [stringValue isParanthesisSymbol] ) {
		return [[NTIMathParenthesisSymbol alloc] initWithMathSymbolString: stringValue];
	}
	if ( [stringValue isMathPrefixedSymbol] ) {
		return [[NTIMathPrefixedSymbol alloc] initWithMathOperatorString: stringValue];
	}
	if ( [stringValue isMathBinaryCombiningSymbol] ) {
		if ([stringValue isEqualToString:@"^"]) {
			return [[NTIMathExponentCombiningBinarySymbol alloc] init];
		}
		if ([stringValue isEqualToString: @"x/y"]) {
			return [[NTIMathFractionCombiningBinarySymbol alloc] init];
		}
		return [[NTIMathAbstractBinaryCombiningSymbol alloc] initWithMathOperatorSymbol: stringValue];
	}
	return nil;
}

-(void)logCurrentAndRootSymbol
{
	NSLog(@"root's string: %@,\ncurrentSymbol's string: %@", [self->rootMathSymbol toString], [self->currentMathSymbol toString]);
}
@end
