//
//  NTIMathUnaryExpression.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbol.h"
@interface NTIMathUnaryExpression : NTIMathSymbol {
	NSString* symbolValue;
	NSUInteger precedenceLevel;
}
@property( nonatomic, strong, readonly) NTIMathSymbol* prefix;
@property( nonatomic, strong) NTIMathSymbol* childMathNode; 

+(NTIMathUnaryExpression *)unaryExpressionForString: (NSString *)stringValue;
-(id)initWithMathOperatorString: (NSString *)operatorString;
-(NTIMathSymbol *)swapNode: (NTIMathSymbol *)childNode 
			   withNewNode: (NTIMathSymbol *)newNode;
-(BOOL)isUnaryOperator;
-(NSString *)toStringValueForChildNode: (NTIMathSymbol *)childExpression;
-(NSString *)latexValueForChildNode: (NTIMathSymbol *)childExpression;
@end

@interface NTIMathAprroxUnaryExpression : NTIMathUnaryExpression
@end

@interface NTIMathSquareRootUnaryExpression : NTIMathUnaryExpression 
@end
