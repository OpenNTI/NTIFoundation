//
//  NTIMathSymbol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIMathExpressionSymbolProtocol.h"
@interface NTIMathSymbol : NSObject<NTIMathExpressionSymbolProtocol>

@property(nonatomic, strong) NTIMathSymbol* parentMathSymbol;
@property(nonatomic) NSUInteger precedenceLevel;
@property(nonatomic, weak) NTIMathSymbol* substituteSymbol; //should only be a placeholder.
//Any valid expression, can have parenthesis. They can be explicit or implicit
//@property(nonatomic)BOOL hasParenthesis;

-(NSString *)toString;
-(NSString *)latexValue;
-(NSArray *)children;
@end
