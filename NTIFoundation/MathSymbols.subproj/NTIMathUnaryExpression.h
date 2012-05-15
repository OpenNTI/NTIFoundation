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
@property( nonatomic ) NSUInteger precedenceLevel; 

-(id)initWithMathOperatorString: (NSString *)operatorString;
-(BOOL)isUnaryOperator;
@end
