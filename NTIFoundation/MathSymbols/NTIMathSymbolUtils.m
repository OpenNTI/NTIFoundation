//
//  NTIMathSymbolUtils.m
//  NTIFoundation
//
//  Created by  on 5/14/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbolUtils.h"
#import "NTIMathUnaryExpression.h"
#import "NTIMathBinaryExpression.h"
#import "NTIMathPlaceholderSymbol.h"
#import "NTIMathParenthesisSymbol.h"

@implementation NTIMathExpressionReverseTraversal
static void traverseDepthFirstStartAt(NTIMathSymbol* mathNode, NSMutableArray* nodesArray)
{
	if ([mathNode respondsToSelector:@selector(isBinaryOperator)]) {
		NTIMathBinaryExpression* bMathNode = (NTIMathBinaryExpression *)mathNode;
		//Add left subtree
		traverseDepthFirstStartAt(bMathNode.leftMathNode, nodesArray);
		//Add the root. FIXME: should we add the whole BinaryOperator or just the operator?
		[nodesArray addObject: bMathNode];
		//Add the right subtree
		traverseDepthFirstStartAt(bMathNode.rightMathNode, nodesArray);
	}
	else if([mathNode respondsToSelector:@selector(isUnaryOperator)]) {	
		//FIXME: NEEDS refactoring.
		NTIMathUnaryExpression* uMathNode = (NTIMathUnaryExpression *)mathNode;
		//Add the root
		[nodesArray addObject: uMathNode];
		//Add the child subtree
		traverseDepthFirstStartAt(uMathNode.childMathNode, nodesArray);
	}
	else {
		//it's a leaf node, add it to the array
		if (mathNode) {
			[nodesArray addObject: mathNode];
		}
	}
}

-(id)initWithRoot:(NTIMathSymbol *)aRootNode selectedNode:(NTIMathSymbol *)aCurrentNode
{
	self = [super init];
	if (self) {
		rootNode = aRootNode;
		currentNode = aCurrentNode;
		flattenTree = [NSMutableArray array];
		traverseDepthFirstStartAt( aRootNode, flattenTree);
	}
	return self;
}

-(NTIMathSymbol *)previousNodeTo: (NTIMathSymbol*)mathNode
{
	//flatten the tree
	//traverseDepthFirstStartAt(self->rootNode, self->flattenTree);
	//find index of the currentNode
	NSUInteger currentIndex = [self->flattenTree indexOfObject: mathNode];
	//
	if (currentIndex == NSNotFound) {
		return nil;
	}
	else {
		//find what proceeds the currentSymbol
		if (currentIndex == 0) {
			return nil;
		}
		else {
			OBASSERT(currentIndex - 1 >= 0);
			return [self->flattenTree objectAtIndex: currentIndex - 1]; 
		}
	}
}
@end
