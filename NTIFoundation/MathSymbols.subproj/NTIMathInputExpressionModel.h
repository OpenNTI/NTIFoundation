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
//@property( nonatomic, strong) NTIMathSymbol* mathInputModel;
-(id)initWithMathSymbol:(NTIMathSymbol *)mathExpression;
-(void)addMathSymbolForString: (NSString *)stringValue;
-(NTIMathSymbol *)fullEquation;
-(NSString *)generateEquationString;
-(void)setCurrentSymbolTo: (NTIMathSymbol *)mathSymbol;
@end
