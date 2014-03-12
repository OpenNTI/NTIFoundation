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
}
@property( nonatomic, strong, readonly) NTIMathSymbol* prefix;
@property( nonatomic, strong) NTIMathSymbol* childMathNode; 

+(NTIMathUnaryExpression *)unaryExpressionForString: (NSString *)stringValue;
-(id)initWithMathOperatorString: (NSString *)operatorString;
-(NTIMathSymbol *)swapNode: (NTIMathSymbol *)childNode 
			   withNewNode: (NTIMathSymbol *)newNode;
-(BOOL)isUnaryOperator;
-(NSString *)toStringValueForChildNode: (NTIMathSymbol *)childExpression;
-(NSString *)latexValueForChildNode: (NTIMathSymbol *)childExpression;;
-(void)replaceNode: (NTIMathSymbol *)newMathNode withPlaceholderFor: (NTIMathSymbol *)pointingTo;
-(NSArray *)nonEmptyChildren;
@end

@interface NTIMathAprroxUnaryExpression : NTIMathUnaryExpression
@end

@interface NTIMathSquareRootUnaryExpression : NTIMathUnaryExpression 
@end
