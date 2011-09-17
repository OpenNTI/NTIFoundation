//
//  NSMutableArray-NTIExtensions.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/15.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniFoundation/NSMutableArray-OFExtensions.h>
#import "NSArray-NTIExtensions.h"

@interface NSMutableArray(NTIExtensions)
-(id)removeAndReturnLastObject;
/**
 * Pushes the object to the back of the array. Returns the array.
 */
-(NSMutableArray*)push: (id)anObject;

/**
 * Removes the last object and returns it.
 */
-(id)pop;
@end

