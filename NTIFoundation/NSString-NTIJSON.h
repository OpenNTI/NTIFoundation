//
//  NSString-NTIJSON.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/07/25.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NTIJSON)
/**
 * If this object is a pareable JSON type, returns the parsed
 * value. Otherwise returns nil. Currently works for arrays of
 * simple types. Whitespacing is tricky. Arrays returned are mutable.
 */
-(id)jsonObjectValue;
@end
