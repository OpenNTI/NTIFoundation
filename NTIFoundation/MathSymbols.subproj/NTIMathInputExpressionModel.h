//
//  NTIMathInputExpressionModel.h
//  NTIFoundation
//
//  Created by  on 4/26/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNTIMathGraphicKeyboardInput @"NTIMathGraphicKeyboardInput"
#define kNTIMathTextfieldInput @"NTIMathTextfieldInput"

@class NTIMathSymbol;
@class NTIMathExpressionStack;
@interface NTIMathInputExpressionModel : NSObject{
	@private
	NTIMathSymbol* currentMathSymbol;
	NTIMathSymbol* rootMathSymbol;
	NTIMathExpressionStack* mathExpressionQueue;
}
// RootMathSymbol is mainly used mainly for keeping up with internal state.
@property(nonatomic, strong) NTIMathSymbol* rootMathSymbol;
// FullEquation is used as an output. It will always be the root of all roots. 
@property(nonatomic, strong, readonly) NTIMathSymbol* fullEquation;

-(id)initWithMathSymbol:(NTIMathSymbol *)mathExpression;
//Addition
-(void)addMathSymbolForString: (NSString *)stringValue 
			   fromSenderType: (NSString *)senderType;
-(void)addMathExpression: (NTIMathSymbol *)newSymbol senderType: (NSString *)senderType;
//Selection
-(void)setCurrentSymbolTo: (NTIMathSymbol *)mathSymbol;
//Deletion
-(void)deleteMathExpression: (NTIMathSymbol *)aMathSymbol;
-(NSString *)generateEquationString;
-(NSString *)tolaTex;
//Selection and navigation
-(NTIMathSymbol *)currentMathSymbol;

//Helpers
-(void)clearEquation;
-(NTIMathSymbol *)findLastLeafNodeFrom: (NTIMathSymbol *)mathSymbol;
-(NTIMathSymbol *)findFirstLeafNodeFrom: (NTIMathSymbol *)mathSymbol;
-(NTIMathSymbol *)mergeLastTreeOnStackWith: (NTIMathSymbol *)mathSymbol;
@end
