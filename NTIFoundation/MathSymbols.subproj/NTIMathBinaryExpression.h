//
//  NTIMathBinaryExpression.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbol.h"
@class NTIMathOperatorSymbol;
@interface NTIMathBinaryExpression : NTIMathSymbol {
	NSUInteger precedenceLevel;
}

@property( nonatomic, strong, readonly) NTIMathOperatorSymbol* operatorMathNode;	//Parent node
@property( nonatomic, strong) NTIMathSymbol* leftMathNode;
@property( nonatomic, strong) NTIMathSymbol* rightMathNode;

-(id)initWithMathOperatorSymbol: (NSString *)operatorString;
-(BOOL)isBinaryOperator;
@end
