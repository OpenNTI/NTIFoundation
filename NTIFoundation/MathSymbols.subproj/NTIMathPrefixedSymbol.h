//
//  NTIMathPrefixedSymbol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbol.h"
@interface NTIMathPrefixedSymbol : NTIMathSymbol {
	NSString* symbolValue;
}
@property( nonatomic, strong) NTIMathSymbol* prefix;
@property( nonatomic, strong) NTIMathSymbol* contents;
@property( nonatomic ) BOOL canAddNewSymbol;

-(id)initWithSymbolValue: (NSString *)value 
		  withMathSymbol: (NTIMathSymbol *)mathSymbol;
@end
