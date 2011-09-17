//
//  NSArray-NTIExtensions.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/15.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniFoundation/NSArray-OFExtensions.h>

@interface NSArray (NTIExtensions)
@property(nonatomic,readonly) id firstObject;
@property(nonatomic,readonly) id secondObject;
/**
 * Returns the last object, or nil if this array is empty.
 */
@property(nonatomic,readonly) id lastObjectOrNil;

/**
 * Returns the last non-null object in this array, or nil if
 * the array is empty.
 */
@property (nonatomic,readonly) id lastNonNullObject;
+(BOOL)isEmptyArray: (id)a;
@end
