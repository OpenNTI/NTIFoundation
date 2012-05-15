//
//  NTIMathSymbolUtils.m
//  NTIFoundation
//
//  Created by  on 5/14/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbolUtils.h"
#import "NTIMathPrefixedSymbol.h"
#import "NTIMathAbstractBinaryCombiningSymbol.h"
#import "NTIMathPlaceholderSymbol.h"


@implementation NTIMathExpressionReverseTraversal
static void traverseDepthFirstStartAt(NTIMathSymbol* mathNode, NSMutableArray* nodesArray)
{
	if ([mathNode respondsToSelector:@selector(isBinaryOperator)]) {
		NTIMathAbstractBinaryCombiningSymbol* bMathNode = (NTIMathAbstractBinaryCombiningSymbol *)mathNode;
		//Add left subtree
		traverseDepthFirstStartAt(bMathNode.leftMathNode, nodesArray);
		//Add the root. FIXME: should we add the whole BinaryOperator or just the operator?
		[nodesArray addObject: bMathNode.operatorMathNode];
		//Add the right subtree
		traverseDepthFirstStartAt(bMathNode.rightMathNode, nodesArray);
	}
	else if([mathNode respondsToSelector:@selector(isUnaryOperator)]) {
		NTIMathPrefixedSymbol* uMathNode = (NTIMathPrefixedSymbol *)mathNode;
		//Add the root
		[nodesArray addObject: uMathNode.prefix];
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

//TODO: For now, we are doing a naive approach, we will delete a given node, and regenerate the tree. The performance cost of regenerating a tree shouldn't be that bad given that these trees are small and we may often be dealing with a subtree. 
-(void)deleteCurrentNode
{
	if ([self->currentNode respondsToSelector:@selector(isPlaceholder)]) {
		NTIMathSymbol* previousNode = [self previousNodeTo:self->currentNode];
		if (previousNode) {
			[self->flattenTree removeObject: self->currentNode];
			NTIMathSymbol* newSelectedSymbol = [self previousNodeTo: previousNode];
			[self->flattenTree removeObject: previousNode];
			self->currentNode = newSelectedSymbol;
			OBASSERT(self->currentNode);
		}
	}
	else {
		NTIMathSymbol* previousNode = [self previousNodeTo:self->currentNode];
		[self->flattenTree removeObject: self->currentNode];
		self->currentNode = previousNode;
	}
}

-(NSString *)newEquationString
{
	NSString* eqString=@"";
	for (NTIMathSymbol* mathSymbol in self->flattenTree) {
		eqString = [NSString stringWithFormat:@"%@%@", eqString, [mathSymbol toString]];
	}
	return eqString;
}

//-(NTIMathSymbol *)replaceNode: (NTIMathSymbol *)mathNode with:(NTIMathSymbol *)newMathNode
//{
//	if (mathNode.parentMathSymbol) {
//		[mathNode.parentMathSymbol deleteSymbol:mathNode];
//		//Update our flatten array
//		[self->flattenTree removeObject: mathNode];
//		return [mathNode.parentMathSymbol addSymbol: newMathNode];
//	}
//	else {
//		//if we don't have a parent, we will just replace the parent. Still more to do?
//		newMathNode.substituteSymbol = mathNode.substituteSymbol;
//	}
//	return nil;
//}
//
//-(BOOL)mathNodeIsRightNode: (NTIMathSymbol *)mathNode
//{
//	if (mathNode.parentMathSymbol) {
//		if ([mathNode.parentMathSymbol respondsToSelector:@selector(isBinaryOperator)]) {
//			return [(NTIMathAbstractBinaryCombiningSymbol *)mathNode.parentMathSymbol rightMathNode] == mathNode;
//		}
//		if ([mathNode.parentMathSymbol respondsToSelector:@selector(isUnaryOperator)]) {
//			return [(NTIMathPrefixedSymbol *)mathNode childMathNode] == mathNode;
//		}
//	}
//	return NO;
//}
//
//-(NTIMathSymbol *)nextBinarySymbolFrom: (NTIMathSymbol *)mathSymbol
//{
//	NSUInteger currentIndex =[self->flattenTree indexOfObject: mathSymbol];
//	if (currentIndex == NSNotFound) {
//		return nil;
//	}
//	for (NSUInteger i = currentIndex; i< self->flattenTree.count; i++) {
//		if ([[self->flattenTree objectAtIndex:i] respondsToSelector:@selector(isBinaryOperator)]) {
//			return [self->flattenTree objectAtIndex: i];
//		}
//	}
//	return nil;
//}
//
////We return the nextSymbol
//-(NTIMathSymbol *)deleteMathNode
//{
//	//if the current node is not a placeholder and has a parent,
//	if (self->currentNode.parentMathSymbol) {
//		if (![self->currentNode respondsToSelector:@selector(isPlaceholder)]) {
//			self->currentNode = [self->currentNode.parentMathSymbol deleteSymbol: self->currentNode];
//			return self->currentNode;
//		}
//		else {
//			//If the right expression is a placeholder, we will delete both the placeholder and its parent, and if we have something on the left node, it will replace it.
//			if ([self mathNodeIsRightNode: self->currentNode]) {
//				NTIMathSymbol* leftNode = [self->currentNode.parentMathSymbol performSelector:@selector(leftMathNode)];
//				return [self replaceNode:self->currentNode.parentMathSymbol with: leftNode];
//			}
//			else {
//				//Decide which symbol to delete
//				NTIMathSymbol* nextSymbol = [self previousNode];
//				NTIMathSymbol* leftNode;
//				if ([nextSymbol respondsToSelector:@selector(leftMathNode)]) {
//					leftNode = [nextSymbol performSelector:@selector(leftMathNode)];
//				}
//				
//				//Reparenting the tree.
//				NTIMathSymbol* newParent = [self nextBinarySymbolFrom: self->currentNode];
//				if (newParent) {
//					return [newParent addSymbol:leftNode];
//				}
//			}
//		}
//	}
//	return nil;
//}


@end
