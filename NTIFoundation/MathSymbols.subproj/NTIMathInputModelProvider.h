//
//  NTIMathInputModelProvider.h
//  NTIFoundation
//
//  Created by  on 4/26/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIMathSymbol.h"
@protocol NTIMathInputModelProvider <NSObject>
@property(nonatomic, strong)NTIMathSymbol* mathSymbolInputModel;	//can be kvo-ed.
@end
