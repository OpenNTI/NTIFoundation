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
	NSArray* array = [[NSArray alloc] initWithObjects:@"^",@"/", @"+", @"-", @"*", @"÷", @"x/y", nil];
	return [array containsObject: self];
}

@end

@interface NTIMathInputExpressionModel()
-(NTIMathSymbol *)addMathNode: (NTIMathSymbol *)newNode on: (NTIMathSymbol *)currentNode;
-(NTIMathSymbol *)createMathSymbolForString: (NSString *)stringValue;
-(void)logCurrentAndRootSymbol;
-(NTIMathSymbol *)closeAndAppendTree;

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
#if 0
	[self logCurrentAndRootSymbol];
#endif
	//Check if it's a special case of implicit multiplication. In which case, we will need to add
	if ([self->currentMathSymbol isKindOfClass:[NTIMathAlphaNumericSymbol class]] && [newSymbol isKindOfClass: [NTIMathPrefixedSymbol class]]) {
		NTIMathSymbol* implicitSymbol = [self createMathSymbolForString:@"*"];
		self->currentMathSymbol = [self addMathNode:implicitSymbol on: self->currentMathSymbol];
	}
	self->currentMathSymbol = [self addMathNode: newSymbol on: self->currentMathSymbol];
#if 0
	[self logCurrentAndRootSymbol];
#endif
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
		//This a special case when a user clicks on an element of the tree, we start a new tree at that element, and we set it as a root element. No child at this point.
		if (newRootSymbol && !childSymbol) {
			NTIMathSymbol* parent = newRootSymbol.parentMathSymbol;
			if ([parent respondsToSelector: @selector(replaceNode:  withPlaceholderFor:)]) {
				//We remove it from its parent
				[parent performSelector: @selector(replaceNode:  withPlaceholderFor:) withObject: newRootSymbol withObject: newRootSymbol];
				//Add current root to stack
				[self->stackEquationTrees addObject: self->rootMathSymbol];
				//Set new root 
				self->rootMathSymbol = newRootSymbol;
				self->rootMathSymbol.parentMathSymbol = nil;
				//Add the childsymbol to new root
				return self->rootMathSymbol;
			}
		}	
		if (childSymbol.parentMathSymbol) {
			NTIMathSymbol* parent = childSymbol.parentMathSymbol;
			if ([parent respondsToSelector: @selector(replaceNode:  withPlaceholderFor:)]) {
				//We remove it from its parent
				[parent performSelector: @selector(replaceNode:  withPlaceholderFor:) withObject: childSymbol withObject: newRootSymbol];
				//Add current root to stack
				[self->stackEquationTrees addObject: self->rootMathSymbol];
				
				//Set new root 
				self->rootMathSymbol = newRootSymbol;
				//self->rootMathSymbol.parentMathSymbol = nil;
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

-(NTIMathSymbol *)findRootOfMathNode: (NTIMathSymbol *)mathSymbol
{
	while (mathSymbol.parentMathSymbol) {
		mathSymbol = mathSymbol.parentMathSymbol;
	}
	return mathSymbol;
}

//We want to traverse the tree from the top to bottom.
-(void)addPlaceholdersTo: (NSMutableArray *)placeholders startingAt: (NTIMathSymbol *)aRootNode
{
	if (!aRootNode) {
		return;
	}
	if (!aRootNode.children) {
		if ( [aRootNode isKindOfClass:[NTIMathPlaceholderSymbol class]] && 
			[(NTIMathPlaceholderSymbol *)aRootNode inPlaceOfObject] ) {
			[placeholders addObject: aRootNode];
		}
		return;
	}
	
	for (NTIMathSymbol* child in aRootNode.children) {
		if ( [child isKindOfClass:[NTIMathPlaceholderSymbol class]] && 
			[(NTIMathPlaceholderSymbol *)child inPlaceOfObject] ) {
			[placeholders addObject: child];
		}
		[self addPlaceholdersTo: placeholders startingAt: child];
	}
}

//We return the currentSymbol
-(NTIMathSymbol *)closeAndAppendTree
{	
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
	if (!stackEquationTrees || stackEquationTrees.count == 0) {
		return self->rootMathSymbol;
	}
	NTIMathSymbol* oldRootSymbol;
	for (int i = stackEquationTrees.count-1;  i>= 0; i--) {
		//Update plaholders pointing to math expressions( trees)
		oldRootSymbol = [self->stackEquationTrees objectAtIndex:i];
		NSMutableArray* placeholders = [NSMutableArray array];
		[self addPlaceholdersTo: placeholders startingAt: oldRootSymbol];
		for (NTIMathPlaceholderSymbol* pholder in placeholders) {
			//The logic is that as we add things, the root changes and we need to know we need to update the pointer of the placeholder to the new root.
			NTIMathSymbol* replacedExpression= [pholder inPlaceOfObject];
			if (replacedExpression) {
				pholder.inPlaceOfObject = [self findRootOfMathNode: replacedExpression];
			}
		}
	}
	return oldRootSymbol;
}

-(void)setCurrentSymbolTo: (NTIMathSymbol *)mathSymbol
{
	//Needs to be implemented better. go through the math expression tree to find our node
	self->currentMathSymbol = [self newMathSymbolTreeWithRoot:mathSymbol firstChild: nil]; 
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
