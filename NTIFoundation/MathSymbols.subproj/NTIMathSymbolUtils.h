//
//  NTIMathSymbolUtils.h
//  NTIFoundation
//
//  Created by  on 5/14/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIMathSymbol.h"
@interface NTIMathExpressionReverseTraversal : NSObject {
@private
    NTIMathSymbol* rootNode;
	NTIMathSymbol* currentNode;
	NSMutableArray* flattenTree;
}
-(id)initWithRoot:(NTIMathSymbol *)aRootNode selectedNode: (NTIMathSymbol *)aCurrentNode;
-(NTIMathSymbol *)previousNodeTo: (NTIMathSymbol*)mathNode;
-(NSString *)newEquationString;
-(void)deleteCurrentNode;
@end