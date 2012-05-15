//
//  NTIMathParenthesisSymbol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbol.h"

@interface NTIMathParenthesisSymbol: NTIMathSymbol
@property(nonatomic, readonly)BOOL openingParanthesis; //either we have an opening paranthesis or a closing paranthesis
-(id)initWithMathSymbolString: (NSString *)string;
@end
