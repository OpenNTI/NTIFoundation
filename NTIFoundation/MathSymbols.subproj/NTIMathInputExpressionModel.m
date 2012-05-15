//
//  NTIMathInputExpressionModel.m
//  NTIFoundation
//
//  Created by  on 4/26/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathInputExpressionModel.h"
#import "NTIMathSymbol.h"
#import "NTIMathBinaryExpression.h"
#import "NTIMathUnaryExpression.h"
#import "NTIMathPlaceholderSymbol.h"
#import "NTIMathAlphaNumericSymbol.h"
#import "NTIMathOperatorSymbol.h"
#import "NTIMathExponentBinaryExpression.h"
#import "NTIMathParenthesisSymbol.h"
#import "NTIMathFractionBinaryExpression.h"
#import "NTIMathSymbolUtils.h"

@interface NSString(mathSymbolExtension)
-(BOOL)isOperatorSymbol;
-(BOOL)isAlphaNumeric;
-(BOOL)isMathPrefixedSymbol;
-(BOOL)isMathBinaryCombiningSymbol;
@end

@implementation NSString(mathSymbolExtension)

-(BOOL)isOperatorSymbol
{
	//NSArray* array = [[NSArray alloc] initWithObjects: @"=", nil];
	return NO; // [array containsObject: self];
}

-(BOOL)isAlphaNumeric
{
	if ([self isEqualToString:@"∏"] || [self isEqualToString:@"π"]) {
		return YES;
	}
	NSString* regex = @"^[a-zA-Z0-9]*$|^\\.$";	//count alphanumeric plus a dot(.)
	NSPredicate* regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	return [regexTest evaluateWithObject: self];
}

-(BOOL)isMathPrefixedSymbol
{
	//The list will grow as we support more symbols
	NSArray* array = [[NSArray alloc] initWithObjects: @"√", @"≈", nil];
	return [array containsObject: self];
}

-(BOOL)isParanthesisSymbol
{
	NSArray* array = [[NSArray alloc] initWithObjects: @"(", @")", nil];
	return [array containsObject: self];
}

-(BOOL)isPlusMinusSymbol
{
	return [self isEqualToString: @"+/-"];
}

-(BOOL)isMathBinaryCombiningSymbol
{
	//The list will grow as we support more symbols
	NSArray* array = [[NSArray alloc] initWithObjects:@"^",@"/", @"+", @"-", @"*", @"÷", @"x/y", @"=", nil];
	return [array containsObject: self];
}

@end

//NOTE: we decided to wrap an object around an nsmutableArray mainly to ensure that everywhere the mathExpressionStack is handled as stack, and thus limit possibility of getting into a bad state if things are inserted out of order. 
@interface NTIMathExpressionStack : NSObject {
@private
    NSMutableArray* _mathStack; 
}

-(void)push: (NTIMathSymbol *)aMathSymbol;
-(NTIMathSymbol *)pop;
-(NTIMathSymbol *)lastMathExpression;
-(NSUInteger)count;
-(NSArray *)stack;
-(void)removeAll;
@end

@implementation NTIMathExpressionStack

-(id)init 
{
	self = [super init];
	if (self) {
		_mathStack = [NSMutableArray array]; 
	}
	return self;
}

-(void)push:(NTIMathSymbol *)aMathSymbol
{
	//TODO: eventually we will get to a point where we test if a math symbol is an expression or not.
	[_mathStack addObject: aMathSymbol];
	NSLog(@"Pushed onto Stack: %@", aMathSymbol.toString);
}

-(NTIMathSymbol *)pop
{
	if (_mathStack.count == 0) {
		return nil;
	}
	NTIMathSymbol* lastObj = [_mathStack lastObject];
	[_mathStack removeLastObject];
	NSLog(@"Popped from Stack: %@", lastObj.toString);
	return lastObj;
}

-(NSUInteger)count
{
	return _mathStack.count;
}

-(NSArray *)stack
{
	return _mathStack;
}

-(NTIMathSymbol *)lastMathExpression
{
	return [_mathStack lastObject];
}

-(void)removeAll
{
	[_mathStack removeAllObjects];
}
@end

@interface NTIMathInputExpressionModel()
-(NTIMathSymbol *)addMathNode: (NTIMathSymbol *)newNode on: (NTIMathSymbol *)currentNode;
-(NTIMathSymbol *)createMathSymbolForString: (NSString *)stringValue;
-(void)logCurrentAndRootSymbol;
-(NTIMathSymbol *)closeAndAppendTree;
-(NTIMathSymbol *)newMathSymbolTreeWithRoot: (NTIMathSymbol *)newRootSymbol 
								 firstChild: (NTIMathSymbol *)childSymbol;
@end

@class NTIMathExpressionReverseTraversal;
@implementation NTIMathInputExpressionModel
@synthesize rootMathSymbol;
-(id)initWithMathSymbol:(NTIMathSymbol *)mathExpression
{
	self = [super init];
	if (self) {
		if (!mathExpression) {
			mathExpression = [[NTIMathPlaceholderSymbol alloc] init];
		}
		self.rootMathSymbol = mathExpression;
		self->currentMathSymbol = mathExpression;
		self->mathExpressionQueue = [[NTIMathExpressionStack alloc] init];
	}
	return self;
}

-(void)setRootMathSymbol:(NTIMathSymbol *)theRootMathSymbol
{
	self->rootMathSymbol = theRootMathSymbol;
	self->rootMathSymbol.parentMathSymbol = nil;
}

-(void)addMathSymbolForString: (NSString *)stringValue
{
	if ([stringValue isPlusMinusSymbol]) {
		if ([self->currentMathSymbol respondsToSelector:@selector(isLiteral)]) {
			[(NTIMathAlphaNumericSymbol *)self->currentMathSymbol setIsNegative: YES];
			return;
		}
	}
	
	NTIMathSymbol* newSymbol = [self createMathSymbolForString:stringValue];
	if (!newSymbol) {
		return;
	}
	//NOTE: As the user navigates through the equation, the may want to insert things in between, we need to be able to distinguish inserting in the equation and adding to the end of the rootsymbol. The easy way if comparing the currentSymbol with the last leaf node of the rootSymbol, if they differ, we are inserting, else we are are adding to the end of the equation
	if (self->currentMathSymbol != [self findLastLeafNodeFrom: self.rootMathSymbol]) {
		//[self setCurrentSymbolTo: self->currentMathSymbol];	// we create a new tree at the current symbol to allow inserting into the equation.
		//Before we create a new tree at the new current symbol, we will close the tree that we were working on.
		self.rootMathSymbol = [self mergeLastTreeOnStackWith: self.rootMathSymbol];
		self->currentMathSymbol = [self newMathSymbolTreeWithRoot:self->currentMathSymbol firstChild: nil]; 
	}
	//Check if it's a special case of implicit multiplication. In which case, we will need to add
	if ([self->currentMathSymbol respondsToSelector:@selector(isLiteral)] && [newSymbol respondsToSelector:@selector(isUnaryOperator)]) {
		NTIMathSymbol* implicitSymbol = [self createMathSymbolForString:@"*"];
		self->currentMathSymbol = [self addMathNode:implicitSymbol on: self->currentMathSymbol];
	}
	self->currentMathSymbol = [self addMathNode: newSymbol on: self->currentMathSymbol];
}

-(void)makeExpression: (NTIMathPlaceholderSymbol *)aPlaceholder representExpression: (NTIMathSymbol *)mathSymbol 
{
	if (![(id)aPlaceholder respondsToSelector: @selector(isPlaceholder)]) {
		return;
	}
	aPlaceholder.inPlaceOfObject = mathSymbol;
	mathSymbol.substituteSymbol = aPlaceholder;
}

#pragma mark -- Handling and building the equation model
//Creating a new tree
-(NTIMathSymbol *)newMathSymbolTreeWithRoot: (NTIMathSymbol *)newRootSymbol 
								 firstChild: (NTIMathSymbol *)childSymbol
{
	//This a special case when a user clicks on an element of the tree, we start a new tree at that element, and we set it as a root element. No child at this point.
	if (newRootSymbol && !childSymbol) {
		NTIMathSymbol* parent = newRootSymbol.parentMathSymbol;
		if ([parent respondsToSelector: @selector(replaceNode:  withPlaceholderFor:)]) {
			//We remove it from its parent
			[parent performSelector: @selector(replaceNode:  withPlaceholderFor:) withObject: newRootSymbol withObject: newRootSymbol];
			//Add current root to stack
			[self->mathExpressionQueue push: self.rootMathSymbol];
			//Set new root 
			self.rootMathSymbol = newRootSymbol;
			//Add the childsymbol to new root
			return self.rootMathSymbol;
		}
		if (!parent) {
			//Odd case, we want to create a new tree at the new root symbol, and we are root already, so no need for a new tree.
			return newRootSymbol;
		}
	}	
	if (childSymbol.parentMathSymbol) {
		NTIMathSymbol* parent = childSymbol.parentMathSymbol;
		if ([parent respondsToSelector: @selector(replaceNode:  withPlaceholderFor:)]) {
			//We remove it from its parent
			[parent performSelector: @selector(replaceNode:  withPlaceholderFor:) withObject: childSymbol withObject: newRootSymbol];
			//Add current root to stack
			[self->mathExpressionQueue push: self.rootMathSymbol];
			
			//Set new root 
			self.rootMathSymbol = newRootSymbol;
			//Add the childsymbol to new root
			return [self.rootMathSymbol addSymbol: childSymbol];
		}
	}
	else {
		//No parent
		//Set new root to be the root symbol
		//If there is anyone pointing to the new root( a delegate symbol), then it needs to be updated
		if (self.rootMathSymbol.substituteSymbol) {
			NTIMathSymbol* pointer = self.rootMathSymbol.substituteSymbol;
			if ([pointer respondsToSelector:@selector(isPlaceholder)]) {
				OBASSERT([(NTIMathPlaceholderSymbol *)pointer inPlaceOfObject] == self.rootMathSymbol);
				//Update the new
				[(NTIMathPlaceholderSymbol *)pointer setInPlaceOfObject: newRootSymbol];
				newRootSymbol.substituteSymbol = pointer;
			}
		}
		self.rootMathSymbol = newRootSymbol;
		
		if ([newRootSymbol respondsToSelector:@selector(isLiteral)]) {
			return self.rootMathSymbol;
		}
		
		//Add as first child the childsymbol
		return [self.rootMathSymbol addSymbol: childSymbol];
	}
	return nil;
}

-(NTIMathSymbol *)findRootOfMathNode: (NTIMathSymbol *)mathSymbol
{
	while (mathSymbol.parentMathSymbol) {
		mathSymbol = mathSymbol.parentMathSymbol;
	}
	return mathSymbol;
}

//We return the currentSymbol
-(NTIMathSymbol *)closeAndAppendTree
{
	NTIMathSymbol* tempCurrentSymbol = self.rootMathSymbol;
	self.rootMathSymbol = [self mergeLastTreeOnStackWith: self.rootMathSymbol];
	return tempCurrentSymbol;
}

-(NTIMathSymbol *)mergeLastTreeOnStackWith: (NTIMathSymbol *)mathSymbol
{
	if (self->mathExpressionQueue.count == 0) {
		return mathSymbol;
	}
	
	//Pop last object 
	NTIMathSymbol* combinedTree = [self->mathExpressionQueue pop];
	NTIMathPlaceholderSymbol* plink = (NTIMathPlaceholderSymbol *)mathSymbol.substituteSymbol;
	OBASSERT( plink.inPlaceOfObject == mathSymbol );
	//combined both tree, and get a notification if it fails.
	if ([plink.parentMathSymbol addSymbol: mathSymbol]) {
		return combinedTree;
	}
	else {
		//FIXME: What should happen in case the last expression on stack doesn't have a parent? or can't add our symbol?
		return mathSymbol;
	}
}

-(NTIMathSymbol *)replacePlaceHolder: (NTIMathSymbol *)pholder withLiteral: (NTIMathSymbol *)literal
{
	if (![pholder respondsToSelector:@selector(isPlaceholder)] ||
		![literal respondsToSelector:@selector(isLiteral)]) {
		return nil;
	}
	if (pholder.parentMathSymbol) {
		// Add literal to replace pholder
		return [pholder.parentMathSymbol addSymbol: literal];
	}
	else {
		//a pholder is the root element, needs to update who is pointing to us.
 		self.rootMathSymbol = literal;
		
		if (self->mathExpressionQueue.count > 0) {
			NTIMathPlaceholderSymbol* linker = (NTIMathPlaceholderSymbol *)pholder.substituteSymbol;
			[self makeExpression: linker representExpression: self.rootMathSymbol];
		}
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
			return [self newMathSymbolTreeWithRoot: currentNode firstChild: nil];
		}
		else {
			//close and append tree --> closing paranthesis
			return [self closeAndAppendTree];
		}
	}
	
	//See if we can append it
	if ([currentNode respondsToSelector: @selector(appendMathSymbol:)] && 
		[newNode respondsToSelector:@selector(isLiteral)]) {
		return [currentNode performSelector:@selector(appendMathSymbol:) withObject: newNode];
	}
	
	//Replace pholder with literal.
	NTIMathSymbol* num = [self replacePlaceHolder: currentNode withLiteral: newNode];
	if (num) {
		return num;
	}
	
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
	return [[self fullEquation] toString];
}

-(NTIMathSymbol *)fullEquation
{
	if (!mathExpressionQueue || mathExpressionQueue.count == 0) {
		return self.rootMathSymbol;
	}
	//First element is the root of all our roots
	return [[self->mathExpressionQueue stack] objectAtIndex: 0];
}

//this method gets called, when a user clicks on a leaf node( i.e literal button, placeholder button), at that point we create a new tree at the location.
-(void)setCurrentSymbolTo: (NTIMathSymbol *)mathSymbol
{
	//If we are the current symbol already, and you click on it, don't do anything.
	if (mathSymbol == self->currentMathSymbol && ![self.rootMathSymbol respondsToSelector:@selector(isUnaryOperator)]) {
		return;
	}
	//Before we create a new tree at the new current symbol, we will close the tree that we were working on.
	//if (![self.rootMathSymbol respondsToSelector:@selector(isUnaryOperator)]) {
		self.rootMathSymbol = [self mergeLastTreeOnStackWith: self.rootMathSymbol];
	//}
	self->currentMathSymbol = [self newMathSymbolTreeWithRoot:mathSymbol firstChild: nil]; 
}

//Returns the current symbol mainly for rendering purposes
-(NTIMathSymbol *)currentMathSymbol
{
	return self->currentMathSymbol;
}

-(void)clearEquation
{
	NTIMathSymbol* pholder = [[NTIMathPlaceholderSymbol alloc] init];
	self.rootMathSymbol= pholder;
	self->currentMathSymbol = pholder;
	[self->mathExpressionQueue removeAll];
}

//Return new current
-(NTIMathSymbol *)switchTotreeInplaceOfPlaceholder: (NTIMathSymbol *)aMathSymbol;
{
	if ([aMathSymbol respondsToSelector:@selector(isPlaceholder)] && self.rootMathSymbol == aMathSymbol && self->mathExpressionQueue.count > 0) {
		//We will pop the last tree off the stackTree
		self.rootMathSymbol = [self->mathExpressionQueue pop];
		//Now we are ready to switch to our substitute symbol.
		NTIMathSymbol* newCurrent = aMathSymbol.substituteSymbol;
		if (newCurrent) {
			[(NTIMathPlaceholderSymbol *)newCurrent setInPlaceOfObject: nil];
		}
		return newCurrent;
	}
	return aMathSymbol;
}

-(NTIMathSymbol *)deleteMathSymbol: (NTIMathSymbol *)mathNode
{
	if ([mathNode respondsToSelector:@selector(isLiteral)]) {
		NTIMathSymbol* newCurrentNode = [(NTIMathAlphaNumericSymbol *)mathNode deleteLastLiteral];
		if (newCurrentNode) {
			return newCurrentNode;
		}
	}
	NTIMathExpressionReverseTraversal* tree = [[NTIMathExpressionReverseTraversal alloc] initWithRoot: self.rootMathSymbol selectedNode: mathNode];
	[tree deleteCurrentNode];
	NSString* newEquationString = [tree newEquationString];
	 
	NTIMathSymbol* oldRootSymbol = self->rootMathSymbol;
	
	//Regenerate the current tree.
	self.rootMathSymbol = [[NTIMathPlaceholderSymbol alloc] init];
	self->currentMathSymbol = self.rootMathSymbol;
	for (NSUInteger i=0; i<newEquationString.length; i++) {
		NSString* symbolString = [newEquationString substringWithRange: NSMakeRange(i, 1)];	
		//Add the mathSymbol to the equation
		[self addMathSymbolForString: symbolString];
	}
	
	//Update pointers, 
	self.rootMathSymbol.substituteSymbol = oldRootSymbol.substituteSymbol;
	NTIMathPlaceholderSymbol* placeholder = (NTIMathPlaceholderSymbol *)oldRootSymbol.substituteSymbol;
	if (placeholder) {
		placeholder.inPlaceOfObject = self.rootMathSymbol;
	}
	
	//when we are a placeholder at this point and someone is pointing to us, we will switch to the last tree. This is eventually how we will move from a subtree to a parent tree
	if ([self.rootMathSymbol respondsToSelector:@selector(isPlaceholder)]) {
		self->currentMathSymbol = [self switchTotreeInplaceOfPlaceholder: self.rootMathSymbol];
	}
	
	return self->currentMathSymbol;
}

-(void)deleteMathExpression: (NTIMathSymbol *)aMathSymbol
{
	if (!aMathSymbol) {
		//if nothing is selected, we assume the user wants to delete the current symbol
		aMathSymbol = self->currentMathSymbol;
	}
	self->currentMathSymbol = [self deleteMathSymbol: aMathSymbol];
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

-(NTIMathSymbol *)findFirstLeafNodeFrom: (NTIMathSymbol *)mathSymbol
{
	if ([mathSymbol respondsToSelector:@selector(isPlaceholder)] ||
		[mathSymbol respondsToSelector:@selector(isLiteral) ]) {
		return mathSymbol;
	}
	else {
		if ([mathSymbol respondsToSelector:@selector(isBinaryOperator)]) {
			NTIMathBinaryExpression* bMathSymbol = (NTIMathBinaryExpression *)mathSymbol;
			return [self findFirstLeafNodeFrom: bMathSymbol.leftMathNode];
		}
		if ([mathSymbol respondsToSelector:@selector(isUnaryOperator)]) {
			NTIMathUnaryExpression* uMathSymbol = (NTIMathUnaryExpression *)mathSymbol;
			return [self findFirstLeafNodeFrom: uMathSymbol.childMathNode];
		}
		return nil;
	}
}

-(NSString *)tolaTex
{
	return [[self fullEquation] latexValue];
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
		return [[NTIMathUnaryExpression alloc] initWithMathOperatorString: stringValue];
	}
	if ( [stringValue isMathBinaryCombiningSymbol] ) {
		if ([stringValue isEqualToString:@"^"]) {
			return [[NTIMathExponentBinaryExpression alloc] init];
		}
		if ([stringValue isEqualToString: @"x/y"] || [stringValue isEqualToString:@"÷"]) {
			return [[NTIMathFractionBinaryExpression alloc] init];
		}
		return [[NTIMathBinaryExpression alloc] initWithMathOperatorSymbol: stringValue];
	}
	return nil;
}

-(void)logCurrentAndRootSymbol
{
	NSLog(@"root's string: %@,\ncurrentSymbol's string: %@", [self.rootMathSymbol toString], [self->currentMathSymbol toString]);
}

@end
