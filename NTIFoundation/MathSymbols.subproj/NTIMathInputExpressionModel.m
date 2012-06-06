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
-(BOOL)isPlusMinusSymbol;
-(BOOL)isClosingParanthesisSymbol;
-(BOOL)isSubtractionSymbol;
@end

@implementation NSString(mathSymbolExtension)

-(BOOL)isOperatorSymbol
{
	//NSArray* array = [[NSArray alloc] initWithObjects: @"=", nil];
	return NO; // [array containsObject: self];
}

-(BOOL)isAlphaNumeric
{
	//alpha numeric is anything that isn't another type
	return	   ![self isMathPrefixedSymbol] 
			&& ![self isClosingParanthesisSymbol] 
			&& ![self isPlusMinusSymbol] 
			&& ![self isMathBinaryCombiningSymbol];
}

-(BOOL)isMathPrefixedSymbol
{
	//The list will grow as we support more symbols
	NSArray* array = [[NSArray alloc] initWithObjects: @"√", @"(", @"( )", nil];
	return [array containsObject: self];
}

-(BOOL)isClosingParanthesisSymbol
{
	//We need to figure out how to handle closing paranthesis )
	//NSArray* array = [[NSArray alloc] initWithObjects: @"(", @"( )", nil];
	//return [array containsObject: self];
	return [self isEqualToString:@")"];
}

-(BOOL)isPlusMinusSymbol
{
	return [self isEqualToString: @"+/-"];
}

-(BOOL)isMathBinaryCombiningSymbol
{
	//The list will grow as we support more symbols
	NSArray* array = [[NSArray alloc] initWithObjects:@"^",@"/", @"+", @"-", @"*", @"÷", @"x/y", @"=", @"≈", nil];
	return [array containsObject: self];
}

-(BOOL)isSubtractionSymbol
{
	return [self isEqualToString: @"-"];
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
-(BOOL)removeMathExpression: (NTIMathSymbol *)root;
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
	if (!aMathSymbol) {
		return;
	}
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

-(BOOL)removeMathExpression: (NTIMathSymbol *)root
{
	if ([_mathStack containsObject: root]) {
		[_mathStack removeObject: root];
		return YES;
	}
	return NO;
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
@property (nonatomic, strong) NTIMathSymbol* currentMathSymbol;
-(void)connectSubtreesUnderneathTree: (NTIMathSymbol *)mathsymbol;
@end

@class NTIMathExpressionReverseTraversal;
@implementation NTIMathInputExpressionModel
@synthesize rootMathSymbol, fullEquation;
@dynamic currentMathSymbol;

-(id)initWithMathSymbol:(NTIMathSymbol *)mathExpression
{
	self = [super init];
	if (self) {
		if (!mathExpression) {
			mathExpression = [[NTIMathPlaceholderSymbol alloc] init];
		}
		self->fullEquation = self.rootMathSymbol;
		self.currentMathSymbol = mathExpression;
		self->mathExpressionQueue = [[NTIMathExpressionStack alloc] init];
	}
	return self;
}

-(NTIMathSymbol*)currentMathSymbol
{
	return self->currentMathSymbol;
}

-(void)setCurrentMathSymbol: (NTIMathSymbol *)symbol
{
	if(symbol == self.currentMathSymbol){
		return;
	}
	
	NTIMathSymbol* root = symbol;
	while(root.parentMathSymbol){
		root = root.parentMathSymbol;
	}
	self.rootMathSymbol = root;
	
	self->currentMathSymbol = symbol;
}

-(void)setRootMathSymbol: (NTIMathSymbol *)theRootMathSymbol
{
	if(self->rootMathSymbol == theRootMathSymbol){
		return;
	}
	
	// FIXME: we get into a problem, when the new rootMathSymbol is part of the stack but it's not the last expression on queue. Normally, we shouldn't check the last one only, we should try to connect every root beneath the the new root. 
//	if( [[self->mathExpressionQueue lastMathExpression] isEqual: theRootMathSymbol] ){
//		theRootMathSymbol = [self mergeLastTreeOnStackWith: self->rootMathSymbol];
//	}
	[self connectSubtreesUnderneathTree: theRootMathSymbol];
	self->rootMathSymbol = theRootMathSymbol;
	self->rootMathSymbol.parentMathSymbol = nil;
}

static BOOL isImplicitSymbol(NTIMathSymbol* currentNode, NTIMathSymbol* newNode, NSString* senderType)
{
	if ([senderType isEqualToString: kNTIMathGraphicKeyboardInput]) {
		//Implicit addition. e.g 2 1/3 is equivalent to 2+1/3. Mixed number case.
		if ([currentNode respondsToSelector:@selector(isLiteral)] && [newNode isKindOfClass:[NTIMathFractionBinaryExpression class]]) {
			return YES;
		}
	}
	else {
		//specific for textfield input
		if ([currentNode respondsToSelector:@selector(isLiteral)] && [newNode respondsToSelector:@selector(isLiteral)] && [[(NTIMathAlphaNumericSymbol *)newNode mathSymbolValue] isEqualToString: @" "]) {
			return YES;
		}
	}
	//Implicit multiplication
	if ([currentNode respondsToSelector:@selector(isLiteral)] && [newNode respondsToSelector:@selector(isUnaryOperator)]) {
		return YES;
	}

	//FIXME: HACK, edge case where we end up with a leaf node at the top.
	if (([currentNode respondsToSelector:@selector(isBinaryOperator)] || [currentNode respondsToSelector:@selector( isUnaryOperator)]) && [newNode respondsToSelector:@selector(isLiteral)] ) {
		return YES;
	}
	return NO;
}

-(void)addImplicitSymbolBetween: (NTIMathSymbol *)currentNode 
				   andNewSymbol: (NTIMathSymbol *)newNode 
					 senderType: (NSString *)senderType
{
	if ([currentNode respondsToSelector:@selector(isLiteral)] && [newNode respondsToSelector:@selector(isUnaryOperator)]) {
		NTIMathBinaryExpression* implicitSymbol = [NTIMathBinaryExpression binaryExpressionForString:@"*"];
		implicitSymbol.isOperatorImplicit = YES;	
		self.currentMathSymbol = [self addMathNode:implicitSymbol on: currentNode];
	}
	
	//FIXME: HACK, edge case where we end up with a leaf node(literal) at the top, we add an implicit multiplication
	if (([currentNode respondsToSelector:@selector(isBinaryOperator)] || [currentNode respondsToSelector:@selector( isUnaryOperator)]) && [newNode respondsToSelector:@selector(isLiteral)] ) {
		NTIMathBinaryExpression* implicitSymbol = [NTIMathBinaryExpression binaryExpressionForString:@"*"];
		implicitSymbol.isOperatorImplicit = YES;	
		self.currentMathSymbol = [self addMathNode:implicitSymbol on: currentNode];
	}
	
	//Implicit addition. e.g 2 1/3 is equivalent to 2+1/3. Mixed number case.
	if ([senderType isEqualToString: kNTIMathGraphicKeyboardInput]) {
		if ([currentNode respondsToSelector:@selector(isLiteral)] && [newNode isKindOfClass:[NTIMathFractionBinaryExpression class]]) {
			NTIMathBinaryExpression* implicitSymbol = [NTIMathBinaryExpression binaryExpressionForString:@"+"];
			implicitSymbol.isOperatorImplicit = YES;	//Set the flag for implicit binary symbol
			implicitSymbol.implicitForSymbol = newNode;
			self.currentMathSymbol = [self addMathNode:implicitSymbol on: self.currentMathSymbol];
		}
	}
	else {
		//Implicit addition with textfield input
		if ([currentNode respondsToSelector:@selector(isLiteral)] && [newNode respondsToSelector:@selector(isLiteral)] && [[(NTIMathAlphaNumericSymbol *)newNode mathSymbolValue] isEqualToString: @" "]) {
			NTIMathBinaryExpression* implicitSymbol = [NTIMathBinaryExpression binaryExpressionForString:@"+"];
			implicitSymbol.isOperatorImplicit = YES;	//Set the flag for implicit binary symbol
			implicitSymbol.implicitForSymbol = newNode;
			self.currentMathSymbol = [self addMathNode:implicitSymbol on: self.currentMathSymbol];
		}
	}
}

-(BOOL)isLeafMathNode: (NTIMathSymbol *)mathNode
{
	if ([mathNode respondsToSelector:@selector(isPlaceholder)] || [mathNode respondsToSelector:@selector(isLiteral)]) {
		return YES;
	}
	return NO;
}

-(void)createTreeWithRoot: (NTIMathSymbol *)mathSymbol
{
	//Close last tree and create a new one
	self.rootMathSymbol = [self mergeLastTreeOnStackWith: self.rootMathSymbol];
	self.currentMathSymbol = [self newMathSymbolTreeWithRoot:mathSymbol firstChild: nil]; 
}


-(void)addMathExpression: (NTIMathSymbol *)newSymbol senderType: (NSString *)senderType
{
	if ([senderType isEqualToString: kNTIMathGraphicKeyboardInput]) {
		//FIXME: #HACK: we want to create a new tree under certain symbol to match user expectations. Needs to be done a better way.
		if ( ([self.currentMathSymbol.parentMathSymbol isKindOfClass:[NTIMathSquareRootUnaryExpression class]] 
				|| [self.currentMathSymbol.parentMathSymbol isKindOfClass: [NTIMathDivisionBinaryExpression class]]) ){
			[self createTreeWithRoot: self.currentMathSymbol];
		}
		//NOTE: As the user navigates through the equation, the may want to insert things in between, we need to be able to distinguish inserting in the equation and adding to the end of the rootsymbol. The easy way if comparing the currentSymbol with the last leaf node of the rootSymbol, if they differ, we are inserting, else we are are adding to the end of the equation
		if (   self.currentMathSymbol != [self findLastLeafNodeFrom: self.rootMathSymbol] ) {
			//Before we create a new tree at the new current symbol, we will close the tree that we were working on.
			[self createTreeWithRoot: self.currentMathSymbol];
		}
	}
	
	//If our parent is a parenthesis we create a new tree, regardless of the sender. This ensures that we stay in the parenthesis.
	if (   [self isLeafMathNode: self.currentMathSymbol] 
		&& [currentMathSymbol.parentMathSymbol isKindOfClass: [NTIMathParenthesisSymbol class]]) {
		self.currentMathSymbol = [self newMathSymbolTreeWithRoot: self.currentMathSymbol firstChild: nil];
	}
	
	if ([self isLeafMathNode: self.currentMathSymbol] 
		&& [self.currentMathSymbol.parentMathSymbolFollowingLinks isKindOfClass:[NTIMathSquareRootUnaryExpression class]]
		&& [newSymbol isKindOfClass: [NTIMathParenthesisSymbol class]]
		&& [senderType isEqualToString: kNTIMathTextfieldInput]) {
		//FIXME: #HACK: for input coming from a textfield, they use paranths to show the beginning of a sqrt and end the of a sqrt. That's why we tree these paranths a little more different from other types. Although it works, we need to have a general way of handling paranths inside of sqrt, the same regardless of where we came from. 
		[self.currentMathSymbol.parentMathSymbolFollowingLinks performSelector:@selector(swapNode:withNewNode:) withObject: self.currentMathSymbol withObject: newSymbol];
		self.currentMathSymbol = [(NTIMathUnaryExpression *)newSymbol childMathNode];
		return;
	}
		
	if ( isImplicitSymbol(self.currentMathSymbol, newSymbol, senderType) ) {
		[self addImplicitSymbolBetween: self.currentMathSymbol 
						  andNewSymbol: newSymbol 
							senderType: senderType];
		if (   [newSymbol respondsToSelector: @selector(isLiteral)] 
			&& [[(NTIMathAlphaNumericSymbol *)newSymbol mathSymbolValue] isEqualToString: @" "] && [senderType isEqualToString:kNTIMathTextfieldInput]) {
			return; 
			//we don't want to add a space symbol, we implicitly interpret it as an implicit addition.
		}
	}
	self.currentMathSymbol = [self addMathNode: newSymbol on: self.currentMathSymbol];
}

-(BOOL)shouldStringBeTreatedAsNegation: (NSString *)stringValue fromSenderType: (NSString *)senderType
{
	if( [stringValue isPlusMinusSymbol] ){
		return YES;
	}
	
	//IF we are a subtraction symbol that would go into a placeholder it is
	//a negation
	if(   [senderType isEqualToString: kNTIMathTextfieldInput]
	   && [stringValue isSubtractionSymbol] ){
		
		if( [self.currentMathSymbol respondsToSelector: @selector(isPlaceholder)]
		   && (   !self.currentMathSymbol.parentMathSymbol 
			   || [self.currentMathSymbol.parentMathSymbol respondsToSelector: @selector(isBinaryOperator)])){
			   return YES;
		}
	}
	
	return NO;
}

-(void)addMathSymbolForString: (NSString *)stringValue fromSenderType: (NSString *)senderType
{
	if( [self shouldStringBeTreatedAsNegation: stringValue fromSenderType: senderType] ) {
		if ([self.currentMathSymbol respondsToSelector:@selector(isLiteral)]) {
			[(NTIMathAlphaNumericSymbol *)self.currentMathSymbol setIsNegative: YES];
			return;
		}
		//if the user placed plusMinus when a placeholder is selected, we will create a literal and add the plus minus afterwards
		NTIMathAlphaNumericSymbol* lit = [[NTIMathAlphaNumericSymbol alloc] initWithValue:@""];
		[lit setIsNegative: YES];
		[self addMathExpression: lit senderType: senderType];
		return;
	}
	NTIMathSymbol* newSymbol = [self createMathSymbolForString: stringValue];
	if (newSymbol) {
		[self addMathExpression: newSymbol senderType: senderType];
	}
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
		OBASSERT(childSymbol == self->rootMathSymbol);
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
	//NTIMathSymbol* tempCurrentSymbol = self.rootMathSymbol;
	self.rootMathSymbol = [self mergeLastTreeOnStackWith: self.rootMathSymbol];
	return self.rootMathSymbol;
	//return tempCurrentSymbol;
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
	if ([plink.parentMathSymbol respondsToSelector:@selector(swapNode:withNewNode:)]) {
		[plink.parentMathSymbol performSelector:@selector(swapNode:withNewNode:) withObject:plink withObject: mathSymbol];
		self.currentMathSymbol = mathSymbol;
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
		//Unary and binary operators should respond to -swapNode:withNewNode:
		if ([pholder.parentMathSymbol respondsToSelector:@selector(swapNode:withNewNode:)]) {
			return [pholder.parentMathSymbol performSelector:@selector(swapNode:withNewNode:) withObject:pholder withObject: literal];
		}
		//return [pholder.parentMathSymbol addSymbol: literal];
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
	// Special casing: closing paranths
	if ([newNode respondsToSelector:@selector(isOperatorSymbol)] && 
		[[newNode toString] isEqualToString:@")"]) {
		//close and append tree --> closing paranthesis
		return [self closeAndAppendTree];
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
		self->fullEquation = self.rootMathSymbol;
		return self->fullEquation;
	}
	//First element is the root of all our roots
	self->fullEquation = [[self->mathExpressionQueue stack] objectAtIndex: 0];
	return self->fullEquation;
}

//this method gets called, when a user clicks on a leaf node( i.e literal button, placeholder button), at that point we create a new tree at the location.
-(void)selectSymbolAsNewExpression: (NTIMathSymbol *)mathSymbol
{
	//If we are the current symbol already, and you click on it, don't do anything.
	if (mathSymbol == self.currentMathSymbol && ![self.rootMathSymbol respondsToSelector:@selector(isUnaryOperator)]) {
		return;
	}
	//Before we create a new tree at the new current symbol, we will close the tree that we were working on.
	[self createTreeWithRoot: mathSymbol];
}

-(void)clearEquation
{
	NTIMathSymbol* pholder = [[NTIMathPlaceholderSymbol alloc] init];
	self.currentMathSymbol = pholder;
	[self->mathExpressionQueue removeAll];
}

-(void)addChildrenOfNode: (NTIMathSymbol *)mathSymbol to: (NTIMathSymbol *)parentSymbol
{
	NSArray* children;
	if ([mathSymbol respondsToSelector:@selector(nonEmptyChildren)]) {
		children = [mathSymbol performSelector:@selector(nonEmptyChildren)];
	}
	
	if (!children || children.count == 0) {
		return;
	}
	
	if (parentSymbol) {
		for (NTIMathSymbol* child in children) {
			//FIXME: we want to add only non-placeholders, or placeholders pointing to valid expression. 
			[parentSymbol addSymbol: child];
		}
	}
	else {
		OBASSERT(mathSymbol == self.rootMathSymbol);
		if (children.count == 1) {
			//old parent
			NTIMathSymbol* oldParent = self.rootMathSymbol;
			self.rootMathSymbol = [children objectAtIndex: 0];
			self.rootMathSymbol.substituteSymbol = oldParent.substituteSymbol;
			[(NTIMathPlaceholderSymbol *)self.rootMathSymbol.substituteSymbol setInPlaceOfObject: self.rootMathSymbol];
			self.currentMathSymbol = self.rootMathSymbol;
		}
		else if(children.count == 2) {
			//old parent
			NTIMathSymbol* oldParent = self.rootMathSymbol;
			self.rootMathSymbol = [children objectAtIndex: 0];
			self.rootMathSymbol.substituteSymbol = oldParent.substituteSymbol;
			[(NTIMathPlaceholderSymbol *)self.rootMathSymbol.substituteSymbol setInPlaceOfObject: self.rootMathSymbol];
			self.currentMathSymbol = self.rootMathSymbol;
			[self addMathExpression: [children objectAtIndex: 1] senderType: kNTIMathGraphicKeyboardInput];	
		}
	}
}

-(NTIMathSymbol *)deletePlaceHolderLink: (NTIMathPlaceholderSymbol *)placeholder forNode:(NTIMathSymbol *)aNode with: (NTIMathSymbol *)replacementNode
{
	if (![placeholder respondsToSelector:@selector(isPlaceholder)]) {
		return nil;
	}
	if ([aNode respondsToSelector:@selector(isBinaryOperator)] && aNode == [placeholder inPlaceOfObject]) {
		//We are replacing the binary node with its left/right node. 
		NTIMathBinaryExpression* bNode = (NTIMathBinaryExpression *)aNode;
		OBASSERT(bNode.leftMathNode == replacementNode);
		if (bNode.rightMathNode == replacementNode && ![replacementNode respondsToSelector:@selector(isPlaceholder)]) {
			bNode.rightMathNode.parentMathSymbol = nil;
			[placeholder setInPlaceOfObject: bNode.rightMathNode];
			[bNode.rightMathNode setSubstituteSymbol: bNode.substituteSymbol];
			return bNode.rightMathNode;
		}
		if (bNode.leftMathNode == replacementNode && ![replacementNode respondsToSelector:@selector(isPlaceholder)]) {
			bNode.leftMathNode.parentMathSymbol = nil;
			[placeholder setInPlaceOfObject: bNode.leftMathNode];
			[bNode.leftMathNode setSubstituteSymbol: bNode.substituteSymbol];
			return bNode.leftMathNode;
		}
	}
	// here, we are disconnecting/deleting the whole tree from the thing tree structure. 
	// FIXME: Need better documentation!
	if ([placeholder inPlaceOfObject] == aNode) {
		[placeholder setInPlaceOfObject:nil];
		self.rootMathSymbol = [self->mathExpressionQueue pop];
		return placeholder;
	}
	return nil;
}

-(NTIMathSymbol *)replaceNode: (NTIMathSymbol *)node withNode: (NTIMathSymbol *)replacementNode
{
	if (!replacementNode) {
		//create one
		replacementNode = [[NTIMathPlaceholderSymbol alloc] init];
	}
	NTIMathSymbol* parent = node.parentMathSymbolFollowingLinks;
	if (!parent) {
		replacementNode.parentMathSymbol = nil;
		//set the new root
		self.rootMathSymbol = replacementNode;
		return replacementNode;
	}
	else {
		NTIMathSymbol* result = [parent deleteSymbol: node];
		if (result) {
			return [parent addSymbol: replacementNode];
		}
		else {
			//NOTE: if our parent could not delete us, it will be because we are linked to our parent through a placeholder. In that case, deletion simply implies to remove the placeholder link to us. 
			for (NTIMathSymbol* child in parent.children) {
				NTIMathSymbol* temp = [self deletePlaceHolderLink:(NTIMathPlaceholderSymbol *)child forNode:node with:replacementNode];
				if (temp) {
					return temp;
				}
			}
		}
	}
	//???
	return replacementNode;
}



-(NTIMathSymbol *)deleteFirstChild: (NTIMathSymbol *)node ofbinaryExpression: (NTIMathBinaryExpression *)parent
{
	if ([node respondsToSelector:@selector(isPlaceholder)]) {
		// since it's a placeholder and it's the 1st child of a binary symbol, we should delete the grand parent, and add its left child to our parent.
		NTIMathExpressionReverseTraversal* tree = [[NTIMathExpressionReverseTraversal alloc] initWithRoot: self.rootMathSymbol selectedNode: node];
		NTIMathSymbol* previousNode = [tree previousNodeTo: node];
		if (  !previousNode 
			|| [previousNode respondsToSelector:@selector(isUnaryOperator)]
			|| [parent isKindOfClass:[NTIMathDivisionBinaryExpression class]]) {
			//replace our parent with the right child node
			return [self replaceNode: parent withNode: parent.rightMathNode];
		}
		else {
			//Special casing division and fraction.
			if ( [parent isKindOfClass:[NTIMathDivisionBinaryExpression class]]
				|| [[parent parentMathSymbolFollowingLinks] isKindOfClass: [NTIMathFractionBinaryExpression class]] ) {
				NTIMathSymbol* grandpa = [parent parentMathSymbolFollowingLinks];
				if (grandpa && [grandpa respondsToSelector:@selector(swapNode:withNewNode:)]) {
					return [grandpa performSelector: @selector(swapNode:withNewNode:) withObject: parent withObject: parent.rightMathNode];
				}
			}
			//Hard case, we need to delete the grand parent and add the left to be the parent.
			if ([previousNode respondsToSelector:@selector(isBinaryOperator)]) {
				// we know we have two binary operators.
				NTIMathBinaryExpression* bpreviousNode = (NTIMathBinaryExpression *)previousNode;
				//see if we should update the tree stack after the swapping
				//BOOL result = doesTreeContainNode( self.rootMathSymbol, parent);
				// if the parent node is not part of the current tree, then we should pop the last tree. 
				if (node.parentMathSymbol != node.parentMathSymbolFollowingLinks){
					self.rootMathSymbol = [self mergeLastTreeOnStackWith: self.rootMathSymbol];
				}
				//FIXME: does this generalizes? should we always want to make the new parent the root?
				parent.parentMathSymbol = nil;
				return [parent swapNode: node withNewNode: bpreviousNode.leftMathNode];
			}
		}
		//In case where we don't have a grand parent, then the right child of parent becomes the parent  
	}
	
	//???
	return parent;
}

-(NTIMathSymbol *)deleteLastChild: (NTIMathSymbol *)mathsymbol ofbinaryExpression: (NTIMathBinaryExpression *)parent
{
	if (parent.parentMathSymbolFollowingLinks) {
		//NTIMathSymbol* grandpa = parent.parentMathSymbolFollowingLinks;
		return [self replaceNode:parent withNode: parent.leftMathNode];
	}
	else {
		parent.leftMathNode.parentMathSymbol = nil;
		//we ought to become the parent
		return parent.leftMathNode;
	}
}

-(NTIMathSymbol *)handleDeletionOfExpression: (NTIMathSymbol *)mathNode
{
	//we have a literal
	if ([mathNode respondsToSelector:@selector(isLiteral)]) {
		NTIMathSymbol* newCurrentNode = [(NTIMathAlphaNumericSymbol *)mathNode deleteLastLiteral];
		if (newCurrentNode) {
			return newCurrentNode;
		}
	}
	if ([mathNode respondsToSelector:@selector(isPlaceholder)]) {
		//we have a placeholder. Deleting a placeholder may imply deleting the binary expression it is associated with.
		NTIMathSymbol* parent = mathNode.parentMathSymbolFollowingLinks;
		if (!parent) {
			return mathNode;
		}
		else {
			if ([parent respondsToSelector:@selector(isUnaryOperator)]) {
				return [self replaceNode: parent withNode: mathNode];
			}
			else {
				// we assume it's a binary expression
				if (parent.firstChild == mathNode) {
					return [self deleteFirstChild: mathNode ofbinaryExpression: (NTIMathBinaryExpression *)parent];
				}
				else {
					//we assume this is the last child node
					return [self deleteLastChild: mathNode ofbinaryExpression: (NTIMathBinaryExpression *)parent];
				}
			}
		}
	}
	else {
		//we are deleting a non-leaf node( binary or unary expression or a literal with one symbol
		return [self replaceNode: mathNode withNode: nil];
	}
}

-(void)deleteMathExpression: (NTIMathSymbol *)aMathSymbol
{
	if (!aMathSymbol) {
		//if nothing is selected, we assume the user wants to delete the current symbol
		aMathSymbol = self.currentMathSymbol;
	}
	self.currentMathSymbol = [self handleDeletionOfExpression: aMathSymbol];
}

-(void)connectSubtreesUnderneathTree: (NTIMathSymbol *)mathsymbol
{
	//NOTE: We want to make sure that if things are part of the current tree, are not on the stack at the same time.
	if ([[self->mathExpressionQueue stack] containsObject: mathsymbol]) {
		[self->mathExpressionQueue removeMathExpression: mathsymbol];
	}
	
	if ( [mathsymbol respondsToSelector:@selector(isPlaceholder)]
		&& [(NTIMathPlaceholderSymbol *)mathsymbol inPlaceOfObject]){
		NTIMathSymbol* representedObj = [(NTIMathPlaceholderSymbol *)mathsymbol inPlaceOfObject];
		NTIMathSymbol* parent = mathsymbol.parentMathSymbol;
		if (parent && [parent respondsToSelector:@selector(swapNode:withNewNode:)]) {
			[parent performSelector: @selector(swapNode:withNewNode:) withObject: mathsymbol withObject: representedObj];
			//Remove it from stack tree
			[self->mathExpressionQueue removeMathExpression: representedObj];
			[self connectSubtreesUnderneathTree: representedObj];
			return;
		}
	}
	else {
		for (NTIMathSymbol* child in mathsymbol.children) {
			[self connectSubtreesUnderneathTree: child];
		}
	}
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
	if ( [stringValue isClosingParanthesisSymbol] ) {
		return [[NTIMathOperatorSymbol alloc] initWithValue:@")"];
	}
	if ( [stringValue isMathPrefixedSymbol] ) {
		return [NTIMathUnaryExpression unaryExpressionForString: stringValue];
	}
	if ( [stringValue isMathBinaryCombiningSymbol] ) {
		if ([stringValue isEqualToString:@"x/y"]) {
			stringValue = @"/";
		}
		return [NTIMathBinaryExpression binaryExpressionForString: stringValue];
	}
	
	//Right now anything that was typed that we do not handle, we will treat it as a literal
	return  [[NTIMathAlphaNumericSymbol alloc] initWithValue: stringValue];
	//return nil;
}

-(void)logCurrentAndRootSymbol
{
	NSLog(@"root's string: %@,\ncurrentSymbol's string: %@", [self.rootMathSymbol toString], [self.currentMathSymbol toString]);
}


#pragma mark -- Navigation through an equation. These functions should be used in the graphic math keyboard

static NSArray* gatherNodes(NTIMathSymbol* root, NSMutableArray* result)
{
	if(!root || [result containsObjectIdenticalTo: root]){
		return result;
	}
	
	[result addObject: root];
	gatherNodes(root.firstChild, result);
	gatherNodes([root.childrenFollowingLinks lastObjectOrNil], result);
	return result;
}

//NOTE. we have a terribly inefficient next and previous implementation
//that requires flattening the tree each time....

-(void)goNextFrom: (NTIMathSymbol*)symbol
{
	NTIMathSymbol* root = symbol;
	while(root.parentMathSymbolFollowingLinks){
		root = root.parentMathSymbolFollowingLinks;
	}

	NSArray* traversal = gatherNodes(root, [NSMutableArray array]);
	
	NSUInteger currentIndex = [traversal indexOfObjectIdenticalTo: symbol];
	NSUInteger nextIndex = 0;
	if(currentIndex != NSNotFound && currentIndex + 1 < traversal.count){
		nextIndex = currentIndex + 1;
	}
	
	self.currentMathSymbol = [traversal objectAtIndex: nextIndex];
	
//	NTIMathSymbol* next = symbol.nextSibling;
//	if(!next){
//		next = symbol.firstChild;
//	}
//	
//	if(next){
//		self.currentMathSymbol = next;
//	}
//	else{
//		//at the beginning, go all the way to the other end
//		//which is the root
//		NTIMathSymbol* mathSymbol = symbol;
//		while(mathSymbol.parentMathSymbolFollowingLinks){
//			mathSymbol = mathSymbol.parentMathSymbolFollowingLinks;
//		}
//		self.currentMathSymbol = mathSymbol;
//	}
}

//If we have a next sibling go to that, else go to our first child
-(void)nextKeyPressed
{
	NTIMathSymbol* current = [NTIMathSymbol followIfPlaceholder: self.currentMathSymbol];
	
	[self goNextFrom: current];
}

-(void)goPreviousFrom: (NTIMathSymbol*)symbol
{
	
	NTIMathSymbol* root = symbol;
	while(root.parentMathSymbolFollowingLinks){
		root = root.parentMathSymbolFollowingLinks;
	}
	
	NSArray* traversal = gatherNodes(root, [NSMutableArray array]);
	
	NSInteger currentIndex = [traversal indexOfObjectIdenticalTo: symbol];
	NSUInteger nextIndex = traversal.count - 1;
	if(currentIndex != NSNotFound && currentIndex - 1 >= 0){
		nextIndex = currentIndex - 1;
	}
	
	self.currentMathSymbol = [traversal objectAtIndex: nextIndex];
	
//	NTIMathSymbol* previous = symbol.previousSibling;
//	
//	if(!previous){
//		previous = [symbol.childrenFollowingLinks lastObjectOrNil];
//	}
//	
//	if(previous){
//		self.currentMathSymbol = previous;
//	}
//	else{
//		//at the beginning, go all the way to the other end
//		//which is the root
//		NTIMathSymbol* mathSymbol = symbol;
//		while(mathSymbol.parentMathSymbolFollowingLinks){
//			mathSymbol = mathSymbol.parentMathSymbolFollowingLinks;
//		}
//		self.currentMathSymbol = mathSymbol;
//	}
}

//If we have a previous sibling go there, else go to our parent
-(void)backPressed
{
	NTIMathSymbol* current = [NTIMathSymbol followIfPlaceholder: self.currentMathSymbol];
	[self goPreviousFrom: current];
}

@end
