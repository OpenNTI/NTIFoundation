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

-(NSString *)toString;
-(NSString *)latexValue;
@end
