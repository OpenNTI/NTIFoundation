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

+(NSUInteger)precedenceLevel;

@property(nonatomic, strong) NTIMathSymbol* parentMathSymbol;
@property (nonatomic, readonly) NTIMathSymbol* parentMathSymbolFollowingLinks;
@property (nonatomic, readonly) NTIMathSymbol* nextSibling;
@property (nonatomic, readonly) NTIMathSymbol* previousSibling;
@property (nonatomic, readonly) NTIMathSymbol* firstChild;
@property (nonatomic, readonly) NSArray* children;
@property (nonatomic, readonly) NSArray* childrenFollowingLinks;

@property(nonatomic, weak) NTIMathSymbol* substituteSymbol; //should only be a placeholder.
 
+(NTIMathSymbol*)followIfPlaceholder: (NTIMathSymbol*) symbol;

//Any valid expression, can have parenthesis. They can be explicit or implicit
//@property(nonatomic)BOOL hasParenthesis;

-(NSString *)toString;
-(NSString *)latexValue;
@end
