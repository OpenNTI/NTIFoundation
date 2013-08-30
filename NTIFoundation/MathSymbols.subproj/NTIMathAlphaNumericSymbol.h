//
//  NTIAlphaNumericSymbol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIMathSymbol.h"

@interface NTIMathAlphaNumericSymbol : NTIMathSymbol {
}
@property(nonatomic) BOOL isNegative;
@property(nonatomic, strong) NSString* mathSymbolValue;

-(id)initWithValue: (NSString *)value;
-(NTIMathSymbol *)deleteLastLiteral;
-(BOOL)isLiteral;
-(NTIMathSymbol *)appendMathSymbol: (NTIMathSymbol *)newSymbol;
@end
