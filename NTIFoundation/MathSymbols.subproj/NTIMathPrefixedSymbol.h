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
@property( nonatomic, strong, readonly) NTIMathSymbol* prefix;
@property( nonatomic, strong) NTIMathSymbol* childMathNode;
//@property( nonatomic, strong) NTIMathSymbol* contents;
//@property( nonatomic ) BOOL canAddNewSymbol;
@property( nonatomic ) NSUInteger precedenceLevel; 

//-(id)initWithSymbolValue: (NSString *)value 
//		  withMathSymbol: (NTIMathSymbol *)mathSymbol;
-(id)initWithMathOperatorString: (NSString *)operatorString;

@end
