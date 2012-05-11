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

-(NSString *)toString;
-(NSString *)latexValue;
-(NSArray *)children;
@end
