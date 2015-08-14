//
//  NTIMathPlaceholderSymbol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIMathSymbol.h"

@interface NTIMathPlaceholderSymbol : NTIMathSymbol
@property(nonatomic, strong)NTIMathSymbol* inPlaceOfObject;
-(BOOL)isPlaceholder;
@end
