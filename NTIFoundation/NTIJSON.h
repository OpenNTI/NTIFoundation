//
//  NTIJSON.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/14.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef _NSOBJECT_NTIJSON
#define _NSOBJECT_NTIJSON
/**
 * An informal protocol for things that have a JSON
 * representation.
 */
@interface NSObject(NTIJSON)
-(NSString*)stringWithJsonRepresentation;
/**
 * Because we have to wrap null to NSNull in JSON collections, this 
 * lets us easily unwrap.
 */
-(id)jsonObjectUnwrap;

@end
#endif
