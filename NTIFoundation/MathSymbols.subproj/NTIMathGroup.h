//
//  NTIMathGroup.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIMathSymbol.h"
@interface NTIMathGroup : NTIMathSymbol {
	NSMutableArray* _components;
}

-(NSArray *)components;
-(id)initWithMathSymbol: (NTIMathSymbol *)aSymbol;
-(id)initWithMathGroupSymbol: (NTIMathGroup *)aSymbol;
-(void)removeAllMathSymbols;
@end
