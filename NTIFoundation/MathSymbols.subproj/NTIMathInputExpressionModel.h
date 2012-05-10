//
//  NTIMathInputExpressionModel.h
//  NTIFoundation
//
//  Created by  on 4/26/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NTIMathSymbol;
@interface NTIMathInputExpressionModel : NSObject{
	@private
	NTIMathSymbol* currentMathSymbol;
	NTIMathSymbol* rootMathSymbol;
	NSMutableArray* stackEquationTrees;
}

-(id)initWithMathSymbol:(NTIMathSymbol *)mathExpression;
//Addition
-(void)addMathSymbolForString: (NSString *)stringValue;
//Selection
-(void)setCurrentSymbolTo: (NTIMathSymbol *)mathSymbol;
//Deletion
-(void)deleteMathExpression: (NTIMathSymbol *)aMathSymbol;
//Output
-(NTIMathSymbol *)fullEquation;
-(NSString *)generateEquationString;
-(NSString *)tolaTex;
//Selection and navigation
-(NTIMathSymbol *)currentMathSymbol;

//Helpers
-(void)clearEquation;
-(NTIMathSymbol *)findLastLeafNodeFrom: (NTIMathSymbol *)mathSymbol;
-(NTIMathSymbol *)findFirstLeafNodeFrom: (NTIMathSymbol *)mathSymbol;
-(NTIMathSymbol *)findPlaceHolderLinkIn: (NTIMathSymbol *)mathNode;
-(NTIMathSymbol *)mergeLastTreeOnStackWith: (NTIMathSymbol *)mathSymbol;
@end
