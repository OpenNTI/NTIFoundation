//
//  NTIMathAbstractBinaryCombiningSymbol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbol.h"
@interface NTIMathAbstractBinaryCombiningSymbol : NTIMathSymbol {
}

@property( nonatomic, strong) NTIMathSymbol* leftMathSymbol;
@property( nonatomic, strong) NTIMathSymbol* rightMathSymbol;
@property( nonatomic ) BOOL leftSymbolOpen;	//To switch between left and right symbol.
@property( nonatomic ) BOOL rightSymbolOpen;

-(id)initWithLeftMathSymbol: (NTIMathSymbol *)leftSymbol rightMathSymbol: (NTIMathSymbol *)rightSymbol;

@end
