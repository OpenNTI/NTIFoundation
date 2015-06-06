//
//  NSMutableDictionary+NTIExtensions.h
//  NTIFoundation
//
//  Created by Christopher Utz on 8/15/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary(NTIExtensions)
-(NSMutableDictionary*)stripKeysWithNullValues;
@end
