//
//  NTIMathOperatorSymbol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbol.h"

@interface NTIMathOperatorSymbol : NTIMathSymbol{
}
@property( nonatomic, strong )NSString* mathSymbolValue;

-(id)initWithValue: (NSString *)value;
@end
